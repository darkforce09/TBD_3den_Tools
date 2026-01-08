/*
    File: fn_database.sqf
    Author: Darkforce
    Description: Synchronous TBD_DB Wrapper (No Daemon, No Auth)
*/

// FORCE RELOAD for Debugging:
TBD_fnc_database_initialized = nil;
TBD_fnc_database_initialized = true;
systemChat "DEBUG: fn_database.sqf LOADED"; // Proof of Life

// Helper: Replace All
TBD_fnc_db_replace = {
    params ["_str", "_find", "_rep"];
    _str splitString _find joinString _rep
};

// --- CORE FUNCTION ---
// Synchronous TBD_DB Wrapper with Hybrid Return Support
TBD_fnc_database = {
    params ["_mode", "_param1", "_param2", ["_callback", {}]];

    systemChat format ["Debug: TBD_fnc_database called with mode: %1", _mode]; // ENTRY CHECK

    private _result = "";
    private _extRes = "";
    
    // Helper to extract string result regardless of Array/String return
    private _fnc_extract = {
        params ["_val"];
        if (_val isEqualType []) then { _val select 0 } else { _val };
    };
    
    // Execute Immediately
    switch (_mode) do {
        case "list": {
            _extRes = ["TBD_DB" callExtension "list"] call _fnc_extract;
            systemChat format ["Debug: List Result Raw: '%1'", _extRes];
            
            if (_extRes == "") then { 
                _result = [];
                ["CRITICAL ERROR: TBD_DB Extension not found or not loaded!\n\nCheck if TBD_DB_x64.dll is in the folder and unblocked.", "TBD Error", "OK"] call BIS_fnc_guiMessage;
                diag_log "TBD_DB CRITICAL: Extension returned empty string (Not loaded).";
            } else {
                if (_extRes select [0,5] == "ERROR") then {
                     diag_log format ["TBD_DB List Error: %1", _extRes];
                     _result = [];
                } else {
                    _result = parseSimpleArray _extRes; 
                    if (isNil "_result") then { _result = []; };
                    // Normalize paths (though we now prefer / natively)
                    _result = _result apply { [_x, "~", "/"] call TBD_fnc_db_replace };
                };
            };
        };

        case "read": {
            private _safePath = _param1; 
            
            // Init Read
            _extRes = ["TBD_DB" callExtension format ["read_init|%1", _safePath]] call _fnc_extract;
            
            if (_extRes select [0, 5] == "ERROR") then {
                _result = _extRes;
            } else {
                private _parts = _extRes splitString "|";
                if (count _parts >= 2) then {
                    private _chunks = parseNumber (_parts select 1);
                    private _totalData = "";
                    
                    // Read Chunks
                    for "_i" from 0 to (_chunks - 1) do {
                        _totalData = _totalData + (["TBD_DB" callExtension format ["read_chunk|%1|%2", _safePath, _i]] call _fnc_extract);
                    };
                    _result = _totalData;
                } else {
                    _result = "ERROR: Bad Read Header";
                };
            };
        };

        case "write": {
            private _safePath = _param1;
            private _safeData = _param2; 
            _extRes = ["TBD_DB" callExtension format ["write|%1|%2", _safePath, _safeData]] call _fnc_extract;
            _result = _extRes; 
        };

        case "delete": {
            private _safePath = _param1;
            _extRes = ["TBD_DB" callExtension format ["delete|%1", _safePath]] call _fnc_extract;
            _result = _extRes;
        };
    };

    // Callback Execution
    if (!isNil "_callback") then {
        if (_callback isEqualType {}) then {
            [_result] call _callback;
        } else {
            if (_callback isEqualType []) then {
                private _code = _callback select 0;
                private _args = _callback select 1;
                [_result, _args] call _code;
            };
        };
    };
};
