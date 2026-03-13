ESX = exports["es_extended"]:getSharedObject()

-- Initialize locale
_SetLocale(Config.Locale)

-- Session tracking: stores connect time and last update time per player source
local PlayerSessions = {}
local PlayerLastUpdate = {}

-- Server-side AFK tracking (no client trust)
local PlayerAFK = {}         -- AFK state: true = currently AFK
local PlayerLastPos = {}     -- Last known position per player
local PlayerAFKSeconds = {}  -- Cumulative AFK seconds per player

---------------------------------------------------------------------------
-- Database Initialization
---------------------------------------------------------------------------
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_online_time` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `name` varchar(255) NOT NULL DEFAULT '',
            `online_time` int(11) NOT NULL DEFAULT '0',
            `last_seen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {}, function()
        print(_L('db_table_created'))
    end)

    -- Daily stats table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_online_daily` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `name` varchar(255) NOT NULL DEFAULT '',
            `date` date NOT NULL,
            `online_time` int(11) NOT NULL DEFAULT '0',
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier_date` (`identifier`, `date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Monthly stats table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_online_monthly` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `name` varchar(255) NOT NULL DEFAULT '',
            `year_month` char(7) NOT NULL,
            `online_time` int(11) NOT NULL DEFAULT '0',
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier_month` (`identifier`, `year_month`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Milestone rewards tracking table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_online_rewards` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `milestone_hours` int(11) NOT NULL,
            `claimed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier_milestone` (`identifier`, `milestone_hours`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Login streaks table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_login_streaks` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `current_streak` int(11) NOT NULL DEFAULT '0',
            `max_streak` int(11) NOT NULL DEFAULT '0',
            `last_login_date` date DEFAULT NULL,
            `last_claimed_date` date DEFAULT NULL,
            `total_logins` int(11) NOT NULL DEFAULT '0',
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Session history table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_sessions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `name` varchar(255) NOT NULL DEFAULT '',
            `connected_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `disconnected_at` timestamp NULL DEFAULT NULL,
            `duration_minutes` int(11) NOT NULL DEFAULT '0',
            `disconnect_reason` varchar(255) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `identifier` (`identifier`),
            KEY `connected_at` (`connected_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Admin audit log table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `uptime_audit_log` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `admin_identifier` varchar(255) NOT NULL,
            `admin_name` varchar(255) NOT NULL DEFAULT '',
            `action` varchar(50) NOT NULL,
            `target_identifier` varchar(255) DEFAULT NULL,
            `target_name` varchar(255) DEFAULT NULL,
            `details` text DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `admin_identifier` (`admin_identifier`),
            KEY `created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Playtime roles tracking table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users_playtime_roles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `role_group` varchar(50) NOT NULL,
            `granted_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier_role` (`identifier`, `role_group`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])
end)

---------------------------------------------------------------------------
-- Helper: Format minutes to human-readable string
---------------------------------------------------------------------------
function FormatTime(minutes)
    if minutes < 60 then
        return _L('time_format_minutes', minutes)
    end
    local hours = math.floor(minutes / 60)
    local mins  = minutes % 60
    return _L('time_format', hours, mins)
end

---------------------------------------------------------------------------
-- Helper: Check if player has admin permission
---------------------------------------------------------------------------
function IsAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: Log admin action to audit table and Discord
---------------------------------------------------------------------------
function AuditLog(adminSource, action, targetIdentifier, targetName, details)
    local xAdmin = ESX.GetPlayerFromId(adminSource)
    if not xAdmin then return end

    MySQL.Async.execute(
        'INSERT INTO uptime_audit_log (admin_identifier, admin_name, action, target_identifier, target_name, details) VALUES (@admin_id, @admin_name, @action, @target_id, @target_name, @details)',
        {
            ['@admin_id']    = xAdmin.identifier,
            ['@admin_name']  = xAdmin.getName(),
            ['@action']      = action,
            ['@target_id']   = targetIdentifier,
            ['@target_name'] = targetName,
            ['@details']     = details,
        }
    )

    SendAuditNotification(xAdmin.getName(), action, targetName, details)
end

---------------------------------------------------------------------------
-- Server-Side AFK Detection (no client trust)
---------------------------------------------------------------------------
if Config.AFK.enabled then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.AFK.checkInterval * 1000)

            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                local ped = GetPlayerPed(src)
                if ped and ped > 0 then
                    local currentPos = GetEntityCoords(ped)

                    if PlayerLastPos[src] then
                        local dx = currentPos.x - PlayerLastPos[src].x
                        local dy = currentPos.y - PlayerLastPos[src].y
                        local dz = currentPos.z - PlayerLastPos[src].z
                        local distance = math.sqrt(dx*dx + dy*dy + dz*dz)

                        if distance < Config.AFK.minDistance then
                            PlayerAFKSeconds[src] = (PlayerAFKSeconds[src] or 0) + Config.AFK.checkInterval
                            if PlayerAFKSeconds[src] >= Config.AFK.timeout and not PlayerAFK[src] then
                                PlayerAFK[src] = true
                                TriggerClientEvent('tayer-uptime:afkStatus', src, true)
                                TriggerClientEvent('chat:addMessage', src, { args = { 'SYSTEM', _L('afk_warning') } })
                            end

                            -- AFK Kick
                            if Config.AFK.kickEnabled and PlayerAFKSeconds[src] >= Config.AFK.kickTimeout then
                                DropPlayer(src, Config.AFK.kickMessage)
                                SendAFKKickNotification(GetPlayerName(src) or 'Unknown')
                            end
                        else
                            if PlayerAFK[src] then
                                PlayerAFK[src] = false
                                TriggerClientEvent('tayer-uptime:afkStatus', src, false)
                            end
                            PlayerAFKSeconds[src] = 0
                        end
                    end

                    PlayerLastPos[src] = currentPos
                end
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Milestone Rewards: Check and grant
---------------------------------------------------------------------------
function CheckMilestones(src, identifier, totalMinutes)
    if not Config.Rewards.enabled then return end

    local totalHours = totalMinutes / 60

    MySQL.Async.fetchAll(
        'SELECT milestone_hours FROM users_online_rewards WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
        function(claimed)
            local claimedSet = {}
            for _, row in ipairs(claimed) do
                claimedSet[row.milestone_hours] = true
            end

            for _, milestone in ipairs(Config.Rewards.milestones) do
                if totalHours >= milestone.hours and not claimedSet[milestone.hours] then
                    local xPlayer = ESX.GetPlayerFromId(src)
                    if xPlayer then
                        xPlayer.addMoney(milestone.money)
                        MySQL.Async.execute(
                            'INSERT IGNORE INTO users_online_rewards (identifier, milestone_hours) VALUES (@identifier, @hours)',
                            { ['@identifier'] = identifier, ['@hours'] = milestone.hours }
                        )
                        TriggerClientEvent('chat:addMessage', src, {
                            args = { 'REWARD', _L('reward_claimed', milestone.label, milestone.money) }
                        })
                        SendMilestoneNotification(xPlayer.getName(), milestone.label, milestone.money)
                    end
                end
            end
        end
    )
