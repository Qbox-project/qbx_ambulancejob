local QBCore = exports['qbx-core']:GetCoreObject()

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
	if GetInvokingResource() then return end
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
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	TriggerClientEvent('hospital:client:SendToBed', src, bedId, Config.Locations.beds[bedId], isRevive)
	TriggerClientEvent('hospital:client:SetBed', -1, "beds", bedId, true)
	billPlayer(player)
end)

---@param text string
RegisterNetEvent('hospital:server:ambulanceAlert', function(text)
	if GetInvokingResource() then return end
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
	if GetInvokingResource() then return end
	TriggerClientEvent('hospital:client:SetBed', -1, "beds", id, false)
end)

---@param data PlayerStatus
RegisterNetEvent('hospital:server:SyncInjuries', function(data)
	if GetInvokingResource() then return end
	local src = source
	playerStatus[src] = data
end)

---@param data number[] weapon hashes
RegisterNetEvent('hospital:server:SetWeaponDamage', function(data)
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	playerWeaponWounds[player.PlayerData.source] = data
end)

RegisterNetEvent('hospital:server:RestoreWeaponDamage', function()
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	playerWeaponWounds[player.PlayerData.source] = nil
end)

---@param isDead boolean
RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead)
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("isdead", isDead)
end)

---@param bool boolean
RegisterNetEvent('hospital:server:SetLaststandStatus', function(bool)
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("inlaststand", bool)
end)

---@param amount number
RegisterNetEvent('hospital:server:SetArmor', function(amount)
	if GetInvokingResource() then return end
	local src = source
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("armor", amount)
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

RegisterNetEvent('hospital:server:resetHungerThirst', function()
	if GetInvokingResource() then return end
	local player = QBCore.Functions.GetPlayer(source)

	if not player then return end

	player.Functions.SetMetaData('hunger', 100)
	player.Functions.SetMetaData('thirst', 100)

	TriggerClientEvent('hud:client:UpdateNeeds', source, 100, 100)
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

lib.addCommand('revive', {
    help = Lang:t('info.revive_player_a'),
	restricted = "qbox.admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	triggerEventOnPlayer(source, 'hospital:client:Revive', args.id)
end)

lib.addCommand('setpain', {
    help = Lang:t('info.pain_level'),
	restricted = "qbox.admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	triggerEventOnPlayer(source, 'hospital:client:SetPain', args.id)
end)

lib.addCommand('kill', {
    help =  Lang:t('info.kill'),
	restricted = "qbox.admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	triggerEventOnPlayer(source, 'hospital:client:KillPlayer', args.id)
end)

lib.addCommand('aheal', {
    help =  Lang:t('info.heal_player_a'),
	restricted = "qbox.admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	triggerEventOnPlayer(source, 'hospital:client:adminHeal', args.id)
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
