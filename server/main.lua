---@alias source number

lib.callback.register('qbx_ambulancejob:server:getPlayerStatus', function(_, targetSrc)
	return exports.qbx_medical:GetPlayerStatus(targetSrc)
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
