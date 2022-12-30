QBCore = exports['qb-core']:GetCoreObject()

local getOutDict = 'switch@franklin@bed'
local getOutAnim = 'sleep_getup_rubeyes'
local canLeaveBed = true
local bedOccupying = nil
local bedObject = nil
local bedOccupyingData = nil
local closestBed = nil
local doctorCount = 0
local CurrentDamageList = {}
local cam = nil
local playerArmor = nil
local listen = false
inBedDict = "anim@gangops@morgue@table@"
inBedAnim = "body_search"
isInHospitalBed = false
isBleeding = 0
bleedTickTimer, advanceBleedTimer = 0, 0
fadeOutTimer, blackoutTimer = 0, 0
legCount = 0
armcount = 0
headCount = 0
playerHealth = nil
isDead = false
isStatusChecking = false
statusChecks = {}
statusCheckTime = 0
healAnimDict = "mini@cpr@char_a@cpr_str"
healAnim = "cpr_pumpchest"
injured = {}
deadAnimDict = "dead"
deadAnim = "dead_a"

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

local function isBedAvailable(pos, bed)
    if bed.taken then return false end
    if #(pos - vector3(bed.coords.x, bed.coords.y, bed.coords.z)) >= 500 then return false end
    return true
end

local function getAvailableBed(bedId)
    local pos = GetEntityCoords(cache.ped)

    if bedId then
        return isBedAvailable(pos, Config.Locations["beds"][bedId]) and bedId or nil
    end

    for index, bed in pairs(Config.Locations["beds"]) do
        if isBedAvailable(pos, bed) then
            return index
        end
    end
end

local function getDamagingWeapon(ped)
    for k, v in pairs(Config.Weapons) do
        if HasPedBeenDamagedByWeapon(ped, k, 0) then
            return v
        end
    end
end

local function isDamagingEvent(damageDone, weapon)
    local luck = math.random(100)
    local multi = damageDone / Config.HealthDamage

    return luck < (Config.HealthDamage * multi) or (damageDone >= Config.ForceInjury or multi > Config.MaxInjuryChanceMulti or Config.ForceInjuryWeapons[weapon])
end

local function doLimbAlert()
    if isDead or InLaststand or #injured == 0 then return end

    local limbDamageMsg = ''
    if #injured <= Config.AlertShowInfo then
        for k, v in pairs(injured) do
            limbDamageMsg = limbDamageMsg .. Lang:t('info.pain_message', { limb = v.label, severity = Config.WoundStates[v.severity] })
            if k < #injured then
                limbDamageMsg = limbDamageMsg .. " | "
            end
        end
    else
        limbDamageMsg = Lang:t('info.many_places')
    end
    lib.notify({ description = limbDamageMsg, type = 'error' })
end

local function doBleedAlert()
    if isDead or tonumber(isBleeding) <= 0 then return end
    lib.notify({ title = Lang:t('info.bleed_alert'), description = Config.BleedingStates[tonumber(isBleeding)].label, type = 'inform' })
end

local function applyBleed(level)
    if isBleeding == 4 then return end
    isBleeding = (isBleeding + level >= 4) and 4 or (isBleeding + level)
    doBleedAlert()
end

local function setClosestBed()
    if isInHospitalBed then return end

    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local minDist = nil
    for index, bed in pairs(Config.Locations["beds"]) do
        local bedDistance = #(pos - vector3(bed.coords.x, bed.coords.y, bed.coords.z))
        if not current or bedDistance < minDist then
            current = index
            minDist = bedDistance
        end
    end

    if current == closestBed then return end
    closestBed = current
end

local function isInjuryCausingLimp()
    for _, v in pairs(BodyParts) do
        if v.causeLimp and v.isDamaged then
            return true
        end
    end
    return false
end

local function makePedLimp(ped)
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

    for k, v in pairs(injured) do
        if v.severity <= 2 then
            v.severity = 0
            table.remove(injured, k)
        end
    end

    if isBleeding <= 2 then
        isBleeding = 0
        bleedTickTimer = 0
        advanceBleedTimer = 0
        fadeOutTimer = 0
        blackoutTimer = 0
    end

    -- TODO: do we need to sync twice?
    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })

    makePedLimp(cache.ped)
    doLimbAlert()
    doBleedAlert()

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })
end

local function resetAll()
    isBleeding = 0
    bleedTickTimer = 0
    advanceBleedTimer = 0
    fadeOutTimer = 0
    blackoutTimer = 0
    onDrugs = 0
    wasOnDrugs = false
    onPainKiller = 0
    wasOnPainKillers = false
    injured = {}

    for _, v in pairs(BodyParts) do
        v.isDamaged = false
        v.severity = 0
    end

    -- TODO: do we need to sync twice?
    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })

    CurrentDamageList = {}
    TriggerServerEvent('hospital:server:SetWeaponDamage', CurrentDamageList)

    makePedLimp(cache.ped)
    doLimbAlert()
    doBleedAlert()

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })
    TriggerServerEvent("hospital:server:resetHungerThirst")
