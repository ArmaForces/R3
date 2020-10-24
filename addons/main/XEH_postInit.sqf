#include "script_component.hpp"

if !(isServer) exitWith { ERROR_WITH_TITLE("AAR - ERROR", "Addon must be run server side only!"); };

if (getNumber (missionConfigFile >> "aar_disabled") != 0) exitWith {
    ERROR_SYSTEM_CHAT("The AAR tool (R3) is disabled in this mission, no replay will be recorded");
};

/*
  Setup database and don't continue if it fails.
  Moved this to spawn and event handlers as it occasionally crashed the game
  while waiting for db to respond
*/
[] spawn FUNC(dbInit);

// Wait until our database is created before inserting new replay entry
["dbSetup", {

    [] spawn FUNC(dbCreateReplayEntry);

}] call CBA_fnc_addEventHandler;

// Capture when dbCreateReplayEntry has finished
["replaySetup", {

    // Start event saving buffer
    call FUNC(trackLoop);

    call FUNC(addMissionEventHandlers);

}] call CBA_fnc_addEventHandler;