end

---------------------------------------------------------------------------
-- Playtime Role Check: Auto-assign groups based on total playtime
---------------------------------------------------------------------------
function CheckPlaytimeRoles(src, identifier, totalMinutes)
    if not Config.PlaytimeRoles.enabled then return end
    if not Config.PlaytimeRoles.roles or #Config.PlaytimeRoles.roles == 0 then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Only auto-assign roles to regular users (don't demote admins)
    local currentGroup = xPlayer.getGroup()
    local isAdmin = false
    for _, group in ipairs(Config.AdminGroups) do
        if currentGroup == group then
            isAdmin = true
            break
        end
    end
    if isAdmin then return end

    local totalHours = totalMinutes / 60

    -- Find the highest qualifying role
    local bestRole = nil
    for _, role in ipairs(Config.PlaytimeRoles.roles) do
        if totalHours >= role.hours then
            if not bestRole or role.hours > bestRole.hours then
                bestRole = role
            end
        end
    end

    if bestRole and currentGroup ~= bestRole.group then
        -- Check if already granted in DB
        MySQL.Async.fetchAll(
            'SELECT role_group FROM users_playtime_roles WHERE identifier = @identifier AND role_group = @group',
            { ['@identifier'] = identifier, ['@group'] = bestRole.group },
            function(result)
                if #result == 0 then
                    xPlayer.setGroup(bestRole.group)
                    MySQL.Async.execute(
                        'INSERT IGNORE INTO users_playtime_roles (identifier, role_group) VALUES (@identifier, @group)',
                        { ['@identifier'] = identifier, ['@group'] = bestRole.group }
                    )
                    TriggerClientEvent('chat:addMessage', src, {
                        args = { 'SYSTEM', _L('role_promoted', bestRole.label) }
                    })
                    SendRolePromotionNotification(xPlayer.getName(), bestRole.label, bestRole.hours)
                end
            end
        )
    end
