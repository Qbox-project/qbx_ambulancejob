return {
    useTarget = false,
    debugPoly = false,
    minForCheckIn = 2, -- Minimum number of people with the ambulance job to prevent the check-in system from being used
    painkillerInterval = 60, -- Time in minutes that painkillers last for
    checkInHealTime = 20, -- Time in seconds that it takes to be healed from the check-in system
    laststandTimer = 300, -- Time in seconds that the laststand timer lasts
    aiHealTimer = 20, -- How long it will take to be healed after checking in, in seconds

    ---@alias Grade integer job grade
    ---@alias VehicleName string as appears in QBCore shared config
    ---@alias VehicleLabel string human friendly name for a vehicle
    ---@alias AuthorizedVehicles table<Grade, table<VehicleName, VehicleLabel>>

    ---@type AuthorizedVehicles for automobiles
    authorizedVehicles = { -- Vehicles players can use based on their ambulance job grade level
        [0] = { -- Grade 0
            ['ambulance'] = 'Ambulance',
        },
        [1] = { -- Grade 1
            ['ambulance'] = 'Ambulance',
        },
        [2] = { -- Grade 2
            ['ambulance'] = 'Ambulance',
        },
        [3] = { -- Grade 3
            ['ambulance'] = 'Ambulance',
        },
        [4] = { -- Grade 4
            ['ambulance'] = 'Ambulance',
        },
    },

    ---@type AuthorizedVehicles for helicopters
    authorizedHelicopters = {
        [0] = { -- Grade 0
            ['polmav'] = 'Helicopter',
        },
        [1] = { -- Grade 1
            ['polmav'] = 'Helicopter',
        },
        [2] = { -- Grade 2
            ['polmav'] = 'Helicopter',
        },
        [3] = { -- Grade 3
            ['polmav'] = 'Helicopter',
        },
        [4] = { -- Grade 4
            ['polmav'] = 'Helicopter',
        },
    },

    vehicleSettings = { -- Enable or disable vehicle extras when pulling them from the ambulance job vehicle spawner
        ['ambulance'] = { -- Model name
            extras = {
                ['1'] = false, -- on/off
                ['2'] = true,
                ['3'] = true,
                ['4'] = true,
                ['5'] = true,
                ['6'] = true,
                ['7'] = true,
                ['8'] = true,
                ['9'] = true,
                ['10'] = true,
                ['11'] = true,
                ['12'] = true,
            },
        },
        ['car2'] = {
            extras = {
                ['1'] = false,
                ['2'] = true,
                ['3'] = true,
                ['4'] = true,
                ['5'] = true,
                ['6'] = true,
                ['7'] = true,
                ['8'] = true,
                ['9'] = true,
                ['10'] = true,
                ['11'] = true,
                ['12'] = true,
            },
        },
        ['polmav'] = {
            livery = 1,
        },
    },
}