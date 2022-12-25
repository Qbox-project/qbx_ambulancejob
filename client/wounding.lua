local prevPos = nil
local painkillerAmount = 0

local function sendBleedAlert()
    if IsDead or tonumber(IsBleeding) > 0 then return end
    lib.notify({ title = Lang:t('info.bleed_alert'), description = Config.BleedingStates[tonumber(IsBleeding)].label, type = 'inform' })
end

local function removeBleed(level)
    if IsBleeding == 0 then return end
    if IsBleeding - level < 0 then
        IsBleeding = 0
    else
        IsBleeding -= level
    end
    sendBleedAlert()
end

local function applyBleed(level)
    if IsBleeding >= 4 then return end

    if IsBleeding + level > 4 then
        IsBleeding = 4
    else
        IsBleeding += level
    end
    sendBleedAlert()
end

-- Events

RegisterNetEvent('hospital:client:UseIfaks', function()
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
        TriggerServerEvent("hospital:server:removeIfaks")
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
    else
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)

RegisterNetEvent('hospital:client:UseBandage', function()
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
        TriggerServerEvent("hospital:server:removeBandage")
        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["bandage"], "remove")
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        if math.random(1, 100) < 50 then
            removeBleed(1)
        end
        if math.random(1, 100) < 7 then
            ResetPartial()
        end
    else
        StopAnimTask(ped, "anim@amb@business@weed@weed_inspecting_high_dry@", "weed_inspecting_high_base_inspector", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
    end
end)

RegisterNetEvent('hospital:client:UsePainkillers', function()
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
        TriggerServerEvent("hospital:server:removePainkillers")
        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["painkillers"], "remove")
        OnPainKillers = true
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
    else
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        lib.notify({ description = Lang:t('error.canceled'), type = 'error' })
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

local function getWorstInjury()
    local level = 0
    for _, injury in pairs(Injured) do
        if injury.severity > level then
            level = injury.severity
        end
    end

    return level
end

CreateThread(function()
    while true do
        if #Injured > 0 then
            local level = getWorstInjury()
            SetPedMoveRateOverride(cache.ped, Config.MovementRate[level])
            Wait(5)
        else
            Wait(1000)
        end
    end
end)

local function makePlayerBlackout(player)
    SetFlash(0, 0, 100, 7000, 100)

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    if not IsPedRagdoll(player) and IsPedOnFoot(player) and not IsPedSwimming(player) then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08) -- change this float to increase/decrease camera shake
        SetPedToRagdollWithFall(player, 7500, 9000, 1, GetEntityForwardVector(player), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    end

    Wait(1500)
    DoScreenFadeIn(1000)
end

local function makePlayerFadeOut()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    DoScreenFadeIn(500)
end

local function applyBleedEffects(player)
    local bleedDamage = tonumber(IsBleeding) * Config.BleedTickDamage
    ApplyDamageToPed(player, bleedDamage, false)
    sendBleedAlert()
    PlayerHealth = PlayerHealth - bleedDamage
    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(player, randX, randY, 0)
    TriggerServerEvent("evidence:server:CreateBloodDrop", QBCore.Functions.GetPlayerData().citizenid, QBCore.Functions.GetPlayerData().metadata["bloodtype"], coords)

    if AdvanceBleedTimer >= Config.AdvanceBleedTimer then
        applyBleed(1)
        AdvanceBleedTimer = 0
    else
        AdvanceBleedTimer += 1
    end
end

local function handleBleeding(player)
    if IsDead or InLaststand or IsBleeding <= 0 then return end
    if FadeOutTimer + 1 == Config.FadeOutTimer then
        if BlackoutTimer + 1 == Config.BlackoutTimer then
            makePlayerBlackout(player)
            BlackoutTimer = 0
        else
            makePlayerFadeOut()
            BlackoutTimer += IsBleeding > 3 and 2 or 1
        end

        FadeOutTimer = 0
    else
        FadeOutTimer += 1
    end

    applyBleedEffects(player)
end

local function bleedTick(player)
    if math.floor(BleedTickTimer % (Config.BleedTickRate / 10)) == 0 then
        local currPos = GetEntityCoords(player, true)
        local moving = #(prevPos.xy - currPos.xy)
        if (moving > 1 and not cache.vehicle) and IsBleeding > 2 then
            AdvanceBleedTimer += Config.BleedMovementAdvance
            BleedTickTimer += Config.BleedMovementTick
            prevPos = currPos
        else
            BleedTickTimer += 1
        end
    end
    BleedTickTimer += 1
end

local function checkBleeding()
    if IsBleeding <= 0 or OnPainKillers then return end
    local player = cache.ped
    if BleedTickTimer >= Config.BleedTickRate and not IsInHospitalBed then
        handleBleeding(player)
        BleedTickTimer = 0
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
