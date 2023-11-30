--- Contains code relevant to the physical hospital building. Things like checking in, beds, spawning vehicles, etc.

---@class Player object from core

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

---@param player Player
local function billPlayer(player)
	player.Functions.RemoveMoney("bank", sharedConfig.checkInCost, "respawned-at-hospital")
	exports.qbx_management:AddMoney("ambulance", sharedConfig.checkInCost)
	TriggerClientEvent('hospital:client:SendBillEmail', player.PlayerData.source, sharedConfig.checkInCost)
end

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

lib.callback.register('qbx_ambulancejob:server:isBedTaken', function(_, hospitalName, bedIndex)
	return hospitalBedsTaken[hospitalName][bedIndex]
end)

---@param player Player
local function wipeInventory(player)
	player.Functions.ClearInventory()
	TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { description = Lang:t('error.possessions_taken'), type = 'error' })
end

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

lib.callback.register('qbx_ambulancejob:server:canCheckIn', function(source, hospitalName)
	local numDoctors = exports.qbx_core:GetDutyCountType('ems')
	if numDoctors >= config.minForCheckIn then
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