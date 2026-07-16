--- Contains code relevant to the physical hospital building. Things like checking in, beds, spawning vehicles, etc.

---@class Player object from core

local config = require 'config.server'
local clientConfig = require 'config.client'
local sharedConfig = require 'config.shared'
local triggerEventHooks = require '@qbx_core.modules.hooks'
local doctorCalled = false
local spawnedVehicles = {}
local vehiclesSpawning = {}

---@type table<string, table<number, boolean | number>>
local hospitalBedsTaken = {}

for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
	hospitalBedsTaken[hospitalName] = {}
	for i = 1, #hospital.beds do
		hospitalBedsTaken[hospitalName][i] = false
	end
end

local function getHospitalBed(hospitalName, bedIndex)
	if type(hospitalName) ~= 'string' or type(bedIndex) ~= 'number' or bedIndex % 1 ~= 0 then return end

	local hospital = sharedConfig.locations.hospitals[hospitalName]
	local bed = hospital and hospital.beds[bedIndex]
	if not bed then return end

	return hospital, bed
end

local function isPlayerNearCoords(source, coords, distance)
	local ped = GetPlayerPed(source)
	if ped == 0 then return false end

	return #(GetEntityCoords(ped) - vec3(coords.x, coords.y, coords.z)) <= distance
end

local function isPlayerNearCheckIn(source, hospital)
	if not hospital.checkIn then return false end

	if type(hospital.checkIn) ~= 'table' then
		return isPlayerNearCoords(source, hospital.checkIn, 5.0)
	end

	for i = 1, #hospital.checkIn do
		if isPlayerNearCoords(source, hospital.checkIn[i], 5.0) then return true end
	end

	return false
end

local function isPlayerInBed(source)
	for hospitalName, beds in pairs(hospitalBedsTaken) do
		for bedIndex = 1, #beds do
			if beds[bedIndex] == source then return hospitalName, bedIndex end
		end
	end
end

local function clearPlayerBed(source)
	local hospitalName, bedIndex = isPlayerInBed(source)
	if hospitalName then hospitalBedsTaken[hospitalName][bedIndex] = false end
end

local function reserveBed(source, hospitalName, bedIndex)
	if isPlayerInBed(source) or hospitalBedsTaken[hospitalName][bedIndex] then return false end

	hospitalBedsTaken[hospitalName][bedIndex] = source
	return true
end

local function getOpenBed(hospitalName)
	local beds = hospitalBedsTaken[hospitalName]
	if not beds then return end

	for i = 1, #beds do
		local isTaken = beds[i]
		if not isTaken then return i end
	end
end

lib.callback.register('qbx_ambulancejob:server:getOpenBed', function(_, hospitalName)
	return getOpenBed(hospitalName)
end)

---@param src number
local function billPlayer(src)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end

	if not player.Functions.RemoveMoney('bank', sharedConfig.checkInCost, 'respawned-at-hospital') then return end
	config.depositSociety('ambulance', sharedConfig.checkInCost)
	TriggerClientEvent('hospital:client:SendBillEmail', src, sharedConfig.checkInCost)
end

RegisterNetEvent('qbx_ambulancejob:server:playerLeftBed', function(hospitalName, bedIndex)
	if GetInvokingResource() then return end
	local _, bed = getHospitalBed(hospitalName, bedIndex)
	if not bed or hospitalBedsTaken[hospitalName][bedIndex] ~= source then return end

	hospitalBedsTaken[hospitalName][bedIndex] = false
end)

---@param playerId number
RegisterNetEvent('hospital:server:putPlayerInBed', function(playerId, hospitalName, bedIndex)
	if GetInvokingResource() then return end
	if type(playerId) ~= 'number' then return end

	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	local patient = exports.qbx_core:GetPlayer(playerId)
	local _, bed = getHospitalBed(hospitalName, bedIndex)
	if not player or player.PlayerData.job.type ~= 'ems' or not player.PlayerData.job.onduty or not patient or not bed then return end
	if not isPlayerNearCoords(src, bed.coords, 5.0) or not isPlayerNearCoords(playerId, bed.coords, 5.0) then return end
	if not reserveBed(playerId, hospitalName, bedIndex) then return end

	TriggerClientEvent('qbx_ambulancejob:client:putPlayerInBed', playerId, hospitalName, bedIndex)
end)

lib.callback.register('qbx_ambulancejob:server:isBedTaken', function(_, hospitalName, bedIndex)
	local _, bed = getHospitalBed(hospitalName, bedIndex)
	if not bed then return true end

	return hospitalBedsTaken[hospitalName][bedIndex]
end)

---@param src number
local function wipeInventory(src)
	exports.ox_inventory:ClearInventory(src)
	exports.qbx_core:Notify(src, locale('error.possessions_taken'), 'error')
end

