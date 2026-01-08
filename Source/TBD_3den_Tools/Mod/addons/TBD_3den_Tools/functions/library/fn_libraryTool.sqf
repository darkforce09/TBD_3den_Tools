/*
    File: fn_libraryTool.sqf
    Author: Darkforce
    Description: Main UI for the Global Library. Handles Listing, Saving, Loading, and Deleting compositions with Folder support.
    Refactored to Async Callback Architecture.
*/

// Helper: Refresh the list UI
TBD_fnc_RefreshListUI = {
    params ["_display", ["_filter", ""]];
    if (isNull _display) exitWith {};
    
    // Disable tree while loading
    private _ctrlTree = _display displayCtrl 101;
    _ctrlTree ctrlEnable false;
    
    // Async List Call
    ["list", "", "", [TBD_fnc_OnListReceived, [_display, _filter]]] call TBD_fnc_database;
};

// Callback for List
TBD_fnc_OnListReceived = {
    params ["_lib", "_args"];
    _args params ["_display", "_filter"];
    
    if (isNull _display) exitWith {};
    private _ctrlTree = _display displayCtrl 101;
    
    tvClear _ctrlTree;
    
    // FILTER LIST IF NEEDED
    if (_filter != "") then {
        _filter = toLower _filter;
        _lib = _lib select { toLower _x find _filter != -1 };
    };
    
    // Cache folders
    private _pathCache = createHashMap; 
    
    {
        private _dataIndex = _forEachIndex;
        private _fullPathStr = _x; // "Folder/Item"
        private _parts = _fullPathStr splitString "/\";
        
        // Get item name
        private _itemName = _parts deleteAt (count _parts - 1);
        
        // Handle folders
        private _currentTreePath = [];
        private _currentStringPath = "";
        
        {
            private _folderName = _x;
            
            // Construct string key for this level
            if (_currentStringPath == "") then {
                _currentStringPath = _folderName;
            } else {
                _currentStringPath = _currentStringPath + "/" + _folderName;
            };
            
            // Check Cache
            if (_currentStringPath in _pathCache) then {
                _currentTreePath = _pathCache get _currentStringPath;
            } else {
                // Not in cache, create valid folder node
                private _idx = _ctrlTree tvAdd [_currentTreePath, _folderName];
                _ctrlTree tvSetPicture [_currentTreePath + [_idx], "\a3\3DEN\Data\Displays\Display3DEN\PanelLeft\entityList_layer_ca.paa"];
                _ctrlTree tvSetPictureColor [_currentTreePath + [_idx], [1,1,1,1]];
                
                // DATA: Mark as folder and store full path
                _ctrlTree tvSetData [_currentTreePath + [_idx], "FOLDER:" + _currentStringPath];
                
                _currentTreePath = _currentTreePath + [_idx];
                
                // Store in Cache - COPY the array!
                _pathCache set [_currentStringPath, +_currentTreePath];
            };
        } forEach _parts;
        
        // Add Leaf Item
        private _idx = _ctrlTree tvAdd [_currentTreePath, _itemName];
        _ctrlTree tvSetPicture [_currentTreePath + [_idx], "\a3\3DEN\Data\Displays\Display3DEN\PanelRight\modeComposition_ca.paa"];
        _ctrlTree tvSetPictureColor [_currentTreePath + [_idx], [1,1,1,1]];
        
        // DATA: store database index string
        _ctrlTree tvSetData [_currentTreePath + [_idx], _fullPathStr];
        
    } forEach _lib;
    
    tvExpandAll _ctrlTree;
    _ctrlTree ctrlEnable true;
};

// Save selected objects
TBD_fnc_SaveGroup = {
    params ["_display"];
    
    // Get Name from Input (IDC 104)
    private _ctrlEdit = _display displayCtrl 104;
    private _name = ctrlText _ctrlEdit;
    
    if (_name == "") exitWith { systemChat "Error: Please enter a composition name."; };
    
    // --- BUILD FOLDER PATH ---
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
    
    // Prepend Prefix
    private _finalName = _name;
    if (_folderPrefix != "") then {
        _finalName = _folderPrefix + "/" + _name;
    };
    
    // ASYNC CHECK: Does file exist?
    ["read", _finalName, "", [TBD_fnc_OnSaveCheckFinished, [_display, _finalName]]] call TBD_fnc_database;
};