end

---------------------------------------------------------------------------
-- Daily Login Rewards
---------------------------------------------------------------------------
function ProcessDailyLogin(src, identifier)
    if not Config.DailyLogin.enabled then return end

    local today = os.date('%Y-%m-%d')

    MySQL.Async.fetchAll(
        'SELECT * FROM users_login_streaks WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
        function(result)
            local streak = 1
            local maxStreak = 1
            local totalLogins = 1
            local lastClaimedDate = nil
            local shouldClaim = true

            if result[1] then
                local row = result[1]
                totalLogins = row.total_logins + 1
                maxStreak = row.max_streak
                lastClaimedDate = row.last_claimed_date

                -- Check if already claimed today
                if lastClaimedDate == today then
                    shouldClaim = false
                else
                    -- Calculate streak
                    local lastLogin = row.last_login_date
                    if lastLogin then
                        local lastTime = os.time({
                            year = tonumber(lastLogin:sub(1,4)),
                            month = tonumber(lastLogin:sub(6,7)),
                            day = tonumber(lastLogin:sub(9,10)),
                            hour = 0
                        })
                        local todayTime = os.time({
                            year = tonumber(today:sub(1,4)),
                            month = tonumber(today:sub(6,7)),
                            day = tonumber(today:sub(9,10)),
                            hour = 0
                        })
                        local daysDiff = math.floor((todayTime - lastTime) / 86400)

                        if daysDiff == 1 then
                            -- Consecutive day
                            streak = row.current_streak + 1
                        elseif daysDiff <= (1 + Config.DailyLogin.gracePeriod) then
                            -- Within grace period
                            streak = row.current_streak + 1
                        else
                            -- Streak broken
                            streak = 1
                        end
                    end

                    if streak > maxStreak then
                        maxStreak = streak
                    end
                end
            end

            if shouldClaim then
                -- Determine reward day (cycle through rewards)
                local rewardCount = #Config.DailyLogin.rewards
                local rewardDay = ((streak - 1) % rewardCount) + 1
                local reward = Config.DailyLogin.rewards[rewardDay]

                if reward then
                    local xPlayer = ESX.GetPlayerFromId(src)
                    if xPlayer and reward.money then
                        xPlayer.addMoney(reward.money)
                        TriggerClientEvent('chat:addMessage', src, {
                            args = { 'LOGIN', _L('login_reward_claimed', streak, reward.money) }
                        })
                        SendLoginRewardNotification(xPlayer.getName(), streak, reward.money)
                    end
                end

                -- Update or insert streak record
                MySQL.Async.execute(
                    'INSERT INTO users_login_streaks (identifier, current_streak, max_streak, last_login_date, last_claimed_date, total_logins) VALUES (@identifier, @streak, @max, @today, @today, 1) ON DUPLICATE KEY UPDATE current_streak = @streak, max_streak = @max, last_login_date = @today, last_claimed_date = @today, total_logins = total_logins + 1',
                    {
                        ['@identifier'] = identifier,
                        ['@streak']     = streak,
                        ['@max']        = maxStreak,
                        ['@today']      = today,
                    }
                )
            end
        end
    )
end

---------------------------------------------------------------------------
-- Server Callback: Get player's own online time
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getOnlineTime', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = xPlayer.identifier },
            function(result)
                cb((result[1] and result[1].online_time) or 0)
            end
        )
    else
        cb(0)
    end
end)

---------------------------------------------------------------------------
-- Server Callback: Get leaderboard data
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getLeaderboard', function(source, cb)
    MySQL.Async.fetchAll(
        'SELECT name, online_time FROM users_online_time ORDER BY online_time DESC LIMIT @limit',
        { ['@limit'] = Config.Leaderboard.maxEntries },
        function(result)
            cb(result or {})
        end
    )
