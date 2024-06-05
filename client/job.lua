local config = require 'config.client'
local sharedConfig = require 'config.shared'
local WEAPONS = exports.qbx_core:GetWeapons()

---Configures and spawns a vehicle and teleports player to the driver seat.
---@param data { vehicleName: string, coords: vector4}
local function takeOutVehicle(data)
    local netId = lib.callback.await('qbx_ambulancejob:server:spawnVehicle', false, data.vehicleName, data.coords)

    local veh = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end)

    SetVehicleEngineOn(veh, true, true, true)

    local settings = config.vehicleSettings[data.vehicleName]
    if not settings then return end

    if settings.extras then
        qbx.setVehicleExtras(veh, settings.extras)
    end

    if settings.livery then
        SetVehicleLivery(veh, settings.livery)
    end
end

---Show the garage spawn menu
---@param vehicles AuthorizedVehicles
---@param coords vector4
local function showGarageMenu(vehicles, coords)
    local authorizedVehicles = vehicles[QBX.PlayerData.job.grade.level]
    local optionsMenu = {}
    for veh, label in pairs(authorizedVehicles) do
        optionsMenu[#optionsMenu + 1] = {
            title = label,
            onSelect = takeOutVehicle,
            args = {
                vehicleName = veh,
                coords = coords,
            }
        }
    end

    lib.registerContext({
        id = 'ambulance_garage_context_menu',
        title = locale('menu.amb_vehicles'),
        options = optionsMenu
    })

    lib.showContext('ambulance_garage_context_menu')
end

---Show patient's treatment menu.
---@param status string[]
local function showTreatmentMenu(status)
    local statusMenu = {}
    for i = 1, #status do
        statusMenu[i] = {
            title = status[i],
            event = 'hospital:client:TreatWounds',
        }
    end

    lib.registerContext({
        id = 'ambulance_status_context_menu',
        title = locale('menu.status'),
        options = statusMenu
    })

    lib.showContext('ambulance_status_context_menu')
end

---Check status of nearest player and show treatment menu.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:CheckStatus', function()
    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    local playerId = GetPlayerServerId(player)

    local status = lib.callback.await('qbx_ambulancejob:server:getPlayerStatus', false, playerId)
    if #status.injuries == 0 then
        exports.qbx_core:Notify(locale('success.healthy_player'), 'success')
        return
    end

    for hash in pairs(status.damageCauses) do
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { locale('info.status'), WEAPONS[hash].damagereason }
        })
    end

    if status.bleedLevel > 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { locale('info.status'), locale('info.is_status', status.bleedState) }
        })
    end

    showTreatmentMenu(status.injuries)
end)

---Use first aid on nearest player to revive them.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:RevivePlayer', function()
    local hasFirstAid = exports.ox_inventory:Search('count', 'firstaid') > 0
    if not hasFirstAid then
        exports.qbx_core:Notify(locale('error.no_firstaid'), 'error')
        return
    end

    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = locale('progress.revive'),
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
        StopAnimTask(cache.ped, HealAnimDict, 'exit', 1.0)
        exports.qbx_core:Notify(locale('success.revived'), 'success')
        TriggerServerEvent('hospital:server:RevivePlayer', GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, HealAnimDict, 'exit', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end)

---Use bandage on nearest player to treat their wounds.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:TreatWounds', function()
    local hasBandage = exports.ox_inventory:Search('count', 'bandage') > 0
    if not hasBandage then
        exports.qbx_core:Notify(locale('error.no_bandage'), 'error')
        return
    end

    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = locale('progress.healing'),
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
        StopAnimTask(cache.ped, HealAnimDict, 'exit', 1.0)
        exports.qbx_core:Notify(locale('success.helped_player'), 'success')
        TriggerServerEvent('hospital:server:TreatWounds', GetPlayerServerId(player))
    else
        StopAnimTask(cache.ped, HealAnimDict, 'exit', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end)

---@param stashNumber integer id of stash to open
local function openStash(stashNumber)
    if not QBX.PlayerData.job.onduty then return end
    exports.ox_inventory:openInventory('stash', sharedConfig.locations.stash[stashNumber].name)
end

