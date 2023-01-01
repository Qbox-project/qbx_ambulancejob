local playerJob = {}
local currentGarage = 0
local checkHeli = false
local checkVehicle = false

---Configures and spawns a vehicle and teleports player to the driver seat
---@param veh any
---@param platePrefix string prefix of the license plate of the vehicle
---@param heading number direction the vehicle should face
local function takeOutVehicle(veh, platePrefix, heading)
    SetVehicleNumberPlateText(veh, platePrefix .. tostring(math.random(1000, 9999)))
    SetEntityHeading(veh, heading)
    SetVehicleFuelLevel(veh, 100.0)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
    SetVehicleEngineOn(veh, true, true)
end

---Configures and spawns an automobile and teleports player to the driver seat
---@param vehicleInfo any
local function takeOutAuto(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        takeOutVehicle(veh, Lang:t('info.amb_plate'), coords.w)
        if Config.VehicleSettings[vehicleInfo] ~= nil then
            QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
        end
    end, vehicleInfo, coords, true)
end

---Configures and spawns a helicopter and teleports player to the driver seat
---@param location number index of the helicopter spawn location
local function takeOutHeli(location)
    local coords = Config.Locations["helicopter"][location]
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        takeOutVehicle(veh, Lang:t('info.heli_plate'), coords.w)
        SetVehicleLivery(veh, 1) -- Ambulance Livery
    end, Config.Helicopter, coords, true)
end

local function menuGarage()
    local optionsMenu = {}

    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    for veh, label in pairs(authorizedVehicles) do
        optionsMenu[#optionsMenu + 1] = {
            title = label,
            event = "ambulance:client:TakeOutVehicle",
            args = { vehicle = veh }
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
    takeOutAuto(vehicle)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    playerJob = JobInfo
    if playerJob.name ~= 'ambulance' then return end
    if playerJob.onduty then
        TriggerServerEvent("hospital:server:AddDoctor", playerJob.name)
    else
        TriggerServerEvent("hospital:server:RemoveDoctor", playerJob.name)
    end
end)

local function initHealthAndArmor(ped, playerId, playerData)
    SetEntityHealth(ped, playerData.metadata["health"])
    SetPlayerHealthRechargeMultiplier(playerId, 0.0)
    SetPlayerHealthRechargeLimit(playerId, 0.0)
    SetPedArmour(ped, playerData.metadata["armor"])
end

local function initDeathAndLastStand(playerData)
    if (not playerData.metadata["inlaststand"] and playerData.metadata["isdead"]) then
        deathTime = Laststand.ReviveInterval
        OnDeath()
        DeathTimer()
    elseif (playerData.metadata["inlaststand"] and not playerData.metadata["isdead"]) then
        startLastStand()
    else
        TriggerServerEvent("hospital:server:SetDeathStatus", false)
        TriggerServerEvent("hospital:server:SetLaststandStatus", false)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    CreateThread(function()
        Wait(1000)
        local ped = cache.ped
        local playerId = cache.playerId
        local playerData = QBCore.Functions.GetPlayerData()
        playerJob = playerData.job
        initHealthAndArmor(ped, playerId, playerData)
        initDeathAndLastStand(playerData)
        if playerJob.name == 'ambulance' and playerJob.onduty then
            TriggerServerEvent("hospital:server:AddDoctor", playerJob.name)
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if playerJob.name == 'ambulance' and playerJob.onduty then
        TriggerServerEvent("hospital:server:RemoveDoctor", playerJob.name)
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if playerJob.name ~= 'ambulance' or duty == playerJob.onduty then return end
    if duty then
        TriggerServerEvent("hospital:server:AddDoctor", playerJob.name)
    else
        TriggerServerEvent("hospital:server:RemoveDoctor", playerJob.name)
    end
end)

local function status()
    if not IsStatusChecking then return end
    local statusMenu = {}
    for _, v in pairs(StatusChecks) do
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

--- TODO: Refactor
local function getPlayerStatus(k, v, result)
    if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
        StatusChecks[#StatusChecks + 1] = { bone = Config.BoneIndexes[k], label = v.label .. " (" .. Config.WoundStates[v.severity] .. ")" }
    elseif result["WEAPONWOUNDS"] then
        for _, v2 in pairs(result["WEAPONWOUNDS"]) do
            TriggerEvent('chat:addMessage', {
                color = { 255, 0, 0 },
                multiline = false,
                args = { Lang:t('info.status'), QBCore.Shared.Weapons[v2].damagereason }
            })
        end
    elseif result["BLEED"] > 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { Lang:t('info.status'), Lang:t('info.is_status', { status = Config.BleedingStates[v].label }) }
        })
    else
        lib.notify({ description = Lang:t('success.healthy_player'), type = 'success' })
    end
end

