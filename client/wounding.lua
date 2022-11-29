local prevPos = nil
onPainKillers = false
local painkillerAmount = 0

-- Functions
local function DoBleedAlert()
    if not isDead and tonumber(isBleeding) > 0 then
        lib.notify({
            title = Lang:t('info.bleed_alert'),
            description = Config.BleedingStates[tonumber(isBleeding)].label,
            type = 'inform'
        })
    end
end

local function RemoveBleed(level)
    if isBleeding ~= 0 then
        if isBleeding - level < 0 then
            isBleeding = 0
        else
            isBleeding = isBleeding - level
        end

        DoBleedAlert()
    end
end

local function ApplyBleed(level)
    if isBleeding ~= 4 then
        if isBleeding + level > 4 then
            isBleeding = 4
        else
            isBleeding = isBleeding + level
        end

        DoBleedAlert()
    end
end

-- Events
RegisterNetEvent('hospital:client:UseIfaks', function()
    if lib.progressBar({
        duration = 3000,
        position = 'bottom',
        label = Lang:t('progress.ifaks'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false
        },
        anim = {
            dict = "mp_suicide",
            clip = "pill"
        }
    }) then
        StopAnimTask(cache.ped, "mp_suicide", "pill", 1.0)

        TriggerServerEvent("hospital:server:removeIfaks")
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))

        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 10)

        onPainKillers = true

        if painkillerAmount < 3 then
            painkillerAmount = painkillerAmount + 1
        end

        if math.random(1, 100) < 50 then
            RemoveBleed(1)
        end
    else
        StopAnimTask(cache.ped, "mp_suicide", "pill", 1.0)

        lib.notify({
            description = Lang:t('error.canceled'),
            type = 'error'
        })
    end
end)

RegisterNetEvent('hospital:client:UseBandage', function()
    if lib.progressBar({
        duration = 4000,
        position = 'bottom',
        label = Lang:t('progress.bandage'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false
        },
        anim = {
            dict = "mp_suicide",
            clip = "pill"
        }
    }) then
        StopAnimTask(cache.ped, "anim@amb@business@weed@weed_inspecting_high_dry@", "weed_inspecting_high_base_inspector", 1.0)

        TriggerServerEvent("hospital:server:removeBandage")

        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 10)

        if math.random(1, 100) < 50 then
            RemoveBleed(1)
        end

        if math.random(1, 100) < 7 then
            ResetPartial()
        end
    else
        StopAnimTask(cache.ped, "anim@amb@business@weed@weed_inspecting_high_dry@", "weed_inspecting_high_base_inspector", 1.0)

        lib.notify({
            description = Lang:t('error.canceled'),
            type = 'error'
        })
    end
end)

RegisterNetEvent('hospital:client:UsePainkillers', function()
    if lib.progressBar({
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
    }) then
        StopAnimTask(cache.ped, "mp_suicide", "pill", 1.0)

        TriggerServerEvent("hospital:server:removePainkillers")

        onPainKillers = true

        if painkillerAmount < 3 then
            painkillerAmount = painkillerAmount + 1
        end
    else
        StopAnimTask(cache.ped, "mp_suicide", "pill", 1.0)

        lib.notify({
            description = Lang:t('error.canceled'),
            type = 'error'
        })
    end
end)

-- Threads
CreateThread(function()
    while true do
        Wait(0)

        if onPainKillers then
            painkillerAmount = painkillerAmount - 1
            
            Wait(Config.PainkillerInterval * 1000)

            if painkillerAmount <= 0 then
                painkillerAmount = 0
                onPainKillers = false
            end
        else
            Wait(3000)
        end
    end
end)

CreateThread(function()
    while true do
        if #injured > 0 then
            local level = 0

            for _, v in pairs(injured) do
                if v.severity > level then
                    level = v.severity
                end
            end

            SetPedMoveRateOverride(cache.ped, Config.MovementRate[level])

            Wait(0)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    Wait(2500)

    prevPos = GetEntityCoords(cache.ped, true)

    while true do
        Wait(1000)

        if isBleeding > 0 and not onPainKillers then
            if bleedTickTimer >= Config.BleedTickRate and not isInHospitalBed then
                if not isDead and not InLaststand then
                    if isBleeding > 0 then
                        if fadeOutTimer + 1 == Config.FadeOutTimer then
                            if blackoutTimer + 1 == Config.BlackoutTimer then
                                SetFlash(0, 0, 100, 7000, 100)

                                DoScreenFadeOut(500)
                                while not IsScreenFadedOut() do
                                    Wait(0)
                                end

                                if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08) -- change this float to increase/decrease camera shake
                                    SetPedToRagdollWithFall(cache.ped, 7500, 9000, 1, GetEntityForwardVector(cache.ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                                end

                                Wait(1500)
                                DoScreenFadeIn(1000)

                                blackoutTimer = 0
                            else
                                DoScreenFadeOut(500)
                                while not IsScreenFadedOut() do
                                    Wait(0)
                                end
                                DoScreenFadeIn(500)

                                if isBleeding > 3 then
                                    blackoutTimer = blackoutTimer + 2
                                else
                                    blackoutTimer = blackoutTimer + 1
                                end
                            end

                            fadeOutTimer = 0
                        else
                            fadeOutTimer = fadeOutTimer + 1
                        end

                        local bleedDamage = tonumber(isBleeding) * Config.BleedTickDamage

                        ApplyDamageToPed(cache.ped, bleedDamage, false)

                        DoBleedAlert()

                        playerHealth = playerHealth - bleedDamage

                        local randX = math.random() + math.random(-1, 1)
                        local randY = math.random() + math.random(-1, 1)
                        local coords = GetOffsetFromEntityInWorldCoords(cache.ped, randX, randY, 0)

                        TriggerServerEvent("evidence:server:CreateBloodDrop", QBCore.Functions.GetPlayerData().citizenid, QBCore.Functions.GetPlayerData().metadata.bloodtype, coords)

                        if advanceBleedTimer >= Config.AdvanceBleedTimer then
                            ApplyBleed(1)

                            advanceBleedTimer = 0
                        else
                            advanceBleedTimer = advanceBleedTimer + 1
                        end
                    end
                end

                bleedTickTimer = 0
            else
                if math.floor(bleedTickTimer % (Config.BleedTickRate / 10)) == 0 then
                    local currPos = GetEntityCoords(cache.ped, true)
                    local moving = #(vec2(prevPos.x, prevPos.y) - vec2(currPos.x, currPos.y))

                    if (moving > 1 and not IsPedInAnyVehicle(cache.ped)) and isBleeding > 2 then
                        advanceBleedTimer = advanceBleedTimer + Config.BleedMovementAdvance
                        bleedTickTimer = bleedTickTimer + Config.BleedMovementTick
                        prevPos = currPos
                    else
                        bleedTickTimer = bleedTickTimer + 1
                    end
                end

                bleedTickTimer = bleedTickTimer + 1
            end
        end
    end
end)