---Opens the hospital armory.
---@param armoryId integer id of armory to open
---@param stashId integer id of armory to open
local function openArmory(armoryId, stashId)
    if not QBX.PlayerData.job.onduty then return end
    exports.ox_inventory:openInventory('shop', { type = sharedConfig.locations.armory[armoryId].shopType, id = stashId })
end

---Teleports the player with a fade in/out effect
---@param coords vector3 | vector4
local function teleportPlayerWithFade(coords)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then
        SetEntityHeading(cache.ped, coords.w)
    end

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
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('police:server:UpdateBlips')
end

---Creates a zone that lets players store and retrieve job vehicles
---@param vehicles AuthorizedVehicles
---@param coords vector4
local function createGarage(vehicles, coords)
    lib.zones.box({
        coords = coords.xyz,
        size = vec3(5, 5, 2),
        rotation = coords.w,
        debug = config.debugPoly,
        onEnter = function()
            if QBX.PlayerData.job.type == 'ems' and QBX.PlayerData.job.onduty then
                lib.showTextUI(locale('text.veh_button'))
            end
        end,
        onExit = function()
            local _, text = lib.isTextUIOpen()
            if text == locale('text.veh_button') then lib.hideTextUI() end
        end,
        inside = function()
            if QBX.PlayerData.job.type == 'ems' and QBX.PlayerData.job.onduty and IsControlJustPressed(0, 38) then
                if cache.vehicle then
                    DeleteEntity(cache.vehicle)
            else
                showGarageMenu(vehicles, coords)
                end
            end
        end,
    })
end

---Creates air and land garages to spawn vehicles at for EMS personnel
CreateThread(function()
    for _, coords in pairs(sharedConfig.locations.vehicle) do
        createGarage(config.authorizedVehicles, coords)
    end

    for _, coords in pairs(sharedConfig.locations.helicopter) do
        createGarage(config.authorizedHelicopters, coords)
    end
end)

---Sets up duty toggle, stash, armory, and elevator interactions using either target or zones.
if config.useTarget then
    CreateThread(function()
        for i = 1, #sharedConfig.locations.duty do
            exports.ox_target:addBoxZone({
                name = 'duty' .. i,
                coords = sharedConfig.locations.duty[i],
                size = vec3(1.5, 1, 2),
                rotation = 71,
                debug = config.debugPoly,
                canInteract = function()
                    return QBX.PlayerData.job.type == 'ems'
                end,
                options = {
                    {
                        icon = 'fa fa-clipboard',
                        label = locale('text.duty'),
                        onSelect = toggleDuty,
                        distance = 2,
                        groups = 'ambulance',
                    }
                }
            })
        end

        for i = 1, #sharedConfig.locations.stash do
            exports.ox_target:addBoxZone({
                name = 'stash' .. i,
                coords = sharedConfig.locations.stash[i].location,
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = config.debugPoly,
                canInteract = function()
                    return QBX.PlayerData.job.type == 'ems'
                end,
                options = {
                    {
                        icon = 'fa fa-clipboard',
                        label = locale('text.pstash'),
                        onSelect = function()
                            openStash(i)
                        end,
                        distance = 2,
                        groups = 'ambulance',
                    }
                }
            })
        end

        for i = 1, #sharedConfig.locations.armory do
            for ii = 1, #sharedConfig.locations.armory[i].locations do
                exports.ox_target:addBoxZone({
                    name = 'armory' .. i .. ':' .. ii,
                    coords = sharedConfig.locations.armory[i].locations[ii],
                    size = vec3(1, 1, 2),
                    rotation = -20,
                    debug = config.debugPoly,
                    canInteract = function()
                        return QBX.PlayerData.job.type == 'ems'
                    end,
                    options = {
                        {
                            icon = 'fa fa-clipboard',
                            label = locale('text.armory'),
                            onSelect = function()
                                openArmory(i, ii)
                            end,
                            distance = 1.5,
                            groups = 'ambulance',
                        }
                    }
                })
            end
        end

        exports.ox_target:addBoxZone({
            name = 'roof1',
            coords = sharedConfig.locations.roof[1],
            size = vec3(1, 2, 2),
            rotation = -20,
            debug = config.debugPoly,
            options = {
                {
                    icon = 'fas fa-hand-point-down',
                    label = locale('text.el_main'),
                    onSelect = teleportToMainElevator,
                    distance = 1.5,
                    groups = 'ambulance',
                }
            }
        })

        exports.ox_target:addBoxZone({
            name = 'main1',
            coords = sharedConfig.locations.main[1],
            size = vec3(2, 1, 2),
            rotation = -20,
            debug = config.debugPoly,
            options = {
                {
                    icon = 'fas fa-hand-point-up',
                    label = locale('text.el_roof'),
                    onSelect = teleportToRoofElevator,
                    distance = 1.5,
                    groups = 'ambulance',
                }
            }
        })
    end)
