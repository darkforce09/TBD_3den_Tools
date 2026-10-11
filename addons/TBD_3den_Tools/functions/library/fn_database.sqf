/*
    File: fn_database.sqf
    Author: Darkforce
    Description:
        Synchronous wrapper around the TBD_DB extension (SQLite storage).
        Registered in CfgFunctions as TBD_fnc_database; this file body is the
        function itself and is directly callable. All extension calls block
        until complete, so results are returned directly.

    Parameter(s):
        _mode   (String): "list", "read", "write" or "delete"
        _param1 (String): Path/name of the entry (unused for "list")
        _param2 (String): Data to store (only used for "write")

    Returns:
        "list"   -> Array of stored paths
        "read"   -> String data, or "ERROR: ..." on failure
        "write"  -> "OK" or "ERROR: ..."
        "delete" -> "OK" or "ERROR: ..."
*/

params ["_mode", ["_param1", ""], ["_param2", ""]];

private _result = "";

// The extension may answer with STRING or [STRING, ...] depending on call form
private _fnc_extract = {
    params ["_val"];
    if (_val isEqualType []) then { _val select 0 } else { _val };
};

switch (_mode) do {
    case "list": {
        private _extRes = ["TBD_DB" callExtension "list"] call _fnc_extract;

        if (_extRes == "") then {
            _result = [];
            if (isNil "TBD_DB_Warned") then {
                ["CRITICAL ERROR: TBD_DB Extension not found or not loaded!\n\nCheck that TBD_DB_x64.dll is in the addon folder and not blocked.", "TBD Error", "OK"] call BIS_fnc_guiMessage;
                diag_log "TBD_DB CRITICAL: Extension returned empty string (not loaded).";
                TBD_DB_Warned = true;
            };
        } else {
            if (_extRes select [0, 5] == "ERROR") then {
                diag_log format ["TBD_DB List Error: %1", _extRes];
                _result = [];
            } else {
                _result = parseSimpleArray _extRes;
                if (isNil "_result") then { _result = []; };
                // Normalize legacy '~' separators to '/'
                _result = _result apply { [_x, "~", "/"] call TBD_fnc_db_replace };
            };
        };
    };

    case "read": {
        private _extRes = ["TBD_DB" callExtension format ["read_init|%1", _param1]] call _fnc_extract;

        if (_extRes select [0, 5] == "ERROR") then {
            _result = _extRes;
        } else {
            private _parts = _extRes splitString "|";
            if (count _parts >= 2) then {
                private _chunks = parseNumber (_parts select 1);
                private _totalData = "";
                for "_i" from 0 to (_chunks - 1) do {
                    private _chunk = ["TBD_DB" callExtension format ["read_chunk|%1|%2", _param1, _i]] call _fnc_extract;
                    if (_chunk select [0, 5] == "ERROR") exitWith { _totalData = _chunk; };
                    _totalData = _totalData + _chunk;
                };
                _result = _totalData;
            } else {
                _result = "ERROR: Bad Read Header";
            };
        };
    };

    case "write": {
        _result = ["TBD_DB" callExtension format ["write|%1|%2", _param1, _param2]] call _fnc_extract;
    };

    case "delete": {
        _result = ["TBD_DB" callExtension format ["delete|%1", _param1]] call _fnc_extract;
    };
};

_result
