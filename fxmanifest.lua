fx_version 'cerulean'
game 'gta5'

description 'https://github.com/QBCore-Remastered'
version '1.0.1'

shared_scripts {
	'@qb-core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua',
	'@ox_lib/init.lua',
}

client_scripts {
	'client/damage/damage-effects.lua',
	'client/damage/damage.lua',
	'client/hospital.lua',
	'client/main.lua',
	'client/wounding.lua',
	'client/laststand.lua',
	'client/job.lua',
	'client/dead.lua',
	'client/setdownedstate.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua',
}

dependencies {
	'ox_lib',
	'ox_target',
	'qb-core',
	'ox_inventory',
	'qb-policejob',
	'qb-management',
	'oxmysql',
}

lua54 'yes'
