fx_version 'cerulean'
game 'gta5'

description 'qbx_ambulancejob'
repository 'https://github.com/Qbox-project/qbx_ambulancejob'
version '1.0.0'

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/utils.lua',
	'@qbx_core/shared/locale.lua',
}

client_scripts {
	'@qbx_core/modules/playerdata.lua',
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}

files {
	'config/client.lua',
	'config/shared.lua',
	'locales/*.json',
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
use_experimental_fxv2_oal 'yes'
