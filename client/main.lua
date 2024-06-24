local sharedConfig = require 'config.shared'
InBedDict = 'anim@gangops@morgue@table@'
InBedAnim = 'body_search'
IsInHospitalBed = false
HealAnimDict = 'mini@cpr@char_a@cpr_str'
HealAnim = 'cpr_pumpchest'
EmsNotified = false
CanLeaveBed = true
OnPainKillers = false

---Notifies EMS of a injury at a location
---@param coords vector3
---@param text string
RegisterNetEvent('hospital:client:ambulanceAlert', function(coords, text)
    if GetInvokingResource() then return end
    local streets = qbx.getStreetName(coords)
    exports.qbx_core:Notify(locale('text.alert'), 'inform', nil, text .. ' | ' .. streets.main .. ' ' .. streets.cross)
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = locale('info.ems_alert', text)
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
    if IsInHospitalBed then
        lib.playAnim(cache.ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
        TriggerEvent('qbx_medical:client:playerRevived')
        CanLeaveBed = true
    end

    EmsNotified = false
end)

RegisterNetEvent('qbx_medical:client:playerRevived', function()
    EmsNotified = false
end)

---Sends player phone email with hospital bill.
---@param amount number
RegisterNetEvent('hospital:client:SendBillEmail', function(amount)
    if GetInvokingResource() then return end
    SetTimeout(math.random(2500, 4000), function()
        local charInfo = QBX.PlayerData.charinfo
        local gender = charInfo.gender == 1 and locale('info.mrs') or locale('info.mr')
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = locale('mail.sender'),
            subject = locale('mail.subject'),
            message = locale('mail.message', gender, charInfo.lastname, amount),
            button = {}
        })
    end)
end)

---Sets blips for stations on map
CreateThread(function()
    for _, station in pairs(sharedConfig.locations.stations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 61)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

function GetClosestPlayer()
    return lib.getClosestPlayer(GetEntityCoords(cache.ped), 5.0, false)
end

function OnKeyPress(cb)
    if IsControlJustPressed(0, 38) then
        lib.hideTextUI()
        cb()
    end
end