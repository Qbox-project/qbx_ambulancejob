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
    checking = {
        [1] = vec3(308.19, -595.35, 43.29),
        [2] = vec3(-254.54, 6331.78, 32.43),
    },
    duty = {
        [1] = vec3(311.18, -599.25, 43.29),
        [2] = vec3(-254.88, 6324.5, 32.58),
    },
    vehicle = {
        [1] = vec4(294.578, -574.761, 43.179, 35.79),
        [2] = vec4(-234.28, 6329.16, 32.15, 222.5),
    },
    helicopter = {
        [1] = vec4(351.58, -587.45, 74.16, 160.5),
        [2] = vec4(-475.43, 5988.353, 31.716, 31.34),
    },
    armory = {
        [1] = vec3(309.93, -602.94, 43.29),
        [2] = vec3(-245.13, 6315.71, 32.82),
    },
    roof = {
        [1] = vec3(338.54, -583.88, 74.17),
    },
    main = {
        [1] = vec3(298.62, -599.66, 43.29),
    },
    stash = {
        [1] = vec3(309.78, -596.6, 43.29),
    },
    ---@class Bed
    ---@field coords vector4
    ---@field taken boolean
    ---@field model number

    ---@type Bed[]
    beds = {
        [1] = { coords = vec4(353.1, -584.6, 43.11, 152.08), taken = false, model = 1631638868 },
        [2] = { coords = vec4(356.79, -585.86, 43.11, 152.08), taken = false, model = 1631638868 },
        [3] = { coords = vec4(354.12, -593.12, 43.1, 336.32), taken = false, model = 2117668672 },
        [4] = { coords = vec4(350.79, -591.8, 43.1, 336.32), taken = false, model = 2117668672 },
        [5] = { coords = vec4(346.99, -590.48, 43.1, 336.32), taken = false, model = 2117668672 },
        [6] = { coords = vec4(360.32, -587.19, 43.02, 152.08), taken = false, model = -1091386327 },
        [7] = { coords = vec4(349.82, -583.33, 43.02, 152.08), taken = false, model = -1091386327 },
        [8] = { coords = vec4(326.98, -576.17, 43.02, 152.08), taken = false, model = -1091386327 },
        --- paleto
        [9] = { coords = vec4(-252.43, 6312.25, 32.34, 313.48), taken = false, model = 2117668672 },
        [10] = { coords = vec4(-247.04, 6317.95, 32.34, 134.64), taken = false, model = 2117668672 },
        [11] = { coords = vec4(-255.98, 6315.67, 32.34, 313.91), taken = false, model = 2117668672 },
    },
    jailbeds = {
        [1] = { coords = vec4(1761.96, 2597.74, 45.66, 270.14), taken = false, model = 2117668672 },
        [2] = { coords = vec4(1761.96, 2591.51, 45.66, 269.8), taken = false, model = 2117668672 },
        [3] = { coords = vec4(1771.8, 2598.02, 45.66, 89.05), taken = false, model = 2117668672 },
        [4] = { coords = vec4(1771.85, 2591.85, 45.66, 91.51), taken = false, model = 2117668672 },
    },
    stations = {
        [1] = { label = Lang:t('info.pb_hospital'), coords = vec4(304.27, -600.33, 43.28, 272.249) }
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
        [1] = {
            name = "radio",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 1,
        },
        [2] = {
            name = "bandage",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 2,
        },
        [3] = {
            name = "painkillers",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 3,
        },
        [4] = {
            name = "firstaid",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 4,
        },
        [5] = {
            name = "weapon_flashlight",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 5,
        },
        [6] = {
            name = "weapon_fireextinguisher",
            price = 0,
            amount = 50,
            info = {},
            type = "item",
            slot = 6,
        },
    }
}

Config.WeaponClasses = { -- Define gta weapon classe numbers
    ['SMALL_CALIBER'] = 1,
    ['MEDIUM_CALIBER'] = 2,
    ['HIGH_CALIBER'] = 3,
    ['SHOTGUN'] = 4,
    ['CUTTING'] = 5,
    ['LIGHT_IMPACT'] = 6,
    ['HEAVY_IMPACT'] = 7,
    ['EXPLOSIVE'] = 8,
    ['FIRE'] = 9,
    ['SUFFOCATING'] = 10,
    ['OTHER'] = 11,
    ['WILDLIFE'] = 12,
    ['NOTHING'] = 13
}

---@alias Bone 'NONE'|'HEAD'|'NECK'|'SPINE'|'UPPER_BODY'|'LOWER_BODY'|'LARM'|'LHAND'|'LFINGER'|'LLEG'|'LFOOT'|'RARM'|'RHAND'|'RFINGER'|'RLEG'|'RFOOT'
Config.BoneIndexes = { -- Correspond bone labels to their hash number
    ['NONE'] = 0,
    -- ['HEAD'] = 31085,
    ['HEAD'] = 31086,
    ['NECK'] = 39317,
    -- ['SPINE'] = 57597,
    -- ['SPINE'] = 23553,
    -- ['SPINE'] = 24816,
    -- ['SPINE'] = 24817,
    ['SPINE'] = 24818,
    -- ['UPPER_BODY'] = 10706,
    ['UPPER_BODY'] = 64729,
    ['LOWER_BODY'] = 11816,
    -- ['LARM'] = 45509,
    ['LARM'] = 61163,
    ['LHAND'] = 18905,
    -- ['LFINGER'] = 4089,
    -- ['LFINGER'] = 4090,
    -- ['LFINGER'] = 4137,
    -- ['LFINGER'] = 4138,
    -- ['LFINGER'] = 4153,
    -- ['LFINGER'] = 4154,
    -- ['LFINGER'] = 4169,
    -- ['LFINGER'] = 4170,
    -- ['LFINGER'] = 4185,
    -- ['LFINGER'] = 4186,
    -- ['LFINGER'] = 26610,
    -- ['LFINGER'] = 26611,
    -- ['LFINGER'] = 26612,
    -- ['LFINGER'] = 26613,
    ['LFINGER'] = 26614,
    -- ['LLEG'] = 58271,
    ['LLEG'] = 63931,
    -- ['LFOOT'] = 2108,
    ['LFOOT'] = 14201,
    -- ['RARM'] = 40269,
    ['RARM'] = 28252,
    ['RHAND'] = 57005,
    -- ['RFINGER'] = 58866,
    -- ['RFINGER'] = 58867,
    -- ['RFINGER'] = 58868,
    -- ['RFINGER'] = 58869,
    -- ['RFINGER'] = 58870,
    -- ['RFINGER'] = 64016,
    -- ['RFINGER'] = 64017,
    -- ['RFINGER'] = 64064,
    -- ['RFINGER'] = 64065,
    -- ['RFINGER'] = 64080,
    -- ['RFINGER'] = 64081,
    -- ['RFINGER'] = 64096,
    -- ['RFINGER'] = 64097,
    -- ['RFINGER'] = 64112,
    ['RFINGER'] = 64113,
    -- ['RLEG'] = 36864,
    ['RLEG'] = 51826,
    -- ['RFOOT'] = 20781,
    ['RFOOT'] = 52301,
}

Config.VehicleSettings = { -- Enable or disable vehicle extras when pulling them from the ambulance job vehicle spawner
    ["car1"] = { -- Model name
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