else
    CreateThread(function()
        for i = 1, #sharedConfig.locations.duty do
            lib.zones.box({
                coords = sharedConfig.locations.duty[i],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = config.debugPoly,
                onEnter = function()
                    if QBX.PlayerData.job.type ~= 'ems' then return end
                    local label = QBX.PlayerData.job.onduty and locale('text.onduty_button') or locale('text.offduty_button')
                    lib.showTextUI(label)
                end,
                onExit = function()
                    local _, text = lib.isTextUIOpen()
                    if text == locale('text.onduty_button') or text == locale('text.offduty_button') then lib.hideTextUI() end
                end,
                inside = function()
                    if QBX.PlayerData.job.type ~= 'ems' then return end
                    OnKeyPress(toggleDuty)
                end,
            })
        end

        for i = 1, #sharedConfig.locations.stash do
            lib.zones.box({
                coords = sharedConfig.locations.stash[i].location,
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = config.debugPoly,
                onEnter = function()
                    if QBX.PlayerData.job.type ~= 'ems' or not QBX.PlayerData.job.onduty then return end
                    lib.showTextUI(locale('text.pstash_button'))
                    end,
                onExit = function()
                    local _, text = lib.isTextUIOpen()
                    if text == locale('text.pstash_button') then lib.hideTextUI() end
                end,
                inside = function()
                    if QBX.PlayerData.job.type ~= 'ems' then return end
                    OnKeyPress(function()
                        openStash(i)
                    end)
                end,
            })
        end

        for i = 1, #sharedConfig.locations.armory do
            for ii = 1, #sharedConfig.locations.armory[i].locations do
                lib.zones.box({
                    coords = sharedConfig.locations.armory[i].locations[ii],
                    size = vec3(1, 1, 2),
                    rotation = -20,
                    debug = config.debugPoly,
                    onEnter = function()
                        if QBX.PlayerData.job.type ~= 'ems' or not QBX.PlayerData.job.onduty then return end
                        lib.showTextUI(locale('text.armory_button'))
                        end,
                    onExit = function()
                        local _, text = lib.isTextUIOpen()
                        if text == locale('text.armory_button') then lib.hideTextUI() end
                    end,
                    inside = function()
                        if QBX.PlayerData.job.type ~= 'ems' then return end
                        OnKeyPress(function()
                            openArmory(i, ii)
                        end)
                    end,
                })
            end
        end

        lib.zones.box({
            coords = sharedConfig.locations.roof[1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = config.debugPoly,
            onEnter = function()
                local label = QBX.PlayerData.job.onduty and locale('text.elevator_main') or locale('error.not_ems')
                lib.showTextUI(label)
            end,
            onExit = function()
                local _, text = lib.isTextUIOpen()
                if text == locale('text.elevator_main') or text == locale('error.not_ems') then lib.hideTextUI() end
            end,
            inside = function()
                OnKeyPress(teleportToMainElevator)
            end,
        })

        lib.zones.box({
            coords = sharedConfig.locations.main[1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = config.debugPoly,
            onEnter = function()
                local label = QBX.PlayerData.job.onduty and locale('text.elevator_roof') or locale('error.not_ems')
                lib.showTextUI(label)
            end,
            onExit = function()
                local _, text = lib.isTextUIOpen()
                if text == locale('text.elevator_roof') or text == locale('error.not_ems') then lib.hideTextUI() end
            end,
            inside = function()
                OnKeyPress(teleportToRoofElevator)
            end,
        })
    end)
end
