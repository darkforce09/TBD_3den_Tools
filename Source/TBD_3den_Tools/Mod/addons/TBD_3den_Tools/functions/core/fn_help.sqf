/*
    File: fn_help.sqf
    Author: Darkforce
    Description: Displays an in-game help dialog for CSO features.
    Parameter(s): None
    Returns: None
*/

disableSerialization;
private _display = findDisplay 313 createDisplay "RscDisplayEmpty";

// Dimensions
private _w = 0.5;
private _h = 0.6;
private _x = (1.0 - _w) / 2;
private _y = (1.0 - _h) / 2;
private _txtH = 0.04;

// Background
private _bg = _display ctrlCreate ["RscText", -1];
_bg ctrlSetPosition [_x, _y, _w, _h];
_bg ctrlSetBackgroundColor [0.05, 0.05, 0.05, 0.95];
_bg ctrlCommit 0;

// Header
private _head = _display ctrlCreate ["RscText", -1];
_head ctrlSetPosition [_x, _y, _w, 0.06];
_head ctrlSetBackgroundColor [0.85, 0.55, 0, 1]; // Professional Gold
_head ctrlSetText localize "STR_CSO_Help_Title";
_head ctrlSetFontHeight (_txtH * 1.2);
_head ctrlCommit 0;

// Text Content (Structured Text for formatting)
private _text = _display ctrlCreate ["RscStructuredText", -1];
_text ctrlSetPosition [_x + 0.02, _y + 0.08, _w - 0.04, _h - 0.16];
_text ctrlSetBackgroundColor [0,0,0,0];
_text ctrlSetText localize "STR_CSO_Help_Content";
_text ctrlSetFontHeight _txtH;
_text ctrlCommit 0;

// Close Button
private _btnClose = _display ctrlCreate ["RscShortcutButton", 2]; // IDC 2 = ESC/Close
_btnClose ctrlSetPosition [_x + (_w * 0.3), _y + _h - 0.07, _w * 0.4, 0.05];
_btnClose ctrlSetText "CLOSE";
_btnClose ctrlSetEventHandler ["ButtonClick", " (ctrlParent (_this select 0)) closeDisplay 2; "];
_btnClose ctrlCommit 0;
