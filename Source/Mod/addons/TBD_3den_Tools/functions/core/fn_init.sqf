/*
    File: fn_init.sqf
    Author: Darkforce
    Description: Post-Initialization script. Runs automatically when the addon is loaded.
    Parameter(s): None
    Returns: None
*/

if (is3DEN) then {
    systemChat "------------------------------------------------";
    systemChat "TBD Tools: Optimization Suite Initialized.";
    
    // STARTUP CHECK: Verify Extension is Loaded
    private _version = "TBD_DB" callExtension "version";
    if (_version == "") then {
        ["CRITICAL WARNING:\n\nTBD_DB Extension NOT Found.\n\nThe library will NOT function.\nEnsure 'TBD_DB_x64.dll' is in the addon folder and not blocked by Windows.", "TBD Tools Error", "OK"] call BIS_fnc_guiMessage;
        systemChat "CRITICAL: TBD_DB Extension FAILED to load.";
    } else {
        systemChat format ["TBD_DB Extension Loaded (v%1)", _version];
        systemChat "Ready to optimize compositions.";
    };

    systemChat "------------------------------------------------";
};
