/*
    File: fn_serializeObjects.sqf
    Author: Darkforce
    Description: Serializes 3DEN objects into a data array for storage or clipboard export.
    Parameter(s):
        _objects (Array): List of 3DEN entities to serialize
    Returns:
        (Array) List of serialized object data
*/

params ["_objects"];

// Helper: Clean file path (removes local drive letters)
private _fnc_cleanPath = { 
    params ["_p"]; 
    if (_p == "") exitWith { "" };
    if (":" in _p) then {
        private _parts = _p splitString "/\";
        _parts select (count _parts - 1) // Return just filename
    } else {
        _p
    };
};

// Helper: Format position
private _fnc_posToString = {
    params ["_pos"];
    format ["[%1,%2,%3]", _pos select 0 toFixed 4, _pos select 1 toFixed 4, _pos select 2 toFixed 4]
};

private _dataLines = [];
private _textureCache = createHashMap;

{
    private _obj = _x;
    
    // 5. Pack Data (Refactored for robustness)
    
    // 1. Detect Mode & Type Safety
    private _mode = "Object";
    private _isObject = false;

    if (_obj isEqualType objNull) then {
        _isObject = true;
        if (_obj isKindOf "Logic") then { _mode = "Logic"; };
        if (_obj isKindOf "EmptyDetector") then { _mode = "Trigger"; };
    } else {
        // Markers can be String (Name) or Number (ID)
        if (_obj isEqualType "" || _obj isEqualType 0) then { _mode = "Marker"; };
        if (_obj isEqualType []) then { _mode = "Waypoint"; };
    };
    
    // 2. Extract Common Attributes (Position, Rotation)
    private _pos = "[(0,0,0)]";
    private _dir = 0;
    private _vec = [[0,1,0],[0,0,1]];
    private _model = "";
    
    if (_isObject) then {
        _pos = [getPosWorld _obj] call _fnc_posToString;
        _dir = getDir _obj;
        _vec = [vectorDir _obj, vectorUp _obj];
        // Model Info - ONLY for true objects/logic/triggers (though triggers don't really have models, they are objects)
        // Check if we should get model
        if (_mode == "Object") then {
             private _modelInfo = getModelInfo _obj;
             if (count _modelInfo > 1) then { 
                 _model = _modelInfo select 1; 
                 if (_model != "" && {!(_model select [0,1] in ["\","/"])}) then { _model = "\" + _model; };
             };
        };
    } else {
        // Handle Non-Object Entities (Markers/Waypoints)
        // Use 3DEN Attributes for position if possible, otherwise skip or handle differently
        // Markers in 3DEN: _obj is the name? Or ID?
        // If it is a string name, we cannot use `getPosWorld`.
        // We rely on get3DENAttribute which takes the entity reference (which might be the string for markers).
        
        private _rawPos = (_obj get3DENAttribute "position") select 0;
        if (!isNil "_rawPos") then {
             // 3DEN Pos is ATL usually
             _pos = format ["[%1,%2,%3]", _rawPos select 0 toFixed 4, _rawPos select 1 toFixed 4, _rawPos select 2 toFixed 4];
        };
        
        // Rotation
        private _rawRot = (_obj get3DENAttribute "rotation") select 0;
        // Construct vector from rotation if needed, or just store rotation attr
        // We store _rotAttr later anyway.
    };
    
    // 3. Texture Info (Optimized caching) - Only for Objects/SimpleObjects
    private _tex = [];
    if (_mode == "Object") then {
        _tex = (getObjectTextures _obj) apply { 
            private _orig = _x;
            if (_orig == "") then { "" } else {
                if (_orig in _textureCache) then { _textureCache get _orig } 
                else {
                    private _clean = [_orig] call _fnc_cleanPath;
                    _textureCache set [_orig, _clean];
                    _clean
                }
            }
        };
    };
    
    // 4. Attributes
    private _align = false;
    private _super = false;
    private _local = true;
    private _scaleAttr = 1;
    private _rotAttr = (_obj get3DENAttribute "rotation") select 0;

    if (_mode == "Object") then {
        _align = (_obj get3DENAttribute "CSO_Align") select 0; if (isNil "_align") then { _align = false; };
        _super = (_obj get3DENAttribute "CSO_Super") select 0; if (isNil "_super") then { _super = false; };
        _local = (_obj get3DENAttribute "CSO_Local") select 0; if (isNil "_local") then { _local = true; };
        _scaleAttr = (_obj get3DENAttribute "Scale") select 0; 
        if (isNil "_scaleAttr") then { _scaleAttr = (_obj get3DENAttribute "ENH_objectScaling") select 0; };
        if (isNil "_scaleAttr") then { _scaleAttr = getObjectScale _obj; };
    };

    // 5. ATTRIBUTE COLLECTION (Custom Props)
    private _customProps = [];
    
    if (_mode == "Trigger") then {
        _customProps = [
            ["size3", (_obj get3DENAttribute "size3") select 0],
            ["activation", (_obj get3DENAttribute "activationBy") select 0],
            ["type", (_obj get3DENAttribute "triggerType") select 0],
            ["text", (_obj get3DENAttribute "text") select 0],
            ["expActiv", (_obj get3DENAttribute "onActivation") select 0],
            ["expDeactiv", (_obj get3DENAttribute "onDeactivation") select 0],
            ["condition", (_obj get3DENAttribute "condition") select 0],
            ["timeout", (_obj get3DENAttribute "timeout") select 0]
        ];
    };
    
    if (_mode == "Marker") then {
         _customProps = [
            ["text", (_obj get3DENAttribute "text") select 0],
            ["color", (_obj get3DENAttribute "baseColor") select 0],
            ["type", (_obj get3DENAttribute "markerType") select 0],
            ["shape", (_obj get3DENAttribute "markerShape") select 0],
            ["size", (_obj get3DENAttribute "size2") select 0],
            ["brush", (_obj get3DENAttribute "brush") select 0],
            ["alpha", (_obj get3DENAttribute "alpha") select 0]
         ];
    };
    
    if (_mode == "Waypoint") then {
         _customProps = [
            ["type", (_obj get3DENAttribute "waypointType") select 0],
            ["speed", (_obj get3DENAttribute "speed") select 0],
            ["behavior", (_obj get3DENAttribute "behaviour") select 0], // Note UK spelling in SQF attr
            ["combat", (_obj get3DENAttribute "combatMode") select 0],
            ["form", (_obj get3DENAttribute "formation") select 0]
         ];
    };
    
    // 6. Final Class Determination
    private _class = "";
    if (_isObject) then {
        _class = typeOf _obj;
    } else {
        if (_mode == "Marker") then {
            
            // STRATEGY 1: Check Icon Type (Mission Namespace)
            private _missionType = getMarkerType _obj;
            if (_missionType != "") then {
                 _class = _missionType;
            };
            
            // STRATEGY 2: 3DEN Attribute Lookup (Primary for Editor Objects)
            if (_class == "") then {
                 private _shapeAttr = (_obj get3DENAttribute "markerShape") select 0;
                 if (!isNil "_shapeAttr" && {_shapeAttr in ["RECTANGLE", "ELLIPSE"]}) then {
                    _class = _shapeAttr;
                 } else {
                     private _typeAttr = (_obj get3DENAttribute "markerType") select 0;
                     // Filter out empty or numeric-looking garbage strings if possible
                     if (!isNil "_typeAttr" && {_typeAttr isEqualType ""} && {_typeAttr != ""}) then {
                         _class = _typeAttr;
                     };
                 };
            };
            
            // STRATEGY 3: Robust Fallback (If _obj is an ID/String reference)
            if (_class == "") then {
                private _realEntity = objNull;
                
                // If it's a direct entity reference, it won't be a string/number usually, but SQF is loose.
                // If we are here, we might have lost the handle or it's a pure data object.
                // Try to find the entity by name or ID matching.
                
                private _refID = str _obj;
                private _allMarkers = (all3DENEntities select 5);
                
                {
                   private _mName = (_x get3DENAttribute "name") select 0;
                   if (!isNil "_mName" && {_mName == _obj}) exitWith { _realEntity = _x; };
                   if (str _x == _refID) exitWith { _realEntity = _x; };
                } forEach _allMarkers;
                
                if (!isNull _realEntity) then {
                     private _sType = (_realEntity get3DENAttribute "markerType") select 0;
                     if (!isNil "_sType" && {_sType != ""}) then { _class = _sType; }
                     else {
                         private _sShape = (_realEntity get3DENAttribute "markerShape") select 0;
                         if (!isNil "_sShape" && {_sShape in ["RECTANGLE", "ELLIPSE"]}) then { _class = _sShape; };
                     };
                };
            };
            
            // Final Safety
            if (isNil "_class" || {_class isEqualType 0} || {_class regexMatch "^[0-9]+$"} || {_class == ""}) then { _class = "mil_dot"; };
        };
        if (_mode == "Waypoint") then {
            // "Move" is a safe default class for waypoints if type is missing or handled by props
            _class = "Move"; 
            private _wt = (_obj get3DENAttribute "waypointType") select 0;
            if (!isNil "_wt") then { _class = _wt; };
        };
    };
    
    // Format: [Type, Model, PosString, Dir, VecDirUp, Textures, Scale, Align, Super, Local, RotationAttr, Mode, CustomProps]
    _dataLines pushBack [_class, _model, _pos, _dir, _vec, _tex, _scaleAttr, _align, _super, _local, _rotAttr, _mode, _customProps];
    
} foreach _objects;

_dataLines