-- TODO: Refactor
RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player == -1 or distance > 5.0 then
        lib.notify({ description = Lang:t('error.no_player'), type = 'error' })
        return
    end
    local playerId = GetPlayerServerId(player)
    QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
        if not result then return end
        for k, v in pairs(result) do
            getPlayerStatus(k, v, result)
        end
        IsStatusChecking = true
        status()
    end, playerId)
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    if not QBCore.Functions.HasItem('firstaid') then
        lib.notify({ description = Lang:t('error.no_firstaid'), type = 'error' })
        return
    end

    local player, distance = GetClosestPlayer()
    if player == -1 or distance >= 5.0 then
        lib.notify({ description = Lang:t('error.no_player'), type = 'error' })
        return
    end

    if lib.progressCircle({
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
            dict = HealAnimDict,
            clip = HealAnim,
        },
    })
    then
        StopAnimTask(cache.ped, HealAnimDict, "exit", 1.0)
        lib.notify({ description = Lang:t('success.revived'), type = 'success' })
        TriggerServerEvent("hospital:server:RevivePlayer", GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, HealAnimDict, "exit", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    if not QBCore.Functions.HasItem('bandage') then
        lib.notify({ description = Lang:t('error.no_bandage'), type = 'error' })
        return
    end

    local player, distance = GetClosestPlayer()
    if player == -1 or distance >= 5.0 then
        lib.notify({ description = Lang:t('error.no_player'), type = 'error' })
        return
    end

    if lib.progressCircle({
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
            dict = HealAnimDict,
            clip = HealAnim,
        },
    })
    then
        StopAnimTask(cache.ped, HealAnimDict, "exit", 1.0)
        lib.notify({ description = Lang:t('success.helped_player'), type = 'success' })
        TriggerServerEvent("hospital:server:TreatWounds", GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, HealAnimDict, "exit", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)

local check = false
local function EMSControls(variable)
    CreateThread(function()
        check = true
        while check do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
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
    if playerJob.onduty then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
        TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
    end
end)

RegisterNetEvent('qb-ambulancejob:armory', function()
    if playerJob.onduty then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
    end
end)

local function EMSVehicle(k)
    checkVehicle = true
    CreateThread(function()
        while checkVehicle do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                checkVehicle = false
                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(cache.vehicle)
                else
                    local currentVehicle = k
                    menuGarage()
                    currentGarage = currentVehicle
                end
            end
            Wait(0)
        end
    end)
end

local function EMSHelicopter(k)
    checkHeli = true
    CreateThread(function()
        while checkHeli do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                checkHeli = false
                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(cache.vehicle)
                else
                    takeOutHeli(k)
                end
            end
            Wait(0)
        end
    end)
end

local function teleportPlayerWithFade(coords)
    local ped = cache.ped
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)

    Wait(100)

    DoScreenFadeIn(1000)
end

RegisterNetEvent('qb-ambulancejob:elevator_roof', function()
    teleportPlayerWithFade(Config.Locations["main"][1])
end)

RegisterNetEvent('qb-ambulancejob:elevator_main', function()
    teleportPlayerWithFade(Config.Locations["roof"][1])
end)

RegisterNetEvent('EMSToggle:Duty', function()
    playerJob.onduty = not playerJob.onduty
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateBlips")
end)


CreateThread(function()
    for k, v in pairs(Config.Locations["vehicle"]) do
        local function inVehicleZone()
            if playerJob.name == "ambulance" and playerJob.onduty then
                lib.showTextUI(Lang:t('text.veh_button'))
                EMSVehicle(k)
            else
                checkVehicle = false
                lib.hideTextUI()
            end
        end

        local function outVehicleZone()
            checkVehicle = false
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

    for k, v in pairs(Config.Locations["helicopter"]) do
        local function inHeliZone()
            if playerJob.name == "ambulance" and playerJob.onduty then
                lib.showTextUI(Lang:t('text.veh_button'))
                EMSHelicopter(k)
            else
                checkHeli = false
                lib.hideTextUI()
            end
        end

        local function outHeliZone()
            checkHeli = false
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
        for k, v in pairs(Config.Locations["duty"]) do
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
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.duty'),
                        distance = 2,
                        groups = "ambulance",
                    }
                }
            })
        end
        for k, v in pairs(Config.Locations["stash"]) do
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
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.pstash'),
                        distance = 2,
                        groups = "ambulance",
                    }
                }
            })
        end
        for k, v in pairs(Config.Locations["armory"]) do
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
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.armory'),
                        distance = 1.5,
                        groups = "ambulance",
                    }
                }
            })
        end
        exports.ox_target:addBoxZone({
            name = "roof1",
            coords = Config.Locations["roof"][1],
            size = vec3(1, 2, 2),
            rotation = -20,
            debug = false,
            options = {
                {
                    type = "client",
                    event = "qb-ambulancejob:elevator_roof",
                    icon = "fas fa-hand-point-up",
                    label = Lang:t('text.el_roof'),
                    distance = 1.5,
                    groups = "ambulance",
                }
            }
        })
        exports.ox_target:addBoxZone({
            name = "main1",
            coords = Config.Locations["main"][1],
            size = vec3(2, 1, 2),
            rotation = -20,
            debug = false,
            options = {
                {
                    type = "client",
                    event = "qb-ambulancejob:elevator_main",
                    icon = "fas fa-hand-point-up",
                    label = Lang:t('text.el_roof'),
                    distance = 1.5,
                    groups = "ambulance",
                }
            }
        })
    end)
else
    CreateThread(function()
        for _, v in pairs(Config.Locations["duty"]) do
            local function EnteredSignInZone()
                if not playerJob.onduty then
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

        for _, v in pairs(Config.Locations["stash"]) do
            local function EnteredStashZone()
                if playerJob.onduty then
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

        for _, v in pairs(Config.Locations["armory"]) do
            local function EnteredArmoryZone()
                if playerJob.onduty then
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

        local function EnteredRoofZone()
            if playerJob.onduty then
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
            coords = Config.Locations["roof"][1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = false,
            onEnter = EnteredRoofZone,
            onExit = outRoofZone
        })

        local function EnteredMainZone()
            if playerJob.onduty then
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
            coords = Config.Locations["main"][1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = false,
            onEnter = EnteredMainZone,
            onExit = outMainZone
        })
    end)
end
