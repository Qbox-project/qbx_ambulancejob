local config = require 'config.client'
local sharedConfig = require 'config.shared'
local bedObject
local bedOccupyingData
local cam
local hospitalOccupying
local bedIndexOccupying

---Teleports the player to lie down in bed and sets the player's camera.
local function setBedCam()
    DoScreenFadeOut(1000)

    while not IsScreenFadedOut() do
        Wait(100)
    end

    if IsPedDeadOrDying(cache.ped, true) then
        local pos = GetEntityCoords(cache.ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(cache.ped), true, false)
    end

    bedObject = GetClosestObjectOfType(bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z, 1.0, bedOccupyingData.model, false, false, false)
    FreezeEntityPosition(bedObject, true)

    SetEntityCoords(cache.ped, bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z + 0.02, true, true, true, false)
    Wait(500)
    FreezeEntityPosition(cache.ped, true)

    lib.playAnim(cache.ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
    SetEntityHeading(cache.ped, bedOccupyingData.coords.w)

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
    AttachCamToPedBone(cam, cache.ped, 31085, 0, 1.0, 1.0, true)
    SetCamFov(cam, 90.0)
    local heading = GetEntityHeading(cache.ped)
    heading = (heading > 180) and heading - 180 or heading + 180
    SetCamRot(cam, -45.0, 0.0, heading, 2)

    DoScreenFadeIn(1000)

    Wait(1000)
    FreezeEntityPosition(cache.ped, true)
end

local function putPlayerInBed(hospitalName, bedIndex, isRevive, skipOpenCheck)
    if IsInHospitalBed then return end
    if not skipOpenCheck then
        if lib.callback.await('qbx_ambulancejob:server:isBedTaken', false, hospitalName, bedIndex) then
            exports.qbx_core:Notify(locale('error.beds_taken'), 'error')
            return
        end
    end

    hospitalOccupying = hospitalName
    bedIndexOccupying = bedIndex
    bedOccupyingData = sharedConfig.locations.hospitals[hospitalName].beds[bedIndex]
    IsInHospitalBed = true
    exports.qbx_medical:DisableDamageEffects()
    exports.qbx_medical:DisableRespawn()
    CanLeaveBed = false
    setBedCam()
    CreateThread(function()
        Wait(5)
        if isRevive then
            exports.qbx_core:Notify(locale('success.being_helped'), 'success')
            Wait(config.aiHealTimer * 1000)
            TriggerEvent('hospital:client:Revive')
        else
            CanLeaveBed = true
        end
    end)
    TriggerServerEvent('qbx_ambulancejob:server:playerEnteredBed', hospitalName, bedIndex)
end

RegisterNetEvent('qbx_ambulancejob:client:putPlayerInBed', function(hospitalName, bedIndex)
    putPlayerInBed(hospitalName, bedIndex, false, true)
end)

---Notifies doctors, and puts player in a hospital bed.
local function checkIn(hospitalName)
    local canCheckIn = lib.callback.await('qbx_ambulancejob:server:canCheckIn', false, hospitalName)
    if not canCheckIn then return end

    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        label = locale('progress.checking_in'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            clip = 'base',
            dict= 'missheistdockssetup1clipboard@base',
            flag = 16
        },
        prop = {
            {
                model = 'prop_notepad_01',
                bone = 18905,
                pos = vec3(0.1, 0.02, 0.05),
                rot = vec3(10.0, 0.0, 0.0),
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = vec3(0.11, -0.02, 0.001),
                rot = vec3(-120.0, 0.0, 0.0)
            }
        }
    })
    then
        lib.callback.await('qbx_ambulancejob:server:checkIn', false, cache.serverId, hospitalName)
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end

RegisterNetEvent('qbx_ambulancejob:client:checkedIn', function(hospitalName, bedIndex)
    putPlayerInBed(hospitalName, bedIndex, true, true)
end)

