/*
    File: fn_toolSelect.sqf
    Author: Darkforce
    Description: Utility to find and select all objects in the mission that are marked for CSO optimization.
    Parameter(s): None
    Returns: None
*/

// Find valid objects
private _allMissionObjects = (all3DENEntities select 0);
private _markedObjects = [];

{
    // Check attribute
    private _isSimpleObject = (_x get3DENAttribute "CSObject") select 0;
    
    if (_isSimpleObject) then {
        _markedObjects pushBack _x;
    };
} forEach _allMissionObjects;

// Select objects
if (count _markedObjects > 0) then {
    
    // Update editor selection
    set3DENSelected _markedObjects;
    
    systemChat format [localize "STR_CSO_FoundSelected", count _markedObjects];
    
} else {
    systemChat localize "STR_CSO_Warn_NoObjects";
    playSound "FD_CP_Not_Clear_F";
};