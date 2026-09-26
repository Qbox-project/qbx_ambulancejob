# qbx_ambulancejob
EMS job for Qbox. Health, injuries, bleeding, last stand and death are handled by [qbx_medical](https://github.com/Qbox-project/qbx_medical); this resource adds the EMS job, hospitals and medical items on top of it.

## Dependencies
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [qbx_medical](https://github.com/Qbox-project/qbx_medical)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target) - only when `useTarget` is enabled
- [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking) - default target for hospital bill payments, see `depositSociety` in `config/server.lua`

The default Pillbox locations in `config/shared.lua` need a Pillbox Hill Medical Center interior (MLO). The default Qbox txAdmin recipe installs one; if you use another map, adjust the locations to match it.

## Features
- Duty toggle, job vehicles and helicopters per grade, armory, personal stash and elevators
- Hospital check-in, billed `checkInCost`, with automatic treatment while fewer than `minForCheckIn` EMS are on duty; otherwise on-duty EMS are paged
- Hospital beds that players can lie in and that EMS can put patients in (target only)
- Respawning puts the player in a free bed at the closest hospital (the jail hospital for inmates), bills `checkInCost` and can clear their inventory
- EMS alerts when a player goes down, when a downed player requests help and through `/911e`

## Commands
- `/911e [message]` - Alert on-duty EMS
- `/status` - (EMS) Check the injuries of the closest player
- `/heal` - (EMS) Treat the wounds of the closest player, uses a `bandage`
- `/revivep` - (EMS) Revive the closest player, uses a `firstaid`

Admin commands (`/revive`, `/aheal`, `/kill`) are provided by qbx_medical.

## Items
These items must be defined in ox_inventory.
- `bandage` - Restores a little health and may reduce bleeding
- `painkillers` - Suppresses injury effects for `painkillerInterval` seconds per dose, up to 3 doses
- `ifaks` - Restores a little health, relieves stress, suppresses injury effects and may reduce bleeding
- `firstaid` - Lets EMS revive a nearby player in last stand

## Configuration
- `config/client.lua` - interaction mode (`useTarget`), timers, job vehicles and their extras/liveries
- `config/shared.lua` - `checkInCost`, `minForCheckIn` and all locations: hospitals and beds, duty, garages, armory, stash, elevators and map blips
- `config/server.lua` - doctor page cooldown, inventory wipe on respawn and the society payment function

With `useTarget = false`, interactions use ox_lib zones and text UI. Job vehicle garages always use zones.

## Exports and events
- Server export `CheckIn(src, patientSrc, hospitalName)` - puts a player in a free bed at the given hospital, bills them and starts treatment. Returns `true` on success.
- Client event `qbx_ambulancejob:client:checkIn` (`hospitalName`) - starts the regular check-in for the local player, who must be at one of that hospital's check-in points.
