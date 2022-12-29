local PlayerInjuries = {}
local PlayerWeaponWounds = {}
local QBCore = exports['qb-core']:GetCoreObject()
local doctorCount = 0
local doctorCalled = false
local Doctors = {}

-- Events

-- Compatibility with txAdmin Menu's heal options.
-- This is an admin only server side event that will pass the target player id or -1.
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
		return
	end

	TriggerClientEvent('hospital:client:Revive', eventData.id)
	TriggerClientEvent("hospital:client:HealInjuries", eventData.id, "full")
end)

local function billPlayer(player)
	player.Functions.RemoveMoney("bank", Config.BillCost, "respawned-at-hospital")
	exports['qb-management']:AddMoney("ambulance", Config.BillCost)
	TriggerClientEvent('hospital:client:SendBillEmail', player.PlayerData.source, Config.BillCost)
end

local function wipeInventory(player)
	player.Functions.ClearInventory()
	MySQL.update('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode({}), player.PlayerData.citizenid })
	TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { description = Lang:t('error.possessions_taken'), type = 'error' })
end

local function respawnAtBed(player, setBedEventName, i, bed)
	TriggerClientEvent('hospital:client:SendToBed', player.PlayerData.source, i, bed, true)
	TriggerClientEvent(setBedEventName, -1, i, true)
	if Config.WipeInventoryOnRespawn then
		wipeInventory(player)
	end
	billPlayer(player)
end

local function respawnAtHospital(player, beds, setBedEventName)
	for i, bed in pairs(beds) do
		if not bed.taken then
			respawnAtBed(player, setBedEventName, i, bed)
			return
		end
	end
	respawnAtBed(player, 'hospital:client:SetBed')
end

RegisterNetEvent('hospital:server:RespawnAtHospital', function()
	local player = QBCore.Functions.GetPlayer(source)
	if player.PlayerData.metadata.injail > 0 then
		respawnAtHospital(player, Config.Locations.jailbeds, 'hospital:client:SetBed2')
	else
		respawnAtHospital(player, Config.Locations.beds, 'hospital:client:SetBed')
	end
end)

RegisterNetEvent('hospital:server:SendToBed', function(bedId, isRevive)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	TriggerClientEvent('hospital:client:SendToBed', src, bedId, Config.Locations["beds"][bedId], isRevive)
	TriggerClientEvent('hospital:client:SetBed', -1, bedId, true)
	billPlayer(player)
end)

RegisterNetEvent('hospital:server:ambulanceAlert', function(text)
	local src = source
	local ped = GetPlayerPed(src)
	local coords = GetEntityCoords(ped)
	local players = QBCore.Functions.GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, text)
		end
	end
end)

RegisterNetEvent('hospital:server:LeaveBed', function(id)
	TriggerClientEvent('hospital:client:SetBed', -1, id, false)
end)

RegisterNetEvent('hospital:server:SyncInjuries', function(data)
	local src = source
	PlayerInjuries[src] = data
end)

RegisterNetEvent('hospital:server:SetWeaponDamage', function(data)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	PlayerWeaponWounds[player.PlayerData.source] = data
end)

RegisterNetEvent('hospital:server:RestoreWeaponDamage', function()
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	PlayerWeaponWounds[player.PlayerData.source] = nil
end)

RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("isdead", isDead)
end)

RegisterNetEvent('hospital:server:SetLaststandStatus', function(bool)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("inlaststand", bool)
end)

RegisterNetEvent('hospital:server:SetArmor', function(amount)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("armor", amount)
end)

RegisterNetEvent('hospital:server:TreatWounds', function(playerId)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	local patient = QBCore.Functions.GetPlayer(playerId)
	if player.PlayerData.job.name ~= "ambulance" or not patient then return end
	
	player.Functions.RemoveItem('bandage', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['bandage'], "remove")
	TriggerClientEvent("hospital:client:HealInjuries", patient.PlayerData.source, "full")
end)

RegisterNetEvent('hospital:server:AddDoctor', function(job)
	if job ~= 'ambulance' then return end
	
	local src = source
	doctorCount += 1
	TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
	Doctors[src] = true
end)

