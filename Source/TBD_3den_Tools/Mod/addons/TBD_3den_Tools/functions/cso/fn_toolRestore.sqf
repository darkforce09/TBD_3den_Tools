/*
    File: fn_toolRestore.sqf
    Author: Darkforce
    Description: Restores a CSO Logic entity back into editable Eden objects, preserving their original layers and textures.
    Parameter(s): None
    Returns: None
*/

private _selected = get3DENSelected "Logic";
if (count _selected == 0) exitWith { systemChat localize "STR_CSO_Err_SelectLogic"; };

private _logic = _selected select 0;
private _logicName = (_logic get3DENAttribute "Name") select 0;
if (_logicName == "") then { _logicName = "TBD_Restored_Group"; }; 

private _initCode = (_logic get3DENAttribute "Init") select 0;
private _markerStart = "_soData = [";
private _markerEnd = "];";
private _startIndex = _initCode find _markerStart;
if (_startIndex == -1) exitWith { systemChat localize "STR_CSO_Err_CorruptData"; };

private _tempStr = _initCode select [_startIndex];
private _endIndex = _tempStr find _markerEnd;
private _arrayCode = _tempStr select [0, _endIndex + 2];

// Clean array code to allow parseSimpleArray
private _eqIndex = _arrayCode find "=";
private _arrOnly = _arrayCode select [_eqIndex + 1];
_arrOnly = [_arrOnly, ";", ""] call { params["_s","_f","_r"]; _s splitString _f joinString _r };

private _soData = parseSimpleArray _arrOnly;

// Restore objects
[_soData, _logicName] call TBD_fnc_restoreObjects;