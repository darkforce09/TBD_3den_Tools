/*
    File: fn_database.sqf
    Author: Darkforce
    Description: 
        Async Daemon wrapper for TBD_DB.
        
        DEBUG MODE: Security features disabled.
        See fn_database_security.sqf for the original security blocks.
        
        To re-enable security:
        1. Restore Call Stack Verification in TBD_fnc_database
        2. Restore Network Check in TBD_fnc_database
        3. Restore Dialog Check in TBD_fnc_database and Daemon loop
        4. Restore Queue Flush logic in Daemon loop
*/

if (!isNil "TBD_fnc_database_initialized") exitWith {};
// SECURITY DISABLED: Context check removed
// if (!is3DEN) exitWith { diag_log "TBD_DB blocked. Not in 3DEN."; };
TBD_fnc_database_initialized = true;

// --- GLOBAL QUEUE ---
// Format: [ [Mode, Param1, Param2, Callback], ... ]
// Callback format: [Code, Arguments] or Code (executed with result)
TBD_Database_Queue = [];

// --- PRODUCER FUNCTION ---
// Usage: ["list", "", "", _callback] call TBD_fnc_database;
// Callback is optional, receiving the Result.
TBD_fnc_database = {
    params ["_mode", "_param1", "_param2", ["_callback", {}]];
    
    // SECURITY DISABLED: Call Stack Verification removed
    // See fn_database_security.sqf for original code
    
    // SECURITY DISABLED: Network Check removed
    // See fn_database_security.sqf for original code
    
    // SECURITY DISABLED: Dialog Open Check removed
    // See fn_database_security.sqf for original code
    
    // Push to Queue (no validation)
    TBD_Database_Queue pushBack [_mode, _param1, _param2, _callback];
    diag_log format ["[DEBUG] TBD_fnc_database: Queued request - Mode: %1", _mode];
};

// --- DAEMON SPAWN ---
// Scheduled Environment Daemon: Manages the extension session.
// DEBUG MODE: No security, simplified flow.
[] spawn {
    // DEBUG: Session always succeeds
    private _secret = (("TBD_DB" callExtension ["init_session", [str is3DEN]]) select 0);
    
    // DEBUG: Accept any response
    if (_secret == "") then {
        _secret = "DEBUG_FALLBACK_KEY";
        diag_log "TBD_DB: Using fallback debug key";
    };
    
    diag_log format ["TBD_DB: Daemon Started. Debug Mode. Key: %1", _secret];
    systemChat "TBD_DB: DEBUG MODE - Security Disabled";
    
    // --- HELPER FUNCTIONS (Within Daemon Scope) ---
    private _fnc_replaceAll = {
        params ["_str", "_tgt", "_rpl"];
        private _res = _str;
        private _tgtLen = count _tgt;
        while {_res find _tgt != -1} do {
            private _idx = _res find _tgt;
            _res = (_res select [0, _idx]) + _rpl + (_res select [_idx + _tgtLen]);
        };
        _res
    };
    
    // --- MAIN LOOP ---
    while {true} do {
        if (count TBD_Database_Queue == 0) then {
            sleep 0.1;
            // SECURITY DISABLED: No heartbeat needed in debug mode
        };

        if (count TBD_Database_Queue > 0) then {
        
        // SECURITY DISABLED: Dialog check removed
        // Process all requests regardless of dialog state
        
        // Process a batch of requests
        for "_k" from 1 to 5 do {
            if (count TBD_Database_Queue == 0) exitWith {};
            
            private _req = TBD_Database_Queue deleteAt 0;
            _req params ["_mode", "_p1", "_p2", "_cb"];
            
            diag_log format ["[DEBUG] Processing: %1", _mode];
            
            private _result = "";
            
            // --- EXECUTE OP ---
            // DEBUG: Keys pass through unchanged
            
            private _rawRes = "";
            
            switch (_mode) do {
                case "list": {
                    _rawRes = (("TBD_DB" callExtension ["list", [_secret]]) select 0);
                };
                
                case "read": {
                    private _rName = [_p1, "/", "~"] call _fnc_replaceAll;
                    private _initRes = (("TBD_DB" callExtension ["read_init", [_secret, _rName]]) select 0);
                    
                    // Parse Init Response: KEY|SIZE|CHUNKS or KEY|ERROR...
                    private _iParts = _initRes splitString "|";
                    if (count _iParts >= 1) then {
                        private _newKey = _iParts select 0;
                        
                        if (_newKey select [0,5] != "ERROR") then {
                            _secret = _newKey; // Update key (even in debug, for compatibility)
                            
                            if (count _iParts >= 3) then {
                                private _chunks = parseNumber (_iParts select 2);
                                private _finalData = "";
                                
                                for "_i" from 0 to (_chunks - 1) do {
                                    private _cRes = (("TBD_DB" callExtension ["read_chunk", [_secret, _rName, _i]]) select 0);
                                    
                                    private _pipeIdx = _cRes find "|";
                                    if (_pipeIdx != -1) then {
                                        _secret = _cRes select [0, _pipeIdx];
                                        _finalData = _finalData + (_cRes select [_pipeIdx + 1]);
                                    };
                                };
                                _result = [_finalData, "!!PIPE!!", "|"] call _fnc_replaceAll;
                            } else {
                                 _result = "ERROR: Bad Format";
                            };
                        } else {
                            _result = _initRes; 
                        };
                    } else {
                         _result = "ERROR: Extension Comm Fail";
                    };
                };
                
                case "write": {
                    private _wName = [_p1, "/", "~"] call _fnc_replaceAll;
                    private _wData = [_p2, "|", "!!PIPE!!"] call _fnc_replaceAll;
                    _rawRes = (("TBD_DB" callExtension ["write", [_secret, _wName, _wData]]) select 0);
                };
                
                case "delete": {
                    private _dName = [_p1, "/", "~"] call _fnc_replaceAll;
                    _rawRes = (("TBD_DB" callExtension ["delete", [_secret, _dName]]) select 0);
                };
            };
            
            // --- PARSE RESPONSE (For List, Write, Delete) ---
            if (_mode != "read") then {
                private _pipeIdx = _rawRes find "|";
                if (_pipeIdx != -1) then {
                    private _potentialKey = _rawRes select [0, _pipeIdx];
                    _secret = _potentialKey; // Update key
                    _result = _rawRes select [_pipeIdx + 1];
                    
                    // Parse List JSON
                    if (_mode == "list") then {
                         if (_result != "" && {_result select [0, 1] == "["}) then {
                            private _arr = parseSimpleArray _result;
                            if (!isNil "_arr") then {
                                _result = _arr apply { [_x, "~", "/"] call _fnc_replaceAll };
                            } else { _result = []; };
                        } else { _result = []; };
                    };
                    
                } else {
                    _result = _rawRes;
                };
            };
            
            diag_log format ["[DEBUG] Result for %1: %2", _mode, _result];
            
            // --- CALLBACK ---
            if (!isNil "_cb" && {_cb isEqualType {}}) then {
                [_result] call _cb;
            } else {
                if (!isNil "_cb" && {_cb isEqualType []}) then {
                     private _code = _cb select 0;
                     private _args = _cb select 1;
                     [_result, _args] call _code;
                };
            };
        };
        
            sleep 0.01;
        };
    };
};
diag_log "TBD_DB: DEBUG Daemon Initialized.";
systemChat "TBD_DB: Daemon Initialized (DEBUG MODE).";
