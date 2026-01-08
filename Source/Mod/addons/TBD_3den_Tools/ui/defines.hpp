#ifndef TBD_DEFINES_HPP
#define TBD_DEFINES_HPP

// --- CONSTANTS ---
#define CT_STATIC           0
#define CT_BUTTON           1
#define CT_EDIT             2
#define CT_SLIDER           3
#define CT_COMBO            4
#define CT_LISTBOX          5
#define CT_TOOLBOX          6
#define CT_CHECKBOXES       7
#define CT_PROGRESS         8
#define CT_HTML             9
#define CT_STATIC_SKEW      10
#define CT_ACTIVETEXT       11
#define CT_TREE             12
#define CT_STRUCTURED_TEXT  13
#define CT_CONTEXT_MENU     14
#define CT_CONTROLS_GROUP   15
#define CT_SHORTCUTBUTTON   16
#define CT_HITEMBOX         17
#define CT_XKEYDESC         40
#define CT_XBUTTON          41
#define CT_XLISTBOX         42
#define CT_XSLIDER          43
#define CT_XCOMBO           44
#define CT_ANIMATED_TEXTURE 45
#define CT_MENU             46
#define CT_MENU_STRIP       47
#define CT_CHECKBOX         77
#define CT_OBJECT           80
#define CT_OBJECT_ZOOM      81
#define CT_OBJECT_CONTAINER 82
#define CT_OBJECT_CONT_ANIM 83
#define CT_LINEBREAK        98
#define CT_USER             99
#define CT_MAP              100
#define CT_MAP_MAIN         101
#define CT_LISTNBOX         102
#define CT_ITEMSLOT         103

// Static styles
#define ST_POS            0x0F
#define ST_HPOS           0x03
#define ST_VPOS           0x0C
#define ST_LEFT           0x00
#define ST_RIGHT          0x01
#define ST_CENTER         0x02
#define ST_DOWN           0x04
#define ST_UP             0x08
#define ST_VCENTER        0x0C

#define ST_TYPE           0xF0
#define ST_SINGLE         0x00
#define ST_MULTI          0x10
#define ST_TITLE_BAR      0x20
#define ST_PICTURE        0x30
#define ST_FRAME          0x40
#define ST_BACKGROUND     0x50
#define ST_GROUP_BOX      0x60
#define ST_GROUP_BOX2     0x70
#define ST_HUD_BACKGROUND 0x80
#define ST_TILE_PICTURE   0x90
#define ST_WITH_RECT      0xA0
#define ST_LINE           0xB0

#define ST_SHADOW         0x100
#define ST_NO_RECT        0x200
#define ST_KEEP_ASPECT_RATIO  0x800

// --- COLORS ---
// --- COLORS ---
#define COL_BG          {0.102, 0.122, 0.149, 1}    // #1a1f26 (Deep Slate Blue)
#define COL_BG_LIGHT    {0.141, 0.165, 0.2, 1}      // #242a33 (Lighter Blue/Slate for lists/inputs)
#define COL_PRIMARY     {0, 0.45, 0.85, 1}          // Primary Blue
#define COL_BTN_SAVE    {0.26, 0.63, 0.28, 1}       // #43a047 (Green)
#define COL_BTN_LOAD    {0.2, 0.46, 0.76, 1}        // #3376c2 (Blue)
#define COL_TEXT        {1, 1, 1, 1}                // White
#define COL_TEXT_SUB    {0.7, 0.7, 0.7, 1}          // Grey text

// --- FONTS ---
#define FONT_MAIN "RobotoCondensed"
#define FONT_LIGHT "RobotoCondensedLight"
#define FONT_BOLD "RobotoCondensedBold"

// --- BASE CLASSES ---
class RscText
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_STATIC;
    idc = -1;
    colorBackground[] = {0,0,0,0};
    colorText[] = COL_TEXT;
    text = "";
    fixedWidth = 0;
    x = 0;
    y = 0;
    h = 0.037;
    w = 0.3;
    style = ST_LEFT;
    shadow = 1;
    colorShadow[] = {0,0,0,0.5};
    font = FONT_MAIN;
    SizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    linespacing = 1;
    tooltipColorText[] = {1,1,1,1};
    tooltipColorBox[] = {1,1,1,1};
    tooltipColorShade[] = {0,0,0,0.65};
};

class RscStructuredText
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_STRUCTURED_TEXT;
    idc = -1;
    style = ST_LEFT;
    colorBackground[] = {0,0,0,0};
    x = 0;
    y = 0;
    h = 0.035;
    w = 0.1;
    text = "";
    size = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    colorText[] = {1,1,1,1};
    shadow = 1;
    class Attributes
    {
        font = FONT_MAIN;
        color = "#ffffff";
        align = "left";
        shadow = 1;
    };
};

class RscPicture
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_STATIC;
    idc = -1;
    style = ST_PICTURE;
    colorBackground[] = {0,0,0,0};
    colorText[] = {1,1,1,1};
    font = "TahomaB";
    sizeEx = 0;
    lineSpacing = 0;
    text = "";
    fixedWidth = 0;
    shadow = 0;
    x = 0;
    y = 0;
    w = 0.2;
    h = 0.15;
    tooltipColorText[] = {1,1,1,1};
    tooltipColorBox[] = {1,1,1,1};
    tooltipColorShade[] = {0,0,0,0.65};
};

class RscEdit
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_EDIT;
    x = 0;
    y = 0;
    h = 0.04;
    w = 0.2;
    colorBackground[] = {0,0,0,0};
    colorText[] = {0.95,0.95,0.95,1};
    colorDisabled[] = {1,1,1,0.25};
    colorSelection[] = COL_PRIMARY;
    autocomplete = "";
    text = "";
    size = 0.2;
    style = ST_FRAME;
    font = FONT_MAIN;
    shadow = 2;
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    canModify = 1;
    tooltipColorText[] = {1,1,1,1};
    tooltipColorBox[] = {1,1,1,1};
    tooltipColorShade[] = {0,0,0,0.65};
};

