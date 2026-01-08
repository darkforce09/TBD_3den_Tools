class TBD_Library_Dialog 
{
    idd = 86000;
    movingenable = 0;
    enableSimulation = 1;
    
    // safeZone anchoring for center screen
    // W = 0.6 * safezoneW
    // H = 0.6 * safezoneH
    #define D_W (0.6 * safezoneW)
    #define D_H (0.6 * safezoneH)
    #define D_X (safezoneX + (safezoneW - D_W)/2)
    #define D_Y (safezoneY + (safezoneH - D_H)/2)
    
    #define H_HEAD (0.04 * safezoneH)
    #define H_BAR  (0.06 * safezoneH) // Increased height for bigger buttons
    #define H_FOOT (0.05 * safezoneH)
    #define PAD    (0.005 * safezoneW)

    class ControlsBackground 
    {
        // MAIN BACKGROUND (Dark Slate)
        class MainBg: RscText {
            idc = -1;
            x = D_X; y = D_Y;
            w = D_W; h = D_H;
            colorBackground[] = COL_BG;
        };
        
        // Header Bg
        class HeaderBg: RscText {
            idc = -1;
            x = D_X; y = D_Y;
            w = D_W; h = H_HEAD;
            colorBackground[] = COL_BG_LIGHT; // Slight contrast
        };
        
        // Footer Bg
        class FooterBg: RscText {
            idc = -1;
            x = D_X; y = D_Y + D_H - H_FOOT;
            w = D_W; h = H_FOOT;
            colorBackground[] = COL_BG_LIGHT;
        };
    };

    class Controls 
    {
        // --- HEADER ---
        class Title: RscText {
            idc = -1;
            text = "TBD GLOBAL COMPOSITION LIBRARY";
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.5)"; // Increased size slightly
            x = D_X + PAD; 
            y = D_Y;
            w = D_W - H_HEAD;
            h = H_HEAD;
            colorText[] = {0.9, 0.9, 0.9, 1}; // Slightly off-white
            shadow = 1;
            style = ST_LEFT; // Removed ST_VCENTER (0x0C) to test visibility
        };
        class CloseBtn: RscButton {
            idc = 2; // Standard Cancel IDC (optional but good practice)
            text = "X";
            style = 2; // ST_CENTER
            font = "PuristaBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
            x = D_X + D_W - (H_HEAD * 0.8) - PAD; 
            y = D_Y + (H_HEAD * 0.1);             
            w = H_HEAD * 0.8; h = H_HEAD * 0.8;
            colorBackground[] = {0, 0, 0, 0};
            colorBackgroundActive[] = {1, 0, 0, 1}; // Red background on hover
            colorFocused[] = {0, 0, 0, 0}; // Transparent when focused (prevents sticky red)
            colorText[] = {0.8, 0.8, 0.8, 1}; // Light grey text
            colorShadow[] = {0,0,0,0};
            colorBorder[] = {0,0,0,0};
            shadow = 0;
            action = "closeDialog 0";
            tooltip = "Close";
        };

        // --- TOOLBAR (Search Left, Actions Right) ---
        class SearchBar: RscEdit {
            idc = 103;
            x = D_X + PAD;
            y = D_Y + H_HEAD + (H_BAR - 0.04)/2; 
            w = D_W * 0.3; // Slightly narrower to give space
            h = 0.04;
            colorBackground[] = COL_BG_LIGHT;
            style = ST_FRAME + ST_VCENTER;
            text = "Search compositions...";
            colorText[] = {0.7, 0.7, 0.7, 1}; // Placeholder color
            font = FONT_MAIN;
            shadow = 0;
            tooltip = "Search compositions...";
            onSetFocus = "params ['_ctrl']; if (ctrlText _ctrl == 'Search compositions...') then { _ctrl ctrlSetText ''; _ctrl ctrlSetTextColor [1,1,1,1]; };";
            onKillFocus = "params ['_ctrl']; if (ctrlText _ctrl == '') then { _ctrl ctrlSetText 'Search compositions...'; _ctrl ctrlSetTextColor [0.7,0.7,0.7,1]; };";
            onKeyUp = "_this call TBD_fnc_OnSearch;";
        };
        
        // Actions: New Folder | Rename | Delete
        // Using relative offsets from SearchBar for tighter packing
        class NewFolderVisual: RscStructuredText {
            idc = -1;
            x = D_X + D_W - (0.22 * safezoneW) - PAD;
            y = D_Y + H_HEAD + (H_BAR - 0.05)/2;
            w = 0.12 * safezoneW; h = 0.05;
            colorBackground[] = {0,0,0,0};
            // 3DEN Folder Icon
            text = "<t align='left' valign='middle' shadow='0'><img image='\a3\3DEN\Data\Displays\Display3DEN\PanelLeft\entityList_layer_ca.paa' size='1.3' /> <t color='#cccccc' size='1.2'>New Folder</t></t>";
        };

        class BtnNewFolder: RscButton {
            idc = 201;
            text = "";
            x = D_X + D_W - (0.22 * safezoneW) - PAD; 
            y = D_Y + H_HEAD + (H_BAR - 0.05)/2;
            w = 0.12 * safezoneW; h = 0.05;
            colorBackground[] = {0,0,0,0};      
            colorBackgroundActive[] = {1,1,1,0.05}; 
            colorText[] = {0,0,0,0}; // Transparent text
            colorBorder[] = {0,0,0,0};
            shadow = 0;
            tooltip = "Create New Folder";
            onButtonClick = "[ctrlParent (_this select 0)] call TBD_fnc_CreateFolder;";
        };
        
        class DeleteVisual: RscStructuredText {
            idc = -1;
            x = D_X + D_W - (0.10 * safezoneW);
            y = D_Y + H_HEAD + (H_BAR - 0.05)/2;
            w = 0.1 * safezoneW; h = 0.05;
            colorBackground[] = {0,0,0,0};
            text = "<t align='left' valign='middle' shadow='0'><img image='a3\3den\data\displays\display3den\panelleft\entitylist_delete_ca.paa' size='1.3' /> <t color='#ff5555' size='1.2'>Delete</t></t>";
            enable = 0;
        };
        
        class BtnDelete: RscButton {
            idc = 203;
            text = "";
            x = D_X + D_W - (0.10 * safezoneW);
            y = D_Y + H_HEAD + (H_BAR - 0.05)/2;
            w = 0.1 * safezoneW; h = 0.05;
            colorBackground[] = {0,0,0,0};
            colorBackgroundActive[] = {1, 0.2, 0.2, 0.1}; // Slight red hover tint
            colorText[] = {0,0,0,0};
            colorBorder[] = {0,0,0,0};
            shadow = 0;
            tooltip = "Delete Selection";
            onButtonClick = "[ctrlParent (_this select 0)] call TBD_fnc_DeleteGroup;";
        };
        
        // --- CONTENT SPLIT VIEW ---
        class FileTree: RscTree {
            idc = 101;
            x = D_X + PAD;
            y = D_Y + H_HEAD + H_BAR + PAD;
            w = (D_W * 0.6) - (PAD * 1.5);
            h = D_H - H_HEAD - H_BAR - H_FOOT - (PAD * 2);
            colorBackground[] = COL_BG_LIGHT;
            colorSelect[] = COL_BTN_LOAD;     
            colorSelectBackground[] = {1,1,1,0.05};
            colorBorder[] = {1,1,1,0.1};
            onTreeSelChanged = "_this call TBD_fnc_OnTreeSelChanged;";
            // Removed onTreeDblClick
        };
        
        // details Background
        class DetailsBg: RscText {
            idc = -1;
            x = D_X + (D_W * 0.6) + (PAD * 0.5);
            y = D_Y + H_HEAD + H_BAR + PAD;
            w = (D_W * 0.4) - (PAD * 1.5);
            h = D_H - H_HEAD - H_BAR - H_FOOT - (PAD * 2);
            colorBackground[] = COL_BG_LIGHT;
        };

        // Details Panel Title
        class DetailsTitle: RscText {
            idc = -1;
            text = "Details Panel";
            font = "RobotoCondensedBold";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.5)";
            x = D_X + (D_W * 0.6) + (PAD * 0.5) + PAD;
            y = D_Y + H_HEAD + H_BAR + (PAD * 2);
            w = (D_W * 0.4) - (PAD * 3);
            h = 0.04;
            colorText[] = {1,1,1,1};
            shadow = 0;
        };

        // Name Label
        class DetailsNameLabel: RscText {
            idc = -1;
            text = "Name";
            font = "RobotoCondensed";
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.9)";
            x = D_X + (D_W * 0.6) + (PAD * 0.5) + PAD;
            y = D_Y + H_HEAD + H_BAR + (PAD * 2) + 0.05;
            w = (D_W * 0.4) - (PAD * 3);
            h = 0.025;
            colorText[] = {0.6,0.6,0.6,1};
            shadow = 0;
        };

        // Name Edit Input (Rename here)
        class DetailsNameEdit: RscEdit {
            idc = 106;
            x = D_X + (D_W * 0.6) + (PAD * 0.5) + PAD;
            y = D_Y + H_HEAD + H_BAR + (PAD * 2) + 0.08;
            w = (D_W * 0.4) - (PAD * 3);
            h = 0.035;
            colorBackground[] = {0.1, 0.1, 0.1, 0.5};
            colorText[] = {1,1,1,1};
            colorBorder[] = {1,1,1,0.1};
            shadow = 0;
            sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
            onKeyDown = "params ['_ctrl', '_key']; if (_key in [28, 156]) then { [ctrlParent _ctrl] call TBD_fnc_CommitDetailRename; true } else { false };";
            tooltip = "Edit name and press Enter to Rename";
        };
        
        // Info Text (Date, Size, Author etc)
        class DetailsGroup: RscStructuredText {
            idc = 105;
            x = D_X + (D_W * 0.6) + (PAD * 0.5) + PAD;
            y = D_Y + H_HEAD + H_BAR + (PAD * 2) + 0.13;
            w = (D_W * 0.4) - (PAD * 3);
            h = D_H - H_HEAD - H_BAR - H_FOOT - (PAD * 4) - 0.13; // Remaining height
            colorBackground[] = {0,0,0,0};
            text = "";
        };

        // --- FOOTER ---
        // Label: "Composition Name:"
        class LabelName: RscText {
            idc = -1;
            text = "Composition Name:";
            x = D_X + PAD;
            y = D_Y + D_H - H_FOOT + (H_FOOT - 0.04)/2;
            w = 0.12 * safezoneW;
            h = 0.04;
            colorText[] = {0.8, 0.8, 0.8, 1};
            sizeEx = 0.035;
            shadow = 0;
            style = ST_RIGHT + ST_VCENTER; // Align right to text input
        };

        // Input: [Name Field]
        class InputName: RscEdit {
            idc = 104;
            x = D_X + PAD + (0.12 * safezoneW); 
            y = D_Y + D_H - H_FOOT + (H_FOOT - 0.04)/2;
            w = (D_W * 0.6) - (PAD * 2) - (0.12 * safezoneW); 
            h = 0.04;
            colorBackground[] = {0.1, 0.1, 0.1, 0.8};
            colorText[] = {1, 1, 1, 1};
            sizeEx = 0.035;
            shadow = 0;
            tooltip = "Enter name here";
            onKeyDown = "params ['_ctrl', '_key']; if (_key in [28, 156]) then { [ctrlParent _ctrl] call TBD_fnc_SaveGroup; true } else { false };";
        };
        
        // Box: Save (Green)
        class SaveVisual: RscStructuredText {
            idc = -1;
            x = D_X + D_W - (0.22 * safezoneW) - PAD;
            y = D_Y + D_H - H_FOOT + (H_FOOT - 0.04)/2;
            w = 0.12 * safezoneW; h = 0.04;
            colorBackground[] = {0.05, 0.05, 0.05, 1}; // Dark background
            text = "<t align='center' valign='middle' shadow='0'><img image='\a3\ui_f\data\gui\Rsc\RscDisplayArcadeMap\icon_save_ca.paa' size='1.0' /> SAVE</t>";
        };

        class BtnSave: RscButton {
            idc = 302;
            text = "";
            x = D_X + D_W - (0.22 * safezoneW) - PAD;
            y = D_Y + D_H - H_FOOT + (H_FOOT - 0.04)/2;
            w = 0.12 * safezoneW; h = 0.04;
            colorBackground[] = {0,0,0,0};
            colorBackgroundActive[] = {0.4, 0.6, 0.2, 0.1}; // Olive tint hover
            colorText[] = {0,0,0,0};
            colorBorder[] = {0.4, 0.6, 0.2, 1}; // Olive Green border
            shadow = 0;
            tooltip = "Save Composition";
            onButtonClick = "[ctrlParent (_this select 0)] call TBD_fnc_SaveGroup;";
        };

        class LoadVisual: RscStructuredText {
            idc = -1;
            x = D_X + D_W - (0.10 * safezoneW);
            y = D_Y + D_H - H_FOOT + (H_FOOT - 0.04)/2;
            w = 0.10 * safezoneW; h = 0.04;
            colorBackground[] = {0.05, 0.05, 0.05, 1}; // Dark background
            text = "<t align='center' valign='middle' shadow='0'><img image='\a3\3DEN\Data\Displays\Display3DEN\ToolBar\open_ca.paa' size='1.0' /> LOAD</t>";
        };

        class BtnLoad: RscButton {
            idc = 301;
            text = "";
            x = D_X + D_W - (0.10 * safezoneW);
            y = D_Y + D_H - H_FOOT + (H_FOOT - 0.04)/2;
            w = 0.10 * safezoneW; h = 0.04;
            colorBackground[] = {0,0,0,0};
            colorBackgroundActive[] = {0.3, 0.5, 0.7, 0.1}; // Blue tint hover
            colorText[] = {0,0,0,0};
            colorBorder[] = {0.3, 0.5, 0.7, 1}; // Steel Blue border
            shadow = 0;
            tooltip = "Load Composition";
            onButtonClick = "[ctrlParent (_this select 0)] call TBD_fnc_LoadGroup;";
        };
    };
};
