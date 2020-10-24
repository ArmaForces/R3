/*
 * Author: Titan
 * Setup unit event handlers
 *
 * Arguments:
 * 0: unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit] call FUNC(addInfantryEventHandlers);
 *
 * Public: No
 */

#include "script_component.hpp"
private _functionLogName = "AAR > addInfantryEventHandlers";

params [
    ["_unit", objNull]
];

if (_unit getVariable ["eventsSetup", false]) exitWith {};
_unit setVariable ["eventsSetup", true];

_unit addMPEventHandler ["MPHit", FUNC(eventHit)];
_unit addEventHandler ["IncomingMissile", FUNC(eventIncomingMissile)];

_unit addEventHandler ["Fired", FUNC(eventFired)];

[_unit] call FUNC(addInfantryACEEventHandlers);

nil
