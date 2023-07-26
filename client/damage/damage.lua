local playerArmor = nil

---If the player health and armor haven't already been set, initialize them.
---@param health number
---@param armor number
local function initHealthAndArmorIfNotSet(health, armor)
    if not exports['qbx-medical']:getHp() then
        exports['qbx-medical']:setHp(health)
    end

    if not playerArmor then
        playerArmor = armor
    end
end

---detects if player took damage, applies injuries, and updates health/armor values
---@param ped number
local function checkForDamage(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)

    initHealthAndArmorIfNotSet(health, armor)

    local isArmorDamaged = (playerArmor ~= armor and armor < (playerArmor - Config.ArmorDamage) and armor > 0) -- Players armor was damaged
    local isHealthDamaged = (exports['qbx-medical']:getHp() ~= health) -- Players health was damaged

    if isArmorDamaged or isHealthDamaged then
        local damageDone = (exports['qbx-medical']:getHp() - health)
        exports['qbx-medical']:applyDamageDeprecated(ped, damageDone, isArmorDamaged)
        exports['qbx-medical']:findDamageCauseDeprecated()
        ClearEntityLastDamageEntity(ped)
    end

    exports['qbx-medical']:setHp(health)
    playerArmor = armor
end

---Checks the player for damage, applies injuries, and damage effects
CreateThread(function()
    while true do
        local ped = cache.ped
        checkForDamage(ped)
        if not OnPainKillers and not IsInHospitalBed then
            exports['qbx-medical']:applyDamageEffectsDeprecated()
        end
        Wait(100)
    end
end)