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

function SetLaststand(bool)
    if bool then
        Wait(1000)

        while GetEntitySpeed(cache.ped) > 0.5 or IsPedRagdoll(cache.ped) do
            Wait(10)
        end

        local pos = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)

        TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)

        LaststandTime = Laststand.ReviveInterval

        if IsPedInAnyVehicle(cache.ped) then
            local veh = GetVehiclePedIsIn(cache.ped)
            local vehseats = GetVehicleModelNumberOfSeats(joaat(GetEntityModel(veh)))

            for i = -1, vehseats do
                local occupant = GetPedInVehicleSeat(veh, i)

                if occupant == cache.ped then
                    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z + 0.5, heading, true, false)
                    SetPedIntoVehicle(cache.ped, veh, i)
                end
            end
        else
            NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z + 0.5, heading, true, false)
        end

        SetEntityHealth(cache.ped, 150)

        if IsPedInAnyVehicle(cache.ped, false) then
            lib.requestAnimDict("veh@low@front_ps@idle_duck")

            TaskPlayAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 8.0, -1, 1, -1, false, false, false)
            RemoveAnimDict("veh@low@front_ps@idle_duck")
        else
            lib.requestAnimDict(lastStandDict)

            TaskPlayAnim(cache.ped, lastStandDict, lastStandAnim, 1.0, 8.0, -1, 1, -1, false, false, false)
            RemoveAnimDict(lastStandDict)
        end

        InLaststand = true

        TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))

        CreateThread(function()
            while InLaststand do
                if LaststandTime - 1 > Laststand.MinimumRevive then
                    LaststandTime = LaststandTime - 1
                    Config.DeathTime = LaststandTime
                elseif LaststandTime - 1 <= Laststand.MinimumRevive and LaststandTime - 1 ~= 0 then
                    LaststandTime = LaststandTime - 1
                    Config.DeathTime = LaststandTime
                elseif LaststandTime - 1 <= 0 then
                    lib.notify({
                        description = Lang:t('error.bled_out'),
                        type = 'error'
                    })

                    SetLaststand(false)

                    local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(cache.playerId)
                    local killer = GetPedSourceOfDeath(cache.ped)

                    if killer_2 ~= 0 and killer_2 ~= -1 then
                        killer = killer_2
                    end

                    local killerId = NetworkGetPlayerIndexFromPed(killer)
                    local killerName = killerId ~= -1 and GetPlayerName(killerId) .. " " .. "(" .. GetPlayerServerId(killerId) .. ")" or Lang:t('info.self_death')
                    local weaponLabel = Lang:t('info.wep_unknown')
                    local weaponName = Lang:t('info.wep_unknown')
                    local weaponItem = QBCore.Shared.Weapons[killerWeapon]

                    if weaponItem then
                        weaponLabel = weaponItem.label
                        weaponName = weaponItem.name
                    end

                    TriggerServerEvent("qb-log:server:CreateLog", "death", Lang:t('logs.death_log_title', { playername = GetPlayerName(cache.playerId), playerid = GetPlayerServerId(cache.playerId) }), "red", Lang:t('logs.death_log_message', { killername = killerName, playername = GetPlayerName(cache.playerId), weaponlabel = weaponLabel, weaponname = weaponName }))

                    deathTime = 0

                    OnDeath()
                    DeathTimer()
                end

                Wait(1000)
            end
        end)
    else
        lib.requestAnimDict(lastStandDict)

        TaskPlayAnim(ped, lastStandDict, "exit", 1.0, 8.0, -1, 1, -1, false, false, false)
        RemoveAnimDict(lastStandDict)

        InLaststand = false
        LaststandTime = 0
    end

    TriggerServerEvent("hospital:server:SetLaststandStatus", bool)
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
        lib.notify({
            description = Lang:t('error.impossible'),
            type = 'error'
        })
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
    if lib.progressBar({
        duration = math.random(30000, 60000),
        position = 'bottom',
        label = Lang:t('progress.revive'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false
        },
        anim = {
            dict = healAnimDict,
            clip = healAnim
        }
    }) then
        ClearPedTasks(cache.ped)

        lib.notify({
            description = Lang:t('success.revived'),
            type = 'success'
        })

        TriggerServerEvent("hospital:server:RevivePlayer", targetId)
    else
        ClearPedTasks(cache.ped)

        lib.notify({
            description = Lang:t('error.canceled'),
            type = 'error'
        })
    end
end)
