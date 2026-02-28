Config = {}

-- Language setting: 'zh-CN' or 'en'
Config.Locale = 'zh-CN'

-- Tracking interval in milliseconds (default: 60000 = 1 minute)
Config.UpdateInterval = 60000

-- Command names (change these to customize in-game commands)
Config.Commands = {
    onlinetime = 'onlinetime',   -- Player checks own online time
    toptime    = 'toptime',      -- View online time leaderboard
    admintime  = 'admintime',   -- Admin checks a player's online time
    resettime  = 'resettime',   -- Admin resets a player's online time
}

-- Leaderboard settings
Config.Leaderboard = {
    maxEntries = 10,  -- Number of players shown on leaderboard
}

-- Admin permission groups
Config.AdminGroups = {
    'admin',
    'superadmin',
}

-- Discord Webhook settings
Config.Discord = {
    enabled    = false,
    webhookUrl = '',  -- Your Discord webhook URL
    botName    = 'Tayer Uptime',
    color      = 3066993,  -- Green embed color (decimal)
}
