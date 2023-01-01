QBCore = exports['qb-core']:GetCoreObject()

InBedDict = "anim@gangops@morgue@table@"
InBedAnim = "body_search"
IsInHospitalBed = false
IsBleeding = 0
BleedTickTimer, AdvanceBleedTimer = 0, 0
FadeOutTimer, BlackoutTimer = 0, 0
LegCount = 0
ArmCount = 0
HeadCount = 0
PlayerHealth = nil
IsDead = false
IsStatusChecking = false
StatusChecks = {}
StatusCheckTime = 0
HealAnimDict = "mini@cpr@char_a@cpr_str"
HealAnim = "cpr_pumpchest"
Injured = {}
DeadAnimDict = "dead"
DeadAnim = "dead_a"
DoctorCount = 0
CurrentDamageList = {}
CanLeaveBed = true
BedOccupying = nil

BodyParts = {
    ['HEAD'] = { label = Lang:t('body.head'), causeLimp = false, isDamaged = false, severity = 0 },
    ['NECK'] = { label = Lang:t('body.neck'), causeLimp = false, isDamaged = false, severity = 0 },
    ['SPINE'] = { label = Lang:t('body.spine'), causeLimp = true, isDamaged = false, severity = 0 },
    ['UPPER_BODY'] = { label = Lang:t('body.upper_body'), causeLimp = false, isDamaged = false, severity = 0 },
    ['LOWER_BODY'] = { label = Lang:t('body.lower_body'), causeLimp = true, isDamaged = false, severity = 0 },
    ['LARM'] = { label = Lang:t('body.left_arm'), causeLimp = false, isDamaged = false, severity = 0 },
    ['LHAND'] = { label = Lang:t('body.left_hand'), causeLimp = false, isDamaged = false, severity = 0 },
    ['LFINGER'] = { label = Lang:t('body.left_fingers'), causeLimp = false, isDamaged = false, severity = 0 },
    ['LLEG'] = { label = Lang:t('body.left_leg'), causeLimp = true, isDamaged = false, severity = 0 },
    ['LFOOT'] = { label = Lang:t('body.left_foot'), causeLimp = true, isDamaged = false, severity = 0 },
    ['RARM'] = { label = Lang:t('body.right_arm'), causeLimp = false, isDamaged = false, severity = 0 },
    ['RHAND'] = { label = Lang:t('body.right_hand'), causeLimp = false, isDamaged = false, severity = 0 },
    ['RFINGER'] = { label = Lang:t('body.right_fingers'), causeLimp = false, isDamaged = false, severity = 0 },
    ['RLEG'] = { label = Lang:t('body.right_leg'), causeLimp = true, isDamaged = false, severity = 0 },
    ['RFOOT'] = { label = Lang:t('body.right_foot'), causeLimp = true, isDamaged = false, severity = 0 },
}

-- Functions
local function doLimbAlert()
    if IsDead or InLaststand or #Injured == 0 then return end

    local limbDamageMsg = ''
    if #Injured <= Config.AlertShowInfo then
        for k, v in pairs(Injured) do
            limbDamageMsg = limbDamageMsg .. Lang:t('info.pain_message', { limb = v.label, severity = Config.WoundStates[v.severity] })
            if k < #Injured then
                limbDamageMsg = limbDamageMsg .. " | "
            end
        end
    else
        limbDamageMsg = Lang:t('info.many_places')
    end
    lib.notify({ description = limbDamageMsg, type = 'error' })
end

local function doBleedAlert()
    if IsDead or tonumber(IsBleeding) <= 0 then return end
    lib.notify({ title = Lang:t('info.bleed_alert'), description = Config.BleedingStates[tonumber(IsBleeding)].label, type = 'inform' })
end

function ApplyBleed(level)
    if IsBleeding == 4 then return end
    IsBleeding = (IsBleeding + level >= 4) and 4 or (IsBleeding + level)
    doBleedAlert()
end

local function isInjuryCausingLimp()
    for _, v in pairs(BodyParts) do
        if v.causeLimp and v.isDamaged then
            return true
        end
    end
    return false
end

function MakePedLimp(ped)
    if not isInjuryCausingLimp() then return end
    lib.requestAnimSet("move_m@injured")
    SetPedMovementClipset(ped, "move_m@injured", 1)
    SetPlayerSprint(cache.playerId, false)
end

function ResetPartial()
    for _, v in pairs(BodyParts) do
        if v.isDamaged and v.severity <= 2 then
            v.isDamaged = false
            v.severity = 0
        end
    end

    for k, v in pairs(Injured) do
        if v.severity <= 2 then
            v.severity = 0
            table.remove(Injured, k)
        end
    end

    if IsBleeding <= 2 then
        IsBleeding = 0
        BleedTickTimer = 0
        AdvanceBleedTimer = 0
        FadeOutTimer = 0
        BlackoutTimer = 0
    end

    -- TODO: do we need to sync twice?
    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(IsBleeding)
    })

    MakePedLimp(cache.ped)
    doLimbAlert()
    doBleedAlert()

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(IsBleeding)
    })
end

