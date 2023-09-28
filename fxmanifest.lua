fx_version 'cerulean'
game 'gta5'

description 'https://github.com/QBCore-Remastered'
version '1.0.0'

modules {
	'qbx_core:playerdata',
    'qbx_core:utils'
}

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/import.lua',
	'@qbx_core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua'
}

client_scripts {
	'client/damage/damage.lua',
	'client/hospital.lua',
	'client/main.lua',
	'client/wounding.lua',
	'client/laststand.lua',
	'client/job.lua',
	'client/setdownedstate.lua',
}

server_scripts {
	'server/main.lua',
}

dependencies {
	'ox_lib',
	'ox_target',
	'ox_inventory',
	'qbx_core',
	'qbx_policejob',
	'qbx_management',
	'qbx_medical',
}

lua54 'yes'
