local bedObject = nil
local bedOccupyingData = nil
local cam = nil
local hospitalOccupying = nil
local bedIndexOccupying = nil

---Teleports the player to lie down in bed and sets the player's camera.
local function setBedCam()
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

local function putPlayerInBed(hospitalName, bedIndex, isRevive, skipOpenCheck)
    if IsInHospitalBed then return end
    if not skipOpenCheck then
        if lib.callback.await('qbx-ambulancejob:server:isBedTaken', false, hospitalName, bedIndex) then
            QBCore.Functions.Notify(Lang:t('error.beds_taken'), 'error')
            return
        end
    end

    hospitalOccupying = hospitalName
    bedIndexOccupying = bedIndex
    bedOccupyingData = Config.Locations.hospitals[hospitalName].beds[bedIndex]
    IsInHospitalBed = true
    exports['qbx-medical']:disableRespawn()
    CanLeaveBed = false
    setBedCam()
    CreateThread(function()
        Wait(5)
        if isRevive then
            QBCore.Functions.Notify(Lang:t('success.being_helped'), 'success')
            Wait(Config.AIHealTimer * 1000)
            TriggerEvent("hospital:client:Revive")
        else
            CanLeaveBed = true
        end
    end)
    TriggerServerEvent('qbx-ambulancejob:server:playerEnteredBed', hospitalName, bedIndex)
end

RegisterNetEvent('qbx-ambulancejob:client:onPlayerRespawn', function(hospitalName, bedIndex)
    putPlayerInBed(hospitalName, bedIndex, true, true)
end)

---Notifies doctors, and puts player in a hospital bed.
local function checkIn(hospitalName)
    local canCheckIn = lib.callback.await('qbx-ambulancejob:server:onCheckIn')
    if not canCheckIn then return end

    exports.scully_emotemenu:playEmoteByCommand('notepad')
    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        label = Lang:t('progress.checking_in'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
    })
    then
        exports.scully_emotemenu:cancelEmote()
        --- ask server for first non taken bed
        local bedIndex = lib.callback.await('qbx-ambulancejob:server:getOpenBed', false, hospitalName)
        if not bedIndex then
            QBCore.Functions.Notify(Lang:t('error.beds_taken'), 'error')
            return
        end

        putPlayerInBed(hospitalName, bedIndex, true, true)
    else
        exports.scully_emotemenu:cancelEmote()
        QBCore.Functions.Notify(Lang:t('error.canceled'), 'error')
    end
end

---Set up check-in and getting into beds using either target or zones
if Config.UseTarget then
    CreateThread(function()
        for hospitalName, hospital in pairs(Config.Locations.hospitals) do
            if hospital.checkIn then
                exports.ox_target:addBoxZone({
                    name = hospitalName.."_checkin",
                    coords = hospital.checkIn,
                    size = vec3(2, 1, 2),
                    rotation = 18,
                    debug = false,
                    options = {
                        {
                            onSelect = function()
                                checkIn(hospitalName)
                            end,
                            icon = "fas fa-clipboard",
                            label = Lang:t('text.check'),
                            distance = 1.5,
                        }
                    }
                })
            end

            for i = 1, #hospital.beds do
                local bed = hospital.beds[i]
                exports.ox_target:addBoxZone({
                    name = hospitalName.."_bed_"..i,
                    coords = bed.coords.xyz,
                    size = vec3(1.7, 1.9, 2),
                    rotation = bed.coords.w,
                    debug = false,
                    options = {
                        {
                            onSelect = function()
                                putPlayerInBed(hospitalName, i, false)
                            end,
                            icon = "fas fa-clipboard",
                            label = Lang:t('text.bed'),
                            distance = 1.5,
                        }
                    }
                })
            end
        end
    end)
else
    CreateThread(function()
        for hospitalName, hospital in pairs(Config.Locations.hospitals) do

            if hospital.checkIn then
                local function enterCheckInZone()
                    if DoctorCount >= Config.MinimalDoctors then
                        lib.showTextUI(Lang:t('text.call_doc'))
                    else
                        lib.showTextUI(Lang:t('text.check_in'))
                    end
                end

                local function outCheckInZone()
                    lib.hideTextUI()
                end

                local function insideCheckInZone()
                    if IsControlJustPressed(0, 38) then
                        exports['qbx-core']:KeyPressed(38)
                        checkIn(hospitalName)
                    end
                end

                lib.zones.box({
                    coords = hospital.checkIn,
                    size = vec3(2, 1, 2),
                    rotation = 18,
                    debug = false,
                    onEnter = enterCheckInZone,
                    onExit = outCheckInZone,
                    inside = insideCheckInZone,
                })
            end
            
            for i = 1, #hospital.beds do
                local bed = hospital.beds[i]
                local function enterBedZone()
                    if not IsInHospitalBed then
                        lib.showTextUI(Lang:t('text.lie_bed'))
                    end
                end

                local function outBedZone()
                    lib.hideTextUI()
                end

                local function insideBedZone()
                    if IsControlJustPressed(0, 38) then
                        exports['qbx-core']:KeyPressed(38)
                        putPlayerInBed(hospitalName, i, false)
                    end
                end

                lib.zones.box({
                    coords = bed.coords.xyz,
                    size = vec3(1.9, 2.1, 2),
                    rotation = bed.coords.w,
                    debug = false,
                    onEnter = enterBedZone,
                    onExit = outBedZone,
                    inside = insideBedZone,
                })
            end
        end
    end)
end

---plays animation to get out of bed and resets variables
local function leaveBed()
    local ped = cache.ped
    local getOutDict = 'switch@franklin@bed'
    local getOutAnim = 'sleep_getup_rubeyes'

    lib.requestAnimDict(getOutDict)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityHeading(ped, bedOccupyingData.coords.w + 90)
    TaskPlayAnim(ped, getOutDict, getOutAnim, 100.0, 1.0, -1, 8, -1, false, false, false)
    Wait(4000)
    ClearPedTasks(ped)
    TriggerServerEvent('qbx-ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
    FreezeEntityPosition(bedObject, true)
    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    hospitalOccupying = nil
    bedIndexOccupying = nil
    bedObject = nil
    bedOccupyingData = nil
    IsInHospitalBed = false

    if PlayerData.metadata.injail <= 0 then return end
    TriggerEvent("prison:client:Enter", PlayerData.metadata.injail)
end

---shows player option to press key to leave bed when available.
CreateThread(function()
    while true do
        if IsInHospitalBed and CanLeaveBed then
            lib.showTextUI(Lang:t('text.bed_out'))
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

---reset player settings that the server is storing
local function onPlayerUnloaded()
    if bedIndexOccupying then
        TriggerServerEvent('qbx-ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', onPlayerUnloaded)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    onPlayerUnloaded()
end)
