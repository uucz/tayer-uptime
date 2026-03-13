fx_version 'cerulean'
game 'gta5'

author 'Tayer Ruze (https://github.com/uucz)'
description 'ESX Online Time Tracker — NUI dashboard, AFK detection, milestone rewards, daily login, playtime roles & Discord integration'
version '2.2.0'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
    'locales/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/discord.lua',
    'server.lua',
}

client_scripts {
    'client.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
}

dependencies {
    'es_extended',
    'oxmysql',
}
