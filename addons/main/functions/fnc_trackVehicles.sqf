/*
 * Author: Titan
 * Loops through all vehicles on the map and saves to db event buffer
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air"] call FUNC(trackVehicles);
 *
 * Public: No
 */

#include "script_component.hpp"
private _functionLogName = "AAR > trackVehicles";

// We have a string length limit with our database extension so we need to break up
// large amounts of units into multiple calls
private _unitCount = 0;
private _movementData = "";

// Loop through all vehicles on the map
{
    private _doNotTrack = _x getVariable ["r3_do_not_track", false];

    if !(_doNotTrack) then {

        [_x] call FUNC(addVehicleEventHandlers);

        // Is there anyone inside the vehicle? We don't want to track empty vehicles
        if (count crew _x > 0) then {

            private _vehicleUid = getPlayerUID _x;
            private _vehiclePos = getPos _x;
            private _vehicleDirection = round getDir _x;
            private _vehicleClass = typeOf _x;

            // We want the iconpathname (without the .paa and without the full path) just the name of the icon
            private _vehicleIconPathRaw = getText (configFile >> "CfgVehicles" >> (typeOf _x) >> "icon");
            private _splitIconPath = _vehicleIconPathRaw splitString "\.";
            private _vehicleIconName = _vehicleIconPathRaw;

            if (count _splitIconPath > 2) then {
                _vehicleIconName = _splitIconPath select (count _splitIconPath - 2);
            };

            private _vehicleIcon = _x call FUNC(getVehicleIcon);

            private _vehicleFaction = _x call FUNC(calcSideInt);
            private _vehicleGroupId = groupID group _x;
            private _vehicleCrew = (
                _x call {
                    private _crew = [];
                    {
                        if(isPlayer _x) then {
                            if(_this getCargoIndex _x == -1) then {
                                _crew pushBack getPlayerUID _x;
                            };
                        };
                    } forEach crew _this;
                    _crew
                }
            );
            private _vehicleCargo = (
                _x call {
                    private _cargo = [];
                    {
                        if(isPlayer _x) then {
                            if(_this getCargoIndex _x >= 0) then {
                                _cargo pushBack getPlayerUID _x;
                            };
                        };
                    } forEach crew _this;
                    _cargo
                }
            );

            // Form JSON for saving
            // It sucks we have to use such abbreviated keys but we need to save as much space as pos!
            private _singleVehicleMovementData = format['
                {
                    "unit": "%1",
                    "id": "%2",
                    "pos": %3,
                    "dir": %4,
                    "cls": "%5",
                    "ico": "%6",
                    "icp": "%11",
                    "fac": "%7",
                    "grp": "%8",
                    "crw": %9,
                    "cgo": %10
                }',
                _x,
                _vehicleUid,
                _vehiclePos,
                _vehicleDirection,
                _vehicleClass,
                _vehicleIcon,
                _vehicleFaction,
                _vehicleGroupId,
                _vehicleCrew,
                _vehicleCargo,
                _vehicleIconName
            ];

            // We don't want leading commas in our JSON
            private _seperator = if (_movementData == "") then { "" } else { "," };

            // Combine this unit's data with our current running movements data
            _movementData = [_movementData, _singleVehicleMovementData] joinString _seperator;

            _unitCount = _unitCount + 1;

            // If we've reached our limit for the number of units in a single db entry lets flush and continue
            if (_unitCount == GVAR(maxUnitCountPerEvent)) then {

                // Save details to db
                private _movementDataJsonArray = format["[%1]", _movementData];
                ["positions_vehicles", _movementDataJsonArray] call FUNC(dbInsertEvent);

                _unitCount = 0;
                _movementData = "";
            };
        }; // count crew
    }; // do not track
} forEach vehicles;

// Send the json to our extension for saving to the db
if (_movementData != "") then {

    private _movementDataJsonArray = format["[%1]", _movementData];
    ["positions_vehicles", _movementDataJsonArray] call FUNC(dbInsertEvent);
};
