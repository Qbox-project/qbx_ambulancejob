local isEscorting = false

local function logPlayerKiller()
    local ped = cache.ped
    local player = cache.playerId
    local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(player)
    local killer = GetPedSourceOfDeath(ped)
    if killer_2 ~= 0 and killer_2 ~= -1 then killer = killer_2 end
    local killerId = NetworkGetPlayerIndexFromPed(killer)
    local killerName = killerId ~= -1 and GetPlayerName(killerId) .. " " .. "(" .. GetPlayerServerId(killerId) .. ")" or Lang:t('info.self_death')
    local weaponLabel = Lang:t('info.wep_unknown')
    local weaponName = Lang:t('info.wep_unknown')
    local weaponItem = QBCore.Shared.Weapons[killerWeapon]
    if weaponItem then
        weaponLabel = weaponItem.label
        weaponName = weaponItem.name
    end
    TriggerServerEvent("qb-log:server:CreateLog", "death", Lang:t('logs.death_log_title', { playername = GetPlayerName(cache.playerId), playerid = GetPlayerServerId(player) }), "red", Lang:t('logs.death_log_message', { killername = killerName, playername = GetPlayerName(player), weaponlabel = weaponLabel, weaponname = weaponName }))
end

---count down last stand, if last stand is over, put player in death mode and log the killer.
local function countdownLastStand()
    
    local laststandTime = exports['qbx-medical']:getLaststandTime()
    if laststandTime - 1 > 0 then
        laststandTime -= 1
        Config.DeathTime = laststandTime
        exports['qbx-medical']:setLaststandTime(laststandTime)
    else
        lib.notify({ description = Lang:t('error.bled_out'), type = 'error' })
        exports['qbx-medical']:endLastStandDeprecated()
        logPlayerKiller()
        exports['qbx-medical']:setDeathTime(0)
        exports['qbx-medical']:killPlayer()
        exports['qbx-medical']:AllowRespawn(IsInHospitalBed)
    end
    Wait(1000)
end

---put player in last stand mode and notify EMS.
function StartLastStand()
    local ped = cache.ped
    Wait(1000)
    exports['qbx-medical']:waitForPlayerToStopMovingDeprecated()
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
    exports['qbx-medical']:setLaststandTime(Laststand.ReviveInterval)
    exports['qbx-medical']:resurrectPlayerDeprecated()
    SetEntityHealth(ped, 150)
    exports['qbx-medical']:playUnescortedLastStandAnimationDeprecated()
    exports['qbx-medical']:setLaststand(true)
    TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
    CreateThread(function()
        while exports['qbx-medical']:getLaststand() do
            countdownLastStand()
        end
    end)
    TriggerServerEvent("hospital:server:SetLaststandStatus", true)
end

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
