Config = {}

-- Language setting: 'zh-CN', 'en', 'es', 'fr', 'de', 'pt-BR'
Config.Locale = 'zh-CN'

-- Tracking interval in milliseconds (default: 60000 = 1 minute)
Config.UpdateInterval = 60000

-- Command names (change these to customize in-game commands)
Config.Commands = {
    onlinetime  = 'onlinetime',    -- Player checks own online time
    toptime     = 'toptime',       -- View online time leaderboard
    admintime   = 'admintime',     -- Admin checks a player's online time
    resettime   = 'resettime',     -- Admin resets a player's online time
    dailytime   = 'dailytime',     -- View today's online time
    weeklytime  = 'weeklytime',    -- View this week's online time
    monthlytime = 'monthlytime',   -- View this month's online time
    rewards     = 'rewards',       -- View milestone rewards progress
    loginreward = 'loginreward',   -- View daily login reward status
    uptime      = 'uptime',        -- Open NUI dashboard panel
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

-- AFK Detection settings (fully server-side, no client trust)
Config.AFK = {
    enabled       = true,
    timeout       = 300,    -- Seconds of no movement before marking as AFK (default: 5 minutes)
    checkInterval = 15,     -- Server check interval in seconds (default: 15 seconds)
    minDistance    = 5.0,    -- Minimum distance (meters) to move within checkInterval to count as active
    kickEnabled   = false,  -- Kick player after extended AFK (optional)
    kickTimeout   = 1800,   -- Seconds before AFK kick (default: 30 minutes, only if kickEnabled)
    kickMessage   = 'You have been kicked for being AFK too long.',
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

-- Daily Login Rewards settings
Config.DailyLogin = {
    enabled     = true,
    gracePeriod = 1,  -- Days allowed to miss before streak resets (0 = strict)
    rewards = {
        -- Day 1-7 cycle (repeats after day 7)
        { day = 1, money = 1000  },
        { day = 2, money = 2000  },
        { day = 3, money = 3000  },
        { day = 4, money = 4000  },
        { day = 5, money = 5000  },
        { day = 6, money = 7500  },
        { day = 7, money = 10000 },  -- Weekly bonus
    },
}

-- Playtime-Gated Roles (auto-assign groups based on total playtime)
Config.PlaytimeRoles = {
    enabled = true,
    roles = {
        -- { hours = required_hours, group = 'esx_group_name', label = 'display_name' }
        -- Players are assigned the highest role they qualify for
        -- NOTE: Only applies to players in the 'user' group (won't demote admins)
    },
}

-- Data Maintenance settings
Config.Maintenance = {
    cleanupEnabled = false,     -- Auto-purge inactive player data
    inactiveDays   = 90,        -- Days of inactivity before cleanup
    cleanupTime    = '04:00',   -- Time to run cleanup (HH:MM, server time)
}

-- First-Join Welcome Bonus
Config.FirstJoin = {
    enabled    = true,
    bonusMoney = 5000,  -- Welcome bonus for first-time players
}

-- Discord Webhook settings
Config.Discord = {
    enabled     = false,
    webhookUrl  = '',  -- Your Discord webhook URL
    botName     = 'Tayer Uptime',
    color       = 3066993,  -- Green embed color (decimal)
    dailyReport = false,    -- Send daily server stats report to Discord
    reportTime  = '00:00',  -- Time to send daily report (HH:MM, server time)
}
