local config = require 'config.client'
local sharedConfig = require 'config.shared'
local checkVehicle = false
local WEAPONS = exports.qbx_core:GetWeapons()

---Configures and spawns a vehicle and teleports player to the driver seat.
---@param data { vehicleName: string, vehiclePlatePrefix: string, coords: vector4}
local function takeOutVehicle(data)
    local netId = lib.callback.await('qbx_ambulancejob:server:spawnVehicle', false, data.vehicleName, data.coords)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local veh = NetworkGetEntityFromNetworkId(netId)
    SetVehicleNumberPlateText(veh, data.vehiclePlatePrefix .. tostring(math.random(1000, 9999)))
    TriggerEvent("vehiclekeys:client:SetOwner", GetPlate(veh))
    SetVehicleEngineOn(veh, true, true, true)

    local settings = config.vehicleSettings[data.vehicleName]
    if not settings then return end

    if settings.extra then
        SetVehicleExtras(veh, settings.extras)
    end

    if settings.livery then
        SetVehicleLivery(veh, settings.livery)
    end
end

---show the garage spawn menu
---@param vehicles AuthorizedVehicles
---@param vehiclePlatePrefix string
---@param coords vector4
local function showGarageMenu(vehicles, vehiclePlatePrefix, coords)
    local authorizedVehicles = vehicles[QBX.PlayerData.job.grade.level]
    local optionsMenu = {}
    for veh, label in pairs(authorizedVehicles) do
        optionsMenu[#optionsMenu + 1] = {
            title = label,
            onSelect = takeOutVehicle,
            args = {
                vehicleName = veh,
                vehiclePlatePrefix = vehiclePlatePrefix,
                coords = coords,
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

---show patient's treatment menu.
---@param status string[]
local function showTreatmentMenu(status)
    local statusMenu = {}
    for i=1, #status do
        statusMenu[i] = {
            title = status[i],
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

---Check status of nearest player and show treatment menu.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:CheckStatus', function()
    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(Lang:t('error.no_player'), 'error')
        return
    end
    local playerId = GetPlayerServerId(player)


    local status = lib.callback.await('qbx_ambulancejob:server:getPlayerStatus', false, playerId)
    if #status.injuries == 0 then
        exports.qbx_core:Notify(Lang:t('success.healthy_player'), 'success')
        return
    end

    for hash in pairs(status.damageCauses) do
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { Lang:t('info.status'), WEAPONS[hash].damagereason }
        })
    end

    if status.bleedLevel > 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { Lang:t('info.status'), Lang:t('info.is_status', { status = status.bleedState }) }
        })
    end

    showTreatmentMenu(status.injuries)
end)

---Use first aid on nearest player to revive them.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:RevivePlayer', function()
    if not exports.qbx_core:HasItem('firstaid') then
        exports.qbx_core:Notify(Lang:t('error.no_firstaid'), 'error')
        return
    end

    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(Lang:t('error.no_player'), 'error')
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
        exports.qbx_core:Notify(Lang:t('success.revived'), 'success')
        TriggerServerEvent("hospital:server:RevivePlayer", GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, HealAnimDict, "exit", 1.0)
        exports.qbx_core:Notify(Lang:t('error.canceled'), 'error')
    end
end)

---Use bandage on nearest player to treat their wounds.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:TreatWounds', function()
    if not exports.qbx_core:HasItem('bandage') then
        exports.qbx_core:Notify(Lang:t('error.no_bandage'), 'error')
        return
    end

    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(Lang:t('error.no_player'), 'error')
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
        exports.qbx_core:Notify(Lang:t('success.helped_player'), 'success')
        TriggerServerEvent("hospital:server:TreatWounds", GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, HealAnimDict, "exit", 1.0)
        exports.qbx_core:Notify(Lang:t('error.canceled'), 'error')
    end
end)

---Opens the hospital stash.
local function openStash()
    if not QBX.PlayerData.job.onduty then return end
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_" .. QBX.PlayerData.citizenid)
    TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_" .. QBX.PlayerData.citizenid)
end

---Opens the hospital armory.
local function openArmory()
    if QBX.PlayerData.job.onduty then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", config.items)
    end
end

---while in the garage pressing a key triggers storing the current vehicle or opening spawn menu.
---@param vehicles AuthorizedVehicles
---@param vehiclePlatePrefix string
---@param coords vector4
local function checkGarageAction(vehicles, vehiclePlatePrefix, coords)
    checkVehicle = true
    CreateThread(function()
        while checkVehicle do
            if IsControlJustPressed(0, 38) then
                lib.hideTextUI()
                checkVehicle = false
                if cache.vehicle then
                    DeleteEntity(cache.vehicle)
                else
                    showGarageMenu(vehicles, vehiclePlatePrefix, coords)
                end
            end
            Wait(0)
        end
    end)
end

---Teleports the player with a fade in/out effect
---@param coords vector4
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

---Teleports the player to main elevator
local function teleportToMainElevator()
    teleportPlayerWithFade(sharedConfig.locations.main[1])
end

---Teleports the player to roof elevator
local function teleportToRoofElevator()
    teleportPlayerWithFade(sharedConfig.locations.roof[1])
end

---Toggles the on duty status of the player.
local function toggleDuty()
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateBlips")
end

