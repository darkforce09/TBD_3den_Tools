/*
    File: fn_parseLogicData.sqf
    Author: Darkforce
    Description: Extracts the serialized "_soData = [...];" array from a CSO Game Logic's Init code.
    Parameter(s):
        _initCode (String): The Init attribute text of the Game Logic
    Returns:
        Array: The parsed object data, or [] if not found or invalid.
*/

params [["_initCode", ""]];

if (_initCode == "") exitWith { [] };

private _startIndex = _initCode find "_soData = [";
if (_startIndex == -1) exitWith { [] };

private _tempStr = _initCode select [_startIndex];
private _endIndex = _tempStr find "];";
if (_endIndex == -1) exitWith { [] };

private _arrayCode = _tempStr select [0, _endIndex + 2];
private _eqIndex = _arrayCode find "=";
private _arrOnly = _arrayCode select [_eqIndex + 1];
_arrOnly = [_arrOnly, ";", ""] call TBD_fnc_db_replace;

private _parsed = parseSimpleArray _arrOnly;
if (isNil "_parsed" || {!(_parsed isEqualType [])}) exitWith { [] };
_parsed