local function resetAll()
    IsBleeding = 0
    BleedTickTimer = 0
    AdvanceBleedTimer = 0
    FadeOutTimer = 0
    BlackoutTimer = 0
    onDrugs = 0
    wasOnDrugs = false
    onPainKiller = 0
    wasOnPainKillers = false
    Injured = {}

    for _, v in pairs(BodyParts) do
        v.isDamaged = false
        v.severity = 0
    end

    -- TODO: do we need to sync twice?
    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(IsBleeding)
    })

    CurrentDamageList = {}
    TriggerServerEvent('hospital:server:SetWeaponDamage', CurrentDamageList)

    MakePedLimp(cache.ped)
    doLimbAlert()
    doBleedAlert()

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(IsBleeding)
    })
    TriggerServerEvent("hospital:server:resetHungerThirst")
end

function CreateInjury(bodyPart, bone, maxSeverity)
    if bodyPart.isDamaged then return end

    bodyPart.isDamaged = true
    bodyPart.severity = math.random(1, maxSeverity)
    Injured[#Injured + 1] = {
        part = bone,
        label = bodyPart.label,
        severity = bodyPart.severity
    }
end

-- Events

RegisterNetEvent('hospital:client:ambulanceAlert', function(coords, text)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)
    lib.notify({ title = Lang:t('text.alert'), description = text .. ' | ' .. street1name .. ' ' .. street2name, type = 'inform' })
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

RegisterNetEvent('hospital:client:Revive', function()
    local ped = cache.ped

    if IsDead or InLaststand then
        local pos = GetEntityCoords(ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
        IsDead = false
        SetEntityInvincible(ped, false)
        endLastStand()
    end

    if IsInHospitalBed then
        lib.requestAnimDict(InBedDict)
        TaskPlayAnim(ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
        SetEntityInvincible(ped, true)
        CanLeaveBed = true
    end

    TriggerServerEvent("hospital:server:RestoreWeaponDamage")
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    SetPlayerSprint(cache.playerId, true)
    resetAll()
    ResetPedMovementClipset(ped, 0.0)
    TriggerServerEvent('hud:server:RelieveStress', 100)
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent("hospital:server:SetLaststandStatus", false)
    emsNotified = false
    lib.notify({ description = Lang:t('info.healthy'), type = 'inform' })
end)

RegisterNetEvent('hospital:client:SetPain', function()
    ApplyBleed(math.random(1, 4))
    local bone = Config.Bones[24816]
    
    CreateInjury(BodyParts[bone], bone, 4)

    bone = Config.Bones[40269]
    CreateInjury(BodyParts[bone], bone, 4)

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(IsBleeding)
    })
end)

RegisterNetEvent('hospital:client:KillPlayer', function()
    SetEntityHealth(cache.ped, 0)
end)

RegisterNetEvent('hospital:client:HealInjuries', function(type)
    if type == "full" then
        resetAll()
    else
        ResetPartial()
    end
    TriggerServerEvent("hospital:server:RestoreWeaponDamage")

    lib.notify({ description = Lang:t('success.wounds_healed'), type = 'success' })
end)

RegisterNetEvent('hospital:client:SetBed', function(bedsKey, id, isTaken)
    Config.Locations[bedsKey][id].taken = isTaken
end)

RegisterNetEvent('hospital:client:RespawnAtHospital', function()
    TriggerServerEvent("hospital:server:RespawnAtHospital")
    if exports["qb-policejob"]:IsHandcuffed() then
        TriggerEvent("police:client:GetCuffed", -1)
    end
    TriggerEvent("police:client:DeEscort")
end)

RegisterNetEvent('hospital:client:SendBillEmail', function(amount)
    SetTimeout(math.random(2500, 4000), function()
        local gender = QBCore.Functions.GetPlayerData().charinfo.gender == 1 and Lang:t('info.mrs') or Lang:t('info.mr')
        local charinfo = QBCore.Functions.GetPlayerData().charinfo
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = Lang:t('mail.sender'),
            subject = Lang:t('mail.subject'),
            message = Lang:t('mail.message', { gender = gender, lastname = charinfo.lastname, costs = amount }),
            button = {}
        })
    end)
end)

RegisterNetEvent('hospital:client:SetDoctorCount', function(amount)
    DoctorCount = amount
end)

RegisterNetEvent('hospital:client:adminHeal', function()
    SetEntityHealth(cache.ped, 200)
    TriggerServerEvent("hospital:server:resetHungerThirst")
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    local ped = cache.ped
    TriggerServerEvent("hospital:server:SetDeathStatus", false)
    TriggerServerEvent('hospital:server:SetLaststandStatus', false)
    TriggerServerEvent("hospital:server:SetArmor", GetPedArmour(ped))
    if BedOccupying then
        TriggerServerEvent("hospital:server:LeaveBed", BedOccupying)
    end
    IsDead = false
    deathTime = 0
    SetEntityInvincible(ped, false)
    SetPedArmour(ped, 0)
    resetAll()
end)

-- Threads

CreateThread(function()
    for _, station in pairs(Config.Locations["stations"]) do
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

CreateThread(function()
    while true do
        Wait((1000 * Config.MessageTimer))
        doLimbAlert()
    end
end)