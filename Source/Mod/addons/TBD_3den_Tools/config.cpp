
class CfgPatches {
  class TBD_3den_Tools {
    units[] = {};
    weapons[] = {};
    requiredVersion = 2.14;
    requiredAddons[] = {"3den"};
    author[] = {"Darkforce"};
  };
};

class Cfg3DEN {
  class Object {
    class AttributeCategories {
      class StateSpecial {
        class Attributes {
          class CSObject {
            displayName = "Create as simple object?";
            tooltip = "Enable this to include this object in the CSO optimization.";
            property = "CSObject";
            control = "Checkbox";
            defaultValue = "false";
          };
          class CSO_Align {
            displayName = "CSO: Align to Terrain?";
            tooltip = "True: Object tilts to match slope.\nFalse: Object stays flat (Vertical).";
            property = "CSO_Align";
            control = "Checkbox";
            defaultValue = "false";
          };
          class CSO_Super {
            displayName = "CSO: Force Super Simple?";
            tooltip = "True: Removes ALL physics (Visual only).\nFalse: Keeps basic collision.";
            property = "CSO_Super";
            control = "Checkbox";
            defaultValue = "false";
          };
          class CSO_Local {
            displayName = "CSO: Create Locally?";
            tooltip = "True: Created on client only (Best Performance).\nFalse: Networked/Global (Synced by server).";
            property = "CSO_Local";
            control = "Checkbox";
            defaultValue = "true";
          };
        };
      };
    };
  };

  // NATIVE CONTEXT MENU INTEGRATION
  class ContextMenu {
    class Items {
      class CSO_Context_Save {
        action = "call TBD_fnc_libraryTool";
        text = "$STR_CSO_Context_Opt"; // Localized "Save to Library"
        conditionShow = "selectedObject";
        value = 0;
      };
      class CSO_Context_Save_Logic {
        action = "call TBD_fnc_libraryTool";
        text = "$STR_CSO_Context_Opt"; 
        conditionShow = "selectedLogic";
        value = 0;
      };
      class CSO_Context_Save_Trigger {
        action = "call TBD_fnc_libraryTool";
        text = "$STR_CSO_Context_Opt"; 
        conditionShow = "selectedTrigger";
        value = 0;
      };
      class CSO_Context_Save_Marker {
        action = "call TBD_fnc_libraryTool";
        text = "$STR_CSO_Context_Opt"; 
        conditionShow = "selectedMarker";
        value = 0;
      };
      class CSO_Context_Save_Waypoint {
        action = "call TBD_fnc_libraryTool";
        text = "$STR_CSO_Context_Opt"; 
        conditionShow = "selectedWaypoint";
        value = 0;
      };
      class CSO_Context_Clip {
        action = "call TBD_fnc_clipboardTool";
        text = "$STR_CSO_Context_Clip"; // Localized "Copy Code"
        conditionShow = "selectedObject";
        value = 0;
      };
    };
  };
};

class ctrlMenu;
class ctrlMenuStrip;
class display3DEN {
  class Controls {
    class MenuStrip : ctrlMenuStrip {
      class Items {
        items[] += {"TBD_Tools_Menu"};
        class TBD_Tools_Menu {
          text = "TBD Tools";
          items[] = {"CSO_Btn_Library",   "CSO_Separator",
                     "CSO_Tools_Submenu"};
        };

        class CSO_Tools_Submenu {
          text = "CSO Operations";
          items[] = {"CSO_Btn_SelectAll", "CSO_Btn_Logic",
                     "CSO_Btn_Clipboard", "CSO_Separator",
                     "CSO_Btn_Delete",    "CSO_Btn_Restore",
                     "CSO_Separator",     "CSO_Btn_Help"};
        };

        // --- BUTTON DEFINITIONS ---
        class CSO_Btn_Library {
          text = "TBD Global Library (Saved Groups)";
          action = "call TBD_fnc_libraryTool";
          picture = "\a3\3DEN\Data\Displays\Display3DEN\ToolBar\open_ca.paa";
        };
        class CSO_Btn_SelectAll {
          text = "Select All Marked Objects (Find)";
          action = "call TBD_fnc_selectMarked";
          picture =
              "\a3\3DEN\Data\Displays\Display3DEN\ToolBar\search_ca.paa"; // Search
                                                                          // Icon
        };
        class CSO_Btn_Logic {
          text = "Save to Game Logic (Auto-Run)";
          action = "call TBD_fnc_createLogic";
          picture =
              "\a3\3DEN\Data\Displays\Display3DEN\EntityMenu\logic_ca.paa";
        };
        class CSO_Btn_Clipboard {
          text = "Copy Code to Clipboard (Manual)";
          action = "call TBD_fnc_clipboardTool";
          picture = "\a3\3DEN\Data\Displays\Display3DEN\ToolBar\copy_ca.paa";
        };
        class CSO_Btn_Delete {
          text = "Delete CSO Objects (Cleanup)";
          action = "call TBD_fnc_deleteTool";
          picture = "\a3\3DEN\Data\Displays\Display3DEN\ToolBar\delete_ca.paa";
        };
        class CSO_Btn_Restore {
          text = "Restore CSO Objects (Edit)";
          action = "call TBD_fnc_restoreTool";
          picture = "\a3\3DEN\Data\Displays\Display3DEN\ToolBar\paste_ca.paa";
        };
        class CSO_Btn_Help {
          text = "CSO Help & Guide";
          action = "call TBD_fnc_help";
          picture = "\a3\3DEN\Data\Displays\Display3DEN\ToolBar\help_ca.paa";
        };
        class CSO_Separator {
          value = 0;
        };
      };
    };
  };
};

class CfgFunctions {
  class TBD {
    tag = "TBD";
    class Core {
      file = "TBD_3den_Tools\functions\core";
      class init {
        postInit = 1;
      };
      class help {};
    };
    class Library {
      file = "TBD_3den_Tools\functions\library";
      class database {};
      class libraryTool {};
    };
    class CSO {
      file = "TBD_3den_Tools\functions\cso";
      class serializeObjects {};
      class restoreObjects {};
      class createLogic {
        file = "TBD_3den_Tools\functions\cso\fn_toolCreateLogic.sqf";
      };
      class clipboardTool {
        file = "TBD_3den_Tools\functions\cso\fn_toolClipboard.sqf";
      };
      class deleteTool {
        file = "TBD_3den_Tools\functions\cso\fn_toolDelete.sqf";
      };
      class restoreTool {
        file = "TBD_3den_Tools\functions\cso\fn_toolRestore.sqf";
      };
      class selectMarked {
        file = "TBD_3den_Tools\functions\cso\fn_toolSelect.sqf";
      };
      class generateSpawnScript {
        file = "TBD_3den_Tools\functions\cso\fn_generateSpawnScript.sqf";
      };
      class collectSimpleObjects {
        file = "TBD_3den_Tools\functions\cso\fn_collectSimpleObjects.sqf";
      };
    };
  };
};

class cfgMods {
  author = "Darkforce";
  timepacked = "1464828630";
};

// --- UI INCLUDES ---
#include "ui\defines.hpp"
#include "ui\dialog.hpp"
