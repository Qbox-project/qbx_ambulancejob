local function respawn()
    TriggerServerEvent("hospital:server:RespawnAtHospital")
    if exports["qb-policejob"]:IsHandcuffed() then
        TriggerEvent("police:client:GetCuffed", -1)
    end
    TriggerEvent("police:client:DeEscort")
end

---Allow player to respawn
function AllowRespawn()
    RespawnHoldTime = 5
    while exports['qbx-medical']:isDead() do
        Wait(1000)
        exports['qbx-medical']:setDeathTime(exports['qbx-medical']:getDeathTime() - 1)
        if exports['qbx-medical']:getDeathTime() <= 0 then
            if IsControlPressed(0, 38) and RespawnHoldTime <= 1 and not IsInHospitalBed then
                respawn()
            end
            if IsControlPressed(0, 38) then
                RespawnHoldTime -= 1
            end
            if IsControlReleased(0, 38) then
                RespawnHoldTime = 5
            end
        end
    end
end

---log the death of a player along with the attacker and the weapon used.
---@param victim number ped
---@param attacker number ped
---@param weapon string weapon hash
local function logDeath(victim, attacker, weapon)
    local playerid = NetworkGetPlayerIndexFromPed(victim)
    local playerName = GetPlayerName(playerid) .. " " .. "(" .. GetPlayerServerId(playerid) .. ")" or Lang:t('info.self_death')
    local killerId = NetworkGetPlayerIndexFromPed(attacker)
    local killerName = GetPlayerName(killerId) .. " " .. "(" .. GetPlayerServerId(killerId) .. ")" or Lang:t('info.self_death')
    local weaponLabel = QBCore.Shared.Weapons[weapon].label or 'Unknown'
    local weaponName = QBCore.Shared.Weapons[weapon].name or 'Unknown'
    TriggerServerEvent("qb-log:server:CreateLog", "death", Lang:t('logs.death_log_title', { playername = playerName, playerid = GetPlayerServerId(playerid) }), "red", Lang:t('logs.death_log_message', { killername = killerName, playername = playerName, weaponlabel = weaponLabel, weaponname = weaponName }))
end

---when player is killed by another player, set last stand mode, or if already in last stand mode, set player to dead mode.
---@param event string
---@param data table
AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= "CEventNetworkEntityDamage" then return end
    local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
    if not IsEntityAPed(victim) or not victimDied or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId or not IsEntityDead(cache.ped) then return end
    local inLaststand = exports['qbx-medical']:getLaststand()
    if not inLaststand then
        StartLastStand()
    elseif inLaststand and not exports['qbx-medical']:isDead() then
        EndLastStand()
        logDeath(victim, attacker, weapon)
        exports['qbx-medical']:setDeathTime(0)
        exports['qbx-medical']:killPlayer()
        AllowRespawn()
    end
end)