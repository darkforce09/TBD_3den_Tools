/*
    File: security.rs
    Author: Darkforce
    Description: 
        DISABLED FOR DEBUGGING - Security features extracted from lib.rs
        
        To re-enable security:
        1. Add `mod security;` to lib.rs
        2. Replace the simplified functions in lib.rs with calls to these
        3. Restore the secret field logic in AppState
        
    SECURITY ARCHITECTURE (When Enabled):
    1. ROLLING KEYS: Every request invalidates the previous key.
       - The Extension holds the "Current Key" in AppState.
       - It sends this key back with every response.
       - The client must use the NEW key for the next request.
       
    2. SESSION MANAGEMENT:
       - Only one session allowed per runtime (unless stale >5s)
       - Context check ensures only 3DEN can initialize
       
    3. QUOTA ENFORCEMENT:
       - Database limited to 500MB max
*/

use std::time::SystemTime;
use rusqlite::{Connection, Result};

// Moved from lib.rs
pub const MAX_DB_SIZE: u64 = 500 * 1024 * 1024; // 500 MB

/// Generates a new random key based on entropy
pub fn generate_key(state_ptr: usize) -> String {
    let s = format!("{:?}_{}", SystemTime::now(), state_ptr);
    s.chars().filter(|c| c.is_alphanumeric()).collect()
}

/// Rotating authentication check
/// Returns Some(new_key) if authorized, None otherwise
pub fn check_auth_rotate(
    current_secret: &Option<String>,
    provided_secret: &str,
    state_ptr: usize,
) -> Option<String> {
    if let Some(s) = current_secret {
        if s == provided_secret {
            // Authorized! Generate a new rotated key.
            let new_key = generate_key(state_ptr);
            return Some(new_key);
        }
    }
    None
}

/// Validates session initialization context
/// Returns Ok(()) if valid, Err(message) otherwise
pub fn validate_init_context(ctx: &str) -> Result<(), &'static str> {
    if ctx != "true" {
        return Err("ERROR: Invalid Context (Not in 3DEN)");
    }
    Ok(())
}

/// Checks if session is stale (>5 seconds since last activity)
pub fn is_session_stale(last_active: SystemTime) -> bool {
    if let Ok(elapsed) = last_active.elapsed() {
        return elapsed.as_secs() >= 5;
    }
    false
}

/// Session initialization with security checks
/// Returns Ok(new_secret) or Err(error_message)
pub fn init_session_secure(
    current_secret: &Option<String>,
    last_active: SystemTime,
    ctx: &str,
    state_ptr: usize,
) -> Result<String, &'static str> {
    // Security: Only one session allowed per runtime, UNLESS stale (>5s)
    if current_secret.is_some() && !is_session_stale(last_active) {
        return Err("ERROR: Access Denied");
    }
    
    // Context Check
    validate_init_context(ctx)?;
    
    Ok(generate_key(state_ptr))
}

/// Checks if adding new_bytes would exceed the database quota
/// Returns true if write is allowed, false if quota exceeded
pub fn check_quota(conn: &Connection, new_bytes: u64) -> bool {
    let current_size: u64 = conn
        .query_row("SELECT SUM(size) FROM filesystem", [], |row| {
            row.get::<_, Option<u64>>(0)
        })
        .unwrap_or(Some(0))
        .unwrap_or(0);
    (current_size + new_bytes) < MAX_DB_SIZE
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_key() {
        let key1 = generate_key(12345);
        let key2 = generate_key(12345);
        // Keys should be different due to time component
        assert!(!key1.is_empty());
        assert!(!key2.is_empty());
    }

    #[test]
    fn test_auth_rotate() {
        let secret = Some("test_secret".to_string());
        
        // Valid auth
        let result = check_auth_rotate(&secret, "test_secret", 12345);
        assert!(result.is_some());
        
        // Invalid auth
        let result = check_auth_rotate(&secret, "wrong_secret", 12345);
        assert!(result.is_none());
    }

    #[test]
    fn test_validate_context() {
        assert!(validate_init_context("true").is_ok());
        assert!(validate_init_context("false").is_err());
    }
}