end

local function setBedCam()
    isInHospitalBed = true
    canLeaveBed = false
    local player = cache.ped

    DoScreenFadeOut(1000)

    while not IsScreenFadedOut() do
        Wait(100)
    end

    if IsPedDeadOrDying(player) then
        local pos = GetEntityCoords(player, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(player), true, false)
    end

    bedObject = GetClosestObjectOfType(bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z, 1.0, bedOccupyingData.model, false, false, false)
    FreezeEntityPosition(bedObject, true)

    SetEntityCoords(player, bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z + 0.02)
    Wait(500)
    FreezeEntityPosition(player, true)

    lib.requestAnimDict(inBedDict)

    TaskPlayAnim(player, inBedDict, inBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
    SetEntityHeading(player, bedOccupyingData.coords.w)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
    AttachCamToPedBone(cam, player, 31085, 0, 1.0, 1.0, true)
    SetCamFov(cam, 90.0)
    local heading = GetEntityHeading(player)
    heading = (heading > 180) and heading - 180 or heading + 180
    SetCamRot(cam, -45.0, 0.0, heading, 2)

    DoScreenFadeIn(1000)

    Wait(1000)
    FreezeEntityPosition(player, true)
end

local function leaveBed()
    local player = cache.ped

    lib.requestAnimDict(getOutDict)
    FreezeEntityPosition(player, false)
    SetEntityInvincible(player, false)
    SetEntityHeading(player, bedOccupyingData.coords.w + 90)
    TaskPlayAnim(player, getOutDict, getOutAnim, 100.0, 1.0, -1, 8, -1, false, false, false)
    Wait(4000)
    ClearPedTasks(player)
    TriggerServerEvent('hospital:server:LeaveBed', bedOccupying)
    FreezeEntityPosition(bedObject, true)
    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    bedOccupying = nil
    bedObject = nil
    bedOccupyingData = nil
    isInHospitalBed = false

    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.metadata.injail <= 0 then return end
        TriggerEvent("prison:client:Enter", PlayerData.metadata.injail)
    end)
end

local function isInDamageList(damage)
    if not CurrentDamageList then return false end

    for _, v in pairs(CurrentDamageList) do
        if v == damage then
            return true
        end
    end

    return false
end

