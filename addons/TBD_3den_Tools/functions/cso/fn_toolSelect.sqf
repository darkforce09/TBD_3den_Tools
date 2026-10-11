/*
    File: fn_toolSelect.sqf
    Author: Darkforce
    Description: Utility to find and select all objects in the mission that are marked for CSO optimization.
    Parameter(s): None
    Returns: None
*/

// Find valid objects
private _markedObjects = call TBD_fnc_collectSimpleObjects;

// Select objects
if (count _markedObjects > 0) then {
    
    // Update editor selection
    set3DENSelected _markedObjects;
    
    systemChat format [localize "STR_CSO_FoundSelected", count _markedObjects];
    
} else {
    systemChat localize "STR_CSO_Warn_NoObjects";
    playSound "FD_CP_Not_Clear_F";
};
