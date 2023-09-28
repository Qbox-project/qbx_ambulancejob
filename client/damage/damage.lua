---Checks the player for damage, applies injuries, and damage effects
CreateThread(function()
    while true do
        exports.qbx_medical:checkForDamageDeprecated()
        if not OnPainKillers and not IsInHospitalBed then
            exports.qbx_medical:applyDamageEffectsDeprecated()
        end
        Wait(100)
    end
end)