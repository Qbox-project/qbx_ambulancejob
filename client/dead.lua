deathTime = 0
emsNotified = false

local function playDeadAnimation(player)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        TaskPlayAnim(player, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
    else
        lib.requestAnimDict(deadAnimDict)
        TaskPlayAnim(player, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
    end
end

function OnDeath()
    if isDead then return end
    isDead = true
    TriggerServerEvent("hospital:server:SetDeathStatus", true)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
    local player = cache.ped

    WaitForPedToStopMoving(player)

    ResurrectPlayer(player)
    playDeadAnimation(player)
    SetEntityInvincible(player, true)
    SetEntityHealth(player, GetEntityMaxHealth(player))

    TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_died'))
end

function DeathTimer()
    local hold = 5
    while isDead do
        Wait(1000)
        deathTime -= 1
        if deathTime <= 0 then
            if IsControlPressed(0, 38) and hold <= 0 and not isInHospitalBed then
                TriggerEvent("hospital:client:RespawnAtHospital")
            end
            if IsControlPressed(0, 38) then
                hold -= 1
            end
            if IsControlReleased(0, 38) then
                hold = 5
            end
        end
    end
end

local function logDeath(victim, attacker, weapon)
    local playerid = NetworkGetPlayerIndexFromPed(victim)
    local playerName = GetPlayerName(playerid) .. " " .. "(" .. GetPlayerServerId(playerid) .. ")" or Lang:t('info.self_death')
    local killerId = NetworkGetPlayerIndexFromPed(attacker)
    local killerName = GetPlayerName(killerId) .. " " .. "(" .. GetPlayerServerId(killerId) .. ")" or Lang:t('info.self_death')
    local weaponLabel = QBCore.Shared.Weapons[weapon].label or 'Unknown'
    local weaponName = QBCore.Shared.Weapons[weapon].name or 'Unknown'
    TriggerServerEvent("qb-log:server:CreateLog", "death", Lang:t('logs.death_log_title', { playername = playerName, playerid = GetPlayerServerId(playerid) }), "red", Lang:t('logs.death_log_message', { killername = killerName, playername = playerName, weaponlabel = weaponLabel, weaponname = weaponName }))
end

-- Damage Handler
AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= "CEventNetworkEntityDamage" then return end
    local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
    if not IsEntityAPed(victim) or not victimDied or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId or not IsEntityDead(cache.ped) then return end
    if not InLaststand then
        startLastStand()
    elseif InLaststand and not isDead then
        endLastStand()
        logDeath(victim, attacker, weapon)
        deathTime = Config.DeathTime
        OnDeath()
        DeathTimer()
    end
end)