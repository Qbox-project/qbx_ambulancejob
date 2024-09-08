local config = require 'config.client'
local sharedConfig = require 'config.shared'
local vehicles = require 'client.vehicles'

---@param hospital? BlipData
local function createBlip(hospital)
    if not hospital then return end

    local blip = AddBlipForCoord(hospital.coords.x, hospital.coords.y, hospital.coords.z)
    SetBlipSprite(blip, hospital.sprite or 61)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, hospital.scale or 0.8)
    SetBlipColour(blip, hospital.color or 25)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(hospital.label or locale('blip'))
    EndTextCommandSetBlipName(blip)
end

---@param job? string
---@param hospital? DutyData
local function createDuty(job, hospital)
    if not job or not hospital then return end

    for i = 1, #hospital do
        local location = hospital[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = location.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-Duty'):format(job),
                    icon = 'fa-solid fa-clipboard-user',
                    label = locale('targets.duty'),
                    serverEvent = 'QBCore:ToggleDuty',
                    groups = location.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job? string
---@param hospital? ManagementData
local function createManagement(job, hospital)
    if not job or not hospital then return end

    for i = 1, #hospital do
        local location = hospital[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = location.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = ('%s-BossMenu'):format(job),
                    icon = 'fa-solid fa-people-roof',
                    label = locale('targets.boss_menu'),
                    canInteract = function()
                        return QBX.PlayerData.job.isboss and QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        exports.qbx_management:OpenBossMenu('job')
                    end,
                    groups = location.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job? string
---@param supplyClosets? ClosetData
local function createSupplyCloset(job, supplyClosets)
    if not job or not supplyClosets then return end

    for i = 1, #supplyClosets do
        local closet = supplyClosets[i]

        for ii = 1, #closet.locations do
            local location = closet.locations[ii]

            exports.ox_target:addSphereZone({
                coords = location,
                radius = closet.radius or 1.5,
                debug = config.debugPoly,
                options = {
                    {
                        name = ('%s-Closet'):format(job),
                        icon = 'fa-solid fa-pills',
                        label = locale('targets.closet'),
                        canInteract = function()
                            return QBX.PlayerData.job.onduty
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('shop', { type = closet.shopType, id = ii })
                        end,
                        groups = closet.groups,
                        distance = 1.5,
                    },
                }
            })
        end
    end
end

---@param job? string
---@param stashes? PersonalStashData
local function createPersonalStash(job, stashes)
    if not job or not stashes then return end

    for i = 1, #stashes do
        local stash = stashes[i]
        local stashId = ('%s-PersonalStash'):format(job)

        exports.ox_target:addSphereZone({
            coords = stash.coords,
            radius = stash.radius or 1.5,
            debug = config.debugPoly,
            options = {
                {
                    name = stashId,
                    icon = 'fa-solid fa-box-archive',
                    label = locale('targets.personal_stash'),
                    canInteract = function()
                        return QBX.PlayerData.job.onduty
                    end,
                    onSelect = function()
                        exports.ox_inventory:openInventory('stash', stashId)
                    end,
                    groups = stash.groups,
                    distance = 1.5,
                },
            }
        })
    end
end

---@param job? string
---@param garages? VehicleData
local function createGarage(job, garages)
    if not job or not garages then return end

    for i = 1, #garages do
        local garage = garages[i]

        lib.zones.sphere({
            coords = garage.coords,
            radius = garage.radius,
            debug = config.debugPoly,
            onEnter = function()
                local hasGroup = exports.qbx_core:HasGroup(garage.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                lib.showTextUI(cache.vehicle and locale('vehicles.store_vehicle') or locale('vehicles.open_garage'))
            end,
            inside = function()
                local hasGroup = exports.qbx_core:HasGroup(garage.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                if IsControlJustReleased(0, 38) then
                    if cache.vehicle then
                        vehicles.store(cache.vehicle)
                    else
                        vehicles.openHelipad(garage)
                    end

                    lib.hideTextUI()
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end
end

---@param job? string
---@param helipads? VehicleData
local function createHelipad(job, helipads)
    if not job or not helipads then return end

    for i = 1, #helipads do
        local helipad = helipads[i]

        lib.zones.sphere({
            coords = helipad.coords,
            radius = helipad.radius,
            debug = config.debugPoly,
            onEnter = function()
                local hasGroup = exports.qbx_core:HasGroup(helipad.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                lib.showTextUI(cache.vehicle and locale('vehicles.store_helicopter') or locale('vehicles.open_helipad'))
            end,
            inside = function()
                local hasGroup = exports.qbx_core:HasGroup(helipad.groups)

                if not hasGroup or not QBX.PlayerData.job.onduty then return end

                if IsControlJustReleased(0, 38) then
                    if cache.vehicle then
                        vehicles.store(cache.vehicle)
                    else
                        vehicles.openHelipad(helipad)
                    end

                    lib.hideTextUI()
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end
end

local function registerAliveRadial()
    lib.registerRadial({
        id = 'emsMenu',
        items = {
            {
                icon = 'thermometer',
                label = locale('radial.check_status'),
                onSelect = function()
                end,
            },
            {
                icon = 'person-arrows',
                label = locale('radial.escort'),
                onSelect = function()
                end,
            },
            {
                icon = 'heart-crack',
                label = locale('radial.ems_down_urgent'),
                onSelect = function()
                end,
            },
            {
                icon = 'heart-pulse',
                label = locale('radial.ems_down'),
                onSelect = function()
                end,
            },
        }
    })
end

local function registerDeadRadial()
    lib.registerRadial({
        id = 'emsMenu',
        items = {
            {
                icon = 'heart-crack',
                label = locale('radial.ems_down_urgent'),
                onSelect = function()
                end,
            },
            {
                icon = 'heart-pulse',
                label = locale('radial.ems_down'),
                onSelect = function()
                end,
            },
        }
    })
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if QBX.PlayerData.job.type ~= 'ems' then return end

    if QBX.PlayerData.metadata.isdead then
        registerDeadRadial()
    else
        registerAliveRadial()
    end

    lib.addRadialItem({
        id = 'ems',
        icon = 'stethoscope',
        label = locale('radial.label'),
        menu = 'emsMenu'
    })
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    lib.removeRadialItem('ems')

    if QBX.PlayerData.job.type ~= 'ems' then return end

    lib.addRadialItem({
        id = 'ems',
        icon = 'stethoscope',
        label = locale('radial.label'),
        menu = 'emsMenu'
    })
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('DEATH_STATE_STATE_BAG', nil, function(bagName, _, dead)
    local player = GetPlayerFromStateBagName(bagName)

    if player ~= cache.playerId or QBX.PlayerData?.job?.type ~= 'ems' then return end

    lib.removeRadialItem('ems')

    if dead then
        registerDeadRadial()
    else
        registerAliveRadial()
    end

    lib.addRadialItem({
        id = 'ems',
        icon = 'stethoscope',
        label = locale('radial.label'),
        menu = 'emsMenu'
    })
end)

CreateThread(function()
    Wait(150)

    for job, data in pairs(sharedConfig.hospitals) do
        createBlip(data.blip)
        createDuty(job, data.duty)
        createManagement(job, data.management)
        createSupplyCloset(job, data.armory)
        createPersonalStash(job, data.personalStash)
        createGarage(job, data.garage)
        createHelipad(job, data.helipad)
    end
end)