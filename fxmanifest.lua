fx_version 'cerulean'
game 'gta5'

author 'Tayer Ruze (https://github.com/uucz)'
description 'ESX Online Time Tracker — Track, leaderboard, AFK detection, milestone rewards, daily stats & Discord integration'
version '2.0.0'

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