local QBCore = exports['qbx-core']:GetCoreObject()

---@class Player object from core

---@alias source number

local doctorCalled = false

---@param player Player
local function billPlayer(player)
	player.Functions.RemoveMoney("bank", Config.BillCost, "respawned-at-hospital")
	exports['qbx-management']:AddMoney("ambulance", Config.BillCost)
	TriggerClientEvent('hospital:client:SendBillEmail', player.PlayerData.source, Config.BillCost)
end

---@param player Player
local function wipeInventory(player)
	player.Functions.ClearInventory()
	TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { description = Lang:t('error.possessions_taken'), type = 'error' })
end

---@param player Player
---@param bedsKey "beds"|"jailbeds"
---@param i integer
---@param bed table Bed
local function respawnAtBed(player, bedsKey, i, bed)
	TriggerClientEvent('hospital:client:SendToBed', player.PlayerData.source, i, bed, true)
	TriggerClientEvent('hospital:client:SetBed', -1, bedsKey, i, true)
	if Config.WipeInventoryOnRespawn then
		wipeInventory(player)
	end
	billPlayer(player)
end

---@param player Player
---@param bedsKey "beds"|"jailbeds"
local function respawnAtHospital(player, bedsKey)
	local beds = Config.Locations[bedsKey]
	local closest, bedIndex = nil, 0
	for i, bed in pairs(beds) do
		if (not closest or closest > #(GetEntityCoords(cache.ped) - bed.coords)) and not bed.taken then
			closest = #(GetEntityCoords(cache.ped) - bed.coords)
			bedIndex = i
		end
	end
	respawnAtBed(player, bedsKey, bedIndex, beds[bedIndex])
end

local function respawn(src)
	local player = QBCore.Functions.GetPlayer(src)
	if player.PlayerData.metadata.injail > 0 then
		respawnAtHospital(player, "jailbeds")
	else
		respawnAtHospital(player, "beds")
	end
end

AddEventHandler('qbx-medical:server:playerRespawned', function(source)
	respawn(source)
end)

---@param bedId integer
---@param isRevive boolean
RegisterNetEvent('hospital:server:SendToBed', function(bedId, isRevive)
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	TriggerClientEvent('hospital:client:SendToBed', src, bedId, Config.Locations.beds[bedId], isRevive)
	TriggerClientEvent('hospital:client:SetBed', -1, "beds", bedId, true)
	billPlayer(player)
end)

local function alertAmbulance(src, text)
	local ped = GetPlayerPed(src)
	local coords = GetEntityCoords(ped)
	local players = QBCore.Functions.GetQBPlayers()
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

RegisterNetEvent('qbx-medical:server:onPlayerLaststand', function(text)
	if GetInvokingResource() then return end
	local src = source
	alertAmbulance(src, text)
end)

---@param id integer
RegisterNetEvent('hospital:server:LeaveBed', function(id)
	if GetInvokingResource() then return end
	TriggerClientEvent('hospital:client:SetBed', -1, "beds", id, false)
end)

---@param playerId number
RegisterNetEvent('hospital:server:TreatWounds', function(playerId)
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	local patient = QBCore.Functions.GetPlayer(playerId)
	if player.PlayerData.job.name ~= "ambulance" or not patient then return end

	player.Functions.RemoveItem('bandage', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['bandage'], "remove")
	TriggerClientEvent("hospital:client:HealInjuries", patient.PlayerData.source, "full")
end)

---@param playerId number
RegisterNetEvent('hospital:server:RevivePlayer', function(playerId)
	if GetInvokingResource() then return end
	local player = QBCore.Functions.GetPlayer(source)
	local patient = QBCore.Functions.GetPlayer(playerId)

	if not patient then return end
	player.Functions.RemoveItem('firstaid', 1)
	TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items['firstaid'], "remove")
	TriggerClientEvent('hospital:client:Revive', patient.PlayerData.source)
end)

RegisterNetEvent('hospital:server:SendDoctorAlert', function()
	if GetInvokingResource() then return end
	local src = source
	if doctorCalled then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('info.dr_needed'), type = 'inform' })
		return
	end

	doctorCalled = true
	local players = QBCore.Functions.GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('info.dr_needed'), type = 'inform' })
		end
	end
	SetTimeout(Config.DocCooldown * 60000, function()
		doctorCalled = false
	end)
end)

---@param targetId number
RegisterNetEvent('hospital:server:UseFirstAid', function(targetId)
	if GetInvokingResource() then return end
	local src = source
	local target = QBCore.Functions.GetPlayer(targetId)
	if not target then return end

	local canHelp = lib.callback.await('hospital:client:canHelp', targetId)
	if not canHelp then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.cant_help'), type = 'error' })
		return
	end

	TriggerClientEvent('hospital:client:HelpPerson', src, targetId)
end)

-- Callbacks

lib.callback.register('hospital:GetDoctors', function()
	local amount = 0
	local players = QBCore.Functions.GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			amount += 1
		end
	end
	return amount
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
	local players = QBCore.Functions.GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, message)
		end
	end
end)

---@param src number
---@param event string
local function triggerEventOnEmsPlayer(src, event)
	local player = QBCore.Functions.GetPlayer(src)
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
	local player = QBCore.Functions.GetPlayer(src)
	if player.Functions.GetItemByName(item.name) == nil then return end
	local removeItem = lib.callback.await(event, src)
	if not removeItem then return end
	player.Functions.RemoveItem(item.name, 1)
end

QBCore.Functions.CreateUseableItem("ifaks", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseIfaks')
end)

QBCore.Functions.CreateUseableItem("bandage", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseBandage')
end)

QBCore.Functions.CreateUseableItem("painkillers", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UsePainkillers')
end)

QBCore.Functions.CreateUseableItem("firstaid", function(source, item)
	triggerItemEventOnPlayer(source, item, 'hospital:client:UseFirstAid')
end)

RegisterNetEvent('qbx-medical:server:playerDied', function()
	if GetInvokingResource() then return end
	local src = source
	alertAmbulance(src, Lang:t('info.civ_died'))
end)