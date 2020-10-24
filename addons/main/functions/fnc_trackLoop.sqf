/*
 * Author: Titan
 * Handle throttling of positional update logging
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(trackLoop);
 *
 * Public: No
 */

#include "script_component.hpp"
private _functionLogName = "AAR > trackLoop";

DBUG("Starting track loop", _functionLogName);

// Just log markers once (for now)
call FUNC(trackMarkers);

[{
    if (GVAR(logEvents)) then {
        GVAR(noPlayers) = playableUnits findIf {isPlayer _x} == -1;
        // We only want to log movements if there are players in the map
        if (GVAR(noPlayers)) exitWith {};

        call FUNC(trackInfantry);
        call FUNC(trackVehicles);
    };
}, 1] call CBA_fnc_addPerFrameHandler;
