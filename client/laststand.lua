Laststand = Laststand or {}
Laststand.ReviveInterval = 360
Laststand.MinimumRevive = 300
InLaststand = false
LaststandTime = 0
lastStandDict = "combat@damage@writhe"
lastStandAnim = "writhe_loop"
isEscorted = false
local isEscorting = false

-- Functions
local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(cache.ped)

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= cache.playerId then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

function WaitForPedToStopMoving(ped)
    while GetEntitySpeed(ped) > 0.5 or IsPedRagdoll(ped) do Wait(10) end
end

function ResurrectPlayer(ped)
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = cache.vehicle
    local seat = cache.seat

    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z + 0.5, heading, true, false)
    if veh then
        SetPedIntoVehicle(ped, veh, seat)
    end
end

local function playLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 8.0, -1, 1, -1, false, false, false)
    else
        lib.requestAnimDict(lastStandDict)
        TaskPlayAnim(ped, lastStandDict, lastStandAnim, 1.0, 8.0, -1, 1, -1, false, false, false)
    end
end

local function logPlayerKiller()
    local ped = cache.ped
    local player = cache.playerId
    local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(player)
    local killer = GetPedSourceOfDeath(ped)
    if killer_2 ~= 0 and killer_2 ~= -1 then killer = killer_2 end
    local killerId = NetworkGetPlayerIndexFromPed(killer)
    local killerName = killerId ~= -1 and GetPlayerName(killerId) .. " " .. "(" .. GetPlayerServerId(killerId) .. ")" or Lang:t('info.self_death')
    local weaponLabel = Lang:t('info.wep_unknown')
    local weaponName = Lang:t('info.wep_unknown')
    local weaponItem = QBCore.Shared.Weapons[killerWeapon]
    if weaponItem then
        weaponLabel = weaponItem.label
        weaponName = weaponItem.name
    end
    TriggerServerEvent("qb-log:server:CreateLog", "death", Lang:t('logs.death_log_title', { playername = GetPlayerName(cache.playerId), playerid = GetPlayerServerId(player) }), "red", Lang:t('logs.death_log_message', { killername = killerName, playername = GetPlayerName(player), weaponlabel = weaponLabel, weaponname = weaponName }))
end

local function countdownLastStand()
    if LaststandTime - 1 > 0 then
        LaststandTime -= 1
        Config.DeathTime = LaststandTime
    else
        lib.notify({ description = Lang:t('error.bled_out'), type = 'error' })
        endLastStand()
        logPlayerKiller()
        deathTime = 0
        OnDeath()
        DeathTimer()
    end
    Wait(1000)
end

function startLastStand()
    local ped = cache.ped
    Wait(1000)
    WaitForPedToStopMoving(ped)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
    LaststandTime = Laststand.ReviveInterval
    ResurrectPlayer(ped)
    SetEntityHealth(ped, 150)
    playLastStandAnimation(ped)
    InLaststand = true
    TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
    CreateThread(function()
        while InLaststand do
            countdownLastStand()
        end
    end)
    TriggerServerEvent("hospital:server:SetLaststandStatus", true)
end

function endLastStand()
    local ped = cache.ped
    TaskPlayAnim(ped, lastStandDict, "exit", 1.0, 8.0, -1, 1, -1, false, false, false)
    InLaststand = false
    LaststandTime = 0
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
end

-- Events

RegisterNetEvent('hospital:client:SetEscortingState', function(bool)
    isEscorting = bool
end)

RegisterNetEvent('hospital:client:isEscorted', function(bool)
    isEscorted = bool
end)

RegisterNetEvent('hospital:client:UseFirstAid', function()
    if not isEscorting then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 1.5 then
            local playerId = GetPlayerServerId(player)
            TriggerServerEvent('hospital:server:UseFirstAid', playerId)
        end
    else
        lib.notify({ description = Lang:t('error.impossible'), type = 'error' })
    end
end)

RegisterNetEvent('hospital:client:CanHelp', function(helperId)
    if InLaststand then
        if LaststandTime <= 300 then
            TriggerServerEvent('hospital:server:CanHelp', helperId, true)
        else
            TriggerServerEvent('hospital:server:CanHelp', helperId, false)
        end
    else
        TriggerServerEvent('hospital:server:CanHelp', helperId, false)
    end
end)

RegisterNetEvent('hospital:client:HelpPerson', function(targetId)
    local ped = cache.ped
    if lib.progressCircle({
        duration = math.random(30000, 60000),
        position = 'bottom',
        label = Lang:t('progress.revive'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = healAnimDict,
            clip = healAnim,
        },
    })
    then
        ClearPedTasks(ped)
        lib.notify({ description = Lang:t('success.revived'), type = 'success' })
        TriggerServerEvent("hospital:server:RevivePlayer", targetId)
    else
        ClearPedTasks(ped)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)