TBD_fnc_OnSaveCheckFinished = {
    params ["_checkData", "_args"];
    _args params ["_display", "_finalName"];
    
    // Logic continues here on the main thread.
    // Ensure blocking calls (like guiMessage) are handled in a scheduled environment if needed.
    
    if (_checkData != "" && {_checkData select [0,5] != "ERROR"}) then {
        // EXISTS - Ask Confirmation
        // spawn a thread to handle BIS_fnc_guiMessage which is blocking/suspending
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
        if (!isNil "_initCode" && {_initCode find "_soData = [" != -1}) then {
             private _markerStart = "_soData = [";
             private _markerEnd = "];";
             private _startIndex = _initCode find _markerStart;
             
             if (_startIndex != -1) then {
                 private _tempStr = _initCode select [_startIndex];
                 private _endIndex = _tempStr find _markerEnd;
                 if (_endIndex != -1) then {
                     private _arrayCode = _tempStr select [0, _endIndex + 2];
                     private _eqIndex = _arrayCode find "=";
                     private _arrOnly = _arrayCode select [_eqIndex + 1];
                     _arrOnly = [_arrOnly, ";", ""] call { params["_s","_f","_r"]; _s splitString _f joinString _r }; 
                     
                     _data = parseSimpleArray _arrOnly;
                     systemChat localize "STR_CSO_ImportedLogic";
                     _imported = true;
                 };
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
    private _months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    private _mStr = _months select ((_sysTime#1) - 1);
    private _dateStr = format ["%1 %2, %3", _mStr, _sysTime#2, _sysTime#0];
    
    private _cnt = count _data;
    private _sizeStr = format ["%1 Objects", _cnt];
    
    private _meta = [_author, _dateStr, _sizeStr];
    private _savePacket = ["TBD_V2", _meta, _data];
    private _strData = str _savePacket;
    
    // Save to DB (Async)
    ["write", _finalName, _strData, {
        params ["_res"];
        if (_res == "OK") then {
            systemChat "Composition Saved.";
        } else {
            systemChat format ["Save Error: %1", _res];
        };
        // Refresh UI
        if (!isNull (findDisplay 86000)) then {
            [findDisplay 86000] call TBD_fnc_RefreshListUI;
        };
    }] call TBD_fnc_database;
    
    // Clear Input immediately
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
    
    private _fullPathName = _sDataIndex;
    systemChat "Loading...";
    
    // ASYNC READ
    ["read", _fullPathName, "", [TBD_fnc_OnLoadRead, [_fullPathName]]] call TBD_fnc_database;
};

TBD_fnc_OnLoadRead = {
    params ["_strData", "_args"];
    _args params ["_groupName"];

    if (_strData == "" || _strData select [0,5] == "ERROR") exitWith {
         systemChat localize "STR_CSO_Err_Read";
    };
    
    // Safety: Prevent loading folder placeholders
    if (_strData == "FOLDER") exitWith { systemChat localize "STR_CSO_Err_FolderLoad"; };
    
    private _data = [];
    if (_strData != "") then {
        private _parsed = parseSimpleArray _strData;
        // Check V2
        if (count _parsed > 0 && {_parsed select 0 isEqualType ""} && {_parsed select 0 == "TBD_V2"}) then {
            _data = _parsed select 2;
        } else {
            // Legacy
            _data = _parsed;
        };
    };
    
    [_data, _groupName] call TBD_fnc_restoreObjects;

    systemChat format [localize "STR_CSO_CompImported", _groupName];
};

// Delete selected group
TBD_fnc_DeleteGroup = {
    params ["_display"];
    private _ctrlTree = _display displayCtrl 101;
    private _selPath = tvCurSel _ctrlTree;
    
    if (count _selPath == 0) exitWith { systemChat localize "STR_CSO_NoItemSel"; };
    
    private _sDataIndex = _ctrlTree tvData _selPath;
    
    // Check Folder Delete
    if (_sDataIndex find "FOLDER:" == 0) then {
         private _fPath = _sDataIndex select [7];
         
         // Need to list first to delete children
         ["list", "", "", [TBD_fnc_OnDeleteFolderList, [_display, _fPath]]] call TBD_fnc_database;
         
    } else {
         private _name = _sDataIndex;
    
         // Delete File
         ["delete", _name, "", {
             params ["_res"];
             [findDisplay 86000] call TBD_fnc_RefreshListUI;
             systemChat localize "STR_CSO_ItemDeleted";
         }] call TBD_fnc_database;
    };
};

TBD_fnc_OnDeleteFolderList = {
    params ["_lib", "_args"];
    _args params ["_display", "_fPath"];
    
    private _deletedCount = 0;
    
    {
        private _key = _x;
        private _match = false;
        
        // Match exact folder or children
        if (_key == _fPath) then { _match = true; };
        if (!_match) then {
            private _prefix = _fPath + "/";
            if (_key find _prefix == 0) then { _match = true; };
        };
        
        if (_match) then {
            ["delete", _key, ""] call TBD_fnc_database; // Fire and forget deletes
            _deletedCount = _deletedCount + 1;
        };
    } forEach _lib;
    
    // Schedule refresh slightly later to allow deletes to process
    [_display, _fPath, _deletedCount] spawn {
        params ["_display", "_fPath", "_cnt"];
        sleep 0.5; 
        [_display] call TBD_fnc_RefreshListUI;
        systemChat format ["Deleted Folder '%1' and %2 item(s).", _fPath, _cnt];
    };
};

// Rename selected group
TBD_fnc_RenameGroup = {
    params ["_display", ["_overrideName", ""]];
    private _ctrlTree = _display displayCtrl 101;
    private _selPath = tvCurSel _ctrlTree;
    
    if (count _selPath == 0) exitWith { systemChat localize "STR_CSO_NoItemSel"; };
    
    private _sDataIndex = _ctrlTree tvData _selPath;
    
    // Need list to handle folder renames or just for general safety
    ["list", "", "", [TBD_fnc_OnRenameList, [_display, _overrideName, _sDataIndex]]] call TBD_fnc_database;
};

TBD_fnc_OnRenameList = {
    params ["_lib", "_args"];
    _args params ["_display", "_overrideName", "_sDataIndex"];
    
    private _isFolder = false;
    private _oldFullPath = "";
    
    // --- IDENTIFY OLD NAME/PATH ---
    if (_sDataIndex find "FOLDER:" == 0) then {
        // FOLDER LOGIC
        _isFolder = true;
        _oldFullPath = _sDataIndex select [7]; // "MyFolder/SubFolder"
    } else {
        // ITEM LOGIC
        _oldFullPath = _sDataIndex;
    };
    
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
    
    private _newNameBase = _newNameInput; 
    
    // --- CONSTRUCT NEW FULL PATH ---
    private _newFullPath = "";
    
    if (_isFolder) then {
        // Parent path of the folder
        private _parentPath = "";
        private _parts = _oldFullPath splitString "/\";
        if (count _parts > 1) then {
            _parts deleteAt (count _parts - 1);
            _parentPath = _parts joinString "/";
        };
        
        if (_parentPath != "") then {
            _newFullPath = _parentPath + "/" + _newNameBase;
        } else {
            _newFullPath = _newNameBase; // Root folder
        };
        
    } else {
        // Item Rename: Preserves parent folder
        private _parentPath = "";
        private _parts = _oldFullPath splitString "/\";
        if (count _parts > 1) then {
            _parts deleteAt (count _parts - 1);
            _parentPath = _parts joinString "/";
        };
        
        if (_parentPath != "") then {
            _newFullPath = _parentPath + "/" + _newNameBase;
        } else {
            _newFullPath = _newNameBase;
        };
    };
    
    if (_newFullPath == _oldFullPath) exitWith { systemChat "Error: Name is unchanged."; };
    
    // --- EXECUTE RENAME ---
    
    if (_isFolder) then {
        // ** RECURSIVE FOLDER RENAME **
        private _changedCount = 0;
        {
            private _key = _x;
            private _match = false;
            
            if (_key == _oldFullPath) then { _match = true; };
            if (!_match) then {
                private _prefix = _oldFullPath + "/";
                if (_key find _prefix == 0) then { _match = true; };
            };
            
            if (_match) then {
                private _suffix = _key select [count _oldFullPath]; 
                private _newKey = _newFullPath + _suffix;
                
                // ASYNC COPY: Read -> Callback(Write -> Delete)
                ["read", _key, "", [TBD_fnc_OnRenameFolderItem, [_key, _newKey]]] call TBD_fnc_database;
                
                _changedCount = _changedCount + 1;
            };
        } forEach _lib;
        
        systemChat format ["Renamed Folder '%1' to '%2' (%3 items moved)", _oldFullPath, _newNameBase, _changedCount];
        
    } else {
        // ** SINGLE ITEM RENAME **
        ["read", _oldFullPath, "", [TBD_fnc_OnRenameItem, [_oldFullPath, _newFullPath, _newNameBase]]] call TBD_fnc_database;
    };
    
    // Refresh Logic (Delayed)
    [_display] spawn {
        params ["_display"];
        sleep 0.5;
        [_display] call TBD_fnc_RefreshListUI;
        private _ctrlEdit = _display displayCtrl 104;
        _ctrlEdit ctrlSetText "";
    };
};

TBD_fnc_OnRenameFolderItem = {
    params ["_data", "_args"];
    _args params ["_oldKey", "_newKey"];
    
    if (_data != "") then {
        ["write", _newKey, _data] call TBD_fnc_database;
        ["delete", _oldKey, ""] call TBD_fnc_database;
    };
};

TBD_fnc_OnRenameItem = {
    params ["_data", "_args"];
    _args params ["_oldFullPath", "_newFullPath", "_baseName"];
    
    if (_data == "") exitWith { systemChat "Error: Could not read original data."; };
        
    ["write", _newFullPath, _data] call TBD_fnc_database;
    ["delete", _oldFullPath, ""] call TBD_fnc_database;
        
    systemChat format ["Renamed '%1' to '%2'", _oldFullPath, _baseName];
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
    // Need list to find unique name
    ["list", "", "", [TBD_fnc_OnCreateFolderList, [_display]]] call TBD_fnc_database;
};

TBD_fnc_OnCreateFolderList = {
    params ["_lib", "_args"];
    _args params ["_display"];
    
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
    ["write", _placeholderName, "FOLDER", {
        params ["_res"];
        [findDisplay 86000] call TBD_fnc_RefreshListUI;
        systemChat format ["Created Folder: %1", _finalName];
    }] call TBD_fnc_database;
};

TBD_fnc_OnTreeSelChanged = {
    params ["_ctrlTree", "_path"];
    private _text = _ctrlTree tvText _path;
    private _display = ctrlParent _ctrlTree;
    // DETAILS PANE ID 105 (Info), ID 106 (Name Edit)
    private _ctrlInfo = _display displayCtrl 105;
    private _ctrlName = _display displayCtrl 106;
    
    // SET NAME EDIT
    _ctrlName ctrlSetText _text;
    
    // AUTO-FILL FOOTER INPUT (IDC 104)
    private _ctrlInput = _display displayCtrl 104;
    _ctrlInput ctrlSetText _text;
    
    private _dataIndex = _ctrlTree tvData _path;
    
    if (_dataIndex find "FOLDER:" == 0) then {
        // --- FOLDER SELECTED ---
        private _html = "";
        _html = _html + format ["<t color='#cccccc'>Folder Selection</t><br/>"];
        _html = _html + "<t size='0.9' color='#888888'>Contains compositions.</t>";
        _ctrlInfo ctrlSetStructuredText parseText _html;
    } else {
        // --- ITEM SELECTED ---
        _ctrlInfo ctrlSetStructuredText parseText "<t color='#aaaaaa'>Loading details...</t>";
        
        private _fullPath = _dataIndex;
        
        // ASYNC READ
        ["read", _fullPath, "", [TBD_fnc_OnDetailsRead, [_ctrlInfo]]] call TBD_fnc_database;
    };
};

TBD_fnc_OnDetailsRead = {
    params ["_strData", "_args"];
    _args params ["_ctrlInfo"];
    
    private _author = "Unknown";
    private _date = "Unknown";
    private _size = "Unknown";
    
    if (_strData != "" && _strData select [0,5] != "ERROR") then {
        // Check for Folder Placeholder
        if (_strData == "FOLDER") then {
            _size = "Empty Folder Placeholder";
        } else {
            private _parsed = parseSimpleArray _strData;
            if (count _parsed > 0 && {_parsed select 0 isEqualType ""} && {_parsed select 0 == "TBD_V2"}) then {
                // V2
                private _meta = _parsed select 1;
                _author = _meta select 0;
                _date = _meta select 1;
                _size = _meta select 2;
                
                // If saved size is just object count, append file size
                private _fileSizeKB = (count _strData) / 1024;
                _size = format ["%1 (%2 KB)", _size, _fileSizeKB toFixed 1];
                
            } else {
                // Legacy
                private _fileSizeKB = (count _strData) / 1024;
                _size = format ["Legacy Format (%1 KB)", _fileSizeKB toFixed 1];
            };
        };
    };
    
    private _html = "";
    _html = _html + format ["<t color='#888888'>Date:</t> <t color='#ffffff'>%1</t><br/>", _date];
    _html = _html + format ["<t color='#888888'>Size:</t> <t color='#ffffff'>%1</t><br/>", _size];
    _html = _html + format ["<t color='#888888'>Author:</t> <t color='#ffffff'>%1</t><br/><br/>", _author];
    _html = _html + "<t size='0.9' color='#00aaff'>Ready to load.</t>";
    
    _ctrlInfo ctrlSetStructuredText parseText _html;
};

TBD_fnc_OnSearch = {
    params ["_ctrlEdit"];
    private _display = ctrlParent _ctrlEdit;
    private _text = ctrlText _ctrlEdit;
    [_display, _text] call TBD_fnc_RefreshListUI;
};

// Create GUI - CONFIG MODE
private _display = findDisplay 313 createDisplay "TBD_Library_Dialog";

// Initialize List
[_display] call TBD_fnc_RefreshListUI;