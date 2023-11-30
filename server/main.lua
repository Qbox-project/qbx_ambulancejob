---@class Player object from core

---@alias source number

local config = require 'config.server'
local sharedConfig = require 'config.shared'
local triggerEventHooks = require '@qbx_core.modules.hooks'
local doctorCalled = false

---@type table<string, table<number, boolean>>
local hospitalBedsTaken = {}
for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
	hospitalBedsTaken[hospitalName] = {}
	for i = 1, #hospital.beds do
		hospitalBedsTaken[hospitalName][i] = false
	end
end

---@param player Player
local function billPlayer(player)
	player.Functions.RemoveMoney("bank", sharedConfig.checkInCost, "respawned-at-hospital")
	exports.qbx_management:AddMoney("ambulance", sharedConfig.checkInCost)
	TriggerClientEvent('hospital:client:SendBillEmail', player.PlayerData.source, sharedConfig.checkInCost)
end

---@param player Player
local function wipeInventory(player)
	player.Functions.ClearInventory()
	TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { description = Lang:t('error.possessions_taken'), type = 'error' })
end

local function getOpenBed(hospitalName)
	local beds = hospitalBedsTaken[hospitalName]
	for i = 1, #beds do
		local isTaken = beds[i]
		if not isTaken then return i end
	end
end

lib.callback.register('qbx_ambulancejob:server:getOpenBed', function(_, hospitalName)
	return getOpenBed(hospitalName)
end)

lib.callback.register('qbx_ambulancejob:server:spawnVehicle', function(source, vehicleName, vehicleCoords)
	local netId = SpawnVehicle(source, vehicleName, vehicleCoords, true)
	return netId
end)

local function respawn(src)
	local player = exports.qbx_core:GetPlayer(src)
	local closestHospital = nil
	if player.PlayerData.metadata.injail > 0 then
		closestHospital = "jail"
	else
		local coords = GetEntityCoords(GetPlayerPed(src))
		local closest = nil

		for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
			if hospitalName ~= 'jail' then
				if not closest or #(coords - hospital.coords) < #(coords - closest) then
					closest = hospital.coords
					closestHospital = hospitalName
				end
			end
		end
	end

	local bedIndex = getOpenBed(closestHospital)
	if not bedIndex then
		---TODO: handle hospital being out of beds. Could send them to backup hospital or notify to wait.
		return
	end

	if config.wipeInvOnRespawn then
		wipeInventory(player)
	end
	TriggerClientEvent('qbx_ambulancejob:client:onPlayerRespawn', src, closestHospital, bedIndex)
end

AddEventHandler('qbx_medical:server:playerRespawned', function(source)
	respawn(source)
end)

lib.callback.register('qbx_ambulancejob:server:isBedTaken', function(_, hospitalName, bedIndex)
	return hospitalBedsTaken[hospitalName][bedIndex]
end)

lib.callback.register('qbx_ambulancejob:server:getPlayerStatus', function(_, targetSrc)
	return exports.qbx_medical:getPlayerStatus(targetSrc)
end)

local function alertAmbulance(src, text)
	local ped = GetPlayerPed(src)
	local coords = GetEntityCoords(ped)
	local players = exports.qbx_core:GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, text)
		end
	end
end

RegisterNetEvent('hospital:server:ambulanceAlert', function()
	if GetInvokingResource() then return end
	local src = source
	alertAmbulance(src, Lang:t('info.civ_down'))
end)

RegisterNetEvent('qbx_medical:server:onPlayerLaststand', function(text)
	if GetInvokingResource() then return end
	local src = source
	alertAmbulance(src, text)
end)

RegisterNetEvent('qbx_ambulancejob:server:playerEnteredBed', function(hospitalName, bedIndex)
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	billPlayer(player)
	hospitalBedsTaken[hospitalName][bedIndex] = true
end)

RegisterNetEvent('qbx_ambulancejob:server:playerLeftBed', function(hospitalName, bedIndex)
	if GetInvokingResource() then return end
	hospitalBedsTaken[hospitalName][bedIndex] = false
end)

---@param playerId number
RegisterNetEvent('hospital:server:TreatWounds', function(playerId)
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local patient = exports.qbx_core:GetPlayer(playerId)
	if player.PlayerData.job.name ~= "ambulance" or not patient then return end

	player.Functions.RemoveItem('bandage', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, exports.ox_inventory:Items()['bandage'], "remove")
	TriggerClientEvent("hospital:client:HealInjuries", patient.PlayerData.source, "full")
end)

