local playerJob = {}
local checkVehicle = false
local check = false

---Configures and spawns a vehicle and teleports player to the driver seat.
---@param vehicleName string
---@param vehiclePlatePrefix string
---@param coords vector4
local function takeOutVehicle(vehicleName, vehiclePlatePrefix, coords)
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, vehiclePlatePrefix .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        SetVehicleFuelLevel(veh, 100.0)
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true, true)
        
        local settings = Config.VehicleSettings[vehicleName]
        if not settings then return end
        QBCore.Shared.SetDefaultVehicleExtras(veh, settings.extras)
        if not settings.livery then return end
        SetVehicleLivery(veh, settings.livery)
    end, vehicleName, coords, true)
end

---show the garage spawn menu
---@param vehicles AuthorizedVehicles
---@param vehiclePlatePrefix string
---@param coords vector4
local function showGarageMenu(vehicles, vehiclePlatePrefix, coords)
    local authorizedVehicles = vehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    local optionsMenu = {}
    for veh, label in pairs(authorizedVehicles) do
        optionsMenu[#optionsMenu + 1] = {
            title = label,
            onSelect = takeOutVehicle,
            args = {veh, vehiclePlatePrefix, coords}
        }
    end

    lib.registerContext({
        id = 'ambulance_garage_context_menu',
        title = Lang:t('menu.amb_vehicles'),
        options = optionsMenu
    })
    lib.showContext('ambulance_garage_context_menu')
end

---Update the doctor count based on whether player is on duty or not.
---@param jobInfo any player's job object
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    playerJob = jobInfo
end)

---Initialize health and armor settings on the player's ped
---@param ped number
---@param playerId number
---@param playerMetadata any
local function initHealthAndArmor(ped, playerId, playerMetadata)
    SetEntityHealth(ped, playerMetadata.health)
    SetPlayerHealthRechargeMultiplier(playerId, 0.0)
    SetPlayerHealthRechargeLimit(playerId, 0.0)
    SetPedArmour(ped, playerMetadata.armor)
end

---starts death or last stand based off of player's metadata
---@param metadata any
local function initDeathAndLastStand(metadata)
    if not metadata.inlaststand and metadata.isdead then
        DeathTime = Laststand.ReviveInterval
        OnDeath()
        AllowRespawn()
    elseif metadata.inlaststand and not metadata.isdead then
        StartLastStand()
    else
        TriggerServerEvent("hospital:server:SetDeathStatus", false)
        TriggerServerEvent("hospital:server:SetLaststandStatus", false)
    end
end

---initialize settings from player object
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    CreateThread(function()
        Wait(1000)
        local ped = cache.ped
        local playerId = cache.playerId
        local playerData = QBCore.Functions.GetPlayerData()
        playerJob = playerData.job
        initHealthAndArmor(ped, playerId, playerData.metadata)
        initDeathAndLastStand(playerData.metadata)
    end)
end)

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

---Convert wounded body part data to a human readable form
---@param damagedBodyParts BodyParts
---@return string[]
local function getPatientStatus(damagedBodyParts)
    local status = {}
    for _, bodyPart in pairs(damagedBodyParts) do
        status[#status + 1] = bodyPart.label .. " (" .. Config.WoundStates[bodyPart.severity] .. ")"
    end
    return status
end

---Check status of nearest player and show treatment menu.
RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player == -1 or distance > 5.0 then
        lib.notify({ description = Lang:t('error.no_player'), type = 'error' })
        return
    end
    local playerId = GetPlayerServerId(player)

    ---@param damage PlayerDamage
    QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(damage)
        if not damage or (damage.bleedLevel == 0 and #damage.damagedBodyParts == 0 and #damage.weaponWounds == 0) then
            lib.notify({ description = Lang:t('success.healthy_player'), type = 'success' })
            return
        end

        for _, hash in pairs(damage.weaponWounds) do
            TriggerEvent('chat:addMessage', {
                color = { 255, 0, 0 },
                multiline = false,
                args = { Lang:t('info.status'), QBCore.Shared.Weapons[hash].damagereason }
            })
        end

        if damage.bleedLevel > 0 then
            TriggerEvent('chat:addMessage', {
                color = { 255, 0, 0 },
                multiline = false,
                args = { Lang:t('info.status'), Lang:t('info.is_status', { status = Config.BleedingStates[damage.bleedLevel].label }) }
            })
        end

        local status = getPatientStatus(damage.damagedBodyParts)
        showTreatmentMenu(status)
    end, playerId)
end)

