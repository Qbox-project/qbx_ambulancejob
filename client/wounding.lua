local painkillerAmount = 0

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
        TriggerEvent("inventory:client:ItemBox", QBX.Shared.Items["ifaks"], "remove")
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        OnPainKillers = true
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        if math.random(1, 100) < 50 then
            exports['qbx-medical']:removeBleed(1)
        end
        return true
    else
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        QBX.Functions.Notify(Lang:t('error.canceled'), 'error')
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
        TriggerEvent("inventory:client:ItemBox", QBX.Shared.Items["bandage"], "remove")
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        if math.random(1, 100) < 50 then
            exports['qbx-medical']:removeBleed(1)
        end
        if math.random(1, 100) < 7 then
            exports['qbx-medical']:resetMinorInjuries()
        end
        return true
    else
        StopAnimTask(ped, "anim@amb@business@weed@weed_inspecting_high_dry@", "weed_inspecting_high_base_inspector", 1.0)
        QBX.Functions.Notify(Lang:t('error.canceled'), 'error')
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
        TriggerEvent("inventory:client:ItemBox", QBX.Shared.Items["painkillers"], "remove")
        OnPainKillers = true
        if painkillerAmount < 3 then
            painkillerAmount += 1
        end
        return true
    else
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        QBX.Functions.Notify(Lang:t('error.canceled'), 'error')
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

CreateThread(function()
    Wait(2500)
    while true do
        Wait(1000)
        if not OnPainKillers then
            exports['qbx-medical']:checkBleedingDeprecated()
        end
    end
end)