end)

---------------------------------------------------------------------------
-- Server Callback: Admin get specific player's time
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getPlayerTime', function(source, cb, targetId)
    if not IsAdmin(source) then
        cb(nil)
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = xTarget.identifier },
            function(result)
                if result[1] then
                    cb({ name = xTarget.getName(), time = result[1].online_time })
                else
                    cb({ name = xTarget.getName(), time = 0 })
                end
            end
        )
    else
        cb(nil)
    end
end)

---------------------------------------------------------------------------
-- Server Callback: Get daily online time
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getDailyTime', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_daily WHERE identifier = @identifier AND date = CURDATE()',
            { ['@identifier'] = xPlayer.identifier },
            function(result)
                cb((result[1] and result[1].online_time) or 0)
            end
        )
    else
        cb(0)
    end
end)

---------------------------------------------------------------------------
-- Server Callback: Get weekly online time
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getWeeklyTime', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        MySQL.Async.fetchAll(
            'SELECT COALESCE(SUM(online_time), 0) as total FROM users_online_daily WHERE identifier = @identifier AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
            { ['@identifier'] = xPlayer.identifier },
            function(result)
                cb((result[1] and result[1].total) or 0)
            end
        )
    else
        cb(0)
    end
end)

---------------------------------------------------------------------------
-- Server Callback: Get monthly online time
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getMonthlyTime', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local yearMonth = os.date('%Y-%m')
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_monthly WHERE identifier = @identifier AND year_month = @ym',
            { ['@identifier'] = xPlayer.identifier, ['@ym'] = yearMonth },
            function(result)
                cb((result[1] and result[1].online_time) or 0)
            end
        )
    else
        cb(0)
    end
end)

---------------------------------------------------------------------------
-- Server Callback: Get rewards progress
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getRewardsProgress', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({ totalTime = 0, claimed = {} }) return end

    local identifier = xPlayer.identifier
    MySQL.Async.fetchAll(
        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
        function(timeResult)
            local totalTime = (timeResult[1] and timeResult[1].online_time) or 0
            MySQL.Async.fetchAll(
                'SELECT milestone_hours FROM users_online_rewards WHERE identifier = @identifier',
                { ['@identifier'] = identifier },
                function(claimedResult)
                    local claimed = {}
                    for _, row in ipairs(claimedResult) do
                        claimed[#claimed + 1] = row.milestone_hours
                    end
                    cb({ totalTime = totalTime, claimed = claimed })
                end
            )
        end
    )
end)

---------------------------------------------------------------------------
-- Server Callback: Get login reward status
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getLoginStatus', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    MySQL.Async.fetchAll(
        'SELECT * FROM users_login_streaks WHERE identifier = @identifier',
        { ['@identifier'] = xPlayer.identifier },
        function(result)
            if result[1] then
                local row = result[1]
                local today = os.date('%Y-%m-%d')
                cb({
                    currentStreak  = row.current_streak,
                    maxStreak      = row.max_streak,
                    totalLogins    = row.total_logins,
                    claimedToday   = (row.last_claimed_date == today),
                })
            else
                cb({
                    currentStreak  = 0,
                    maxStreak      = 0,
                    totalLogins    = 0,
                    claimedToday   = false,
                })
            end
        end
    )
end)

---------------------------------------------------------------------------
-- Admin Command: Reset a player's online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.resettime, function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_no_permission') } })
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_usage_reset', Config.Commands.resettime) } })
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        MySQL.Async.execute(
            'UPDATE users_online_time SET online_time = 0 WHERE identifier = @identifier',
            { ['@identifier'] = xTarget.identifier },
            function()
                TriggerClientEvent('chat:addMessage', source, {
                    args = { 'SYSTEM', _L('admin_reset_success', xTarget.getName(), targetId) }
                })
                AuditLog(source, 'reset_time', xTarget.identifier, xTarget.getName(), 'Reset online time to 0')
            end
        )
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_player_offline') } })
    end
end, false)