local function checkWeaponDamage(ped)
    local detected = false
    for k, v in pairs(QBCore.Shared.Weapons) do
        if HasPedBeenDamagedByWeapon(ped, k, 0) then
            detected = true
            if not isInDamageList(k) then
                TriggerEvent('chat:addMessage', {
                    color = { 255, 0, 0 },
                    multiline = false,
                    args = { Lang:t('info.status'), v.damagereason }
                })
                CurrentDamageList[#CurrentDamageList + 1] = k
            end
        end
    end
    if detected then
        TriggerServerEvent("hospital:server:SetWeaponDamage", CurrentDamageList)
    end
    ClearEntityLastDamageEntity(ped)
end

local function applyStaggerEffect(ped, staggerArea, chance)
    if not staggerArea.armored or armor > 0 or math.random(100) > math.ceil(chance) then return end
    SetPedToRagdoll(ped, 1500, 2000, 3, true, true, false)
end

local function applyImmediateMinorEffects(ped, bone, armor)
    if Config.CriticalAreas[bone] and armor <= 0 then
       applyBleed(1)
    end

    local staggerArea = Config.StaggerAreas[bone]
    if not staggerArea then return end
    applyStaggerEffect(ped, staggerArea, staggerArea.minor)
end

local function applyImmediateMajorEffects(ped, bone, armor)
    local criticalArea = Config.CriticalAreas[bone]
    if criticalArea then
        if armor > 0 and criticalArea.armored then
            if math.random(100) <= math.ceil(Config.MajorArmoredBleedChance) then
                applyBleed(1)
            end
        else
            applyBleed(1)
        end
    else
        if armor > 0 then
            if math.random(100) < (Config.MajorArmoredBleedChance) then
                applyBleed(1)
            end
        elseif math.random(100) < (Config.MajorArmoredBleedChance * 2) then
            applyBleed(1)
        end
    end

    local staggerArea = Config.StaggerAreas[bone]
    if not staggerArea then return end
    applyStaggerEffect(ped, staggerArea, staggerArea.major)
end

local function applyImmediateEffects(ped, bone, weapon, damageDone)
    local armor = GetPedArmour(ped)
    if Config.MinorInjurWeapons[weapon] and damageDone < Config.DamageMinorToMajor then
        applyImmediateMinorEffects(ped, bone, armor)
    elseif Config.MajorInjurWeapons[weapon] or (Config.MinorInjurWeapons[weapon] and damageDone >= Config.DamageMinorToMajor) then
        applyImmediateMajorEffects(ped, bone, armor)
    end
end

local function createInjury(bodyPart, bone, maxSeverity)
    if bodyPart.isDamaged then return end

    bodyPart.isDamaged = true
    bodyPart.severity = math.random(1, maxSeverity)
    injured[#injured + 1] = {
        part = bone,
        label = bodyPart.label,
        severity = bodyPart.severity
    }
end

local function upgradeInjury(bodyPart, bone)
    if bodyPart.severity >= 4 then return end

    bodyPart.severity += 1
    for _, v in pairs(injured) do
        if v.part == bone then
            v.severity = bodyPart.severity
        end
    end
end

local function injureBodyPart(bone)
    local bodyPart = BodyParts[bone]
    if not bodyPart.isDamaged then
        createInjury(bodyPart, bone, 3)
    else
        upgradeInjury(bodyPart, bone)
    end
end

local function checkDamage(ped, boneId, weapon, damageDone)
    if not weapon then return end

    local bone = Config.Bones[boneId]
    if not bone or isDead or InLaststand then return end

    applyImmediateEffects(ped, bone, weapon, damageDone)
    injureBodyPart(bone)

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
    })

    makePedLimp(ped)
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

    if isDead or InLaststand then
        local pos = GetEntityCoords(ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
        isDead = false
        SetEntityInvincible(ped, false)
        endLastStand()
    end

    if isInHospitalBed then
        lib.requestAnimDict(inBedDict)
        TaskPlayAnim(ped, inBedDict, inBedAnim, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
        SetEntityInvincible(ped, true)
        canLeaveBed = true
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
    applyBleed(math.random(1, 4))
    local bone = Config.Bones[24816]
    
    createInjury(BodyParts[bone], bone, 4)

    bone = Config.Bones[40269]
    createInjury(BodyParts[bone], bone, 4)

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(isBleeding)
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

RegisterNetEvent('hospital:client:SendToBed', function(id, data, isRevive)
    bedOccupying = id
    bedOccupyingData = data
    setBedCam()
    CreateThread(function()
        Wait(5)
        if isRevive then
            lib.notify({ description = Lang:t('success.being_helped'), type = 'success' })
            Wait(Config.AIHealTimer * 1000)
            TriggerEvent("hospital:client:Revive")
        else
            canLeaveBed = true
        end
    end)
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
    doctorCount = amount
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
    if bedOccupying then
        TriggerServerEvent("hospital:server:LeaveBed", bedOccupying)
    end
    isDead = false
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

--- shows leave bed text if the player can leave the bed, triggers leaving the bed if the right key is pressed.
---@return 1000|0 sleep how long to sleep before next run of this function
local function showLeaveBedText()
    if not isInHospitalBed or not canLeaveBed then return 1000 end
    lib.showTextUI(Lang:t('text.bed_out'))
    if not IsControlJustReleased(0, 38) then return 0 end

    exports['qb-core']:KeyPressed(38)
    leaveBed()
    lib.hideTextUI()
end

CreateThread(function()
    while true do
        local sleep = showLeaveBedText()
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait((1000 * Config.MessageTimer))
        doLimbAlert()
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        setClosestBed()
        if isStatusChecking then
            statusCheckTime -= 1
            if statusCheckTime <= 0 then
                statusChecks = {}
                isStatusChecking = false
            end
        end
    end
end)

--- returns true if player took damage in their upper body or if the weapon class is nothing.
local function checkBodyHitOrWeakWeapon(isArmorDamaged, bodypart, weapon)
    return isArmorDamaged and (bodypart == 'SPINE' or bodypart == 'UPPER_BODY') or weapon == Config.WeaponClasses['NOTHING']
end

local function applyDamage(ped, damageDone, isArmorDamaged)
    local hit, bone = GetPedLastDamageBone(ped)
    local bodypart = Config.Bones[bone]
    local weapon = getDamagingWeapon(ped)

    if not hit or bodypart == 'NONE' then return end

    if damageDone >= Config.HealthDamage then
        if weapon then
            local isBodyHitOrWeakWeapon = checkBodyHitOrWeakWeapon(isArmorDamaged, bodypart, weapon)
            if isBodyHitOrWeakWeapon and isArmorDamaged then
                TriggerServerEvent("hospital:server:SetArmor", GetPedArmour(ped))
            elseif not isBodyHitOrWeakWeapon and isDamagingEvent(damageDone, weapon) then
                checkDamage(ped, bone, weapon, damageDone)
            end
        end
    elseif Config.AlwaysBleedChanceWeapons[weapon]
        and math.random(100) < Config.AlwaysBleedChance 
        and not checkBodyHitOrWeakWeapon(isArmorDamaged, bodypart, weapon) then
        
        applyBleed(1)
    end
end

CreateThread(function()
    while true do
        local ped = cache.ped()
        local health = GetEntityHealth(ped)
        local armor = GetPedArmour(ped)

        if not playerHealth then
            playerHealth = health
        end

        if not playerArmor then
            playerArmor = armor
        end

        local isArmorDamaged = (playerArmor ~= armor and armor < (playerArmor - Config.ArmorDamage) and armor > 0) -- Players armor was damaged
        local isHealthDamaged = (playerHealth ~= health) -- Players health was damaged

        if isArmorDamaged or isHealthDamaged then
            local damageDone = (playerHealth - health)
            applyDamage(ped, damageDone, isArmorDamaged)
            checkWeaponDamage(ped)
        end

        playerHealth = health
        playerArmor = armor

        if not isInHospitalBed then
            ProcessDamage(ped)
        end
        Wait(100)
    end
end)

local function checkInControls(variable)
    listen = true
    repeat
        if IsControlJustPressed(0, 38) then
            exports['qb-core']:KeyPressed(38)
            if variable == "checkin" then
                TriggerEvent('qb-ambulancejob:checkin')
                listen = false
            elseif variable == "beds" then
                TriggerEvent('qb-ambulancejob:beds')
                listen = false
            end
        end
        Wait(0)
    until not listen
end

RegisterNetEvent('qb-ambulancejob:checkin', function()
    if doctorCount >= Config.MinimalDoctors then
        TriggerServerEvent("hospital:server:SendDoctorAlert")
        return
    end

    TriggerEvent('animations:client:EmoteCommandStart', { "notepad" })
    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        label = Lang:t('progress.checking_in'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = healAnimDict,
            clip = healAnim,
        },
    })
    then
        TriggerEvent('animations:client:EmoteCommandStart', { "c" })
        local bedId = getAvailableBed()
        if not bedId then
            lib.notify({ description = Lang:t('error.beds_taken'), type = 'error' })
            return
        end

        TriggerServerEvent("hospital:server:SendToBed", bedId, true)
    else
        TriggerEvent('animations:client:EmoteCommandStart', { "c" })
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)

RegisterNetEvent('qb-ambulancejob:beds', function()
    if getAvailableBed(closestBed) then
        TriggerServerEvent("hospital:server:SendToBed", closestBed, false)
    else
        lib.notify({ description = Lang:t('error.beds_taken'), type = 'error' })
    end
end)

-- Convar turns into a boolean
if Config.UseTarget then
    CreateThread(function()
        for k, v in pairs(Config.Locations["checking"]) do
            exports.ox_target:addBoxZone({
                name = "checking" .. k,
                coords = vec3(v.x, v.y, v.z),
                size = vec3(2, 1, 2),
                rotation = 18,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "qb-ambulancejob:checkin",
                        icon = "fas fa-clipboard",
                        label = Lang:t('text.check'),
                        distance = 1.5,
                        groups = "ambulance",
                    }
                }
            })
        end

        for k, v in pairs(Config.Locations["beds"]) do
            exports.ox_target:addBoxZone({
                name = "beds" .. k,
                coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                size = vec3(1.7, 1.9, 2),
                rotation = v.coords.w,
                debug = false,
                options = {
                    {
                        type = "client",
                        event = "qb-ambulancejob:beds",
                        icon = "fas fa-clipboard",
                        label = Lang:t('text.bed'),
                        distance = 1.5,
                        groups = "ambulance",
                    }
                }
            })
        end
    end)
else
    CreateThread(function()
        for _, v in pairs(Config.Locations["checking"]) do
            local function enterCheckInZone()
                if doctorCount >= Config.MinimalDoctors then
                    lib.showTextUI(Lang:t('text.call_doc'))
                    CreateThread(function()
                        checkInControls("checkin")
                    end)
                else
                    lib.showTextUI(Lang:t('text.check_in'))
                end
            end

            local function outCheckInZone()
                listen = false
                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.x, v.y, v.z),
                size = vec3(2, 1, 2),
                rotation = 18,
                debug = false,
                onEnter = enterCheckInZone,
                onExit = outCheckInZone
            })
        end
        for _, v in pairs(Config.Locations["beds"]) do
            local function enterBedZone()
                lib.showTextUI(Lang:t('text.lie_bed'))
                CreateThread(function()
                    checkInControls("beds")
                end)
            end

            local function outBedZone()
                listen = false
                lib.hideTextUI()
            end

            lib.zones.box({
                coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                size = vec3(1.9, 2.1, 2),
                rotation = v.coords.w,
                debug = false,
                onEnter = enterBedZone,
                onExit = outBedZone
            })
        end
    end)
end
