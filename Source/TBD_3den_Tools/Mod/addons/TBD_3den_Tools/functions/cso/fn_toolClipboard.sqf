/* CLIPBOARD TOOL (Smart Path Cleaner - Preserves Folders) */

TBD_fnc_RunClipboardScan = {
    params ["_customVarName", "_exportRaw"];

    private _arrayOfCSObjects = call TBD_fnc_collectSimpleObjects;

    if (count _arrayOfCSObjects == 0) exitWith { systemChat "CSO ERROR: No objects found."; };
    
    // --- SHARED UTILITIES EXPECTED ---
    /* 
       User's code had a check for GMN_fnc_SerializeObjects. 
       In this mod, the function is defined as TBD_fnc_serializeObjects in config.cppFunctions.
       So we don't need to manually complie or check it if the addon is loaded correctly.
    */

    // Get Data
    private _dataArray = [_arrayOfCSObjects] call TBD_fnc_serializeObjects;
    private _dataString = str _dataArray;

    // Use the shared generator function
    private _textSQF = [_dataArray, _customVarName, _exportRaw] call TBD_fnc_generateSpawnScript;

    copyToClipboard _textSQF;
    systemChat format ["CSO: Copied %1 objects (%2).", count _arrayOfCSObjects, if (_exportRaw) then {"Raw Data"} else {"Full Code"}];
};

disableSerialization;
private _display = findDisplay 313 createDisplay "RscDisplayEmpty";
private _w = 0.5; private _h = 0.35; private _x = (1.0 - _w) / 2; private _y = (1.0 - _h) / 2; private _txtH = 0.05; 
private _bg = _display ctrlCreate ["RscText", -1]; _bg ctrlSetPosition [_x, _y, _w, _h]; _bg ctrlSetBackgroundColor [0.05, 0.05, 0.05, 0.95]; _bg ctrlCommit 0;
private _title = _display ctrlCreate ["RscText", -1]; _title ctrlSetPosition [_x, _y, _w, 0.06]; _title ctrlSetBackgroundColor [0.85, 0.55, 0, 1]; _title ctrlSetText " CSO: Export Settings"; _title ctrlSetFontHeight (_txtH * 1.2); _title ctrlCommit 0;
private _label = _display ctrlCreate ["RscText", -1]; _label ctrlSetPosition [_x, _y + 0.08, _w, 0.05]; _label ctrlSetText "Enter variable name (Optional):"; _label ctrlSetFontHeight _txtH; _label ctrlCommit 0;
private _edit = _display ctrlCreate ["RscEdit", 100]; _edit ctrlSetPosition [_x + 0.05, _y + 0.14, _w - 0.1, 0.06]; _edit ctrlSetBackgroundColor [0, 0, 0, 1]; _edit ctrlSetText "CSO_Objects_01"; _edit ctrlSetFontHeight _txtH; _edit ctrlCommit 0;
private _chk = _display ctrlCreate ["RscCheckbox", 101]; _chk ctrlSetPosition [_x + 0.05, _y + 0.21, 0.05, 0.05]; _chk ctrlCommit 0;
private _chkLabel = _display ctrlCreate ["RscText", -1]; _chkLabel ctrlSetPosition [_x + 0.11, _y + 0.21, _w - 0.15, 0.05]; _chkLabel ctrlSetText "Export RAW DATA Only"; _chkLabel ctrlSetFontHeight _txtH; _chkLabel ctrlCommit 0;
private _btn = _display ctrlCreate ["RscShortcutButton", -1]; _btn ctrlSetPosition [_x + 0.1, _y + 0.27, _w - 0.2, 0.06]; _btn ctrlSetText "COPY TO CLIPBOARD"; _btn ctrlSetFontHeight _txtH;
_btn ctrlSetEventHandler ["ButtonClick", " _display = ctrlParent (_this select 0); _text = ctrlText (_display displayCtrl 100); _raw = cbChecked (_display displayCtrl 101); _display closeDisplay 1; [_text, _raw] call TBD_fnc_RunClipboardScan; "]; _btn ctrlCommit 0;
ctrlSetFocus _edit;