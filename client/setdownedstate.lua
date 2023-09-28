local doctorCount = 0

local function getDoctorCount()
    return lib.callback.await('hospital:GetDoctors')
end

local function displayRespawnText()
    local deathTime = exports.qbx_medical:getDeathTime()
    if deathTime > 0 and doctorCount > 0 then
        DrawText2D(Lang:t('info.respawn_txt', { deathtime = math.ceil(deathTime) }), vec2(1.0, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    else
        DrawText2D(Lang:t('info.respawn_revive', { holdtime = exports.qbx_medical:getRespawnHoldTimeDeprecated(), cost = Config.BillCost }), vec2(1.0, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
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
        exports.qbx_medical:playDeadAnimation()
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

---Player is able to send a notification to EMS there are any on duty
local function handleRequestingEms()
    if not EmsNotified then
        DrawText2D(Lang:t('info.request_help'), vec2(1.0, 1.40), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
        if IsControlJustPressed(0, 47) then
            TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
            EmsNotified = true
        end
    else
        DrawText2D(Lang:t('info.help_requested'), vec2(1.0, 1.40), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    end
end

local function handleLastStand()
    local laststandTime = exports.qbx_medical:getLaststandTime()
    if laststandTime > Config.LaststandMinimumRevive then
        DrawText2D(Lang:t('info.bleed_out', { time = math.ceil(laststandTime) }), vec2(1.0, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    elseif doctorCount == 0 then
        DrawText2D(Lang:t('info.bleed_out', { time = math.ceil(laststandTime) }), vec2(1.0, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
    else
        DrawText2D(Lang:t('info.bleed_out_help', { time = math.ceil(laststandTime) }), vec2(1.0, 1.44), 1.0, 1.0, 0.6, 4, 255, 255, 255, 255)
        handleRequestingEms()
    end

    exports.qbx_medical:playLastStandAnimationDeprecated()
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
        local isDead = exports.qbx_medical:isDead()
        local inLaststand = exports.qbx_medical:getLaststand()
        if isDead or inLaststand then
            disableControls()
            if isDead then
                handleDead(cache.ped)
            elseif inLaststand then
                handleLastStand()
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        doctorCount = getDoctorCount()
        Wait(60000)
    end
end)
