fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Heino'
version '1.1.0'
repository 'https://github.com/HeinoDev/heino_kanaltfyr'

ui_page 'web/build/index.html'

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/logs.lua',
    'server/server.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
}

files {
    'config.lua',
    'locales/*.json',
    'web/build/index.html',
    'web/build/**/*'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
}
