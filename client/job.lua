local PlayerJob = {}
local currentGarage = 0
local currentHospital

-- Functions

local function GetClosestPlayer()
    local coords = GetEntityCoords(cache.ped)
    return QBCore.Functions.GetClosestPlayer(coords)
end

local function takeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, Lang:t('info.amb_plate') .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        SetVehicleFuelLevel(veh, 100.0)
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
        if Config.VehicleSettings[vehicleInfo] ~= nil then
            QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
        end
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
    end, vehicleInfo, coords, true)
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
    takeOutVehicle(vehicle)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    if PlayerJob.name ~= 'ambulance' then return end
    if PlayerJob.onduty then
        TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
    else
        TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
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
        PlayerJob = playerData.job
        initHealthAndArmor(ped, playerId, playerData)
        initDeathAndLastStand(playerData)
        if PlayerJob.name == 'ambulance' and PlayerJob.onduty then
            TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if PlayerJob.name == 'ambulance' and PlayerJob.onduty then
        TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if PlayerJob.name ~= 'ambulance' or duty == PlayerJob.onduty then return end
    if duty then
        TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
    else
        TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
    end
end)

local function status()
    if not isStatusChecking then return end
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

--- TODO: Refactor
local function getPlayerStatus(k, v, result)
    if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
        statusChecks[#statusChecks + 1] = { bone = Config.BoneIndexes[k], label = v.label .. " (" .. Config.WoundStates[v.severity] .. ")" }
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
        isStatusChecking = true
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
            dict = healAnimDict,
            clip = healAnim,
        },
    })
    then
        StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)
        lib.notify({ description = Lang:t('success.revived'), type = 'success' })
        TriggerServerEvent("hospital:server:RevivePlayer", GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)
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
            dict = healAnimDict,
            clip = healAnim,
        },
    })
    then
        StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)
        lib.notify({ description = Lang:t('success.helped_player'), type = 'success' })
        TriggerServerEvent("hospital:server:TreatWounds", GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, healAnimDict, "exit", 1.0)
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
    if PlayerJob.onduty then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
        TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
    end
end)

RegisterNetEvent('qb-ambulancejob:armory', function()
    if PlayerJob.onduty then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
    end
end)

local CheckVehicle = false
local function EMSVehicle(k)
    CheckVehicle = true
    CreateThread(function()
        while CheckVehicle do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                CheckVehicle = false
                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(cache.vehicle)
                else
                    local currentVehicle = k
                    menuGarage(currentVehicle)
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
                exports['qb-core']:KeyPressed(38)
                CheckHeli = false
                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(cache.vehicle)
                else
                    local currentHelictoper = k
                    local coords = Config.Locations["helicopter"][currentHelictoper]
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
    local ped = cache.ped
    for k, _ in pairs(Config.Locations["roof"]) do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(10)
        end

        currentHospital = k

        local coords = Config.Locations["main"][currentHospital]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)

        Wait(100)

        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('qb-ambulancejob:elevator_main', function()
    local ped = cache.ped
    for k, _ in pairs(Config.Locations["main"]) do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(10)
        end

        currentHospital = k

        local coords = Config.Locations["roof"][currentHospital]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)

        Wait(100)

        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('EMSToggle:Duty', function()
    PlayerJob.onduty = not PlayerJob.onduty
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateBlips")
end)


CreateThread(function()
    for k, v in pairs(Config.Locations["vehicle"]) do
        local function inVehicleZone()
            if PlayerJob.name == "ambulance" and PlayerJob.onduty then
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

    for k, v in pairs(Config.Locations["helicopter"]) do
        local function inHeliZone()
            if PlayerJob.name == "ambulance" and PlayerJob.onduty then
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
        for k, v in pairs(Config.Locations["roof"]) do
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
                        icon = "fas fa-hand-point-up",
                        label = Lang:t('text.el_roof'),
                        distance = 1.5,
                        groups = "ambulance",
                    }
                }
            })
        end
        for k, v in pairs(Config.Locations["main"]) do
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
                        icon = "fas fa-hand-point-up",
                        label = Lang:t('text.el_roof'),
                        distance = 1.5,
                        groups = "ambulance",
                    }
                }
            })
        end
    end)
else
    CreateThread(function()
        for _, v in pairs(Config.Locations["duty"]) do
            local function EnteredSignInZone()
                if not PlayerJob.onduty then
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
                if PlayerJob.onduty then
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
                if PlayerJob.onduty then
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

        for _, v in pairs(Config.Locations["roof"]) do
            local function EnteredRoofZone()
                if PlayerJob.onduty then
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

        for _, v in pairs(Config.Locations["main"]) do
            local function EnteredMainZone()
                if PlayerJob.onduty then
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
