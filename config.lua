Config = {}

-- Language setting: 'zh-CN' or 'en'
Config.Locale = 'zh-CN'

-- Tracking interval in milliseconds (default: 60000 = 1 minute)
Config.UpdateInterval = 60000

-- Command names (change these to customize in-game commands)
Config.Commands = {
    onlinetime = 'onlinetime',   -- Player checks own online time
    toptime    = 'toptime',      -- View online time leaderboard
    admintime  = 'admintime',    -- Admin checks a player's online time
    resettime  = 'resettime',    -- Admin resets a player's online time
    dailytime  = 'dailytime',    -- View today's online time
    weeklytime = 'weeklytime',   -- View this week's online time
    rewards    = 'rewards',      -- View milestone rewards progress
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

-- AFK Detection settings
Config.AFK = {
    enabled       = true,
    timeout       = 300,    -- Seconds of no movement before marking as AFK (default: 5 minutes)
    checkInterval = 10000,  -- Client check interval in ms (default: 10 seconds)
    minDistance    = 5.0,    -- Minimum distance (meters) to move within checkInterval to count as active
    kickEnabled   = false,  -- Kick player after extended AFK (optional)
    kickTimeout   = 1800,   -- Seconds before AFK kick (default: 30 minutes, only if kickEnabled)
}

-- Milestone Rewards settings
Config.Rewards = {
    enabled = true,
    milestones = {
        -- { hours = required_hours, money = reward_amount, label = display_name }
        { hours = 1,    money = 5000,   label = '1h'    },
        { hours = 5,    money = 15000,  label = '5h'    },
        { hours = 10,   money = 30000,  label = '10h'   },
        { hours = 24,   money = 50000,  label = '24h'   },
        { hours = 48,   money = 80000,  label = '48h'   },
        { hours = 100,  money = 150000, label = '100h'  },
        { hours = 200,  money = 300000, label = '200h'  },
        { hours = 500,  money = 500000, label = '500h'  },
    },
}

-- Discord Webhook settings
Config.Discord = {
    enabled    = false,
    webhookUrl = '',  -- Your Discord webhook URL
    botName    = 'Tayer Uptime',
    color      = 3066993,  -- Green embed color (decimal)
}
