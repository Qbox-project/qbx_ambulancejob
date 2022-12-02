local PlayerJob = {}
local onDuty = false
local currentGarage = 0
local currentHospital

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

function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations.vehicle[currentGarage]

    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)

        SetVehicleNumberPlateText(veh, Lang:t('info.amb_plate') .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        SetVehicleFuelLevel(veh, 100.0)
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)

        if Config.VehicleSettings[vehicleInfo] then
            QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
        end

        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))

        SetVehicleEngineOn(veh, true, true)
    end, vehicleInfo, coords, true)
end

function MenuGarage()
    local optionsMenu = {}
    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]

    for veh, label in pairs(authorizedVehicles) do
        optionsMenu[#optionsMenu + 1] = {
            title = label,
            event = "ambulance:client:TakeOutVehicle",
            args = {
                vehicle = veh
            }
        }
    end

    lib.registerContext({
        id = 'ambulance_garage_context_menu',
        title = Lang:t('menu.amb_vehicles'),
        options = optionsMenu
    })
    lib.showContext('ambulance_garage_context_menu')
end

-- Events
RegisterNetEvent('ambulance:client:TakeOutVehicle', function(data)
    local vehicle = data.vehicle

    TakeOutVehicle(vehicle)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo

    if PlayerJob.name == 'ambulance' then
        onDuty = PlayerJob.onduty

        if PlayerJob.onduty then
            TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
        else
            TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)

    CreateThread(function()
        Wait(1000)

        QBCore.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
            onDuty = PlayerData.job.onduty

            SetEntityHealth(cache.ped, PlayerData.metadata.health)
            SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)
            SetPlayerHealthRechargeLimit(cache.playerId, 0.0)
            SetPedArmour(cache.ped, PlayerData.metadata.armor)

            if not PlayerData.metadata.inlaststand and PlayerData.metadata.isdead then
                deathTime = Laststand.ReviveInterval

                OnDeath()
                DeathTimer()
            elseif PlayerData.metadata.inlaststand and not PlayerData.metadata.isdead then
                SetLaststand(true)
            else
                TriggerServerEvent("hospital:server:SetDeathStatus", false)
                TriggerServerEvent("hospital:server:SetLaststandStatus", false)
            end

            if PlayerJob.name == 'ambulance' and onDuty then
                TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
            end
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if PlayerJob.name == 'ambulance' and onDuty then
        TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if PlayerJob.name == 'ambulance' and duty ~= onDuty then
        if duty then
            TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
        else
            TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
        end
    end

    onDuty = duty
end)

function Status()
    if isStatusChecking then
        local statusMenu = {}

        for _, v in pairs(statusChecks) do
            statusMenu[#statusMenu + 1] = {
                title = v.label,
                event = "hospital:client:TreatWounds",
            }
        end

        lib.registerContext({
            id = 'ambulance_status_context_menu',
            title = Lang:t('menu.status'),
            options = statusMenu
        })
        lib.showContext('ambulance_status_context_menu')
    end
end

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()

    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)

        QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
            if result then
                for k, v in pairs(result) do
                    if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
                        statusChecks[#statusChecks + 1] = {
                            bone = Config.BoneIndexes[k],
                            label = v.label .. " (" .. Config.WoundStates[v.severity] .. ")"
                        }
                    elseif result["WEAPONWOUNDS"] then
                        for _, v2 in pairs(result["WEAPONWOUNDS"]) do
                            lib.notify({
                                title = Lang:t('info.status'),
                                description = QBCore.Shared.Weapons[v2].damagereason,
                                type = 'error'
                            })
                        end
                    elseif result["BLEED"] > 0 then
                        lib.notify({
                            title = Lang:t('info.status'),
                            description = Lang:t('info.is_status', {
                                status = Config.BleedingStates[v].label
                            }),
                            type = 'error'
                        })
                    else
                        lib.notify({
                            description = Lang:t('success.healthy_player'),
                            type = 'success'
                        })
                    end
                end

                isStatusChecking = true

                Status()
            end
        end, playerId)
    else
        lib.notify({
            description = Lang:t('error.no_player'),
            type = 'error'
        })
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local player, distance = GetClosestPlayer()

            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)

                if lib.progressBar({
                    duration = 5000,
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
                        clip = healAnim
                    }
                })
                then
                    StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)

                    lib.notify({
                        description = Lang:t('success.revived'),
                        type = 'success'
                    })

                    TriggerServerEvent("hospital:server:RevivePlayer", playerId)
                else
                    StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)

                    lib.notify({
                        description = Lang:t('error.canceled'),
                        type = 'error'
                    })
                end
            else
                lib.notify({
                    description = Lang:t('error.no_player'),
                    type = 'error'
                })
            end
        else
            lib.notify({
                description = Lang:t('error.no_firstaid'),
                type = 'error'
            })
        end
    end, 'firstaid')
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local player, distance = GetClosestPlayer()

            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)

                if lib.progressBar({
                    duration = 5000,
                    position = 'bottom',
                    label = Lang:t('progress.healing'),
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
                        clip = healAnim
                    }
                })
                then
                    StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)

                    lib.notify({
                        description = Lang:t('success.helped_player'),
                        type = 'success'
                    })

                    TriggerServerEvent("hospital:server:TreatWounds", playerId)
                else
                    StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)

                    lib.notify({
                        description = Lang:t('error.canceled'),
                        type = 'error'
                    })
                end
            else
                lib.notify({
                    description = Lang:t('error.no_player'),
                    type = 'error'
                })
            end
        else
            lib.notify({
                description = Lang:t('error.no_bandage'),
                type = 'error'
            })
        end
    end, 'bandage')