---Set up check-in and getting into beds using either target or zones
if config.useTarget then
    CreateThread(function()
        for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
            if hospital.checkIn then
                exports.ox_target:addBoxZone({
                    name = hospitalName..'_checkin',
                    coords = hospital.checkIn,
                    size = vec3(2, 1, 2),
                    rotation = 18,
                    debug = config.debugPoly,
                    options = {
                        {
                            onSelect = function()
                                checkIn(hospitalName)
                            end,
                            icon = 'fas fa-clipboard',
                            label = locale('text.check'),
                            distance = 3.0,
                        }
                    }
                })
            end

            for i = 1, #hospital.beds do
                local bed = hospital.beds[i]
                exports.ox_target:addBoxZone({
                    name = hospitalName..'_bed_'..i,
                    coords = bed.coords.xyz,
                    size = vec3(1.7, 1.9, 2),
                    rotation = bed.coords.w,
                    debug = config.debugPoly,
                    options = {
                        {
                            onSelect = function()
                                putPlayerInBed(hospitalName, i, false)
                            end,
                            icon = 'fas fa-clipboard',
                            label = locale('text.bed'),
                            distance = 3.0,
                        },
                        {
                            canInteract = function()
                                return QBX.PlayerData.job.type == 'ems'
                            end,
                            onSelect = function()
                                local player = GetClosestPlayer()
                                if player then
                                    local playerId = GetPlayerServerId(player)
                                    TriggerServerEvent('hospital:server:putPlayerInBed', playerId, hospitalName, i)
                                end
                            end,
                            icon = 'fas fa-clipboard',
                            label = locale('text.put_bed'),
                            distance = 3.0,
                        }
                    }
                })
            end
        end
    end)
else
    CreateThread(function()
        for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
            if hospital.checkIn then
                lib.zones.box({
                    coords = hospital.checkIn,
                    size = vec3(2, 1, 2),
                    rotation = 18,
                    debug = config.debugPoly,
                    onEnter = function()
                        local numDoctors = lib.callback.await('qbx_ambulancejob:server:getNumDoctors')
                        if numDoctors >= sharedConfig.minForCheckIn then
                            lib.showTextUI(locale('text.call_doc'))
                        else
                            lib.showTextUI(locale('text.check_in'))
                        end
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                    inside = function()
                        if IsControlJustPressed(0, 38) then
                            checkIn(hospitalName)
                        end
                    end,
                })
            end

            for i = 1, #hospital.beds do
                local bed = hospital.beds[i]
                lib.zones.box({
                    coords = bed.coords.xyz,
                    size = vec3(1.9, 2.1, 2),
                    rotation = bed.coords.w,
                    debug = config.debugPoly,
                    onEnter = function()
                        if not IsInHospitalBed then
                            lib.showTextUI(locale('text.lie_bed'))
                        end
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                    inside = function()
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            putPlayerInBed(hospitalName, i, false)
                        end
                    end,
                })
            end
        end
    end)
end

---Plays animation to get out of bed and resets variables
local function leaveBed()
    lib.requestAnimDict('switch@franklin@bed', 10000)
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)
    SetEntityHeading(cache.ped, bedOccupyingData.coords.w + 90)
    TaskPlayAnim(cache.ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 100.0, 1.0, -1, 8, -1, false, false, false)
    RemoveAnimDict('switch@franklin@bed')
    Wait(4000)
    ClearPedTasks(cache.ped)
    TriggerServerEvent('qbx_ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
    FreezeEntityPosition(bedObject, true)
    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    hospitalOccupying = nil
    bedIndexOccupying = nil
    bedObject = nil
    bedOccupyingData = nil
    IsInHospitalBed = false
    exports.qbx_medical:EnableDamageEffects()

    if QBX.PlayerData.metadata.injail <= 0 then return end
    TriggerEvent('prison:client:Enter', QBX.PlayerData.metadata.injail)
end

---Shows player option to press key to leave bed when available.
CreateThread(function()
    while true do
        if IsInHospitalBed and CanLeaveBed then
            lib.showTextUI(locale('text.bed_out'))
            while IsInHospitalBed and CanLeaveBed do
                OnKeyPress(leaveBed)
                Wait(0)
            end
            lib.hideTextUI()
        else
            Wait(1000)
        end
    end
end)

---Reset player settings that the server is storing
local function onPlayerUnloaded()
    if bedIndexOccupying then
        TriggerServerEvent('qbx_ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', onPlayerUnloaded)

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource ~= resourceName then return end
    onPlayerUnloaded()
end)
