QBCore = exports['qbx-core']:GetCoreObject()

InBedDict = "anim@gangops@morgue@table@"
InBedAnim = "body_search"
IsInHospitalBed = false
HealAnimDict = "mini@cpr@char_a@cpr_str"
HealAnim = "cpr_pumpchest"
EmsNotified = false
CanLeaveBed = true
OnPainKillers = false
PlayerData = {
    job = nil
}

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if GetInvokingResource() then return end
    PlayerData = data
end)

-- Events

---notifies EMS of a injury at a location
---@param coords vector3
---@param text string
RegisterNetEvent('hospital:client:ambulanceAlert', function(coords, text)
    if GetInvokingResource() then return end
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)
    QBCore.Functions.Notify({ title = Lang:t('text.alert'), description = text .. ' | ' .. street1name .. ' ' .. street2name, type = 'inform' })
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = Lang:t('info.ems_alert', { text = text })
    SetBlipSprite(blip, 153)
    SetBlipSprite(blip2, 161)
    SetBlipColour(blip, 1)
    SetBlipColour(blip2, 1)
    SetBlipDisplay(blip, 4)
    SetBlipDisplay(blip2, 8)
    SetBlipAlpha(blip, transG)
    SetBlipAlpha(blip2, transG)
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    SetBlipAsShortRange(blip, false)
    SetBlipAsShortRange(blip2, false)
    PulseBlip(blip2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipText)
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(720)
        transG -= 1
        SetBlipAlpha(blip, transG)
        SetBlipAlpha(blip2, transG)
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)

---Revives player, healing all injuries
---Intended to be called from client or server.
RegisterNetEvent('hospital:client:Revive', function()
    local ped = cache.ped
    if IsInHospitalBed then
        lib.requestAnimDict(InBedDict)
        TaskPlayAnim(ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
        SetEntityInvincible(ped, true)
        CanLeaveBed = true
    end

    EmsNotified = false
end)

---sends player phone email with hospital bill.
---@param amount number
RegisterNetEvent('hospital:client:SendBillEmail', function(amount)
    if GetInvokingResource() then return end
    SetTimeout(math.random(2500, 4000), function()
        local charInfo = PlayerData.charinfo
        local gender = charInfo.gender == 1 and Lang:t('info.mrs') or Lang:t('info.mr')
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = Lang:t('mail.sender'),
            subject = Lang:t('mail.subject'),
            message = Lang:t('mail.message', { gender = gender, lastname = charInfo.lastname, costs = amount }),
            button = {}
        })
    end)
end)

-- Threads

---sets blips for stations on map
CreateThread(function()
    for _, station in pairs(Config.Locations.stations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 61)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

function GetClosestPlayer()
    local coords = GetEntityCoords(cache.ped)
    return QBCore.Functions.GetClosestPlayer(coords)
end

function OnKeyPress(cb)
    if IsControlJustPressed(0, 38) then
        exports['qbx-core']:KeyPressed(38)
        cb()
    end
end