---------------------------------------------------------------------------
-- Online Time Tracking Loop
---------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.UpdateInterval)
        local today = os.date('%Y-%m-%d')
        local yearMonth = os.date('%Y-%m')
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                -- Skip AFK players if AFK detection is enabled
                if Config.AFK.enabled and PlayerAFK[src] then
                    goto continue
                end

                local identifier = xPlayer.identifier
                local name       = xPlayer.getName() or 'Unknown'

                PlayerLastUpdate[src] = os.time()

                -- Update total online time
                MySQL.Async.execute(
                    'INSERT INTO users_online_time (identifier, name, online_time) VALUES (@identifier, @name, 1) ON DUPLICATE KEY UPDATE online_time = online_time + 1, name = @name',
                    { ['@identifier'] = identifier, ['@name'] = name }
                )

                -- Update daily online time
                MySQL.Async.execute(
                    'INSERT INTO users_online_daily (identifier, name, date, online_time) VALUES (@identifier, @name, @date, 1) ON DUPLICATE KEY UPDATE online_time = online_time + 1, name = @name',
                    { ['@identifier'] = identifier, ['@name'] = name, ['@date'] = today }
                )

                -- Update monthly online time
                MySQL.Async.execute(
                    'INSERT INTO users_online_monthly (identifier, name, year_month, online_time) VALUES (@identifier, @name, @ym, 1) ON DUPLICATE KEY UPDATE online_time = online_time + 1, name = @name',
                    { ['@identifier'] = identifier, ['@name'] = name, ['@ym'] = yearMonth }
                )

                -- Check milestone rewards (every 5 minutes to reduce DB load)
                if os.time() % 300 < 61 then
                    MySQL.Async.fetchAll(
                        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
                        { ['@identifier'] = identifier },
                        function(result)
                            if result[1] then
                                CheckMilestones(src, identifier, result[1].online_time)
                                CheckPlaytimeRoles(src, identifier, result[1].online_time)
                            end
                        end
                    )
                end

                ::continue::
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Data Maintenance: Cleanup inactive players
---------------------------------------------------------------------------
if Config.Maintenance.cleanupEnabled then
    Citizen.CreateThread(function()
        while true do
            -- Check once per hour
            Citizen.Wait(3600000)
            local currentTime = os.date('%H:%M')
            if currentTime == Config.Maintenance.cleanupTime then
                local cutoffDate = os.date('%Y-%m-%d', os.time() - (Config.Maintenance.inactiveDays * 86400))
                MySQL.Async.execute(
                    'DELETE FROM users_online_daily WHERE date < @cutoff',
                    { ['@cutoff'] = cutoffDate }
                )
                print(('[tayer-uptime] ^3Data cleanup: removed daily records older than %s^0'):format(cutoffDate))
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Exports API
---------------------------------------------------------------------------
-- Get a player's total online time (minutes)
exports('GetPlaytime', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local result = MySQL.Sync.fetchAll(
        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
        { ['@identifier'] = xPlayer.identifier }
    )
    return (result[1] and result[1].online_time) or 0
end)

-- Check if a player is AFK
exports('IsPlayerAFK', function(source)
    return PlayerAFK[source] == true
end)

-- Get top players
exports('GetTopPlayers', function(limit)
    limit = limit or Config.Leaderboard.maxEntries
    local result = MySQL.Sync.fetchAll(
        'SELECT name, online_time FROM users_online_time ORDER BY online_time DESC LIMIT @limit',
        { ['@limit'] = limit }
    )
    return result or {}
end)

-- Check if player has minimum playtime hours
exports('HasPlaytimeHours', function(source, hours)
    local minutes = exports['tayer-uptime']:GetPlaytime(source)
    return (minutes / 60) >= hours
end)

-- Get a player's daily online time (minutes)
exports('GetDailyPlaytime', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local result = MySQL.Sync.fetchAll(
        'SELECT online_time FROM users_online_daily WHERE identifier = @identifier AND date = CURDATE()',
        { ['@identifier'] = xPlayer.identifier }
    )
    return (result[1] and result[1].online_time) or 0
end)

-- Get a player's weekly online time (minutes)
exports('GetWeeklyPlaytime', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local result = MySQL.Sync.fetchAll(
        'SELECT COALESCE(SUM(online_time), 0) as total FROM users_online_daily WHERE identifier = @identifier AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
        { ['@identifier'] = xPlayer.identifier }
    )
    return (result[1] and result[1].total) or 0
end)

-- Get player's login streak info
exports('GetLoginStreak', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { streak = 0, maxStreak = 0 } end
    local result = MySQL.Sync.fetchAll(
        'SELECT current_streak, max_streak FROM users_login_streaks WHERE identifier = @identifier',
        { ['@identifier'] = xPlayer.identifier }
    )
    if result[1] then
        return { streak = result[1].current_streak, maxStreak = result[1].max_streak }
    end
    return { streak = 0, maxStreak = 0 }
end)

---------------------------------------------------------------------------
-- Player Connect / Disconnect Events (Session Tracking + Discord)
---------------------------------------------------------------------------
-- Initialize sessions for players already online (handles resource restart)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local currentTime = os.time()
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
            PlayerSessions[src] = currentTime
            PlayerLastUpdate[src] = currentTime
        end
    end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    PlayerSessions[src] = os.time()
    SendConnectNotification(name)
end)