local function getAuthorizedVehicleSpawn(player, vehicleName)
	local grade = player.PlayerData.job.grade.level
	local ped = GetPlayerPed(player.PlayerData.source)
	if ped == 0 then return end

	local playerCoords = GetEntityCoords(ped)
	local vehicleGroups = {
		{ vehicles = clientConfig.authorizedVehicles[grade], locations = sharedConfig.locations.vehicle },
		{ vehicles = clientConfig.authorizedHelicopters[grade], locations = sharedConfig.locations.helicopter }
	}

	for i = 1, #vehicleGroups do
		local group = vehicleGroups[i]
		if group.vehicles and group.vehicles[vehicleName] then
			for j = 1, #group.locations do
				local coords = group.locations[j]
				if #(playerCoords - coords.xyz) <= 7.5 then return coords end
			end
		end
	end
end

lib.callback.register('qbx_ambulancejob:server:spawnVehicle', function(source, vehicleName)
	if type(vehicleName) ~= 'string' then return end

	local player = exports.qbx_core:GetPlayer(source)
	if not player or player.PlayerData.job.type ~= 'ems' or not player.PlayerData.job.onduty then return end

	local existingVehicle = spawnedVehicles[source]
	if vehiclesSpawning[source] or existingVehicle and DoesEntityExist(existingVehicle) then return end

	local vehicleCoords = getAuthorizedVehicleSpawn(player, vehicleName)
	if not vehicleCoords then return end

	vehiclesSpawning[source] = true
	local netId, veh = qbx.spawnVehicle({ spawnSource = vehicleCoords, model = vehicleName, warp = GetPlayerPed(source)})
	vehiclesSpawning[source] = nil
	if not netId or not veh or veh == 0 then return end
	if not exports.qbx_core:GetPlayer(source) then
		DeleteEntity(veh)
		return
	end
	spawnedVehicles[source] = veh

	local vehType = GetVehicleType(veh)
	local platePrefix = (vehType == 'heli') and locale('info.heli_plate') or locale('info.amb_plate')
	local plate = platePrefix .. tostring(math.random(1000, 9999))

	SetVehicleNumberPlateText(veh, plate)
	TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
	return netId
end)

local function sendDoctorAlert()
	if doctorCalled then return end
	doctorCalled = true
	local _, doctors = exports.qbx_core:GetDutyCountType('ems')
	for i = 1, #doctors do
		local doctor = doctors[i]
		exports.qbx_core:Notify(doctor, locale('info.dr_needed'), 'inform')
	end

	SetTimeout(config.doctorCallCooldown * 60000, function()
		doctorCalled = false
	end)
end

local function canCheckIn(source, hospitalName)
	local hospital = type(hospitalName) == 'string' and sharedConfig.locations.hospitals[hospitalName]
	if not hospital or not isPlayerNearCheckIn(source, hospital) then return false end

	local numDoctors = exports.qbx_core:GetDutyCountType('ems')
	if numDoctors >= sharedConfig.minForCheckIn then
		exports.qbx_core:Notify(source, locale('info.dr_alert'), 'inform')
		sendDoctorAlert()
		return false
	end

	if not triggerEventHooks('checkIn', { source = source, hospitalName = hospitalName }) then return false end

	return true
end

lib.callback.register('qbx_ambulancejob:server:canCheckIn', canCheckIn)

---Sends the patient to an open bed within the hospital
---@param src number the player doing the checking in
---@param patientSrc number the player being checked in
---@param hospitalName string name of the hospital matching the config where player should be placed
local function checkIn(src, patientSrc, hospitalName)
	if type(patientSrc) ~= 'number' then return false end

	local hospital = type(hospitalName) == 'string' and sharedConfig.locations.hospitals[hospitalName]
	if not hospital or not exports.qbx_core:GetPlayer(patientSrc) then return false end
	if src == patientSrc and not canCheckIn(patientSrc, hospitalName) then return false end

	local bedIndex = getOpenBed(hospitalName)
	if not bedIndex then
		exports.qbx_core:Notify(src, locale('error.beds_taken'), 'error')
		return false
	end
	if not reserveBed(patientSrc, hospitalName, bedIndex) then return false end

	billPlayer(patientSrc)
	TriggerClientEvent('qbx_ambulancejob:client:checkedIn', patientSrc, hospitalName, bedIndex)
	return true
end

lib.callback.register('qbx_ambulancejob:server:checkIn', function(source, _, hospitalName)
	return checkIn(source, source, hospitalName)
end)

exports('CheckIn', checkIn)

local function respawn(src)
	local player = exports.qbx_core:GetPlayer(src)
	local closestHospital
	if player.PlayerData.metadata.injail > 0 then
		closestHospital = 'jail'
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

	clearPlayerBed(src)
	local bedIndex = getOpenBed(closestHospital)
	if not bedIndex then
		exports.qbx_core:Notify(src, locale('error.beds_taken'), 'error')
		return
	end
	if not reserveBed(src, closestHospital, bedIndex) then return end
	billPlayer(src)
	TriggerClientEvent('qbx_ambulancejob:client:checkedIn', src, closestHospital, bedIndex)

	if config.wipeInvOnRespawn then
		wipeInventory(src)
	end
end

AddEventHandler('qbx_medical:server:playerRespawned', respawn)

AddEventHandler('playerDropped', function()
	clearPlayerBed(source)

	local vehicle = spawnedVehicles[source]
	if vehicle and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
	spawnedVehicles[source] = nil
	vehiclesSpawning[source] = nil
end)