---@param playerId number
RegisterNetEvent('hospital:server:RevivePlayer', function(playerId)
	if GetInvokingResource() then return end
	local player = exports.qbx_core:GetPlayer(source)
	local patient = exports.qbx_core:GetPlayer(playerId)

	if not patient then return end
	player.Functions.RemoveItem('firstaid', 1)
	TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, exports.ox_inventory:Items()['firstaid'], "remove")
	TriggerClientEvent('hospital:client:Revive', patient.PlayerData.source)
end)

---@param playerId number
RegisterNetEvent('hospital:server:putPlayerInBed', function(playerId, hospitalName, bedIndex)
	if GetInvokingResource() then return end
	local patient = exports.qbx_core:GetPlayer(playerId)

	if not patient then return end
	TriggerClientEvent('qbx_ambulancejob:client:putPlayerInBed', patient.PlayerData.source, hospitalName, bedIndex)
end)

local function sendDoctorAlert()
	if doctorCalled then return end
	doctorCalled = true
	local _, doctors = exports.qbx_core:GetDutyCountType('ems')
	for i = 1, #doctors do
		local doctor = doctors[i]
		TriggerClientEvent('ox_lib:notify', doctor, { description = Lang:t('info.dr_needed'), type = 'inform' })
	end

	SetTimeout(config.doctorCallCooldown * 60000, function()
		doctorCalled = false
	end)
end

---@param targetId number
RegisterNetEvent('hospital:server:UseFirstAid', function(targetId)
	if GetInvokingResource() then return end
	local src = source
	local target = exports.qbx_core:GetPlayer(targetId)
	if not target then return end

	local canHelp = lib.callback.await('hospital:client:canHelp', targetId)
	if not canHelp then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.cant_help'), type = 'error' })
		return
	end

	TriggerClientEvent('hospital:client:HelpPerson', src, targetId)
end)

-- Callbacks

lib.callback.register('qbx_ambulancejob:server:getNumDoctors', function()
	local count = exports.qbx_core:GetDutyCountType('ems')
	return count
end)

lib.callback.register('qbx_ambulancejob:server:canCheckIn', function(source, hospitalName)
	local numDoctors = exports.qbx_core:GetDutyCountType('ems')
	if numDoctors < config.minForCheckIn then
		TriggerClientEvent('ox_lib:notify', source, { description = Lang:t('info.dr_alert'), type = 'inform' })
		sendDoctorAlert()
		return false
	end

	if not triggerEventHooks('checkIn', {
		source = source,
		hospitalName = hospitalName,
	}) then return false end

	return true
end)

-- Commands

lib.addCommand('911e', {
    help = Lang:t('info.ems_report'),
    params = {
        { name = 'message', help = Lang:t('info.message_sent'), type = 'string', optional = true},
    }
}, function(source, args)
	local message = args.message or Lang:t('info.civ_call')
	local ped = GetPlayerPed(source)
	local coords = GetEntityCoords(ped)
	local players = exports.qbx_core:GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, message)
		end
	end
end)

---@param src number
---@param event string
local function triggerEventOnEmsPlayer(src, event)
	local player = exports.qbx_core:GetPlayer(src)
	if player.PlayerData.job.name ~= "ambulance" then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.not_ems'), type = 'error' })
		return
	end

	TriggerClientEvent(event, src)
end

lib.addCommand('status', {
    help = Lang:t('info.check_health'),
}, function(source)
	triggerEventOnEmsPlayer(source, 'hospital:client:CheckStatus')
end)

lib.addCommand('heal', {
    help = Lang:t('info.heal_player'),
}, function(source)
	triggerEventOnEmsPlayer(source, 'hospital:client:TreatWounds')
end)

lib.addCommand('revivep', {
    help = Lang:t('info.revive_player'),
}, function(source)
	triggerEventOnEmsPlayer(source, 'hospital:client:RevivePlayer')
end)

-- Items
---@param src number
---@param item table
---@param event string
local function triggerItemEventOnPlayer(src, item, event)
	local player = exports.qbx_core:GetPlayer(src)
	if player.Functions.GetItemByName(item.name) == nil then return end
	local removeItem = lib.callback.await(event, src)
	if not removeItem then return end
	player.Functions.RemoveItem(item.name, 1)
end

exports.qbx_core:CreateUseableItem("ifaks", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseIfaks')
end)

exports.qbx_core:CreateUseableItem("bandage", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseBandage')
end)

exports.qbx_core:CreateUseableItem("painkillers", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UsePainkillers')
end)

exports.qbx_core:CreateUseableItem("firstaid", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseFirstAid')
end)

RegisterNetEvent('qbx_medical:server:playerDied', function()
	if GetInvokingResource() then return end
	local src = source
	alertAmbulance(src, Lang:t('info.civ_died'))
end)
