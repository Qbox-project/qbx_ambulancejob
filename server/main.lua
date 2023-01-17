local QBCore = exports['qb-core']:GetCoreObject()

---@class Player object from core

---@alias source number

---@class PlayerStatus
---@field limbs BodyParts
---@field isBleeding number

---@type table<source, PlayerStatus>
local playerStatus = {}

---@type table<source, number[]> weapon hashes
local playerWeaponWounds = {}

local doctorCalled = false


-- Events

---Compatibility with txAdmin Menu's heal options.
---This is an admin only server side event that will pass the target player id or -1.
---@class EventData
---@field id number
---@param eventData EventData
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
		return
	end

	TriggerClientEvent('hospital:client:Revive', eventData.id)
	TriggerClientEvent("hospital:client:HealInjuries", eventData.id, "full")
end)

---@param player Player
local function billPlayer(player)
	player.Functions.RemoveMoney("bank", Config.BillCost, "respawned-at-hospital")
	exports['qb-management']:AddMoney("ambulance", Config.BillCost)
	TriggerClientEvent('hospital:client:SendBillEmail', player.PlayerData.source, Config.BillCost)
end

---@param player Player
local function wipeInventory(player)
	player.Functions.ClearInventory()
	MySQL.update('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode({}), player.PlayerData.citizenid })
	TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { description = Lang:t('error.possessions_taken'), type = 'error' })
end

---@param player Player
---@param bedsKey "beds"|"jailbeds"
---@param i integer
---@param bed Bed
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
	for i, bed in pairs(beds) do
		if not bed.taken then
			respawnAtBed(player, bedsKey, i, bed)
			return
		end
	end
	respawnAtBed(player, bedsKey)
end

RegisterNetEvent('hospital:server:RespawnAtHospital', function()
	local player = QBCore.Functions.GetPlayer(source)
	if player.PlayerData.metadata.injail > 0 then
		respawnAtHospital(player, "jailbeds")
	else
		respawnAtHospital(player, "beds")
	end
end)

---@param bedId integer
---@param isRevive boolean
RegisterNetEvent('hospital:server:SendToBed', function(bedId, isRevive)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	TriggerClientEvent('hospital:client:SendToBed', src, bedId, Config.Locations.beds[bedId], isRevive)
	TriggerClientEvent('hospital:client:SetBed', -1, "beds", bedId, true)
	billPlayer(player)
end)

---@param text string
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

---@param id integer
RegisterNetEvent('hospital:server:LeaveBed', function(id)
	TriggerClientEvent('hospital:client:SetBed', -1, "beds", id, false)
end)

---@param data Injury
RegisterNetEvent('hospital:server:SyncInjuries', function(data)
	local src = source
	playerStatus[src] = data
end)

---@param data number[] weapon hashes
RegisterNetEvent('hospital:server:SetWeaponDamage', function(data)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	playerWeaponWounds[player.PlayerData.source] = data
end)

RegisterNetEvent('hospital:server:RestoreWeaponDamage', function()
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	playerWeaponWounds[player.PlayerData.source] = nil
end)

---@param isDead boolean
RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("isdead", isDead)
end)

---@param bool boolean
RegisterNetEvent('hospital:server:SetLaststandStatus', function(bool)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("inlaststand", bool)
end)

---@param amount number
RegisterNetEvent('hospital:server:SetArmor', function(amount)
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("armor", amount)
end)

---@param playerId number
RegisterNetEvent('hospital:server:TreatWounds', function(playerId)
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

---@param targetId number
RegisterNetEvent('hospital:server:UseFirstAid', function(targetId)
	local src = source
	local target = QBCore.Functions.GetPlayer(targetId)
	if not target then return end

	TriggerClientEvent('hospital:client:CanHelp', targetId, src)
end)

---@param helperId number
---@param canHelp boolean
RegisterNetEvent('hospital:server:CanHelp', function(helperId, canHelp)
	local src = source
	if not canHelp then
		TriggerClientEvent('ox_lib:notify', src, { description = Lang:t('error.cant_help'), type = 'error' })
		return
	end

	TriggerClientEvent('hospital:client:HelpPerson', helperId, src)
end)

---@param src number
---@param itemName string
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

---@param _ any
---@param cb function
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

---@param limbs BodyParts
---@return BodyParts
local function getDamagedBodyParts(limbs)
	local bodyParts = {}
	for bone, bodyPart in pairs(limbs) do
		if bodyPart.isDamaged then
			bodyParts[bone] = bodyPart
		end
	end
	return bodyParts
end

---@param _ any
---@param cb fun(damage: PlayerDamage)
---@param playerId number
QBCore.Functions.CreateCallback('hospital:GetPlayerStatus', function(_, cb, playerId)
	local playerSource = QBCore.Functions.GetPlayer(playerId).PlayerData.source

	---@class PlayerDamage
	---@field damagedBodyParts BodyParts
	---@field bleedLevel number
	---@field weaponWounds number[]

	---@type PlayerDamage
	local damage = {
		damagedBodyParts = {},
		bleedLevel = 0,
		weaponWounds = {}
	}
	if not playerSource then cb(damage) return end

	local playerInjuries = playerStatus[playerSource]
	if playerInjuries then
		damage.bleedLevel = playerInjuries.isBleeding or 0
		damage.damagedBodyParts = getDamagedBodyParts(playerInjuries.limbs)
	end

	damage.weaponWounds = playerWeaponWounds[playerSource] or {}
	cb(damage)
end)

---@param source number
---@param cb function
QBCore.Functions.CreateCallback('hospital:GetPlayerBleeding', function(source, cb)
	local src = source
	local injuries = playerStatus[src]
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

---Triggers the event on the player or src, if no target is specified
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
---@param src number
---@param item table
---@param event string
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