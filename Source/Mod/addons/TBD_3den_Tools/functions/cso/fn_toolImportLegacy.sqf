/*
    File: fn_toolImportLegacy.sqf
    Author: Darkforce
    Description: Imports legacy object data directly from a selected Game Logic's Init field.
    Parameter(s): None
*/

private _selected = get3DENSelected "Logic";
if (count _selected == 0) exitWith { 
    systemChat "TBD Import: Please select the Game Logic containing the legacy data."; 
};

private _logic = _selected select 0;
private _layerName = (_logic get3DENAttribute "Name") select 0;
if (_layerName == "") then { _layerName = "Imported_Legacy"; };

private _initCode = (_logic get3DENAttribute "Init") select 0;
if (_initCode == "") exitWith { systemChat "TBD Import: Selected Logic has no Init code."; };

// LOGIC MIRRORED FROM fn_toolRestore.sqf
private _markerStart = "_soData = [";
private _markerEnd = "];";
private _startIndex = _initCode find _markerStart;

// If exact match not found, try flexible match for user convenience (extra spaces)
// But to strictly follow "same idea", we rely on FIND finding the substring.
if (_startIndex == -1) exitWith { 
    systemChat "TBD Import: Data must start with '_soData = [' (ensure spacing is exact)."; 
};

private _tempStr = _initCode select [_startIndex];
private _endIndex = _tempStr find _markerEnd;

if (_endIndex == -1) exitWith {
    systemChat "TBD Import: Data must end with '];'.";
};

// Extract the full assignment statement
private _arrayCode = _tempStr select [0, _endIndex + 2];

// Clean array code to allow parseSimpleArray
private _eqIndex = _arrayCode find "=";
private _arrOnly = _arrayCode select [_eqIndex + 1];

// Remove semi-colons using the split/join method from restore tool
_arrOnly = [_arrOnly, ";", ""] call { params["_s","_f","_r"]; _s splitString _f joinString _r };

private _soData = parseSimpleArray _arrOnly;

if (isNil "_soData" || {!(_soData isEqualType [])}) exitWith {
    systemChat "TBD Import: Failed to parse array data.";
};

systemChat format ["TBD Import: Found %1 objects. Restoring to layer '%2'...", count _soData, _layerName];

// Execute Restoration
[_soData, _layerName] call TBD_fnc_restoreObjects;
