// The crate name must match the DLL name Arma expects (TBD_DB_x64).
#![allow(non_snake_case)]

use lazy_static::lazy_static;
use parking_lot::Mutex;
use rusqlite::{Connection, Result};
use std::cmp;
use std::collections::HashMap;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::ptr;

// -- Configuration --
const DB_FILENAME: &str = "TBD_DB.db";
const CHUNK_SIZE: usize = 9000;
const MAX_DB_SIZE: u64 = 1024 * 1024 * 1024; // 1024 MB

// -- State --
struct CachedRead {
    data: Vec<u8>,
    chunks: Vec<(usize, usize)>,
}

struct AppState {
    conn: Option<Connection>,
    read_cache: HashMap<String, CachedRead>,
}

/// Splits `data` into byte ranges of at most CHUNK_SIZE, snapping each cut to
/// a UTF-8 char boundary so multi-byte characters are never split across
/// chunks (which would corrupt them via from_utf8_lossy).
fn compute_chunks(data: &[u8]) -> Vec<(usize, usize)> {
    let len = data.len();
    let mut chunks = Vec::with_capacity(len / CHUNK_SIZE + 1);
    let mut start = 0;
    while start < len {
        let mut end = cmp::min(start + CHUNK_SIZE, len);
        while end > start && end < len && (data[end] & 0xC0) == 0x80 {
            end -= 1;
        }
        if end == start {
            // Not valid UTF-8 at this position; fall back to a hard byte cut.
            end = cmp::min(start + CHUNK_SIZE, len);
        }
        chunks.push((start, end));
        start = end;
    }
    chunks
}

lazy_static! {
    static ref STATE: Mutex<AppState> = Mutex::new(AppState {
        conn: None,
        read_cache: HashMap::new(),
    });
}

// -- Helpers --
fn init_db(state: &mut AppState) -> Result<(), String> {
    if state.conn.is_some() {
        return Ok(());
    }
    let db_path = DB_FILENAME;
    let conn = Connection::open(db_path).map_err(|e| format!("DB Open Error: {}", e))?;
    conn.execute("PRAGMA journal_mode=WAL;", []).ok();
    conn.execute("PRAGMA synchronous=NORMAL;", []).ok();
    conn.execute(
        "CREATE TABLE IF NOT EXISTS filesystem (
            path TEXT PRIMARY KEY,
            data BLOB,
            size INTEGER
        )",
        [],
    )
    .map_err(|e| format!("Create Table Error: {}", e))?;
    state.conn = Some(conn);
    Ok(())
}

// -- ARMA 3 EXTENSION ENTRY POINTS --

/// # Safety
/// Called by the Arma 3 engine. `output` must point to a writable buffer of
/// at least `output_size` bytes.
#[no_mangle]
pub unsafe extern "C" fn RVExtensionVersion(output: *mut c_char, output_size: usize) {
    let version = "3.0.0";
    let len = version.len();
    if len < output_size {
        ptr::copy_nonoverlapping(version.as_ptr(), output as *mut u8, len);
        *output.add(len) = 0;
    }
}

/// # Safety
/// Called by the Arma 3 engine. `output` must point to a writable buffer of
/// at least `output_size` bytes and `function` must be a valid NUL-terminated string.
#[no_mangle]
pub unsafe extern "C" fn RVExtension(
    output: *mut c_char,
    output_size: usize,
    function: *const c_char,
) {
    let func_str = CStr::from_ptr(function).to_string_lossy();

    // Dispatch Command
    let result = handle_command(&func_str);

    // Return String
    let res_bytes = result.as_bytes();
    let len = res_bytes.len();

    // Arma output buffer is usually 10kb+ but safe to check
    // We must reserve 1 byte for null terminator
    let max_len = output_size - 1;
    let copy_len = cmp::min(len, max_len);

    ptr::copy_nonoverlapping(res_bytes.as_ptr(), output as *mut u8, copy_len);
    *output.add(copy_len) = 0;
}

// -- COMMAND DISPATCHER --
// Format: "CMD|ARG1|ARG2..."
fn handle_command(input: &str) -> String {
    let parts: Vec<&str> = input.split('|').collect();
    if parts.is_empty() {
        return "ERROR: Empty Command".into();
    }

    let cmd = parts[0];

    match cmd {
        "version" => "3.0.0".into(),
        "list" => list(),
        "write" => {
            if parts.len() < 3 {
                return "ERROR: Missing Args".into();
            }
            // write|filename|data
            // If data contains |, it's split. We must join headers [2..]
            let filename = parts[1].to_string();
            let data = parts[2..].join("|"); // Re-join if data had pipes
            write(filename, data)
        }
        "read_init" => {
            if parts.len() < 2 {
                return "ERROR: Missing Args".into();
            }
            let filename = parts[1].to_string();
            read_init(filename)
        }
        "read_chunk" => {
            if parts.len() < 3 {
                return "ERROR: Missing Args".into();
            }
            let filename = parts[1].to_string();
            let idx_str = parts[2];
            let idx = idx_str.parse::<i32>().unwrap_or(-1);
            read_chunk(filename, idx)
        }
        "delete" => {
            if parts.len() < 2 {
                return "ERROR: Missing Args".into();
            }
            let filename = parts[1].to_string();
            delete(filename)
        }
        _ => "ERROR: Unknown Command".into(),
    }
}

// -- LOGIC --

