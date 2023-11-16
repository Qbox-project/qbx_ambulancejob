fx_version 'cerulean'
game 'gta5'

description 'QBX_AmbulanceJob'
repository 'https://github.com/Qbox-project/qbx_ambulancejob'
version '1.0.0'

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/utils.lua',
	'@qbx_core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua'
}

client_scripts {
	'@qbx_core/modules/playerdata.lua',
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
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
