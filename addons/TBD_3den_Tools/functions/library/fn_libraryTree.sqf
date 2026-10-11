/*
    File: fn_libraryTree.sqf
    Author: Darkforce
    Description:
        Defines the tree/list UI handlers for the Global Library dialog
        (referenced by name from dialog.hpp event handlers).
        Called once by TBD_fnc_libraryTool before the dialog is created.
        All database access is synchronous via TBD_fnc_database.
*/

// Refresh the composition tree (optionally filtered)
TBD_fnc_RefreshListUI = {
    params ["_display", ["_filter", ""]];
    if (isNull _display) exitWith {};

    private _ctrlTree = _display displayCtrl 101;
    _ctrlTree ctrlEnable false;

    private _lib = ["list"] call TBD_fnc_database;
    [_lib, _display, _filter] call TBD_fnc_BuildTree;
};

// Build the tree control from the path list (sorted + filtered)
TBD_fnc_BuildTree = {
    params ["_lib", "_display", "_filter"];

    if (isNull _display) exitWith {};
    private _ctrlTree = _display displayCtrl 101;
    tvClear _ctrlTree;

    _lib sort true;

    if (_filter != "") then {
        _filter = toLower _filter;
        _lib = _lib select { toLower _x find _filter != -1 };
    };

    private _pathCache = createHashMap;

    {
        private _fullPathStr = _x;
        private _parts = _fullPathStr splitString "/\";

        private _itemName = _parts deleteAt (count _parts - 1);

        // Handle folders
        private _currentTreePath = [];
        private _currentStringPath = "";

        {
            private _folderName = _x;
            if (_currentStringPath == "") then { _currentStringPath = _folderName; }
            else { _currentStringPath = _currentStringPath + "/" + _folderName; };

            if (_currentStringPath in _pathCache) then {
                _currentTreePath = _pathCache get _currentStringPath;
            } else {
                private _idx = _ctrlTree tvAdd [_currentTreePath, _folderName];
                _ctrlTree tvSetPicture [_currentTreePath + [_idx], "\a3\3DEN\Data\Displays\Display3DEN\PanelLeft\entityList_layer_ca.paa"];
                _ctrlTree tvSetPictureColor [_currentTreePath + [_idx], [1,1,1,1]];
                _ctrlTree tvSetData [_currentTreePath + [_idx], "FOLDER:" + _currentStringPath];
                _currentTreePath = _currentTreePath + [_idx];
                _pathCache set [_currentStringPath, +_currentTreePath];
            };
        } forEach _parts;

        // Add Leaf Item (Only if not Empty placeholder)
        if (_itemName != "(Empty)") then {
            private _idx = _ctrlTree tvAdd [_currentTreePath, _itemName];
            _ctrlTree tvSetPicture [_currentTreePath + [_idx], "\a3\3DEN\Data\Displays\Display3DEN\PanelRight\modeComposition_ca.paa"];
            _ctrlTree tvSetPictureColor [_currentTreePath + [_idx], [1,1,1,1]];
            _ctrlTree tvSetData [_currentTreePath + [_idx], _fullPathStr];
        };

    } forEach _lib;

    tvExpandAll _ctrlTree;
    _ctrlTree ctrlEnable true;
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
        private _strData = ["read", _dataIndex] call TBD_fnc_database;
        [_strData, _ctrlInfo] call TBD_fnc_ShowDetails;
    };
};

TBD_fnc_ShowDetails = {
    params ["_strData", "_ctrlInfo"];

    private _author = "Unknown";
    private _date = "Unknown";
    private _size = "Unknown";

    if (_strData != "" && _strData select [0,5] != "ERROR") then {
        // Check for Folder Placeholder
        if (_strData == "FOLDER") then {
            _size = "Empty Folder Placeholder";
        } else {
            // SAFETY: Check for array bracket
            if (_strData select [0,1] == "[") then {
                private _parsed = parseSimpleArray _strData;
                if (count _parsed > 0 && {_parsed select 0 isEqualType ""} && {_parsed select 0 == "TBD_V2"}) then {
                    // V2
                    private _meta = _parsed select 1;
                    _author = _meta select 0;
                    _date = _meta select 1;
                    _size = _meta select 2;
                    private _fileSizeKB = (count _strData) / 1024;
                    _size = format ["%1 (%2 KB)", _size, _fileSizeKB toFixed 1];
                } else {
                    // Unversioned array without the TBD_V2 header
                    private _fileSizeKB = (count _strData) / 1024;
                    _size = format ["Legacy Format (%1 KB)", _fileSizeKB toFixed 1];
                };
            } else {
                // Not an array (Raw Text / Corrupt)
                _size = "Unknown/Corrupt Data";
                private _fileSizeKB = (count _strData) / 1024;
                _author = format ["Raw Data (%1 KB)", _fileSizeKB toFixed 1];
            };
        };
    };

    private _html = "";
    _html = _html + format ["<t color='#888888'>Date:</t> <t color='#ffffff'>%1</t><br/>", _date];
    _html = _html + format ["<t color='#888888'>Size:</t> <t color='#ffffff'>%1</t><br/>", _size];
    _html = _html + format ["<t color='#888888'>Author:</t> <t color='#ffffff'>%1</t><br/><br/>", _author];

    _ctrlInfo ctrlSetStructuredText parseText _html;
};

TBD_fnc_OnSearch = {
    params ["_ctrlEdit"];
    private _display = ctrlParent _ctrlEdit;
    private _text = ctrlText _ctrlEdit;
    [_display, _text] call TBD_fnc_RefreshListUI;
};

// Key Handler for Tree
TBD_fnc_OnTreeKeyDown = {
    params ["_ctrl", "_key", "_shift", "_ctrlKey", "_alt"];

    // DELETE KEY (211)
    if (_key == 211) exitWith {
        private _display = ctrlParent _ctrl;
        [_display] call TBD_fnc_DeleteGroup;
        true // consume input
    };
    false
};
