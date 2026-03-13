fx_version 'cerulean'
game 'gta5'

author 'Tayer Ruze (https://github.com/uucz)'
description 'Multi-Framework Online Time Tracker — NUI dashboard, AFK detection, milestone rewards, daily login, playtime roles & Discord integration'
version '2.4.0'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
    'locales/*.lua',
    'shared/bridge.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/discord.lua',
    'server.lua',
    'server/api.lua',
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

-- Only oxmysql is required; framework is auto-detected
dependencies {
    'oxmysql',
}
