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
private _soData = [_initCode] call TBD_fnc_parseLogicData;
if (count _soData == 0) exitWith { systemChat localize "STR_CSO_Err_CorruptData"; };

// Restore objects
[_soData, _logicName] call TBD_fnc_restoreObjects;
