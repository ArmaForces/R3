/*
 * Author: Titan
 * Loops through all infantry units on the map and saves to db event buffer
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(trackInfantry);
 *
 * Public: No
 */

#include "script_component.hpp"
private _functionLogName = "AAR > movementsInfantry";

// We have a string length limit with our database extension so we need to break up
// large amounts of units into multiple calls
private _unitCount = 0;
private _movementData = "";

// Loop through all units on the map
{
    private _doNotTrack = _x getVariable ["r3_do_not_track", false];

    if (_x in _x && {!_doNotTrack}) then {
        private _unitUid = getPlayerUID _x;
        private _unitPos = getPos _x;
        private _unitDirection = round getDir _x;
        private _unitIconRaw = getText (configOf _x >> "icon");
        private _unitIcon = _unitIconRaw splitString "\" joinString "";
        private _unitFaction = _x call FUNC(calcSideInt);
        private _unitGroupId = groupID group _x;
        private _unitIsLeader = leader group _x isEqualTo _x;

        // Save player to db
        [_unitUid, name _x] spawn FUNC(dbSavePlayer);

        // Form JSON for saving
        // It sucks we have to use such abbreviated keys but we need to save as much space as pos!
        private _singleUnitMovementData = format['
            {
                "unit": "%1",
                "id": "%2",
                "pos": %3,
                "dir": %4,
                "ico": "%5",
                "fac": "%6",
                "grp": "%7",
                "ldr": "%8"
            }',
            _x,
            _unitUid,
            _unitPos,
            _unitDirection,
            _unitIcon,
            _unitFaction,
            _unitGroupId,
            _unitIsLeader
        ];

        // We don't want leading commas in our JSON
        private _seperator = if (_movementData == "") then { "" } else { "," };

        // Combine this unit's data with our current running movements data
        _movementData = [_movementData, _singleUnitMovementData] joinString _seperator;

        _unitCount = _unitCount + 1;

        // If we've reached our limit for the number of units in a single db entry lets flush and continue
        if (_unitCount == GVAR(maxUnitCountPerEvent)) then {

            // Save details to db
            private _movementDataJsonArray = format["[%1]", _movementData];
            ["positions_infantry", _movementDataJsonArray] call FUNC(dbInsertEvent);

            _unitCount = 0;
            _movementData = "";
        };
    };
} forEach allUnits;

// Send the json to our extension for saving to the db
if (_movementData != "") then {

    private _movementDataJsonArray = format["[%1]", _movementData];
    ["positions_infantry", _movementDataJsonArray] call FUNC(dbInsertEvent);
};
