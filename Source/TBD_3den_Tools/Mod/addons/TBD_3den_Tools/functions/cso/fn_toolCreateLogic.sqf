/*
    File: fn_toolCreateLogic.sqf
    Author: Darkforce
    Description: Compacts selected objects into a Game Logic entity with a self-contained spawn script.
    Parameter(s): 
        _rawName (String): Name of the Game Logic
    Returns: None
*/

TBD_fnc_RunLogicCreation = {
    params ["_rawName"];
    if (_rawName == "") exitWith { systemChat localize "STR_CSO_Err_EnterName"; };

    // Sanitization
    private _validName = _rawName splitString " " joinString "_";
    
    private _arrayOfCSObjects = call TBD_fnc_collectSimpleObjects;

    if (count _arrayOfCSObjects == 0) exitWith { systemChat localize "STR_CSO_Err_NoObjectsFound"; };

    private _br = toString [13, 10]; 
    private _finalCodeParts = [];
    
    // 2. Prepare data
    private _dataArray = [_arrayOfCSObjects] call TBD_fnc_serializeObjects;
    
    // 3. Assemble script using shared generator
    private _textSQF = [_dataArray, _validName, false] call TBD_fnc_generateSpawnScript;

    collect3DENHistory {
        private _centerPos = screenToWorld [0.5, 0.5];
        private _logic = create3DENEntity ["Logic", "Logic", _centerPos];
        _logic set3DENAttribute ["Name", _validName];
        _logic set3DENAttribute ["Init", _textSQF];
        _logic set3DENAttribute ["description", "Simple Objects Data"];
        systemChat format [localize "STR_CSO_Success_CreatedLogic", _validName];
    };
};

disableSerialization;
private _display = findDisplay 313 createDisplay "RscDisplayEmpty";
private _w = 0.5; private _h = 0.3; private _x = (1.0 - _w) / 2; private _y = (1.0 - _h) / 2; private _txtH = 0.05; 
private _bg = _display ctrlCreate ["RscText", -1]; _bg ctrlSetPosition [_x, _y, _w, _h]; _bg ctrlSetBackgroundColor [0.05, 0.05, 0.05, 0.95]; _bg ctrlCommit 0;
private _title = _display ctrlCreate ["RscText", -1]; _title ctrlSetPosition [_x, _y, _w, 0.06]; _title ctrlSetBackgroundColor [0.85, 0.55, 0, 1]; _title ctrlSetText " TBD: Name Your Logic Entity"; _title ctrlSetFontHeight (_txtH * 1.2); _title ctrlCommit 0;
private _label = _display ctrlCreate ["RscText", -1]; _label ctrlSetPosition [_x, _y + 0.08, _w, 0.05]; _label ctrlSetText "Enter unique name (e.g. TBD_Airport):"; _label ctrlSetFontHeight _txtH; _label ctrlCommit 0;
private _edit = _display ctrlCreate ["RscEdit", 100]; _edit ctrlSetPosition [_x + 0.05, _y + 0.14, _w - 0.1, 0.06]; _edit ctrlSetBackgroundColor [0, 0, 0, 1]; _edit ctrlSetText "TBD_Manager_01"; _edit ctrlSetFontHeight _txtH; _edit ctrlCommit 0;
private _btn = _display ctrlCreate ["RscShortcutButton", -1]; _btn ctrlSetPosition [_x + 0.1, _y + 0.22, _w - 0.2, 0.06]; _btn ctrlSetText "CREATE LOGIC"; _btn ctrlSetFontHeight _txtH;
_btn ctrlSetEventHandler ["ButtonClick", " _display = ctrlParent (_this select 0); _text = ctrlText (_display displayCtrl 100); _display closeDisplay 1; [_text] call TBD_fnc_RunLogicCreation; "]; _btn ctrlCommit 0;
_edit ctrlSetEventHandler ["KeyDown", " params ['_ctrl', '_key']; if (_key == 28 || _key == 156) then { _display = ctrlParent _ctrl; _text = ctrlText _ctrl; _display closeDisplay 1; [_text] call TBD_fnc_RunLogicCreation; }; "];
ctrlSetFocus _edit;