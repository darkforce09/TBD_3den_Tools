/*
    File: fn_collectSimpleObjects.sqf
    Author: Darkforce
    Description: Scans the Eden Editor mission for objects marked for Simple Object conversion.
    Parameter(s): None
    Returns: 
        Array: List of objects with the "CSObject" attribute enabled.
*/

private _allMissionObjects = (all3DENEntities select 0);
private _arrayOfCSObjects = [];

{
    private _isSimpleObject = (_x get3DENAttribute "CSObject") select 0;
    if (_isSimpleObject) then { _arrayOfCSObjects pushBack _x; };
} forEach _allMissionObjects;

_arrayOfCSObjects
