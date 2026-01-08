/*
    File: fn_generateSpawnScript.sqf
    Author: Darkforce
    Description: Generates a formatted SQF script for spawning simple objects.
    Parameter(s): 
        _dataArray (Array): The serialized object data.
        _varName (String): Optional. The variable name to assign the spawned objects to. Defaults to "CSO_Objects_<random>".
        _exportRaw (Boolean): Optional. If true, returns only the data array string. Defaults to false.
    Returns: 
        String: The generated SQF code.
*/

params ["_dataArray", ["_varName", ""], ["_exportRaw", false]];

private _br = toString [13, 10]; 
private _finalCodeParts = [];

// 1. Header & Function Definition
if (!_exportRaw) then {

    _finalCodeParts pushBack ("if (isNil 'TBD_fnc_spawnSimpleObjects') then {" + _br + " TBD_fnc_spawnSimpleObjects = {" + _br + "  params ['_data'];" + _br + "  private _spawnedObjects = [];" + _br + "  {" + _br + "   _x params ['_class', '_path', '_pos', '_dir', '_vec', '_tex', '_scale', '_align', '_super', '_local'];" + _br + "   if (_pos isEqualType '') then { _pos = call compile _pos; };" + _br + "   _obj = [[_class, _path], _pos, _dir, _align, _super, _local] call BIS_fnc_createSimpleObject;" + _br + "   _obj setVectorDirAndUp _vec;" + _br + "   _obj setObjectScale _scale;" + _br + "   { if (_x != '') then { _obj setObjectTexture [_forEachIndex, _x]; }; } forEach _tex;" + _br + "   _spawnedObjects pushBack _obj;" + _br + "  } forEach _data;" + _br + "  _spawnedObjects" + _br + " };" + _br + "};");
    _finalCodeParts pushBack "";
    
    // 2. Data Array (Formatted line-by-line)
    _finalCodeParts pushBack ("_soData = [");
    {
        _finalCodeParts pushBack (str _x + (if (_forEachIndex == (count _dataArray - 1)) then {""} else {","}));
    } forEach _dataArray;
    _finalCodeParts pushBack ("];");
} else {
    // Raw export just returns the list
    _finalCodeParts pushBack (str _dataArray);
};

// 3. Footer (Execution)
if (!_exportRaw) then {
    _finalCodeParts pushBack "";
    if (_varName == "") then { _varName = format ["CSO_Objects_%1", floor(random 10000)]; };
    _finalCodeParts pushBack format ["%1 = [_soData] call TBD_fnc_spawnSimpleObjects;", _varName];
};

_finalCodeParts joinString _br;