fn list() -> String {
    let mut state = STATE.lock();
    if let Err(e) = init_db(&mut state) {
        return format!("ERROR: {}", e);
    }

    if let Some(conn) = &state.conn {
        let stmt_result = conn.prepare("SELECT path FROM filesystem");
        if let Ok(mut stmt) = stmt_result {
            let rows = stmt.query_map([], |row| row.get::<_, String>(0));
            let mut result = Vec::new();
            if let Ok(iter) = rows {
                for path in iter.flatten() {
                    result.push(path);
                }
            }
            let json = serde_json::to_string(&result).unwrap_or("[]".into());
            return json;
        }
    }
    "ERROR: No DB".into()
}

fn write(filename: String, data: String) -> String {
    let mut state = STATE.lock();
    if let Err(e) = init_db(&mut state) {
        return format!("ERROR: {}", e);
    }

    let filename = filename.replace('\\', "/");
    if filename.is_empty() || filename.len() > 256 {
        return "ERROR: Invalid Name".into();
    }

    // Check Quota
    if let Ok(meta) = std::fs::metadata(DB_FILENAME) {
        if meta.len() + (data.len() as u64) > MAX_DB_SIZE {
            return "ERROR: Database Full (1024MB Limit)".into();
        }
    }

    if let Some(conn) = &state.conn {
        let res = conn.execute(
            "INSERT OR REPLACE INTO filesystem (path, data, size) VALUES (?1, ?2, ?3)",
            (&filename, data.as_bytes(), data.len() as i64),
        );
        match res {
            Ok(_) => {
                state.read_cache.remove(&filename);
                return "OK".into();
            }
            Err(_) => return "ERROR: SQL Write Failed".into(),
        }
    }
    "ERROR: DB Error".into()
}

fn read_init(filename: String) -> String {
    let mut state = STATE.lock();
    if let Err(e) = init_db(&mut state) {
        return format!("ERROR: {}", e);
    }

    let filename = filename.replace('\\', "/");
    let mut found_data: Option<Vec<u8>> = None;

    if let Some(conn) = &state.conn {
        let res: Result<Vec<u8>> = conn.query_row(
            "SELECT data FROM filesystem WHERE path = ?",
            [&filename],
            |row| row.get(0),
        );
        if let Ok(d) = res {
            found_data = Some(d);
        }
    }

    if let Some(data) = found_data {
        let size = data.len();
        let chunks = compute_chunks(&data);
        let chunk_count = chunks.len();

        // Cache
        if state.read_cache.len() > 100 {
            state.read_cache.clear();
        }
        state
            .read_cache
            .insert(filename, CachedRead { data, chunks });

        return format!("{}|{}", size, chunk_count);
    }
    "ERROR: Not Found".into()
}

fn read_chunk(filename: String, index: i32) -> String {
    if index < 0 {
        return "ERROR: Invalid Index".into();
    }
    let mut state = STATE.lock();
    if state.conn.is_none() {
        let _ = init_db(&mut state);
    }

    let filename = filename.replace('\\', "/");

    if let Some(cached) = state.read_cache.get(&filename) {
        if let Some(&(start, end)) = cached.chunks.get(index as usize) {
            return String::from_utf8_lossy(&cached.data[start..end]).to_string();
        }
    }
    "ERROR: Cache Miss".into()
}

fn delete(filename: String) -> String {
    let mut state = STATE.lock();
    if let Err(e) = init_db(&mut state) {
        return format!("ERROR: {}", e);
    }
    let filename = filename.replace('\\', "/");
    if let Some(conn) = &state.conn {
        conn.execute("DELETE FROM filesystem WHERE path = ?", [&filename])
            .ok();
    }
    "OK".into()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn chunk_count(n: usize) -> usize {
        compute_chunks(&vec![b'a'; n]).len()
    }

    #[test]
    fn chunk_counts_at_boundaries() {
        assert_eq!(chunk_count(0), 0);
        assert_eq!(chunk_count(1), 1);
        assert_eq!(chunk_count(8999), 1);
        assert_eq!(chunk_count(9000), 1); // exactly one full chunk, not two
        assert_eq!(chunk_count(9001), 2);
        assert_eq!(chunk_count(18000), 2);
        assert_eq!(chunk_count(18001), 3);
    }

    #[test]
    fn chunks_are_contiguous_and_cover_all_data() {
        let data = vec![b'x'; 25000];
        let chunks = compute_chunks(&data);
        assert_eq!(chunks.first().unwrap().0, 0);
        assert_eq!(chunks.last().unwrap().1, data.len());
        for pair in chunks.windows(2) {
            assert_eq!(pair[0].1, pair[1].0);
        }
        assert!(chunks.iter().all(|&(s, e)| e > s && e - s <= CHUNK_SIZE));
    }

    #[test]
    fn multibyte_chars_are_never_split() {
        // Place 2-byte chars so the 9000-byte mark lands inside a character.
        let mut s = "a".repeat(8999);
        s.push_str(&"é".repeat(20));
        s.push_str(&"x".repeat(12000));
        let data = s.as_bytes();
        let chunks = compute_chunks(data);
        let mut rebuilt = String::new();
        for &(start, end) in &chunks {
            let part = std::str::from_utf8(&data[start..end])
                .expect("chunk boundary split a multi-byte character");
            rebuilt.push_str(part);
        }
        assert_eq!(rebuilt, s);
        assert!(chunks.iter().all(|&(start, end)| end - start <= CHUNK_SIZE));
    }
}