---creates a zone that lets players store and retrieve job vehicles
---@param vehicles AuthorizedVehicles
---@param vehiclePlatePrefix string
---@param coords vector4
local function createGarage(vehicles, vehiclePlatePrefix, coords)

    local function inVehicleZone()
        if QBX.PlayerData.job.name == "ambulance" and QBX.PlayerData.job.onduty then
            lib.showTextUI(Lang:t('text.veh_button'))
            checkGarageAction(vehicles, vehiclePlatePrefix, coords)
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
        coords = coords.xyz,
        size = vec3(5, 5, 2),
        rotation = coords.w,
        debug = false,
        inside = inVehicleZone,
        onExit = outVehicleZone
    })
end

---Creates air and land garages to spawn vehicles at for EMS personnel
CreateThread(function()
    for _, coords in pairs(sharedConfig.locations.vehicle) do
        createGarage(config.authorizedVehicles, Lang:t('info.amb_plate'), coords)
    end

    for _, coords in pairs(sharedConfig.locations.helicopter) do
        createGarage(config.authorizedHelicopters, Lang:t('info.heli_plate'), coords)
    end
end)

---Sets up duty toggle, stash, armory, and elevator interactions using either target or zones.
if config.useTarget then
    CreateThread(function()
        for i = 1, #sharedConfig.locations.duty do
            exports.ox_target:addBoxZone({
                name = "duty" .. i,
                coords = sharedConfig.locations.duty[i],
                size = vec3(1.5, 1, 2),
                rotation = 71,
                debug = false,
                options = {
                    {
                        type = "client",
                        onSelect = toggleDuty,
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.duty'),
                        distance = 2,
                        groups = "ambulance",
                    }
                }
            })
        end
        for i = 1, #sharedConfig.locations.stash do
            exports.ox_target:addBoxZone({
                name = "stash" .. i,
                coords = sharedConfig.locations.stash[i],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                options = {
                    {
                        type = "client",
                        onSelect = openStash,
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.pstash'),
                        distance = 2,
                        groups = "ambulance",
                    }
                }
            })
        end
        for i = 1, #sharedConfig.locations.armory do
            exports.ox_target:addBoxZone({
                name = "armory" .. i,
                coords = sharedConfig.locations.armory[i],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                options = {
                    {
                        type = "client",
                        onSelect = openArmory,
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
            coords = sharedConfig.locations.roof[1],
            size = vec3(1, 2, 2),
            rotation = -20,
            debug = false,
            options = {
                {
                    type = "client",
                    onSelect = teleportToMainElevator,
                    icon = "fas fa-hand-point-up",
                    label = Lang:t('text.el_main'),
                    distance = 1.5,
                    groups = "ambulance",
                }
            }
        })
        exports.ox_target:addBoxZone({
            name = "main1",
            coords = sharedConfig.locations.main[1],
            size = vec3(2, 1, 2),
            rotation = -20,
            debug = false,
            options = {
                {
                    type = "client",
                    onSelect = teleportToRoofElevator,
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
        for i = 1, #sharedConfig.locations.duty do
            local function enteredSignInZone()
                if not QBX.PlayerData.job.onduty then
                    lib.showTextUI(Lang:t('text.onduty_button'))
                else
                    lib.showTextUI(Lang:t('text.offduty_button'))
                end
            end

            local function outSignInZone()
                lib.hideTextUI()
            end

            local function insideDutyZone()
                OnKeyPress(toggleDuty)
            end

            lib.zones.box({
                coords = sharedConfig.locations.duty[i],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = enteredSignInZone,
                onExit = outSignInZone,
                inside = insideDutyZone,
            })
        end

        for i = 1, #sharedConfig.locations.stash do
            local function enteredStashZone()
                if QBX.PlayerData.job.onduty then
                    lib.showTextUI(Lang:t('text.pstash_button'))
                end
            end

            local function outStashZone()
                lib.hideTextUI()
            end
            
            local function insideStashZone()
                OnKeyPress(openStash)
            end

            lib.zones.box({
                coords = sharedConfig.locations.stash[i],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = enteredStashZone,
                onExit = outStashZone,
                inside = insideStashZone,
            })
        end

        for i = 1, #sharedConfig.locations.armory do
            local function enteredArmoryZone()
                if QBX.PlayerData.job.onduty then
                    lib.showTextUI(Lang:t('text.armory_button'))
                end
            end

            local function outArmoryZone()
                lib.hideTextUI()
            end

            local function insideArmoryZone()
                OnKeyPress(openArmory)
            end

            lib.zones.box({
                coords = sharedConfig.locations.armory[i],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = false,
                onEnter = enteredArmoryZone,
                onExit = outArmoryZone,
                inside = insideArmoryZone,
            })
        end

        local function enteredRoofZone()
            if QBX.PlayerData.job.onduty then
                lib.showTextUI(Lang:t('text.elevator_main'))
            else
                lib.showTextUI(Lang:t('error.not_ems'))
            end
        end

        local function outRoofZone()
            lib.hideTextUI()
        end

        local function insideRoofZone()
            OnKeyPress(teleportToMainElevator)
        end

        lib.zones.box({
            coords = sharedConfig.locations.roof[1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = false,
            onEnter = enteredRoofZone,
            onExit = outRoofZone,
            inside = insideRoofZone,
        })

        local function enteredMainZone()
            if QBX.PlayerData.job.onduty then
                lib.showTextUI(Lang:t('text.elevator_roof'))
            else
                lib.showTextUI(Lang:t('error.not_ems'))
            end
        end

        local function outMainZone()
            lib.hideTextUI()
        end

        local function insideMainZone()
            OnKeyPress(teleportToRoofElevator)
        end

        lib.zones.box({
            coords = sharedConfig.locations.main[1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = false,
            onEnter = enteredMainZone,
            onExit = outMainZone,
            inside = insideMainZone,
        })
    end)
end
