return {

    ---@type table<string, HospitalData>
    hospitals = {
        ambulance = { -- Pillbox
            blip = {
                label = 'Pillbox Hill Medical Center',
                coords = vec3(304.27, -600.33, 43.28),
                sprite = 61,
                scale = 0.8,
                color = 25
            },
            duty = {
                {
                    coords = vec3(311.18, -599.25, 43.29),
                    radius = 1.5,
                    groups = { ambulance = 0 }
                },
            },
            management = {
                {
                    coords = vec3(337.21, -592.92, 43.29),
                    radius = 1.5,
                    groups = { ambulance = 0 }
                }
            },
            armory = {
                {
                    shopType = 'MedicalCloset',
                    name = 'Medical Closet',
                    radius = 1.5,
                    groups = { ambulance = 0 },
                    inventory = {
                        { name = 'weapon_flashlight', price = 50, metadata = { registered = true, serial = 'LEO' } },
                        { name = 'radio', price = 50 },
                        { name = 'bandage', price = 50 },
                        { name = 'painkillers', price = 100 },
                    },
                    locations = {
                        vec3(309.93, -602.94, 43.29),
                    }
                }
            },
            personalStash = {
                {
                    label = 'Personal Stash',
                    coords = vec3(309.78, -596.6, 43.29),
                    radius = 1.5,
                    slots = 100,
                    weight = 100000,
                    groups = { ambulance = 0 }
                },
            },
            garage = {
                {
                    coords = vec3(-586.17, -427.92, 31.16),
                    spawn = vec4(-588.28, -419.13, 30.59, 270.21),
                    radius = 2.5,
                    catalogue = {
                        { name = 'ambulance', grade = 0 },
                    },
                    groups = { ambulance = 0 }
                },
            },
            helipad = {
                {
                    coords = vec3(-595.85, -431.48, 51.38),
                    spawn = vec4(-595.85, -431.48, 51.38, 2.56),
                    radius = 2.5,
                    catalogue = {
                        { name = 'polmav', grade = 0 },
                    },
                    groups = { ambulance = 0 }
                }
            }
        },
    },
}