class RscTree
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_TREE;
    x = 0;
    y = 0;
    w = 0.1;
    h = 0.2;
    style = ST_LEFT;
    font = FONT_MAIN;
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    expandedTexture = "A3\ui_f\data\gui\rsccommon\rsctree\expandedTexture_ca.paa";
    hiddenTexture = "A3\ui_f\data\gui\rsccommon\rsctree\hiddenTexture_ca.paa";
    rowHeight = 0.0439091;
    color[] = {1,1,1,1};
    colorSelect[] = {1,1,1,0.7};
    colorBackground[] = {0,0,0,0};
    colorSelectBackground[] = {0,0,0,0.5};
    colorBorder[] = {0,0,0,0};
    borderSize = 0;
    
    colorText[] = {1,1,1,1};
    colorDisabled[] = {1,1,1,0.25};
    colorMarked[] = {0.2,0.3,0.7,1};
    colorMarkedSelected[] = {0,0.5,0.5,1};
    colorMarkedText[] = {0,0,0,1};
    colorMarkedSelectedText[] = {0,0,0,1};
    
    colorArrow[] = {1,1,1,1};

    class ScrollBar
    {
        color[] = {1,1,1,0.6};
        colorActive[] = {1,1,1,1};
        colorDisabled[] = {1,1,1,0.3};
        thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
        arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
        arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
        border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
        shadow = 0;
        scrollSpeed = 0.06;
        width = 0;
        height = 0;
        autoScrollEnabled = 0;
        autoScrollSpeed = -1;
        autoScrollDelay = 5;
        autoScrollRewind = 0;
    };
    
    shadow = 0;
    mcolor[] = {0,0,0,0}; // Legacy
};

class RscButton
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_BUTTON;
    text = "";
    colorText[] = {1,1,1,1};
    colorDisabled[] = {1,1,1,0.25};
    colorBackground[] = {0,0,0,0.5};
    colorBackgroundDisabled[] = {0,0,0,0.5};
    colorBackgroundActive[] = {0,0,0,1};
    colorFocused[] = {0,0,0,1};
    colorShadow[] = {0,0,0,0};
    colorBorder[] = {0,0,0,1};
    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter",0.09,1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush",0.09,1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick",0.09,1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape",0.09,1};
    style = ST_CENTER;
    x = 0;
    y = 0;
    w = 0.095589;
    h = 0.039216;
    shadow = 2;
    font = FONT_MAIN;
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0;
    offsetPressedY = 0;
    borderSize = 0;
};

class RscActiveText
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = CT_ACTIVETEXT;
    style = ST_CENTER;
    x = 0;
    y = 0;
    h = 0.035;
    w = 0.035;
    font = FONT_MAIN;
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    color[] = {1, 1, 1, 1};
    colorActive[] = {1, 0.2, 0.2, 1};
    colorDisabled[] = {1, 1, 1, 0.25};
    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter",0.09,1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush",0.09,1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick",0.09,1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape",0.09,1};
    action = "";
    text = "";
    default = 0;
    tooltipColorText[] = {1,1,1,1};
    tooltipColorBox[] = {1,1,1,1};
    tooltipColorShade[] = {0,0,0,0.65};
};

class RscActivePicture: RscActiveText
{
    style = ST_PICTURE + ST_KEEP_ASPECT_RATIO;
    color[] = {1, 1, 1, 0.5};
    colorActive[] = {1, 1, 1, 1};
};
class RscShortcutButton
{
    deletable = 0;
    fade = 0;
    type = CT_SHORTCUTBUTTON;
    x = 0;
    y = 0;
    style = ST_LEFT;
    default = 0;
    shadow = 1;
    w = 0.183825;
    h = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    color[] = {1,1,1,1.0};
    colorFocused[] = {1,1,1,1.0};
    color2[] = {0.95,0.95,0.95,1};
    colorDisabled[] = {1,1,1,0.25};
    colorBackground[] = {((111/255)/4096),((113/255)/4096),((122/255)/4096),1}; // A3 Green (default)
    colorBackgroundFocused[] = {((111/255)/4096),((113/255)/4096),((122/255)/4096),1};
    colorBackground2[] = {1,1,1,1};
    animTextureDefault = "\A3\ui_f\data\GUI\RscCommon\RscShortcutButton\normal_ca.paa";
    animTextureNormal = "\A3\ui_f\data\GUI\RscCommon\RscShortcutButton\normal_ca.paa";
    animTextureDisabled = "\A3\ui_f\data\GUI\RscCommon\RscShortcutButton\normal_ca.paa";
    animTextureOver = "\A3\ui_f\data\GUI\RscCommon\RscShortcutButton\over_ca.paa";
    animTextureFocused = "\A3\ui_f\data\GUI\RscCommon\RscShortcutButton\focus_ca.paa";
    animTexturePressed = "\A3\ui_f\data\GUI\RscCommon\RscShortcutButton\down_ca.paa";
    period = 0.4;
    font = FONT_MAIN;
    size = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    text = "";
    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter",0.09,1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush",0.09,1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick",0.09,1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape",0.09,1};
    action = "";
    class Attributes
    {
        font = FONT_MAIN;
        color = "#E5E5E5";
        align = "left";
        shadow = "true";
    };
    class AttributesImage
    {
        font = FONT_MAIN;
        color = "#E5E5E5";
        align = "left";
    };
};

#endif