end)

local check = false

local function EMSControls(variable)
    CreateThread(function()
        check = true

        while check do
            if IsControlJustPressed(0, 38) then
                if variable == "sign" then
                    TriggerEvent('EMSToggle:Duty')
                elseif variable == "stash" then
                    TriggerEvent('qb-ambulancejob:stash')
                elseif variable == "armory" then
                    TriggerEvent('qb-ambulancejob:armory')
                elseif variable == "storeheli" then
                    TriggerEvent('qb-ambulancejob:storeheli')
                elseif variable == "takeheli" then
                    TriggerEvent('qb-ambulancejob:pullheli')
                elseif variable == "roof" then
                    TriggerEvent('qb-ambulancejob:elevator_main')
                elseif variable == "main" then
                    TriggerEvent('qb-ambulancejob:elevator_roof')
                end
            end

            Wait(0)
        end
    end)
end

RegisterNetEvent('qb-ambulancejob:stash', function()
    if onDuty then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
    end
end)

RegisterNetEvent('qb-ambulancejob:armory', function()
    if onDuty then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
    end
end)

local CheckVehicle = false

local function EMSVehicle(k)
    CheckVehicle = true

    CreateThread(function()
        while CheckVehicle do
            if IsControlJustPressed(0, 38) then
                CheckVehicle = false

                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(cache.ped))
                else
                    local currentVehicle = k

                    MenuGarage(currentVehicle)

                    currentGarage = currentVehicle
                end
            end

            Wait(0)
        end
    end)
end

local CheckHeli = false

local function EMSHelicopter(k)
    CheckHeli = true

    CreateThread(function()
        while CheckHeli do
            if IsControlJustPressed(0, 38) then
                CheckHeli = false

                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(cache.ped))
                else
                    local currentHelictoper = k
                    local coords = Config.Locations.helicopter[currentHelictoper]

                    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
                        local veh = NetToVeh(netId)

                        SetVehicleNumberPlateText(veh, Lang:t('info.heli_plate') .. tostring(math.random(1000, 9999)))
                        SetEntityHeading(veh, coords.w)
                        SetVehicleLivery(veh, 1) -- Ambulance Livery
                        SetVehicleFuelLevel(veh, 100.0)
                        TaskWarpPedIntoVehicle(cache.ped, veh, -1)

                        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))

                        SetVehicleEngineOn(veh, true, true)
                    end, Config.Helicopter, coords, true)
                end
            end

            Wait(0)
        end
    end)
end

