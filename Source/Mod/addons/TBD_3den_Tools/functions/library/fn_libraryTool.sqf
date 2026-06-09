/*
    File: fn_libraryTool.sqf
    Author: Darkforce
    Description:
        Opens the Global Library dialog.
        Defines the UI handlers (dialog.hpp references them by name via
        TBD_fnc_libraryTree / TBD_fnc_libraryActions), creates the display
        and populates the composition tree.
*/

// Define the dialog's handler functions
call TBD_fnc_libraryTree;
call TBD_fnc_libraryActions;

// Create GUI - CONFIG MODE
private _display = findDisplay 313 createDisplay "TBD_Library_Dialog";

// Add Event Handlers
private _ctrlTree = _display displayCtrl 101;
_ctrlTree ctrlSetEventHandler ["KeyDown", "_this call TBD_fnc_OnTreeKeyDown"];

// Initialize List
[_display] call TBD_fnc_RefreshListUI;
