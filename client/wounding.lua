local prevPos = nil
local painkillerAmount = 0

---reduce bleeding by level. Bleed level cannot be negative.
---@param level number
local function removeBleed(level)
    local bleedLevel = exports['qbx-medical']:getBleedLevel()
    if bleedLevel == 0 then return end
    bleedLevel -= level
    exports['qbx-medical']:setBleedLevel((bleedLevel < 0) and 0 or bleedLevel)
    SendBleedAlert()
end

-- Events

lib.callback.register('hospital:client:UseIfaks', function()
    local ped = cache.ped
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = Lang:t('progress.ifaks'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = "mp_suicide",
            clip = "pill",
        },
    })
    then
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["ifaks"], "remove")
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        OnPainKillers = true
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        if math.random(1, 100) < 50 then
            removeBleed(1)
        end
        return true
    else
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
        return false
    end
end)

lib.callback.register('hospital:client:UseBandage', function()
    local ped = cache.ped
    if lib.progressCircle({
        duration = 4000,
        position = 'bottom',
        label = Lang:t('progress.bandage'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = "mp_suicide",
            clip = "pill",
        },
    })
    then
        StopAnimTask(ped, "anim@amb@business@weed@weed_inspecting_high_dry@", "weed_inspecting_high_base_inspector", 1.0)
        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["bandage"], "remove")
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        if math.random(1, 100) < 50 then
            removeBleed(1)
        end
        if math.random(1, 100) < 7 then
            ResetMajorInjuries()
        end
        return true
    else
        StopAnimTask(ped, "anim@amb@business@weed@weed_inspecting_high_dry@", "weed_inspecting_high_base_inspector", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
        return false
    end
end)

lib.callback.register('hospital:client:UsePainkillers', function()
    local ped = cache.ped
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = Lang:t('progress.painkillers'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = "mp_suicide",
            clip = "pill",
        },
    })
    then
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["painkillers"], "remove")
        OnPainKillers = true
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        return true
    else
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
        return false
    end
end)

local function consumePainKiller()
    painkillerAmount -= 1
    Wait(Config.PainkillerInterval * 1000)
    if painkillerAmount > 0 then return end
    painkillerAmount = 0
    OnPainKillers = false
end

CreateThread(function()
    while true do
        Wait(1)
        if OnPainKillers then
            consumePainKiller()
        else
            Wait(3000)
        end
    end
end)

---@param ped number
local function applyBleedEffects(ped)
    local bleedDamage = exports['qbx-medical']:getBleedLevel() * Config.BleedTickDamage
    ApplyDamageToPed(ped, bleedDamage, false)
    SendBleedAlert()
    PlayerHealth = PlayerHealth - bleedDamage
    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)
    TriggerServerEvent("evidence:server:CreateBloodDrop", PlayerData.citizenid, PlayerData.metadata.bloodtype, coords)

    local advanceBleedTimer = exports['qbx-medical']:getAdvanceBleedTimerDeprecated()
    if advanceBleedTimer >= Config.AdvanceBleedTimer then
        ApplyBleed(1)
        exports['qbx-medical']:setAdvanceBleedTimerDeprecated(0)
    else
        exports['qbx-medical']:setAdvanceBleedTimerDeprecated(advanceBleedTimer + 1)
    end
end

---@param ped number
local function handleBleeding(ped)
    local bleedLevel = exports['qbx-medical']:getBleedLevel()
    if IsDead or InLaststand or bleedLevel <= 0 then return end
    exports['qbx-medical']:handleBloodLossEffectsDeprecated()
    applyBleedEffects(ped)
end

---@param ped number
local function bleedTick(ped)
    local bleedTickTimer = exports['qbx-medical']:getBleedTickTimerDeprecated()
    if math.floor(bleedTickTimer % (Config.BleedTickRate / 10)) == 0 then
        local currPos = GetEntityCoords(ped, true)
        local moving = #(prevPos.xy - currPos.xy)
        if (moving > 1 and not cache.vehicle) and exports['qbx-medical']:getBleedLevel() > 2 then
            exports['qbx-medical']:setAdvanceBleedTimerDeprecated(exports['qbx-medical']:getAdvanceBleedTimerDeprecated() + Config.BleedMovementAdvance)
            bleedTickTimer += Config.BleedMovementTick
            prevPos = currPos
        else
            bleedTickTimer += 1
        end
    end
    bleedTickTimer += 1
    exports['qbx-medical']:setBleedTickTimerDeprecated(bleedTickTimer)
end

local function checkBleeding()
    if exports['qbx-medical']:getBleedLevel() == 0 or OnPainKillers then return end
    local player = cache.ped
    if exports['qbx-medical']:getBleedTickTimerDeprecated() >= Config.BleedTickRate and not IsInHospitalBed then
        handleBleeding(player)
        exports['qbx-medical']:setBleedTickTimerDeprecated(0)
    else
        bleedTick(player)
    end
end

CreateThread(function()
    Wait(2500)
    prevPos = GetEntityCoords(cache.ped, true)
    while true do
        Wait(1000)
        checkBleeding()
    end
end)
