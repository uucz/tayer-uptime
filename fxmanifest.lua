fx_version 'cerulean'
game 'gta5'

author 'Tayer Ruze (https://github.com/uucz)'
description 'ESX Online Time Tracker — AFK detection, milestone rewards, daily login rewards, playtime roles, session history & Discord integration'
version '2.1.0'

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

dependencies {
    'es_extended',
    'oxmysql',
}