local function isLegDamaged(injury)
    return (injury.part == 'LLEG' and injury.severity > 1) or (injury.part == 'RLEG' and injury.severity > 1) or (injury.part == 'LFOOT' and injury.severity > 2) or (injury.part == 'RFOOT' and injury.severity > 2)
end

local function makePedFall(ped)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08) -- change this float to increase/decrease camera shake
    SetPedToRagdollWithFall(ped, 1500, 2000, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
end

local function chancePedFalls(ped)
    if IsPedRagdoll(ped) or not IsPedOnFoot(ped) then return end
    local chance = (IsPedRunning(ped) or IsPedSprinting(ped)) and Config.LegInjuryChance.Running or Config.LegInjuryChance.Walking
    local rand = math.random(100)
    if rand > chance then return end
    makePedFall(ped)
end

local function isLeftArmDamaged(injury)
    return (injury.part == 'LARM' and injury.severity > 1) or (injury.part == 'LHAND' and injury.severity > 1) or (injury.part == 'LFINGER' and injury.severity > 2)
end

local function isArmDamaged(injury)
    return isLeftArmDamaged(injury) or (injury.part == 'RARM' and injury.severity > 1) or (injury.part == 'RHAND' and injury.severity > 1) or (injury.part == 'RFINGER' and injury.severity > 2)
end

local function disableArms(ped, injury)
    local disableTimer = 15
    local isLeftArm = isLeftArmDamaged(injury)
    while disableTimer > 0 do
        if IsPedInAnyVehicle(ped, true) then
            DisableControlAction(0, 63, true) -- veh turn left
        end

        local playerId = cache.playerId
        if IsPlayerFreeAiming(playerId) then
            if isLeftArm then
                DisablePlayerFiring(playerId, true) -- Disable weapon firing
            else
                DisableControlAction(0, 25, true) -- Disable weapon aiming
            end
        end

        disableTimer -= 1
        Wait(1)
    end
end

local function isHeadDamaged(injury)
    return injury.part == 'HEAD' and injury.severity > 2
end

local function playBrainDamageEffectAndRagdoll(ped)
    SetFlash(0, 0, 100, 10000, 100)

    DoScreenFadeOut(100)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08) -- change this float to increase/decrease camera shake
        SetPedToRagdoll(ped, 5000, 1, 2)
    end

    Wait(5000)
    DoScreenFadeIn(250)
end

---applies disabling status effects based on injuries to specific body parts
---@param ped any
function ProcessDamage(ped)
    if isDead or InLaststand or onPainKillers then return end
    for _, injury in pairs(injured) do
        if isLegDamaged(injury) then
            if legCount >= Config.LegInjuryTimer then
                chancePedFalls(ped)
                legCount = 0
            else
                legCount += 1
            end
        elseif isArmDamaged(injury) then
            if armcount >= Config.ArmInjuryTimer then
                CreateThread(disableArms(ped, injury))
                armcount = 0
            else
                armcount += 1
            end
        elseif isHeadDamaged(injury) then
            if headCount >= Config.HeadInjuryTimer then
                local chance = math.random(100)

                if chance <= Config.HeadInjuryChance then
                    playBrainDamageEffectAndRagdoll(ped)
                end
                headCount = 0
            else
                headCount += 1
            end
        end
    end
end