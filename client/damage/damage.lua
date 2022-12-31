local playerArmor = nil

--- returns true if player took damage in their upper body or if the weapon class is nothing.
local function checkBodyHitOrWeakWeapon(isArmorDamaged, bodypart, weapon)
    return isArmorDamaged and (bodypart == 'SPINE' or bodypart == 'UPPER_BODY') or weapon == Config.WeaponClasses['NOTHING']
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

local function applyStaggerEffect(ped, staggerArea, chance, armor)
    if not staggerArea.armored or armor > 0 or math.random(100) > math.ceil(chance) then return end
    SetPedToRagdoll(ped, 1500, 2000, 3, true, true, false)
end

local function applyImmediateMinorEffects(ped, bone, armor)
    if Config.CriticalAreas[bone] and armor <= 0 then
       ApplyBleed(1)
    end

    local staggerArea = Config.StaggerAreas[bone]
    if not staggerArea then return end
    applyStaggerEffect(ped, staggerArea, staggerArea.minor, armor)
end

local function applyImmediateMajorEffects(ped, bone, armor)
    local criticalArea = Config.CriticalAreas[bone]
    if criticalArea then
        if armor > 0 and criticalArea.armored then
            if math.random(100) <= math.ceil(Config.MajorArmoredBleedChance) then
                ApplyBleed(1)
            end
        else
            ApplyBleed(1)
        end
    else
        if armor > 0 then
            if math.random(100) < (Config.MajorArmoredBleedChance) then
                ApplyBleed(1)
            end
        elseif math.random(100) < (Config.MajorArmoredBleedChance * 2) then
            ApplyBleed(1)
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

local function upgradeInjury(bodyPart, bone)
    if bodyPart.severity >= 4 then return end

    bodyPart.severity += 1
    for _, v in pairs(Injured) do
        if v.part == bone then
            v.severity = bodyPart.severity
        end
    end
end

local function injureBodyPart(bone)
    local bodyPart = BodyParts[bone]
    if not bodyPart.isDamaged then
        CreateInjury(bodyPart, bone, 3)
    else
        upgradeInjury(bodyPart, bone)
    end
end

local function checkDamage(ped, boneId, weapon, damageDone)
    if not weapon then return end

    local bone = Config.Bones[boneId]
    if not bone or IsDead or InLaststand then return end

    applyImmediateEffects(ped, bone, weapon, damageDone)
    injureBodyPart(bone)

    TriggerServerEvent('hospital:server:SyncInjuries', {
        limbs = BodyParts,
        isBleeding = tonumber(IsBleeding)
    })

    MakePedLimp(ped)
end

--- creates injuries on body parts
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
        
        ApplyBleed(1)
    end
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

--- adds weapon hashes that damaged the ped that aren't already in the CurrentDamagedList and syncs to the server.
local function findDamageCause(ped)
    local detected = false
    for hash, weapon in pairs(QBCore.Shared.Weapons) do
        if HasPedBeenDamagedByWeapon(ped, hash, 0) and not isInDamageList(hash) then
            detected = true
            TriggerEvent('chat:addMessage', {
                color = { 255, 0, 0 },
                multiline = false,
                args = { Lang:t('info.status'), weapon.damagereason }
            })
            CurrentDamageList[#CurrentDamageList + 1] = hash
        end
    end
    if detected then
        TriggerServerEvent("hospital:server:SetWeaponDamage", CurrentDamageList)
    end
end

--- if the player health and armor haven't already been set, initialize them.
local function initHealthAndArmorIfNotSet(health, armor)
    if not PlayerHealth then
        PlayerHealth = health
    end

    if not playerArmor then
        playerArmor = armor
    end
end

--- detects if player took damage, applies injuries, and updates health/armor values 
local function checkForDamage(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)

    initHealthAndArmorIfNotSet(health, armor)

    local isArmorDamaged = (playerArmor ~= armor and armor < (playerArmor - Config.ArmorDamage) and armor > 0) -- Players armor was damaged
    local isHealthDamaged = (PlayerHealth ~= health) -- Players health was damaged

    if isArmorDamaged or isHealthDamaged then
        local damageDone = (PlayerHealth - health)
        applyDamage(ped, damageDone, isArmorDamaged)
        findDamageCause(ped)
        ClearEntityLastDamageEntity(ped)
    end

    PlayerHealth = health
    playerArmor = armor
end

--- checks the player for damage, applies injuries, and damage effects
CreateThread(function()
    while true do
        local ped = cache.ped
        checkForDamage(ped)
        ApplyDamageEffects(ped)
        Wait(100)
    end
end)