RegisterNetEvent('hospital:server:RemoveDoctor', function(job)
	if job ~= 'ambulance' then return end
	
	local src = source
	doctorCount -= 1
	TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
	Doctors[src] = nil
end)

AddEventHandler("playerDropped", function()
	local src = source
	if not Doctors[src] then return end
	
	doctorCount -= 1
	TriggerClientEvent("hospital:client:SetDoctorCount", -1, doctorCount)
	Doctors[src] = nil
end)

RegisterNetEvent('hospital:server:RevivePlayer', function(playerId)
	local player = QBCore.Functions.GetPlayer(source)
	local patient = QBCore.Functions.GetPlayer(playerId)

	if not patient then return end
	player.Functions.RemoveItem('firstaid', 1)
	TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items['firstaid'], "remove")
	TriggerClientEvent('hospital:client:Revive', patient.PlayerData.source)
end)

RegisterNetEvent('hospital:server:SendDoctorAlert', function()
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

RegisterNetEvent('hospital:server:UseFirstAid', function(targetId)
	local src = source
	local target = QBCore.Functions.GetPlayer(targetId)
	if not target then return end
	
	TriggerClientEvent('hospital:client:CanHelp', targetId, src)
end)

RegisterNetEvent('hospital:server:CanHelp', function(helperId, canHelp)
	local src = source
	if not canHelp then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.cant_help'), type = 'error' })
		return
	end

	TriggerClientEvent('hospital:client:HelpPerson', helperId, src)
end)

local function removeItem(src, itemName)
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.RemoveItem(itemName, 1)
end

RegisterNetEvent('hospital:server:removeBandage', function()
	removeItem(source, 'bandage')
end)

RegisterNetEvent('hospital:server:removeIfaks', function()
	removeItem(source, 'ifaks')
end)

RegisterNetEvent('hospital:server:removePainkillers', function()
	removeItem(source, 'painkillers')
end)

RegisterNetEvent('hospital:server:resetHungerThirst', function()
	local player = QBCore.Functions.GetPlayer(source)

	if not player then return end

	player.Functions.SetMetaData('hunger', 100)
	player.Functions.SetMetaData('thirst', 100)

	TriggerClientEvent('hud:client:UpdateNeeds', source, 100, 100)
end)

-- Callbacks

QBCore.Functions.CreateCallback('hospital:GetDoctors', function(_, cb)
	local amount = 0
	local players = QBCore.Functions.GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			amount += 1
		end
	end
	cb(amount)
end)

QBCore.Functions.CreateCallback('hospital:GetPlayerStatus', function(_, cb, playerId)
	local playerSource = QBCore.Functions.GetPlayer(playerId).PlayerData.source
	local injuries = {}
	injuries["WEAPONWOUNDS"] = {}
	if not playerSource then cb(injuries) return end

	local playerInjuries = PlayerInjuries[playerSource]
	if playerInjuries then
		if (playerInjuries.isBleeding > 0) then
			injuries["BLEED"] = playerInjuries.isBleeding
		end
		for k, v in pairs(playerInjuries.limbs) do
			if v.isDamaged then
				injuries[k] = v
			end
		end
	end
	
	local playerWeaponWounds = PlayerWeaponWounds[playerSource]
	if playerWeaponWounds then
		for k, v in pairs(playerWeaponWounds) do
			injuries["WEAPONWOUNDS"][k] = v
		end
	end
	cb(injuries)
end)

QBCore.Functions.CreateCallback('hospital:GetPlayerBleeding', function(source, cb)
	local src = source
	local injuries = PlayerInjuries[src]
	if not injuries or injuries.isBleeding == nil then
		cb(nil)
		return
	end

	cb(injuries.isBleeding)
end)

-- Commands

QBCore.Commands.Add('911e', Lang:t('info.ems_report'), { { name = 'message', help = Lang:t('info.message_sent') } }, false, function(source, args)
	local src = source
	local message = args[1] and table.concat(args, " ") or Lang:t('info.civ_call')
	local ped = GetPlayerPed(src)
	local coords = GetEntityCoords(ped)
	local players = QBCore.Functions.GetQBPlayers()
	for _, v in pairs(players) do
		if v.PlayerData.job.name == 'ambulance' and v.PlayerData.job.onduty then
			TriggerClientEvent('hospital:client:ambulanceAlert', v.PlayerData.source, coords, message)
		end
	end
end)

local function triggerEventOnEmsPlayer(src, event)
	local player = QBCore.Functions.GetPlayer(src)
	if player.PlayerData.job.name ~= "ambulance" then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.not_ems'), type = 'error' })
		return
	end

	TriggerClientEvent(event, src)
end

QBCore.Commands.Add("status", Lang:t('info.check_health'), {}, false, function(source, _)
	local src = source
	triggerEventOnEmsPlayer(src, 'hospital:client:CheckStatus')
end)

QBCore.Commands.Add("heal", Lang:t('info.heal_player'), {}, false, function(source, _)
	local src = source
	triggerEventOnEmsPlayer(src, 'hospital:client:TreatWounds')
end)

QBCore.Commands.Add("revivep", Lang:t('info.revive_player'), {}, false, function(source, _)
	local src = source
	triggerEventOnEmsPlayer(src, 'hospital:client:RevivePlayer')
end)

--- Triggers the event on the player or src, if no target is specified
---@param src number playerId of the one triggering the event
---@param event string event name
---@param targetPlayerId? string playerId of the target of the event
local function triggerEventOnPlayer(src, event, targetPlayerId)
	if not targetPlayerId then
		TriggerClientEvent(event, src)
		return
	end

	local player = QBCore.Functions.GetPlayer(tonumber(targetPlayerId))

	if not player then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.not_online'), type = 'error' })
		return
	end
		
	TriggerClientEvent(event, player.PlayerData.source)
end

QBCore.Commands.Add("revive", Lang:t('info.revive_player_a'), { { name = "id", help = Lang:t('info.player_id') } }, false, function(source, args)
	local src = source
	triggerEventOnPlayer(src, 'hospital:client:Revive', args[1])
end, "admin")

QBCore.Commands.Add("setpain", Lang:t('info.pain_level'), { { name = "id", help = Lang:t('info.player_id') } }, false, function(source, args)
	local src = source
	triggerEventOnPlayer(src, 'hospital:client:SetPain', args[1])
end, "admin")

QBCore.Commands.Add("kill", Lang:t('info.kill'), { { name = "id", help = Lang:t('info.player_id') } }, false, function(source, args)
	local src = source
	triggerEventOnPlayer(src, 'hospital:client:KillPlayer', args[1])
end, "admin")

QBCore.Commands.Add('aheal', Lang:t('info.heal_player_a'), { { name = 'id', help = Lang:t('info.player_id') } }, false, function(source, args)
	local src = source
	triggerEventOnPlayer(src, 'hospital:client:adminHeal', args[1])
end, 'admin')

-- Items
local function triggerItemEventOnPlayer(src, item, event)
	local player = QBCore.Functions.GetPlayer(src)
	if player.Functions.GetItemByName(item.name) == nil then return end
	TriggerClientEvent(event, src)
end

QBCore.Functions.CreateUseableItem("ifaks", function(source, item)
	local src = source
	triggerItemEventOnPlayer(src, item, 'hospital:client:UseIfaks')
end)

QBCore.Functions.CreateUseableItem("bandage", function(source, item)
	local src = source
	triggerItemEventOnPlayer(src, item, 'hospital:client:UseBandage')
end)

QBCore.Functions.CreateUseableItem("painkillers", function(source, item)
	local src = source
	triggerItemEventOnPlayer(src, item, 'hospital:client:UsePainkillers')
end)

QBCore.Functions.CreateUseableItem("firstaid", function(source, item)
	local src = source
	triggerItemEventOnPlayer(src, item, 'hospital:client:UseFirstAid')
end)

exports('GetDoctorCount', function() return doctorCount end)
