local function displayRespawnText()
    local deathTime = exports['qbx-medical']:getDeathTime()
    if deathTime > 0 and DoctorCount > 0 then
        DrawText2D(Lang:t('info.respawn_txt', { deathtime = math.ceil(deathTime) }), vec2(0.93, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    else
        DrawText2D(Lang:t('info.respawn_revive', { holdtime = RespawnHoldTime, cost = Config.BillCost }), vec2(0.865, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    end
end

---@param ped number
local function playDeadAnimation(ped)
    if IsInHospitalBed then
        if not IsEntityPlayingAnim(ped, InBedDict, InBedAnim, 3) then
            lib.requestAnimDict(InBedDict)
            TaskPlayAnim(ped, InBedDict, InBedAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        exports['qbx-medical']:playDeadAnimation()
    end
end

---@param ped number
local function handleDead(ped)
    if not IsInHospitalBed then
        displayRespawnText()
    end

    playDeadAnimation(ped)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end

---@param ped number
local function playEscortedLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        if IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
            StopAnimTask(ped, "veh@low@front_ps@idle_duck", "sit", 3)
        end
    else
        lib.requestAnimDict(LastStandDict)
        if IsEntityPlayingAnim(ped, LastStandDict, LastStandAnim, 3) then
            StopAnimTask(ped, LastStandDict, LastStandAnim, 3)
        end
    end
end

---@param ped number
local function playUnescortedLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict("veh@low@front_ps@idle_duck")
        if not IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
            TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        lib.requestAnimDict(LastStandDict)
        if not IsEntityPlayingAnim(ped, LastStandDict, LastStandAnim, 3) then
            TaskPlayAnim(ped, LastStandDict, LastStandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    end
end

---@param ped number
local function playLastStandAnimation(ped)
    if IsEscorted then
        playEscortedLastStandAnimation(ped)
    else
        playUnescortedLastStandAnimation(ped)
    end
end

---Player is able to send a notification to EMS there are any on duty
local function handleRequestingEms()
    if DoctorCount == 0 then return end
    if not EmsNotified then
        DrawText2D(Lang:t('info.request_help'), vec2(0.91, 1.40), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
        if IsControlJustPressed(0, 47) then
            TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
            EmsNotified = true
        end
    else
        DrawText2D(Lang:t('info.help_requested'), vec2(0.90, 1.40), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    end
end

---@param ped number
local function handleLastStand(ped)
    local laststandTime = exports['qbx-medical']:getLaststandTime()
    if laststandTime > Laststand.MinimumRevive then
        DrawText2D(Lang:t('info.bleed_out', { time = math.ceil(laststandTime) }), vec2(0.94, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    else
        DrawText2D(Lang:t('info.bleed_out_help', { time = math.ceil(laststandTime) }), vec2(0.845, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
        handleRequestingEms()
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

---Set dead and last stand states.
CreateThread(function()
    while true do
        local isDead = exports['qbx-medical']:isDead()
        local inLaststand = exports['qbx-medical']:getLaststand()
        if isDead or inLaststand then
            disableControls()
            if isDead then
                handleDead(cache.ped)
            elseif inLaststand then
                handleLastStand(cache.ped)
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)