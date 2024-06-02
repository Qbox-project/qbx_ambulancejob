fx_version 'cerulean'
game 'gta5'

description 'qbx_ambulancejob'
repository 'https://github.com/Qbox-project/qbx_ambulancejob'
version '1.0.0'

ox_lib 'locale'

dependencies {
    'qbx_core',
	'qbx_medical',
    'ox_lib',
	'ox_inventory'
}

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/lib.lua',
}

client_scripts {
	'@qbx_core/modules/playerdata.lua',
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}

files {
	'locales/*.json',
	'config/client.lua',
	'config/shared.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'