local deadAnimDict = "dead"
local deadAnim = "dead_a"
local hold = 5
deathTime = 0

-- Functions
local function IsEmsOnDuty()
    QBCore.Functions.TriggerCallback('hospital:GetDoctors', function(medics)
        return medics > 0
    end)
end

function OnDeath()
    if not isDead then
        isDead = true

        TriggerServerEvent("hospital:server:SetDeathStatus", true)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)

        while GetEntitySpeed(cache.ped) > 0.5 or IsPedRagdoll(cache.ped) do
            Wait(10)
        end

        if isDead then
            local pos = GetEntityCoords(cache.ped)
            local heading = GetEntityHeading(cache.ped)

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

            SetEntityInvincible(cache.ped, true)
            SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))

            if cache.vehicle then
                lib.requestAnimDict("veh@low@front_ps@idle_duck")

                TaskPlayAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
                RemoveAnimDict("veh@low@front_ps@idle_duck")
            else
                lib.requestAnimDict(deadAnimDict)

                TaskPlayAnim(cache.ped, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
                RemoveAnimDict(deadAnimDict)
            end

            TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_died'))
        end
    end
end

function DeathTimer()
    hold = 5

    while isDead do
        Wait(1000)

        deathTime = deathTime - 1

        if deathTime <= 0 then
            if IsControlPressed(0, 38) and hold <= 0 and not isInHospitalBed then
                TriggerEvent("hospital:client:RespawnAtHospital")

                hold = 5
            end

            if IsControlPressed(0, 38) then
                if hold - 1 >= 0 then
                    hold = hold - 1
                else
                    hold = 0
                end
            end

            if IsControlReleased(0, 38) then
                hold = 5
            end
        end
    end
end

local function DrawTxt(x, y, width, height, scale, text, r, g, b, a, _)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x - width / 2, y - height / 2 + 0.005)
end

-- Damage Handler
AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]

        if not IsEntityAPed(victim) then return end

        if victimDied and NetworkGetPlayerIndexFromPed(victim) == cache.playerId and IsEntityDead(cache.ped) then
            if not InLaststand then
                SetLaststand(true)
            elseif InLaststand and not isDead then
                SetLaststand(false)

                local playerid = NetworkGetPlayerIndexFromPed(victim)
                local playerName = GetPlayerName(playerid) .. " " .. "(" .. cache.serverId .. ")" or Lang:t('info.self_death')
                local killerId = NetworkGetPlayerIndexFromPed(attacker)
                local killerName = GetPlayerName(killerId) .. " " .. "(" .. GetPlayerServerId(killerId) .. ")" or Lang:t('info.self_death')
                local weaponLabel = QBCore.Shared.Weapons[weapon].label or 'Unknown'
                local weaponName = QBCore.Shared.Weapons[weapon].name or 'Unknown'
                
                TriggerServerEvent("qb-log:server:CreateLog", "death", Lang:t('logs.death_log_title', { playername = playerName, playerid = cache.serverId }), "red", Lang:t('logs.death_log_message', { killername = killerName, playername = playerName, weaponlabel = weaponLabel, weaponname = weaponName }))
                
                deathTime = Config.DeathTime

                OnDeath()
                DeathTimer()
            end
        end
    end
end)

-- Threads
emsNotified = false

CreateThread(function()
    while true do
        local sleep = 1000

        if isDead or InLaststand then
            sleep = 5

            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 38, true)
            EnableControlAction(0, 0, true)
            EnableControlAction(0, 322, true)
            EnableControlAction(0, 288, true)
            EnableControlAction(0, 213, true)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 46, true)
            EnableControlAction(0, 47, true)

            if isDead then
                if not isInHospitalBed then
                    if deathTime > 0 and IsEmsOnDuty() then
                        DrawTxt(0.93, 1.44, 1.0, 1.0, 0.6, Lang:t('info.respawn_txt', { deathtime = math.ceil(deathTime) }), 255, 255, 255, 255)
                    else
                        DrawTxt(0.865, 1.44, 1.0, 1.0, 0.6, Lang:t('info.respawn_revive', { holdtime = hold, cost = Config.BillCost }), 255, 255, 255, 255)
                    end
                end

                if cache.vehicle then
                    if not IsEntityPlayingAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                        lib.requestAnimDict("veh@low@front_ps@idle_duck")

                        TaskPlayAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
                        RemoveAnimDict("veh@low@front_ps@idle_duck")
                    end
                else
                    if isInHospitalBed then
                        if not IsEntityPlayingAnim(cache.ped, inBedDict, inBedAnim, 3) then
                            lib.requestAnimDict(inBedDict)

                            TaskPlayAnim(cache.ped, inBedDict, inBedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
                            RemoveAnimDict(inBedDict)
                        end
                    else
                        if not IsEntityPlayingAnim(cache.ped, deadAnimDict, deadAnim, 3) then
                            lib.requestAnimDict(deadAnimDict)

                            TaskPlayAnim(cache.ped, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
                            RemoveAnimDict(deadAnimDict)
                        end
                    end
                end

                SetCurrentPedWeapon(cache.ped, joaat('WEAPON_UNARMED'), true)
            elseif InLaststand then
                sleep = 5

                if LaststandTime > Laststand.MinimumRevive then
                    DrawTxt(0.94, 1.44, 1.0, 1.0, 0.6, Lang:t('info.bleed_out', {
                        time = math.ceil(LaststandTime)
                    }), 255, 255, 255, 255)
                else
                    DrawTxt(0.845, 1.44, 1.0, 1.0, 0.6, Lang:t('info.bleed_out_help', {
                        time = math.ceil(LaststandTime)
                    }), 255, 255, 255, 255)

                    if not emsNotified then
                        DrawTxt(0.91, 1.40, 1.0, 1.0, 0.6, Lang:t('info.request_help'), 255, 255, 255, 255)
                    else
                        DrawTxt(0.90, 1.40, 1.0, 1.0, 0.6, Lang:t('info.help_requested'), 255, 255, 255, 255)
                    end

                    if IsControlJustPressed(0, 47) and not emsNotified and IsEmsOnDuty() then
                        TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))

                        emsNotified = true
                    end
                end

                if not isEscorted then
                    if cache.vehicle then
                        if not IsEntityPlayingAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                            lib.requestAnimDict("veh@low@front_ps@idle_duck")

                            TaskPlayAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
                            RemoveAnimDict("veh@low@front_ps@idle_duck")
                        end
                    else
                        if not IsEntityPlayingAnim(cache.ped, lastStandDict, lastStandAnim, 3) then
                            lib.requestAnimDict(lastStandDict)

                            TaskPlayAnim(cache.ped, lastStandDict, lastStandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
                            RemoveAnimDict(lastStandDict)
                        end
                    end
                else
                    if cache.vehicle then
                        if IsEntityPlayingAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                            lib.requestAnimDict("veh@low@front_ps@idle_duck")

                            StopAnimTask(cache.ped, "veh@low@front_ps@idle_duck", "sit", 3)
                            RemoveAnimDict("veh@low@front_ps@idle_duck")
                        end
                    else
                        if IsEntityPlayingAnim(cache.ped, lastStandDict, lastStandAnim, 3) then
                            lib.requestAnimDict(lastStandDict)

                            StopAnimTask(cache.ped, lastStandDict, lastStandAnim, 3)
                            RemoveAnimDict(lastStandDict)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)