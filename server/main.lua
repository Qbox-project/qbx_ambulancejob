local config = require 'config.server'
local sharedConfig = require 'config.shared'

---@param job? string
---@param hospital? PersonalStashData
local function registerPersonalStash(job, hospital)
    if not job or not hospital then return end

    for i = 1, #hospital do
        local stash = hospital[i]
        local stashId = ('%s-PersonalStash'):format(job)

        exports.ox_inventory:RegisterStash(stashId, stash.label, stash.slots or 100, stash.weight or 100000, true, stash.groups, stash.coords)
    end
end

---@param hospital? ClosetData
local function registerSupplyCloset(hospital)
    if not hospital then return end

    for i = 1, #hospital do
        local closet = hospital[i]

        exports.ox_inventory:RegisterShop(closet.shopType, closet)
    end
end

---@param source number
---@param vehicle table
---@param spawn vector4
lib.callback.register('qbx_ems:server:spawnVehicle', function(source, vehicle, spawn)
    local ped = GetPlayerPed(source)
    local plate = ('EMS%s'):format(math.random(10000, 99999))
    local netId, _ = qbx.spawnVehicle({
        spawnSource = spawn,
        model = vehicle.name,
        warp = ped,
        props = {
            plate = plate,
            modLivery = vehicle.livery or 0
        }
    })

    config.giveVehicleKeys(source, plate)

    return netId
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= cache.resource then return end

    for job, data in pairs(sharedConfig.hospitals) do
        registerSupplyCloset(data.armory)
        registerPersonalStash(job, data.personalStash)
    end
end)