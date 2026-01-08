/*
    File: fn_toolDelete.sqf
    Author: Darkforce
    Description: Safely deletes objects marked for optimization, with a confirmation dialog.
    Parameter(s): None
    Returns: None
*/

TBD_fnc_RunDelete = {
    params ["_objects"];
    
    collect3DENHistory {
        delete3DENEntities _objects;
    };
    
    systemChat format [localize "STR_CSO_Success_Deleted", count _objects];
};

// Find marked objects
private _allMissionObjects = (all3DENEntities select 0);
private _objectsToDelete = [];

{
    private _isSimpleObject = (_x get3DENAttribute "CSObject") select 0;
    if (_isSimpleObject) then { _objectsToDelete pushBack _x; };
} forEach _allMissionObjects;

// Confirm deletion
private _count = count _objectsToDelete;

if (_count > 0) then {
    // Create dialog
    disableSerialization;
    private _display = findDisplay 313 createDisplay "RscDisplayEmpty";
    
    private _w = 0.4; private _h = 0.25; private _x = (1.0 - _w) / 2; private _y = (1.0 - _h) / 2; private _txtH = 0.05; 
    
    // Background
    private _bg = _display ctrlCreate ["RscText", -1]; 
    _bg ctrlSetPosition [_x, _y, _w, _h]; 
    _bg ctrlSetBackgroundColor [0.05, 0.05, 0.05, 0.95]; 
    _bg ctrlCommit 0;
    
    // Header
    private _head = _display ctrlCreate ["RscText", -1]; 
    _head ctrlSetPosition [_x, _y, _w, 0.06]; 
    _head ctrlSetBackgroundColor [0.85, 0.2, 0, 1]; // Red Warning Color
    _head ctrlSetText " DELETE CONFIRMATION"; 
    _head ctrlSetFontHeight (_txtH * 1.2); 
    _head ctrlCommit 0;
    
    // Text
    private _text = _display ctrlCreate ["RscText", -1]; 
    _text ctrlSetPosition [_x + 0.02, _y + 0.08, _w - 0.04, 0.08]; 
    _text ctrlSetText format ["Are you sure you want to delete %1 marked objects?", _count]; 
    _text ctrlSetFontHeight _txtH; 
    _text ctrlCommit 0;
    
    // Store list for callback
    uiNamespace setVariable ["TBD_Delete_List", _objectsToDelete];
    
    // DELETE Button
    private _btnDel = _display ctrlCreate ["RscShortcutButton", -1]; 
    _btnDel ctrlSetPosition [_x + 0.02, _y + 0.17, _w * 0.45, 0.06]; 
    _btnDel ctrlSetText "DELETE"; 
    _btnDel ctrlSetFontHeight _txtH; 
    _btnDel ctrlSetEventHandler ["ButtonClick", " _display = ctrlParent (_this select 0); _list = uiNamespace getVariable 'TBD_Delete_List'; [_list] call TBD_fnc_RunDelete; _display closeDisplay 1; "]; 
    _btnDel ctrlCommit 0;
    
    // CANCEL Button
    private _btnCancel = _display ctrlCreate ["RscShortcutButton", -1]; 
    _btnCancel ctrlSetPosition [_x + (_w * 0.53), _y + 0.17, _w * 0.45, 0.06]; 
    _btnCancel ctrlSetText "CANCEL"; 
    _btnCancel ctrlSetFontHeight _txtH; 
    _btnCancel ctrlSetEventHandler ["ButtonClick", " _display = ctrlParent (_this select 0); _display closeDisplay 1; "]; 
    _btnCancel ctrlCommit 0;
    
    ctrlSetFocus _btnCancel; // Focus cancel by default for safety
    
} else {
    systemChat localize "STR_CSO_Warn_NoObjects";
    playSound "FD_CP_Not_Clear_F";
};