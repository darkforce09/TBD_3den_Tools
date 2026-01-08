/*
    File: fn_restoreObjects.sqf
    Author: Darkforce
    Description: Restores objects from a data array into the 3DEN Editor.
    Parameter(s):
        _soData (Array): The data array containing object info
        _layerName (String): Name of the filtered 3DEN layer
    Returns: None
*/

params ["_soData", "_layerName"];

if (isNil "_soData" || { !(_soData isEqualType []) }) exitWith { 
    systemChat localize "STR_CSO_Err_InvalidRestoration"; 
};

collect3DENHistory {
    private _rootLayerID = -1 add3DENLayer _layerName;
    private _scaleLayerMap = createHashMap; 
    private _subLayerMap = createHashMap;
    private _textureCache = createHashMap;
    private _restoredCount = 0;
    
    // Helper: Clean path (locally scoped for speed)
    private _fnc_cleanPath = { 
        params ["_p"]; 
        if (_p == "") exitWith { "" };
        if (":" in _p) then {
            private _parts = _p splitString "/\";
            _parts select (count _parts - 1)
        } else { _p };
    };
    
    {
        _x params ['_class', '_path', '_pos', '_dir', '_vec', '_tex', '_scale', '_align', '_super', '_local', '_rotAttr', '_mode', '_customProps'];
        
        // Safety checks and type conversion
        if (_pos isEqualType "") then { _pos = parseSimpleArray _pos; }; // Safer than call compile
        if (isNil "_scale") then { _scale = 1; };

        if (isNil "_mode" || {!(_mode isEqualType "")}) then { _mode = "Object"; };
        if (isNil "_customProps") then { _customProps = []; };
        
        // Safety: Ensure class is string
        if (isNil "_class") then { 
            _class = ""; 
        } else {
            if (!(_class isEqualType "")) then { _class = str _class; };
        };
        
        // Special Class Handling
        // Markers use class for shape/icon sometimes, or just empty?
        // create3DENEntity for marker: ["Marker", "mil_dot", pos]
        // serialization `typeOf` for marker returns marker class (e.g. "mill_dot")? NO, `typeOf` on 3DEN marker entity often returns "Marker".
        // Wait, if I used `typeOf` during serialization, it might be generic.
        // But for markers, the "markerType" attribute holds the visual class.
        // Let's rely on _customProps for visual class if needed.
        
        // Create Entity
        private _ent = objNull;
        
        if (_mode == "Marker") then {
            // Safety: If class is a number string (e.g. ID leaked into class), fallback
            if (_class regexMatch "^[0-9]+$") then { _class = "mil_dot"; };
            
            // Trust the saved class. create3DENEntity defaults to dot if invalid.
            _ent = create3DENEntity ["Marker", _class, [0,0,0]];
        } else {
             if (_mode == "Waypoint") then {
                 // Waypoint creation
                  _ent = create3DENEntity ["Waypoint", _class, [0,0,0]];
             } else {
                  _ent = create3DENEntity [_mode, _class, [0,0,0]];
             };
        };

        // Validate Validation
        private _failed = false;
        if (_mode == "Marker") then {
             if (_ent isEqualType "" && {_ent == ""}) then { _failed = true; };
             if (!(_ent isEqualType "")) then { _failed = true; }; // Should be string
        } else {
             if (isNull _ent) then { _failed = true; };
        };

        if (_failed) then {
            systemChat format [localize "STR_CSO_Warn_CreateClass", _class];
        } else {
            // Attributes
            
            // Set Position (Branching)
            // Markers/Waypoints interaction with setPosWorld is undefined or error.
            if (_mode == "Marker" || _mode == "Waypoint") then {
                 // Use 3DEN Attribute mainly
                 _ent set3DENAttribute ["position", _pos];
            } else {
                 _ent setPosWorld _pos;
                 _ent set3DENAttribute ["position", getPosATL _ent];
            };
            
            // Rotation
            if (!isNil "_rotAttr") then { 
                _ent set3DENAttribute ["rotation", _rotAttr]; 
            } else { 
                if (!(_mode in ["Marker", "Waypoint"])) then {
                    _ent setVectorDirAndUp _vec; 
                };
            };

            // --- Layer Management ---
            private _scaleLayerID = -1;
            private _targetScale = if (!isNil "_scale") then { _scale } else { 1 };
            
            if (_targetScale in _scaleLayerMap) then { _scaleLayerID = _scaleLayerMap get _targetScale; } 
            else {
                _scaleLayerID = _rootLayerID add3DENLayer format ["Scale: %1", _targetScale];
                _scaleLayerMap set [_targetScale, _scaleLayerID];
            };
            
            private _hasTexture = false;
            { if (_x != "") exitWith { _hasTexture = true; }; } forEach _tex;
            private _subName = if (_hasTexture) then { "Custom_Texture" } else { "No_Texture" };
            
            // Simplified sub-layering: Only split by texture if it's an Object or Logic
            private _finalLayerID = _scaleLayerID;
            
            if (_mode in ["Object", "Logic"]) then {
                private _subKey = format ["%1_%2", _scaleLayerID, _subName];
                if (_subKey in _subLayerMap) then { _finalLayerID = _subLayerMap get _subKey; }
                else {
                    _finalLayerID = _scaleLayerID add3DENLayer _subName;
                    _subLayerMap set [_subKey, _finalLayerID];
                };
            };
            
            _ent set3DENLayer _finalLayerID;
            
            // Apply Custom Props
            {
                _x params ["_attr", "_val"];
                if (!isNil "_val") then {
                     // Map keys to 3DEN attribute names
                     switch (_attr) do {
                         case "size3": { _ent set3DENAttribute ["size3", _val]; };
                         case "activation": { _ent set3DENAttribute ["activationBy", _val]; };
                         case "type": { 
                             if (_mode == "Trigger") then { _ent set3DENAttribute ["triggerType", _val]; };
                             if (_mode == "Marker") then { _ent set3DENAttribute ["markerType", _val]; };
                             if (_mode == "Waypoint") then { _ent set3DENAttribute ["waypointType", _val]; };
                         };
                         case "text": { _ent set3DENAttribute ["text", _val]; };
                         case "expActiv": { _ent set3DENAttribute ["onActivation", _val]; };
                         case "expDeactiv": { _ent set3DENAttribute ["onDeactivation", _val]; };
                         case "condition": { _ent set3DENAttribute ["condition", _val]; };
                         case "timeout": { _ent set3DENAttribute ["timeout", _val]; };
                         case "color": { _ent set3DENAttribute ["baseColor", _val]; };
                         case "brush": { _ent set3DENAttribute ["brush", _val]; };
                         case "alpha": { _ent set3DENAttribute ["alpha", _val]; };
                         case "speed": { _ent set3DENAttribute ["speed", _val]; };
                         case "behavior": { _ent set3DENAttribute ["behaviour", _val]; };
                         case "combat": { _ent set3DENAttribute ["combatMode", _val]; };
                         case "form": { _ent set3DENAttribute ["formation", _val]; };
                     };
                };
            } forEach _customProps;
            
            // Standard Object Logic (Texture/CSO) - Only for Objects
            if (_mode == "Object") then {
                // Apply Scale
                if (!isNil "_scale") then { 
                    _ent set3DENAttribute ["Scale", _scale]; 
                    _ent set3DENAttribute ["ENH_objectScaling", _scale]; 
                    _ent setObjectScale _scale;
                };
                
                // Apply Textures
                { 
                    if (_x != "") then {
                        private _p = "";
                        if (_x in _textureCache) then { _p = _textureCache get _x; }
                        else {
                            _p = [_x] call _fnc_cleanPath;
                            _textureCache set [_x, _p];
                        };
                        _ent setObjectTexture [_forEachIndex, _p]; 
                    }; 
                } forEach _tex;
                
                // CSO Attributes
                _ent set3DENAttribute ["CSObject", true]; 
                if (!isNil "_align") then { _ent set3DENAttribute ["CSO_Align", _align]; };
                if (!isNil "_super") then { _ent set3DENAttribute ["CSO_Super", _super]; };
                if (!isNil "_local") then { _ent set3DENAttribute ["CSO_Local", _local]; };
            };
            
            _restoredCount = _restoredCount + 1;
        };
    } forEach _soData;
    
    systemChat format [localize "STR_CSO_Success_Restored", _restoredCount, _layerName];
};