RegisterNetEvent('qb-ambulancejob:elevator_roof', function()
    for k, _ in pairs(Config.Locations.roof) do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(10)
        end

        currentHospital = k

        local coords = Config.Locations.main[currentHospital]
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(cache.ped, coords.w)

        Wait(100)

        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('qb-ambulancejob:elevator_main', function()
    for k, _ in pairs(Config.Locations.main) do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(10)
        end

        currentHospital = k

        local coords = Config.Locations.roof[currentHospital]

        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(cache.ped, coords.w)

        Wait(100)

        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('EMSToggle:Duty', function()
    onDuty = not onDuty

    TriggerServerEvent("QBCore:ToggleDuty")
end)

CreateThread(function()
    for k, v in pairs(Config.Locations.vehicle) do
        local function inVehicleZone()
            if PlayerJob.name == "ambulance" and onDuty then
                lib.showTextUI(Lang:t('text.veh_button'))

                EMSVehicle(k)
            else
                CheckVehicle = false

                lib.hideTextUI()
            end
        end

        local function outVehicleZone()
            CheckVehicle = false

            lib.hideTextUI()
        end

        lib.zones.box({
            coords = vec3(v.x, v.y, v.z),
            size = vec3(5, 5, 2),
            rotation = v.w,
            debug = false,
            inside = inVehicleZone,
            onExit = outVehicleZone
        })
    end

    for k, v in pairs(Config.Locations.helicopter) do
        local function inHeliZone()
            if PlayerJob.name == "ambulance" and onDuty then
                lib.showTextUI(Lang:t('text.veh_button'))

                EMSHelicopter(k)
            else
                CheckHeli = false

                lib.hideTextUI()
            end
        end

        local function outHeliZone()
            CheckHeli = false

            lib.hideTextUI()
        end

        lib.zones.box({
            coords = vec3(v.x, v.y, v.z),
            size = vec3(5, 5, 2),
            rotation = v.w,
            debug = false,
            inside = inHeliZone,
            onExit = outHeliZone
        })
    end
end)

-- Convar turns into a boolean
if Config.UseTarget then
    CreateThread(function()
        for k, v in pairs(Config.Locations.duty) do
            exports.ox_target:addBoxZone({
                name = "duty" .. k,
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1.5, 1, 2),
                rotation = 71,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "EMSToggle:Duty",
                        icon = "fa-solid fa-clipboard",
                        label = Lang:t('text.duty'),
                        distance = 2,
                        groups = "ambulance"
                    }
                }
            })
        end

        for k, v in pairs(Config.Locations.stash) do
            exports.ox_target:addBoxZone({
                name = "stash" .. k,
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "qb-ambulancejob:stash",
                        icon = "fa-solid fa-clipboard",
                        label = Lang:t('text.pstash'),
                        distance = 2,
                        groups = "ambulance"
                    }
                }
            })
        end

        for k, v in pairs(Config.Locations.armory) do
            exports.ox_target:addBoxZone({
                name = "armory" .. k,
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "qb-ambulancejob:armory",
                        icon = "fa-solid fa-clipboard",
                        label = Lang:t('text.armory'),
                        distance = 1.5,
                        groups = "ambulance"
                    }
                }
            })
        end

        for k, v in pairs(Config.Locations.roof) do
            exports.ox_target:addBoxZone({
                name = "roof" .. k,
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 2, 2),
                rotation = -20,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "qb-ambulancejob:elevator_roof",
                        icon = "fa-solid fa-hand-point-up",
                        label = Lang:t('text.el_roof'),
                        distance = 1.5,
                        groups = "ambulance"
                    }
                }
            })
        end

        for k, v in pairs(Config.Locations.main) do
            exports.ox_target:addBoxZone({
                name = "main" .. k,
                coords = vec3(v.x, v.y, v.z),
                size = vec3(2, 1, 2),
                rotation = -20,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "qb-ambulancejob:elevator_main",
                        icon = "fa-solid fa-hand-point-up",
                        label = Lang:t('text.el_roof'),
                        distance = 1.5,
                        groups = "ambulance"
                    }
                }
            })
        end
    end)
else
    CreateThread(function()
        for _, v in pairs(Config.Locations.duty) do
            local function EnteredSignInZone()
                if not onDuty then
                    lib.showTextUI(Lang:t('text.onduty_button'))

                    EMSControls("sign")
                else
                    lib.showTextUI(Lang:t('text.offduty_button'))

                    EMSControls("sign")
                end
            end

            local function outSignInZone()
                check = false

                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = EnteredSignInZone,
                onExit = outSignInZone
            })
        end

        for _, v in pairs(Config.Locations.stash) do
            local function EnteredStashZone()
                if onDuty then
                    lib.showTextUI(Lang:t('text.pstash_button'))

                    EMSControls("stash")
                end
            end

            local function outStashZone()
                check = false

                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = EnteredStashZone,
                onExit = outStashZone
            })
        end

        for _, v in pairs(Config.Locations.armory) do
            local function EnteredArmoryZone()
                if onDuty then
                    lib.showTextUI(Lang:t('text.armory_button'))

                    EMSControls("armory")
                end
            end

            local function outArmoryZone()
                check = false

                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = EnteredArmoryZone,
                onExit = outArmoryZone
            })
        end

        for _, v in pairs(Config.Locations.roof) do
            local function EnteredRoofZone()
                if onDuty then
                    lib.showTextUI(Lang:t('text.elevator_main'))

                    EMSControls("main")
                else
                    lib.showTextUI(Lang:t('error.not_ems'))
                end
            end

            local function outRoofZone()
                check = false

                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = EnteredRoofZone,
                onExit = outRoofZone
            })
        end

        for _, v in pairs(Config.Locations.main) do
            local function EnteredMainZone()
                if onDuty then
                    lib.showTextUI(Lang:t('text.elevator_roof'))

                    EMSControls("roof")
                else
                    lib.showTextUI(Lang:t('error.not_ems'))
                end
            end

            local function outMainZone()
                check = false

                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.x, v.y, v.z),
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = EnteredMainZone,
                onExit = outMainZone
            })
        end
    end)
end