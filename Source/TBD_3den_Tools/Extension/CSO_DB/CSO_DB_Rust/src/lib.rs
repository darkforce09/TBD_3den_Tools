use arma_rs::{arma, Extension};
use lazy_static::lazy_static;
use parking_lot::Mutex;
use rusqlite::{Connection, Result};
use std::collections::HashMap;

// Security module extracted for debugging - see security.rs to re-enable
// mod security;

// -- Configuration --
const DB_FILENAME: &str = "TBD_DB.db";
const CHUNK_SIZE: usize = 9000;
// SECURITY DISABLED: MAX_DB_SIZE moved to security.rs

// -- State --
// DEBUG MODE: Security features disabled
// When re-enabling:
// 1. Uncomment `mod security;` above
// 2. Restore `secret` and `last_active` fields
// 3. Add auth checks back to each command
struct AppState {
    conn: Option<Connection>,
    read_cache: HashMap<String, Vec<u8>>,
    // SECURITY DISABLED: secret: Option<String>,
    // SECURITY DISABLED: last_active: std::time::SystemTime,
}

lazy_static! {
    static ref STATE: Mutex<AppState> = Mutex::new(AppState {
        conn: None,
        read_cache: HashMap::new(),
        // SECURITY DISABLED: secret: None,
        // SECURITY DISABLED: last_active: std::time::SystemTime::now(),
    });
}

// -- Helpers --
fn init_db(state: &mut AppState) -> Result<(), String> {
    if state.conn.is_some() { return Ok(()); }

    // Use Current Working Directory (Arma 3 Root)
    let db_path = DB_FILENAME; // Relative path = CWD

    let conn = Connection::open(&db_path).map_err(|e| format!("DB Open Error: {}", e))?;

    conn.execute("PRAGMA journal_mode=WAL;", []).ok();
    conn.execute("PRAGMA synchronous=NORMAL;", []).ok();

    conn.execute(
        "CREATE TABLE IF NOT EXISTS filesystem (
            path TEXT PRIMARY KEY,
            data BLOB,
            size INTEGER
        )",
        [],
    ).map_err(|e| format!("Create Table Error: {}", e))?;

    state.conn = Some(conn);
    Ok(())
}

// SECURITY DISABLED: check_quota moved to security.rs

// -- Arma Commands --

#[arma]
fn init() -> Extension {
    Extension::build()
        .command("list", list)
        .command("init_session", init_session)
        .command("write", write)
        .command("read_init", read_init)
        .command("read_chunk", read_chunk)
        .command("delete", delete)
        .command("heartbeat", heartbeat)
        .finish()
}

// DEBUG MODE: Heartbeat is a no-op, just returns same key
fn heartbeat(secret: String) -> String {
    // SECURITY DISABLED: Would normally rotate key here
    secret
}

// DEBUG MODE: List without auth
fn list(secret: String) -> String {
    let mut state = STATE.lock();
    
    // SECURITY DISABLED: No auth check
    let key = secret; // Just pass through the key
    
    if let Err(e) = init_db(&mut state) { return format!("{}|ERROR: {}", key, e); }
    
    if let Some(conn) = &state.conn {
        let stmt_result = conn.prepare("SELECT path FROM filesystem");
        if let Ok(mut stmt) = stmt_result {
            let rows = stmt.query_map([], |row| row.get::<_, String>(0));
            let mut result = Vec::new();
            if let Ok(iter) = rows {
                for r in iter {
                    if let Ok(path) = r { result.push(path); }
                }
            }
            let json = serde_json::to_string(&result).unwrap_or("[]".into());
            // Return Format: KEY|DATA
            return format!("{}|{}", key, json);
        }
    }
    format!("{}|ERROR: No DB", key)
}

// DEBUG MODE: Init session always succeeds
fn init_session(_ctx: String) -> String {
    // SECURITY DISABLED: No context check, no session locking
    // Just return a static debug key
    "DEBUG_KEY_NO_SECURITY".to_string()
}