---Use first aid on nearest player to revive them.
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

---Use bandage on nearest player to treat their wounds.
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

---Triggers event when the player presses a key
---@param event string event name to trigger
local function emsControls(event)
    CreateThread(function()
        check = true
        while check do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                TriggerEvent(event)
            end
            Wait(0)
        end
    end)
end

---Opens the hospital stash.
AddEventHandler('qb-ambulancejob:stash', function()
    if not playerJob.onduty then return end
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
    TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
end)

---Opens the hospital armory.
AddEventHandler('qb-ambulancejob:armory', function()
    if playerJob.onduty then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
    end
end)

---while in the garage pressing a key triggers storing the current vehicle or opening spawn menu.
---@param vehicles AuthorizedVehicles
---@param vehiclePlatePrefix string
---@param coords vector4
local function checkGarageAction(vehicles, vehiclePlatePrefix, coords)
    checkVehicle = true
    CreateThread(function()
        while checkVehicle do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                checkVehicle = false
                if cache.vehicle then
                    QBCore.Functions.DeleteVehicle(cache.vehicle)
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
AddEventHandler('qb-ambulancejob:elevator_roof', function()
    teleportPlayerWithFade(Config.Locations.main[1])
end)

---Teleports the player to roof elevator
AddEventHandler('qb-ambulancejob:elevator_main', function()
    teleportPlayerWithFade(Config.Locations.roof[1])
end)

---Toggles the on duty status of the player.
AddEventHandler('EMSToggle:Duty', function()
    playerJob.onduty = not playerJob.onduty
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateBlips")
end)

---creates a zone that lets players store and retrieve job vehicles
---@param vehicles AuthorizedVehicles
---@param vehiclePlatePrefix string
---@param coords vector4
local function createGarage(vehicles, vehiclePlatePrefix, coords)
    
    local function inVehicleZone()
        if playerJob.name == "ambulance" and playerJob.onduty then
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
        coords = vec3(coords.x, coords.y, coords.z),
        size = vec3(5, 5, 2),
        rotation = coords.w,
        debug = false,
        inside = inVehicleZone,
        onExit = outVehicleZone
    })
end

---Creates air and land garages to spawn vehicles at for EMS personnel
CreateThread(function()
    for _, coords in pairs(Config.Locations.vehicle) do
        createGarage(Config.AuthorizedVehicles, Lang:t('info.amb_plate'), coords)
    end

    for _, coords in pairs(Config.Locations.helicopter) do
        createGarage(Config.AuthorizedHelicopters, Lang:t('info.heli_plate'), coords)
    end
end)

---Sets up duty toggle, stash, armory, and elevator interactions using either target or zones.
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
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.duty'),
                        distance = 2,
                        groups = "ambulance",
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
                        icon = "fa fa-clipboard",
                        label = Lang:t('text.pstash'),
                        distance = 2,
                        groups = "ambulance",
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
            coords = Config.Locations.roof[1],
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
            coords = Config.Locations.main[1],
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
        for _, v in pairs(Config.Locations.duty) do
            local function EnteredSignInZone()
                if not playerJob.onduty then
                    lib.showTextUI(Lang:t('text.onduty_button'))
                    emsControls("EMSToggle:Duty")
                else
                    lib.showTextUI(Lang:t('text.offduty_button'))
                    emsControls("EMSToggle:Duty")
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
                if playerJob.onduty then
                    lib.showTextUI(Lang:t('text.pstash_button'))
                    emsControls("qb-ambulancejob:stash")
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
                if playerJob.onduty then
                    lib.showTextUI(Lang:t('text.armory_button'))
                    emsControls("qb-ambulancejob:armory")
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
                emsControls("qb-ambulancejob:elevator_roof")
            else
                lib.showTextUI(Lang:t('error.not_ems'))
            end
        end

        local function outRoofZone()
            check = false
            lib.hideTextUI()
        end

        lib.zones.box({
            coords = Config.Locations.roof[1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = false,
            onEnter = EnteredRoofZone,
            onExit = outRoofZone
        })

        local function EnteredMainZone()
            if playerJob.onduty then
                lib.showTextUI(Lang:t('text.elevator_roof'))
                emsControls("qb-ambulancejob:elevator_main")
            else
                lib.showTextUI(Lang:t('error.not_ems'))
            end
        end

        local function outMainZone()
            check = false
            lib.hideTextUI()
        end

        lib.zones.box({
            coords = Config.Locations.main[1],
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = false,
            onEnter = EnteredMainZone,
            onExit = outMainZone
        })
    end)
end
