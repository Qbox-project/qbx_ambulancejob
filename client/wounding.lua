local config = require 'config.client'
local painkillerAmount = 0

lib.callback.register('hospital:client:UseIfaks', function()
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = locale('progress.ifaks'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'mp_suicide',
            clip = 'pill',
        },
    })
    then
        StopAnimTask(cache.ped, 'mp_suicide', 'pill', 1.0)
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))
        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 10)
        OnPainKillers = true
        exports.qbx_medical:DisableDamageEffects()
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        if math.random(1, 100) < 50 then
            exports.qbx_medical:removeBleed(1)
        end
        return true
    else
        StopAnimTask(cache.ped, 'mp_suicide', 'pill', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

lib.callback.register('hospital:client:UseBandage', function()
    if lib.progressCircle({
        duration = 4000,
        position = 'bottom',
        label = locale('progress.bandage'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'mp_suicide',
            clip = 'pill',
        },
    })
    then
        StopAnimTask(cache.ped, 'anim@amb@business@weed@weed_inspecting_high_dry@', 'weed_inspecting_high_base_inspector', 1.0)
        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) + 10)
        if math.random(1, 100) < 50 then
            exports.qbx_medical:removeBleed(1)
        end
        if math.random(1, 100) < 7 then
            exports.qbx_medical:resetMinorInjuries()
        end
        return true
    else
        StopAnimTask(cache.ped, 'anim@amb@business@weed@weed_inspecting_high_dry@', 'weed_inspecting_high_base_inspector', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

lib.callback.register('hospital:client:UsePainkillers', function()
    if lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = locale('progress.painkillers'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = 'mp_suicide',
            clip = 'pill',
        },
    })
    then
        StopAnimTask(cache.ped, 'mp_suicide', 'pill', 1.0)
        OnPainKillers = true
        exports.qbx_medical:DisableDamageEffects()
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        return true
    else
        StopAnimTask(cache.ped, 'mp_suicide', 'pill', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
        return false
    end
end)

local function consumePainKiller()
    painkillerAmount -= 1
    Wait(config.painkillerInterval * 1000)
    if painkillerAmount > 0 then return end
    painkillerAmount = 0
    OnPainKillers = false
    exports.qbx_medical:EnableDamageEffects()
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