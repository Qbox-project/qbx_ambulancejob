local isEscorting = false

---@param bool boolean
---TODO: this event name should be changed within qb-policejob to be generic
AddEventHandler('hospital:client:SetEscortingState', function(bool)
    isEscorting = bool
end)

---use first aid pack on nearest player.
lib.callback.register('hospital:client:UseFirstAid', function()
    if isEscorting then
        lib.notify({ description = Lang:t('error.impossible'), type = 'error' })
        return
    end
        
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 1.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent('hospital:server:UseFirstAid', playerId)
    end
end)

lib.callback.register('hospital:client:canHelp', function()
    return exports['qbx-medical']:getLaststand() and exports['qbx-medical']:getLaststandTime() <= 300
end)

---@param targetId number playerId
RegisterNetEvent('hospital:client:HelpPerson', function(targetId)
    if GetInvokingResource() then return end
    local ped = cache.ped
    if lib.progressCircle({
        duration = math.random(30000, 60000),
        position = 'bottom',
        label = Lang:t('progress.revive'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = HealAnimDict,
            clip = HealAnim,
        },
    })
    then
        ClearPedTasks(ped)
        lib.notify({ description = Lang:t('success.revived'), type = 'success' })
        TriggerServerEvent("hospital:server:RevivePlayer", targetId)
    else
        ClearPedTasks(ped)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)