// DEBUG MODE: Write without auth
fn write(secret: String, filename: String, data: String) -> String {
    let mut state = STATE.lock();
    
    // SECURITY DISABLED: No auth check
    let key = secret;

    if let Err(e) = init_db(&mut state) { return format!("{}|ERROR: {}", key, e); }

    let filename = filename.replace('\\', "/");
    if filename.is_empty() || filename.len() > 256 { return format!("{}|ERROR: Invalid Name", key); }
    
    if let Some(conn) = &state.conn {
        // SECURITY DISABLED: Quota check removed
        // if !check_quota(conn, data.len() as u64) { return format!("{}|ERROR: Quota Exceeded", key); }
        
        let res = conn.execute(
            "INSERT OR REPLACE INTO filesystem (path, data, size) VALUES (?1, ?2, ?3)",
            (&filename, data.as_bytes(), data.len() as i64),
        );
        match res {
            Ok(_) => {
                state.read_cache.remove(&filename);
                return format!("{}|OK", key);
            }
            Err(_) => return format!("{}|ERROR: SQL Write Failed", key),
        }
    }
    format!("{}|ERROR: DB Error", key)
}

// DEBUG MODE: Read init without auth
fn read_init(secret: String, filename: String) -> String {
    let mut state = STATE.lock();
    
    // SECURITY DISABLED: No auth check
    let key = secret;

    if let Err(e) = init_db(&mut state) { return format!("{}|ERROR: {}", key, e); }

    let filename = filename.replace('\\', "/");
    let mut found_data: Option<Vec<u8>> = None;

    if let Some(conn) = &state.conn {
        let res: Result<Vec<u8>> = conn.query_row(
            "SELECT data FROM filesystem WHERE path = ?",
            [&filename],
            |row| row.get(0),
        );
        if let Ok(d) = res { found_data = Some(d); }
    }

    if let Some(data) = found_data {
        let size = data.len();
        let chunks = if size > 0 { (size / CHUNK_SIZE) + 1 } else { 1 };
        
        if state.read_cache.len() > 100 { state.read_cache.clear(); }
        state.read_cache.insert(filename, data);
        
        return format!("{}|{}|{}", key, size, chunks);
    }
    format!("{}|ERROR: Not Found", key)
}

// DEBUG MODE: Read chunk without auth
fn read_chunk(secret: String, filename: String, index: i32) -> String {
    if index < 0 { return "ERROR: Invalid Index".into(); }
    let mut state = STATE.lock();
    // No init needed usually, but safe to check
    if state.conn.is_none() { let _ = init_db(&mut state); }

    // SECURITY DISABLED: No auth check
    let key = secret;

    let filename = filename.replace('\\', "/");
    
    if let Some(data) = state.read_cache.get(&filename) {
        let start = (index as usize) * CHUNK_SIZE;
        if start < data.len() {
            let end = std::cmp::min(start + CHUNK_SIZE, data.len());
            let chunk_data = String::from_utf8_lossy(&data[start..end]).to_string();
            return format!("{}|{}", key, chunk_data);
        }
    }
    format!("{}|ERROR: Cache Miss", key)
}

// DEBUG MODE: Delete without auth
fn delete(secret: String, filename: String) -> String {
    let mut state = STATE.lock();
    
    // SECURITY DISABLED: No auth check
    let key = secret;

    if let Err(e) = init_db(&mut state) { return format!("{}|ERROR: {}", key, e); }

    let filename = filename.replace('\\', "/");
    if let Some(conn) = &state.conn {
        conn.execute("DELETE FROM filesystem WHERE path = ?", [&filename]).ok();
    }
    format!("{}|OK", key)
}



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_flow_debug() {
        // DEBUG: No security, just test basic flow
        let key = init_session("true".into());
        assert_eq!(key, "DEBUG_KEY_NO_SECURITY");
        
        // Write
        let res = write(key.clone(), "test_debug.txt".into(), "Debug Data".into());
        assert!(res.contains("|OK"));

        // Read Init
        let res = read_init(key.clone(), "test_debug.txt".into());
        assert!(res.contains("|")); // Contains size|chunks
        
        // Delete
        let res = delete(key.clone(), "test_debug.txt".into());
        assert!(res.contains("|OK"));
        
        // Verify Delete
        let res = read_init(key.clone(), "test_debug.txt".into());
        assert!(res.contains("ERROR: Not Found"));
    }
}
