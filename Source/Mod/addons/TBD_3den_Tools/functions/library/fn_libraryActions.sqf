/*
    File: fn_libraryActions.sqf
    Author: Darkforce
    Description:
        Defines the save/load/rename/delete/folder action handlers for the
        Global Library dialog (referenced by name from dialog.hpp).
        Called once by TBD_fnc_libraryTool before the dialog is created.
        All database access is synchronous via TBD_fnc_database, so the
        UI can be refreshed immediately after each operation completes.
*/

// Save selected objects
TBD_fnc_SaveGroup = {
    params ["_display"];
    private _ctrlEdit = _display displayCtrl 104;
    private _name = ctrlText _ctrlEdit;

    if (_name == "") exitWith { systemChat "Error: Please enter a composition name."; };

    // SANITIZATION: Prevent protocol breakers (|) and filesystem invalid chars
    private _invalidChars = ["|", "*", "?", "<", ">", ":", """"];
    {
        _name = [_name, _x, "_"] call TBD_fnc_db_replace;
    } forEach _invalidChars;
    // Update input box to show sanitized name
    _ctrlEdit ctrlSetText _name;

    private _ctrlTree = _display displayCtrl 101;
    private _selPath = tvCurSel _ctrlTree;
    private _folderPrefix = "";

    if (count _selPath > 0) then {
        private _data = _ctrlTree tvData _selPath;
        if (_data find "FOLDER:" == 0) then {
            _folderPrefix = _data select [7];
        } else {
            if (count _selPath > 1) then {
                private _parentPath = +_selPath;
                _parentPath deleteAt (count _parentPath - 1);
                private _pData = _ctrlTree tvData _parentPath;
                if (_pData find "FOLDER:" == 0) then {
                   _folderPrefix = _pData select [7];
                };
            };
        };
    };

    private _finalName = _name;
    if (_folderPrefix != "") then { _finalName = _folderPrefix + "/" + _name; };

    // Overwrite check
    private _checkData = ["read", _finalName] call TBD_fnc_database;

    if (_checkData != "" && {_checkData select [0,5] != "ERROR"}) then {
        // EXISTS - Ask Confirmation.
        // spawn a thread because BIS_fnc_guiMessage suspends.
        [_display, _finalName] spawn {
            params ["_display", "_finalName"];
            private _result = [format ["Overwrite composition '%1'?", _finalName], "Confirm Save", "Yes", "No", _display] call BIS_fnc_guiMessage;
            if (_result) then {
                [_display, _finalName] call TBD_fnc_DoSaveInfo;
            };
        };
    } else {
        // Doesn't exist, proceed directly
        [_display, _finalName] call TBD_fnc_DoSaveInfo;
    };
};

TBD_fnc_DoSaveInfo = {
    params ["_display", "_finalName"];

    // Check for all selected entity types
    private _selectedObjects = get3DENSelected "object";
    private _selectedLogic = get3DENSelected "logic";
    private _selectedTriggers = get3DENSelected "trigger";
    private _selectedMarkers = get3DENSelected "marker";
    private _selectedWaypoints = get3DENSelected "waypoint";

    private _allSelected = _selectedObjects + _selectedLogic + _selectedTriggers + _selectedMarkers + _selectedWaypoints;

    private _data = [];
    private _imported = false;

    // Special Case: Import from Logic (Handle Legacy Logic Item Import)
    if (count _allSelected == 1 && {(_allSelected select 0) isKindOf "Logic"}) then {
        private _logic = _allSelected select 0;
        private _initCode = (_logic get3DENAttribute "Init") select 0;
        if (!isNil "_initCode") then {
            private _parsed = [_initCode] call TBD_fnc_parseLogicData;
            if (count _parsed > 0) then {
                _data = _parsed;
                systemChat localize "STR_CSO_ImportedLogic";
                _imported = true;
            };
        };
    };

    if (!_imported && {count _allSelected > 0}) then {
        // Serialize Objects AND Logic
        _data = [_allSelected] call TBD_fnc_serializeObjects;
    };

    if (count _data == 0) exitWith { systemChat localize "STR_CSO_Err_InvalidSelection"; };

    // Serialization
    private _author = profileName;
    private _sysTime = systemTime;
    private _y = _sysTime#0;
    private _m = _sysTime#1;
    private _d = _sysTime#2;
    private _dateStr = format ["%1-%2-%3", _y, if (_m < 10) then {"0" + str _m} else {_m}, if (_d < 10) then {"0" + str _d} else {_d}];

    private _cnt = count _data;
    private _sizeStr = format ["%1 Objects", _cnt];

    private _meta = [_author, _dateStr, _sizeStr];
    private _savePacket = ["TBD_V2", _meta, _data];
    private _strData = str _savePacket;

    // Save to DB
    private _res = ["write", _finalName, _strData] call TBD_fnc_database;
    if (_res == "OK") then {
        systemChat "Composition Saved.";
    } else {
        systemChat format ["Save Error: %1", _res];
    };

    [_display] call TBD_fnc_RefreshListUI;

    private _ctrlEdit = _display displayCtrl 104;
    _ctrlEdit ctrlSetText "";
};

// Load selected group
TBD_fnc_LoadGroup = {
    params ["_display"];
    private _ctrlTree = _display displayCtrl 101;
    private _selPath = tvCurSel _ctrlTree;

    if (count _selPath == 0) exitWith { systemChat localize "STR_CSO_NoItemSel"; };

    private _sDataIndex = _ctrlTree tvData _selPath;

    // Check if folder
    if (_sDataIndex find "FOLDER:" == 0) exitWith { systemChat localize "STR_CSO_SelFolder"; };

    if (_sDataIndex == "") exitWith {};

    private _groupName = _sDataIndex;
    private _strData = ["read", _groupName] call TBD_fnc_database;

    if (_strData == "" || _strData select [0,5] == "ERROR") exitWith {
         systemChat localize "STR_CSO_Err_Read";
    };

    // Safety: Prevent loading folder placeholders
    if (_strData == "FOLDER") exitWith { systemChat localize "STR_CSO_Err_FolderLoad"; };

    private _data = [];
    if (_strData select [0,1] == "[") then {
        private _parsed = parseSimpleArray _strData;
        // Check V2
        if (count _parsed > 0 && {_parsed select 0 isEqualType ""} && {_parsed select 0 == "TBD_V2"}) then {
            _data = _parsed select 2;
        } else {
            // Legacy
            _data = _parsed;
        };
    } else {
        systemChat "Error: Data is not in a valid array format.";
    };

    if (count _data == 0) exitWith {};

    [_data, _groupName] call TBD_fnc_restoreObjects;

    systemChat format [localize "STR_CSO_CompImported", _groupName];
};

// Delete selected group or folder
TBD_fnc_DeleteGroup = {
    params ["_display"];
    private _ctrlTree = _display displayCtrl 101;
    private _selPath = tvCurSel _ctrlTree;

    if (count _selPath == 0) exitWith { systemChat localize "STR_CSO_NoItemSel"; };

    private _sDataIndex = _ctrlTree tvData _selPath;

    if (_sDataIndex find "FOLDER:" == 0) then {
        // Folder: delete the folder entry and all children sequentially
        private _fPath = _sDataIndex select [7];
        private _lib = ["list"] call TBD_fnc_database;
        private _deletedCount = 0;

        {
            private _key = _x;
            if (_key == _fPath || {_key find (_fPath + "/") == 0}) then {
                ["delete", _key] call TBD_fnc_database;
                _deletedCount = _deletedCount + 1;
            };
        } forEach _lib;

        [_display] call TBD_fnc_RefreshListUI;
        systemChat format ["Deleted Folder '%1' and %2 item(s).", _fPath, _deletedCount];
    } else {
        private _res = ["delete", _sDataIndex] call TBD_fnc_database;
        if (_res != "OK") exitWith {
            systemChat format ["Error: %1", _res];
            diag_log format ["TBD Error: %1", _res];
        };
        [_display] call TBD_fnc_RefreshListUI;
        systemChat localize "STR_CSO_ItemDeleted";
    };
};

// Copy a DB entry to a new key, then delete the original.
// The original is only deleted after the new entry was written successfully,
// so a failed read or write can never destroy data.
TBD_fnc_MoveDBItem = {
    params ["_oldKey", "_newKey"];

    private _data = ["read", _oldKey] call TBD_fnc_database;
    if (_data == "" || {_data select [0,5] == "ERROR"}) exitWith {
        diag_log format ["TBD Rename: Read failed for '%1': %2", _oldKey, _data];
        false
    };

    private _res = ["write", _newKey, _data] call TBD_fnc_database;
    if (_res != "OK") exitWith {
        diag_log format ["TBD Rename: Write failed for '%1': %2", _newKey, _res];
        false
    };

    ["delete", _oldKey] call TBD_fnc_database;
    true
};

// Rename selected group or folder
TBD_fnc_RenameGroup = {
    params ["_display", ["_overrideName", ""]];
    private _ctrlTree = _display displayCtrl 101;
    private _selPath = tvCurSel _ctrlTree;

    if (count _selPath == 0) exitWith { systemChat localize "STR_CSO_NoItemSel"; };

    private _sDataIndex = _ctrlTree tvData _selPath;

    // --- IDENTIFY OLD NAME/PATH ---
    private _isFolder = _sDataIndex find "FOLDER:" == 0;
    private _oldFullPath = if (_isFolder) then { _sDataIndex select [7] } else { _sDataIndex };

    if (_oldFullPath == "") exitWith { systemChat "Error: Target not found." };

    // --- DETERMINE NEW NAME ---
    private _newNameInput = "";
    if (_overrideName != "") then {
        _newNameInput = _overrideName;
    } else {
        private _ctrlEdit = _display displayCtrl 104;
        _newNameInput = ctrlText _ctrlEdit;
    };

    if (_newNameInput == "") exitWith { systemChat "Error: Name cannot be empty."; };

    // SANITIZATION
    private _invalidChars = ["|", "*", "?", "<", ">", ":", """"];
    {
        _newNameInput = [_newNameInput, _x, "_"] call TBD_fnc_db_replace;
    } forEach _invalidChars;

    private _newNameBase = _newNameInput;

    // --- CONSTRUCT NEW FULL PATH (preserve parent folder) ---
    private _parentPath = "";
    private _parts = _oldFullPath splitString "/\";
    if (count _parts > 1) then {
        _parts deleteAt (count _parts - 1);
        _parentPath = _parts joinString "/";
    };

    private _newFullPath = _newNameBase;
    if (_parentPath != "") then { _newFullPath = _parentPath + "/" + _newNameBase; };

    if (_newFullPath == _oldFullPath) exitWith { systemChat "Error: Name is unchanged."; };

    // --- EXECUTE RENAME ---
    if (_isFolder) then {
        // ** RECURSIVE FOLDER RENAME **
        private _lib = ["list"] call TBD_fnc_database;
        private _movedCount = 0;
        private _failedCount = 0;

        {
            private _key = _x;
            if (_key == _oldFullPath || {_key find (_oldFullPath + "/") == 0}) then {
                private _suffix = _key select [count _oldFullPath];
                private _newKey = _newFullPath + _suffix;
                if ([_key, _newKey] call TBD_fnc_MoveDBItem) then {
                    _movedCount = _movedCount + 1;
                } else {
                    _failedCount = _failedCount + 1;
                };
            };
        } forEach _lib;

        if (_failedCount > 0) then {
            systemChat format ["Warning: %1 item(s) could not be moved (originals kept).", _failedCount];
        };
        systemChat format ["Renamed Folder '%1' to '%2' (%3 items moved)", _oldFullPath, _newNameBase, _movedCount];
    } else {
        // ** SINGLE ITEM RENAME **
        if ([_oldFullPath, _newFullPath] call TBD_fnc_MoveDBItem) then {
            systemChat format ["Renamed '%1' to '%2'", _oldFullPath, _newNameBase];
        } else {
            systemChat "Error: Rename failed - original kept.";
        };
    };

    [_display] call TBD_fnc_RefreshListUI;
    private _ctrlEdit = _display displayCtrl 104;
    _ctrlEdit ctrlSetText "";
};

// Commit rename from Details Panel Input (IDC 106)
TBD_fnc_CommitDetailRename = {
    params ["_display"];
    private _ctrlName = _display displayCtrl 106; // Details Name Edit
    private _newName = ctrlText _ctrlName;

    // Trigger Rename
    [_display, _newName] call TBD_fnc_RenameGroup;

    // Refocus Tree
    ctrlSetFocus (_display displayCtrl 101);
};

// Create new folder
TBD_fnc_CreateFolder = {
    params ["_display"];
    private _lib = ["list"] call TBD_fnc_database;

    private _baseName = "New Folder";
    private _finalName = _baseName;
    private _counter = 1;

    // Helper to check if folder exists (prefix match)
    private _fnc_exists = {
        params ["_checkName", "_list"];
        private _prefix = _checkName + "/";
        private _found = false;
        {
            if (_x find _prefix == 0) exitWith { _found = true; };
        } forEach _list;
        _found
    };

    while { [_finalName, _lib] call _fnc_exists } do {
        _finalName = format ["%1 %2", _baseName, _counter];
        _counter = _counter + 1;
    };

    private _placeholderName = format ["%1/(Empty)", _finalName];

    // Write placeholder
    private _res = ["write", _placeholderName, "FOLDER"] call TBD_fnc_database;
    if (_res != "OK") exitWith {
        systemChat format ["Error: %1", _res];
        diag_log format ["TBD Error: %1", _res];
    };

    [_display] call TBD_fnc_RefreshListUI;
    systemChat format ["Created Folder: %1", _finalName];
};
