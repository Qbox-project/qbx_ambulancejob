local function drawTxt(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(false)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width / 2, y - height / 2 + 0.005)
end

local function isEmsOnDuty()
    local p = promise.new()
    QBCore.Functions.TriggerCallback('hospital:GetDoctors', function(medics)
        p:resolve(medics > 0)
    end)

    return Citizen.Await(p)
end

local function displayRespawnText()
    if deathTime > 0 and isEmsOnDuty() then
        drawTxt(0.93, 1.44, 1.0, 1.0, 0.6, Lang:t('info.respawn_txt', { deathtime = math.ceil(deathTime) }), 255, 255, 255, 255)
    else
        drawTxt(0.865, 1.44, 1.0, 1.0, 0.6, Lang:t('info.respawn_revive', { holdtime = hold, cost = Config.BillCost }), 255, 255, 255, 255)
    end
end

local function playDeadAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        if not IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
            TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        if isInHospitalBed then
            if not IsEntityPlayingAnim(ped, inBedDict, inBedAnim, 3) then
                lib.requestAnimDict(inBedDict)
                TaskPlayAnim(ped, inBedDict, inBedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
            end
        else
            if not IsEntityPlayingAnim(ped, deadAnimDict, deadAnim, 3) then
                lib.requestAnimDict(deadAnimDict)
                TaskPlayAnim(ped, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
            end
        end
    end
end

local function handleDead(ped)
    if not isInHospitalBed then
        displayRespawnText()
    end

    playDeadAnimation(ped)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end

local function playEscortedLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        if IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
            StopAnimTask(ped, "veh@low@front_ps@idle_duck", "sit", 3)
        end
    else
        lib.requestAnimDict(lastStandDict)
        if IsEntityPlayingAnim(ped, lastStandDict, lastStandAnim, 3) then
            StopAnimTask(ped, lastStandDict, lastStandAnim, 3)
        end
    end
end

local function playUnescortedLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        if not IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
            TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        lib.requestAnimDict(lastStandDict)
        if not IsEntityPlayingAnim(ped, lastStandDict, lastStandAnim, 3) then
            TaskPlayAnim(ped, lastStandDict, lastStandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    end
end

local function playLastStandAnimation(ped)
    if isEscorted then
        playEscortedLastStandAnimation(ped)
    else
        playUnescortedLastStandAnimation(ped)
    end
end

local function handleLastStand(ped)
    if LaststandTime > Laststand.MinimumRevive then
        drawTxt(0.94, 1.44, 1.0, 1.0, 0.6, Lang:t('info.bleed_out', { time = math.ceil(LaststandTime) }), 255, 255, 255, 255)
    else
        drawTxt(0.845, 1.44, 1.0, 1.0, 0.6, Lang:t('info.bleed_out_help', { time = math.ceil(LaststandTime) }), 255, 255, 255, 255)
        if not emsNotified then
            drawTxt(0.91, 1.40, 1.0, 1.0, 0.6, Lang:t('info.request_help'), 255, 255, 255, 255)
        else
            drawTxt(0.90, 1.40, 1.0, 1.0, 0.6, Lang:t('info.help_requested'), 255, 255, 255, 255)
        end

        if IsControlJustPressed(0, 47) and not emsNotified and isEmsOnDuty() then
            TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
            emsNotified = true
        end
    end

    playLastStandAnimation(ped)
end

local function disableControls()
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 0, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 288, true)
    EnableControlAction(0, 213, true)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
    EnableControlAction(0, 47, true)
end

--- Set dead and last stand states.
CreateThread(function()
    while true do
        if isDead or InLaststand then
            disableControls()
            if isDead then
                handleDead(cache.ped)
            elseif InLaststand then
                handleLastStand(cache.ped)
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)