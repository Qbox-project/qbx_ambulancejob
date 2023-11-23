Config = {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add setr UseTarget true)
Config.MinimalDoctors = 2 -- How many players with the ambulance job to prevent the hospital check-in system from being used
Config.DocCooldown = 1 -- Cooldown between doctor calls allowed, in minutes
Config.WipeInventoryOnRespawn = true -- Enable or disable removing all the players items when they respawn at the hospital
Config.BillCost = 2000 -- Price that players are charged for using the hospital check-in system
Config.PainkillerInterval = 60 -- Set the length of time painkillers last (per one)
Config.AIHealTimer = 20 -- How long it will take to be healed after checking in, in seconds
Config.LaststandMinimumRevive = 300

Config.Locations = { -- Edit the various interaction points for players or create new ones
    duty = {
        vec3(311.18, -599.25, 43.29),
        vec3(-254.88, 6324.5, 32.58),
    },
    vehicle = {
        vec4(294.578, -574.761, 43.179, 35.79),
        vec4(-234.28, 6329.16, 32.15, 222.5),
    },
    helicopter = {
        vec4(351.58, -587.45, 74.16, 160.5),
        vec4(-475.43, 5988.353, 31.716, 31.34),
    },
    armory = { -- Currently not in use, use ox_inventory/data/shops.lua instead
        --vec3(0.0, 0.0, 0.0),
    },
    roof = {
        vec3(338.54, -583.88, 74.17),
    },
    main = {
        vec3(298.62, -599.66, 43.29),
    },
    stash = { -- Currently not in use, use ox_inventory/data/stashes.lua instead
        --vec3(0.0, 0.0, 0.0),
    },

    ---@class Bed
    ---@field coords vector4
    ---@field model number

    ---@type table<string, {coords: vector3, checkIn?: vector3, beds: Bed[]}>
    hospitals = {
        pillbox = {
            coords = vec3(350, -580, 43),
            checkIn = vec3(308.19, -595.35, 43.29),
            beds = {
                { coords = vec4(353.1, -584.6, 43.11, 152.08), model = 1631638868 },
                { coords = vec4(356.79, -585.86, 43.11, 152.08), model = 1631638868 },
                { coords = vec4(354.12, -593.12, 43.1, 336.32), model = 2117668672 },
                { coords = vec4(350.79, -591.8, 43.1, 336.32), model = 2117668672 },
                { coords = vec4(346.99, -590.48, 43.1, 336.32), model = 2117668672 },
                { coords = vec4(360.32, -587.19, 43.02, 152.08), model = -1091386327 },
                { coords = vec4(349.82, -583.33, 43.02, 152.08), model = -1091386327 },
                { coords = vec4(326.98, -576.17, 43.02, 152.08), model = -1091386327 },
            }
        },
        paleto = {
            coords = vec3(-250, 6315, 32),
            checkIn = vec3(-254.54, 6331.78, 32.43),
            beds = {
                { coords = vec4(-252.43, 6312.25, 32.34, 313.48), model = 2117668672 },
                { coords = vec4(-247.04, 6317.95, 32.34, 134.64), model = 2117668672 },
                { coords = vec4(-255.98, 6315.67, 32.34, 313.91), model = 2117668672 },
            }
        },
        jail = {
            coords = vec3(1761, 2600, 46),
            beds = {
                { coords = vec4(1761.96, 2597.74, 45.66, 270.14), model = 2117668672 },
                { coords = vec4(1761.96, 2591.51, 45.66, 269.8), model = 2117668672 },
                { coords = vec4(1771.8, 2598.02, 45.66, 89.05), model = 2117668672 },
                { coords = vec4(1771.85, 2591.85, 45.66, 91.51), model = 2117668672 },
            }
        }
    },

    stations = {
        { label = Lang:t('info.pb_hospital'), coords = vec4(304.27, -600.33, 43.28, 272.249) }
    }
}

---@alias Grade integer job grade
---@alias VehicleName string as appears in QBCore shared config
---@alias VehicleLabel string human friendly name for a vehicle
---@alias AuthorizedVehicles table<Grade, table<VehicleName, VehicleLabel>>

---@type AuthorizedVehicles for automobiles
Config.AuthorizedVehicles = { -- Vehicles players can use based on their ambulance job grade level
    -- Grade 0
    [0] = {
        ["ambulance"] = "Ambulance",
    },
    -- Grade 1
    [1] = {
        ["ambulance"] = "Ambulance",
    },
    -- Grade 2
    [2] = {
        ["ambulance"] = "Ambulance",
    },
    -- Grade 3
    [3] = {
        ["ambulance"] = "Ambulance",
    },
    -- Grade 4
    [4] = {
        ["ambulance"] = "Ambulance",
    }
}

---@type AuthorizedVehicles for helicopters
Config.AuthorizedHelicopters = {
    -- Grade 0
    [0] = {
        ["polmav"] = "Helicopter",
    },
    -- Grade 1
    [1] = {
        ["polmav"] = "Helicopter",
    },
    -- Grade 2
    [2] = {
        ["polmav"] = "Helicopter",
    },
    -- Grade 3
    [3] = {
        ["polmav"] = "Helicopter",
    },
    -- Grade 4
    [4] = {
        ["polmav"] = "Helicopter",
    }
}

Config.Items = { -- Items found in the ambulance shop for players with the ambulance job to purchase
    label = Lang:t('info.safe'),
    slots = 30,
    items = {
        {
            name = "radio",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 1,
        },
        {
            name = "bandage",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 2,
        },
        {
            name = "painkillers",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 3,
        },
        {
            name = "firstaid",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 4,
        },
        {
            name = "weapon_flashlight",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 5,
        },
        {
            name = "weapon_fireextinguisher",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 6,
        },
    }
}

Config.VehicleSettings = { -- Enable or disable vehicle extras when pulling them from the ambulance job vehicle spawner
    ["ambulance"] = { -- Model name
        extras = {
            ["1"] = false, -- on/off
            ["2"] = true,
            ["3"] = true,
            ["4"] = true,
            ["5"] = true,
            ["6"] = true,
            ["7"] = true,
            ["8"] = true,
            ["9"] = true,
            ["10"] = true,
            ["11"] = true,
            ["12"] = true,
        }
    },
    ["car2"] = {
        extras = {
            ["1"] = false,
            ["2"] = true,
            ["3"] = true,
            ["4"] = true,
            ["5"] = true,
            ["6"] = true,
            ["7"] = true,
            ["8"] = true,
            ["9"] = true,
            ["10"] = true,
            ["11"] = true,
            ["12"] = true,
        }
    },
    ["polmav"] = {
        livery = 1
    }
}
