local listen = false
local closestBed = nil
local getOutDict = 'switch@franklin@bed'
local getOutAnim = 'sleep_getup_rubeyes'
local bedObject = nil
local bedOccupyingData = nil
local cam = nil

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

RegisterNetEvent('qb-ambulancejob:checkin', function()
    if DoctorCount >= Config.MinimalDoctors then
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
            dict = HealAnimDict,
            clip = HealAnim,
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
                if DoctorCount >= Config.MinimalDoctors then
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

local function setClosestBed()
    if IsInHospitalBed then return end

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

CreateThread(function()
    while true do
        Wait(1000)
        setClosestBed()
        if IsStatusChecking then
            StatusCheckTime -= 1
            if StatusCheckTime <= 0 then
                StatusChecks = {}
                IsStatusChecking = false
            end
        end
    end
end)

local function leaveBed()
    local ped = cache.ped

    lib.requestAnimDict(getOutDict)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityHeading(ped, bedOccupyingData.coords.w + 90)
    TaskPlayAnim(ped, getOutDict, getOutAnim, 100.0, 1.0, -1, 8, -1, false, false, false)
    Wait(4000)
    ClearPedTasks(ped)
    TriggerServerEvent('hospital:server:LeaveBed', BedOccupying)
    FreezeEntityPosition(bedObject, true)
    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    BedOccupying = nil
    bedObject = nil
    bedOccupyingData = nil
    IsInHospitalBed = false

    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.metadata.injail <= 0 then return end
        TriggerEvent("prison:client:Enter", PlayerData.metadata.injail)
    end)
end

--- shows leave bed text if the player can leave the bed, triggers leaving the bed if the right key is pressed.
local function givePlayerOptionToLeaveBed()
    lib.showTextUI(Lang:t('text.bed_out'))
    if not IsControlJustReleased(0, 38) then return end

    exports['qb-core']:KeyPressed(38)
    leaveBed()
    lib.hideTextUI()
end

CreateThread(function()
    while true do
        if IsInHospitalBed and CanLeaveBed then
            givePlayerOptionToLeaveBed()
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

--- teleports the player to lie down in bed and sets the player's camera.
local function setBedCam()
    IsInHospitalBed = true
    CanLeaveBed = false
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

    lib.requestAnimDict(InBedDict)

    TaskPlayAnim(player, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
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

--- puts the player in bed
---@param id number the map key of the bed
---@param data any the bed object
---@param isRevive boolean if true, heals the player
RegisterNetEvent('hospital:client:SendToBed', function(id, data, isRevive)
    BedOccupying = id
    bedOccupyingData = data
    setBedCam()
    CreateThread(function()
        Wait(5)
        if isRevive then
            lib.notify({ description = Lang:t('success.being_helped'), type = 'success' })
            Wait(Config.AIHealTimer * 1000)
            TriggerEvent("hospital:client:Revive")
        else
            CanLeaveBed = true
        end
    end)
end)