-- Process login rewards when ESX player is fully loaded
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local src = source
    if xPlayer then
        ProcessDailyLogin(src, xPlayer.identifier)

        -- Record session start in DB
        MySQL.Async.execute(
            'INSERT INTO users_sessions (identifier, name) VALUES (@identifier, @name)',
            { ['@identifier'] = xPlayer.identifier, ['@name'] = xPlayer.getName() or 'Unknown' }
        )

        -- Check playtime roles on login
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = xPlayer.identifier },
            function(result)
                if result[1] then
                    CheckPlaytimeRoles(src, xPlayer.identifier, result[1].online_time)
                end
            end
        )
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src      = source
    local xPlayer  = ESX.GetPlayerFromId(src)
    local name     = GetPlayerName(src) or 'Unknown'

    -- Calculate session duration
    local sessionMinutes = 0
    if PlayerSessions[src] then
        sessionMinutes = math.floor((os.time() - PlayerSessions[src]) / 60)
        PlayerSessions[src] = nil
    end

    -- Save unsaved minutes since last tracking loop tick
    local unsavedMinutes = 0
    if PlayerLastUpdate[src] then
        unsavedMinutes = math.floor((os.time() - PlayerLastUpdate[src]) / 60)
        PlayerLastUpdate[src] = nil
    elseif sessionMinutes > 0 then
        unsavedMinutes = sessionMinutes
    end

    -- Clean up AFK and position state
    PlayerAFK[src] = nil
    PlayerLastPos[src] = nil
    PlayerAFKSeconds[src] = nil

    -- Update session history
    if xPlayer then
        MySQL.Async.execute(
            'UPDATE users_sessions SET disconnected_at = NOW(), duration_minutes = @duration, disconnect_reason = @reason WHERE identifier = @identifier AND disconnected_at IS NULL ORDER BY id DESC LIMIT 1',
            { ['@identifier'] = xPlayer.identifier, ['@duration'] = sessionMinutes, ['@reason'] = reason }
        )
    end

    -- Fetch total time and send Discord notification
    if xPlayer then
        local identifier = xPlayer.identifier
        if unsavedMinutes > 0 then
            MySQL.Async.execute(
                'INSERT INTO users_online_time (identifier, name, online_time) VALUES (@identifier, @name, @time) ON DUPLICATE KEY UPDATE online_time = online_time + @time, name = @name',
                { ['@identifier'] = identifier, ['@name'] = name, ['@time'] = unsavedMinutes },
                function()
                    MySQL.Async.fetchAll(
                        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
                        { ['@identifier'] = identifier },
                        function(result)
                            local totalTime = (result[1] and result[1].online_time) or 0
                            SendDisconnectNotification(name, FormatTime(sessionMinutes), FormatTime(totalTime))
                        end
                    )
                end
            )
        else
            MySQL.Async.fetchAll(
                'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
                { ['@identifier'] = identifier },
                function(result)
                    local totalTime = (result[1] and result[1].online_time) or 0
                    SendDisconnectNotification(name, FormatTime(sessionMinutes), FormatTime(totalTime))
                end
            )
        end
    else
        SendDisconnectNotification(name, FormatTime(sessionMinutes), _L('no_data'))
    end
end)
