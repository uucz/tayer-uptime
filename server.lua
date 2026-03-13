-- Bridge is loaded via shared_scripts (shared/bridge.lua)
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
    local group = Bridge.GetGroup(source)
    for _, adminGroup in ipairs(Config.AdminGroups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: Log admin action to audit table and Discord
---------------------------------------------------------------------------
function AuditLog(adminSource, action, targetIdentifier, targetName, details)
    local adminId = Bridge.GetIdentifier(adminSource)
    local adminName = Bridge.GetName(adminSource)
    if not adminId then return end

    MySQL.Async.execute(
        'INSERT INTO uptime_audit_log (admin_identifier, admin_name, action, target_identifier, target_name, details) VALUES (@admin_id, @admin_name, @action, @target_id, @target_name, @details)',
        {
            ['@admin_id']    = adminId,
            ['@admin_name']  = adminName,
            ['@action']      = action,
            ['@target_id']   = targetIdentifier,
            ['@target_name'] = targetName,
            ['@details']     = details,
        }
    )

    SendAuditNotification(adminName, action, targetName, details)
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
                    local playerName = Bridge.GetName(src)
                    -- Grant reward based on type
                    local rewardType = milestone.type or 'money'
                    if rewardType == 'money' then
                        Bridge.AddMoney(src, milestone.money or 0)
                    elseif rewardType == 'item' then
                        Bridge.AddItem(src, milestone.item, milestone.count or 1)
                    elseif rewardType == 'vehicle' then
                        -- Vehicle rewards handled via callback or SQL
                        if milestone.callback then
                            milestone.callback(src, identifier)
                        end
                    end

                    -- Always grant money if specified alongside other types
                    if rewardType ~= 'money' and milestone.money and milestone.money > 0 then
                        Bridge.AddMoney(src, milestone.money)
                    end

                    MySQL.Async.execute(
                        'INSERT IGNORE INTO users_online_rewards (identifier, milestone_hours) VALUES (@identifier, @hours)',
                        { ['@identifier'] = identifier, ['@hours'] = milestone.hours }
                    )

                    local rewardText = milestone.money and ('$' .. milestone.money) or milestone.label
                    Bridge.Notify(src, _L('reward_claimed', milestone.label, rewardText), 'success')
                    SendMilestoneNotification(playerName, milestone.label, milestone.money or 0)
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

    -- Only auto-assign roles to regular users (don't demote admins)
    local currentGroup = Bridge.GetGroup(src)
    if not currentGroup then return end

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
                    Bridge.SetGroup(src, bestRole.group)
                    MySQL.Async.execute(
                        'INSERT IGNORE INTO users_playtime_roles (identifier, role_group) VALUES (@identifier, @group)',
                        { ['@identifier'] = identifier, ['@group'] = bestRole.group }
                    )
                    Bridge.Notify(src, _L('role_promoted', bestRole.label), 'success')
                    SendRolePromotionNotification(Bridge.GetName(src), bestRole.label, bestRole.hours)
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
                    if reward.money then
                        Bridge.AddMoney(src, reward.money)
                        Bridge.Notify(src, _L('login_reward_claimed', streak, reward.money), 'success')
                        SendLoginRewardNotification(Bridge.GetName(src), streak, reward.money)
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
Bridge.RegisterServerCallback('tayer-uptime:getOnlineTime', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if identifier then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = identifier },
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
Bridge.RegisterServerCallback('tayer-uptime:getLeaderboard', function(source, cb)
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
Bridge.RegisterServerCallback('tayer-uptime:getPlayerTime', function(source, cb, targetId)
    if not IsAdmin(source) then
        cb(nil)
        return
    end

    local targetIdentifier = Bridge.GetIdentifier(targetId)
    local targetName = Bridge.GetName(targetId)
    if targetIdentifier then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = targetIdentifier },
            function(result)
                if result[1] then
                    cb({ name = targetName, time = result[1].online_time })
                else
                    cb({ name = targetName, time = 0 })
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
Bridge.RegisterServerCallback('tayer-uptime:getDailyTime', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if identifier then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_daily WHERE identifier = @identifier AND date = CURDATE()',
            { ['@identifier'] = identifier },
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
Bridge.RegisterServerCallback('tayer-uptime:getWeeklyTime', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if identifier then
        MySQL.Async.fetchAll(
            'SELECT COALESCE(SUM(online_time), 0) as total FROM users_online_daily WHERE identifier = @identifier AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
            { ['@identifier'] = identifier },
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
Bridge.RegisterServerCallback('tayer-uptime:getMonthlyTime', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if identifier then
        local yearMonth = os.date('%Y-%m')
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_monthly WHERE identifier = @identifier AND year_month = @ym',
            { ['@identifier'] = identifier, ['@ym'] = yearMonth },
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
Bridge.RegisterServerCallback('tayer-uptime:getRewardsProgress', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then cb({ totalTime = 0, claimed = {} }) return end
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
Bridge.RegisterServerCallback('tayer-uptime:getLoginStatus', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then cb(nil) return end

    MySQL.Async.fetchAll(
        'SELECT * FROM users_login_streaks WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
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
-- Server Callback: Get full dashboard data (for NUI)
---------------------------------------------------------------------------
Bridge.RegisterServerCallback('tayer-uptime:getDashboardData', function(source, cb)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then cb(nil) return end

    local playerName = Bridge.GetName(source)
    local today = os.date('%Y-%m-%d')
    local yearMonth = os.date('%Y-%m')

    -- Session time
    local sessionTime = 0
    if PlayerSessions[source] then
        sessionTime = math.floor((os.time() - PlayerSessions[source]) / 60)
    end

    -- Gather all data in parallel via nested callbacks
    MySQL.Async.fetchAll(
        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
        function(totalResult)
            local totalTime = (totalResult[1] and totalResult[1].online_time) or 0

            MySQL.Async.fetchAll(
                'SELECT online_time FROM users_online_daily WHERE identifier = @identifier AND date = CURDATE()',
                { ['@identifier'] = identifier },
                function(dailyResult)
                    local dailyTime = (dailyResult[1] and dailyResult[1].online_time) or 0

                    MySQL.Async.fetchAll(
                        'SELECT COALESCE(SUM(online_time), 0) as total FROM users_online_daily WHERE identifier = @identifier AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
                        { ['@identifier'] = identifier },
                        function(weeklyResult)
                            local weeklyTime = (weeklyResult[1] and weeklyResult[1].total) or 0

                            MySQL.Async.fetchAll(
                                'SELECT online_time FROM users_online_monthly WHERE identifier = @identifier AND year_month = @ym',
                                { ['@identifier'] = identifier, ['@ym'] = yearMonth },
                                function(monthlyResult)
                                    local monthlyTime = (monthlyResult[1] and monthlyResult[1].online_time) or 0

                                    -- Get rank
                                    MySQL.Async.fetchAll(
                                        'SELECT COUNT(*) as rank FROM users_online_time WHERE online_time > @time',
                                        { ['@time'] = totalTime },
                                        function(rankResult)
                                            local rank = (rankResult[1] and rankResult[1].rank or 0) + 1

                                            -- Get leaderboard
                                            MySQL.Async.fetchAll(
                                                'SELECT name, online_time FROM users_online_time ORDER BY online_time DESC LIMIT @limit',
                                                { ['@limit'] = Config.Leaderboard.maxEntries },
                                                function(lbResult)

                                                    -- Get milestones
                                                    MySQL.Async.fetchAll(
                                                        'SELECT milestone_hours FROM users_online_rewards WHERE identifier = @identifier',
                                                        { ['@identifier'] = identifier },
                                                        function(rewardResult)
                                                            local claimedSet = {}
                                                            for _, row in ipairs(rewardResult) do
                                                                claimedSet[row.milestone_hours] = true
                                                            end

                                                            local milestones = {}
                                                            for _, ms in ipairs(Config.Rewards.milestones) do
                                                                milestones[#milestones + 1] = {
                                                                    hours   = ms.hours,
                                                                    money   = ms.money,
                                                                    label   = ms.label,
                                                                    claimed = claimedSet[ms.hours] == true,
                                                                }
                                                            end

                                                            -- Get login streak
                                                            MySQL.Async.fetchAll(
                                                                'SELECT * FROM users_login_streaks WHERE identifier = @identifier',
                                                                { ['@identifier'] = identifier },
                                                                function(streakResult)
                                                                    local loginStreak = {
                                                                        currentStreak = 0,
                                                                        maxStreak     = 0,
                                                                        totalLogins   = 0,
                                                                        claimedToday  = false,
                                                                    }
                                                                    if streakResult[1] then
                                                                        local row = streakResult[1]
                                                                        loginStreak.currentStreak = row.current_streak
                                                                        loginStreak.maxStreak     = row.max_streak
                                                                        loginStreak.totalLogins   = row.total_logins
                                                                        loginStreak.claimedToday  = (row.last_claimed_date == today)
                                                                    end

                                                                    cb({
                                                                        playerName  = playerName,
                                                                        totalTime   = totalTime,
                                                                        dailyTime   = dailyTime,
                                                                        weeklyTime  = weeklyTime,
                                                                        monthlyTime = monthlyTime,
                                                                        sessionTime = sessionTime,
                                                                        rank        = rank,
                                                                        isAFK       = PlayerAFK[source] == true,
                                                                        leaderboard = lbResult or {},
                                                                        milestones  = milestones,
                                                                        loginStreak = loginStreak,
                                                                    })
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
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

    local targetIdentifier = Bridge.GetIdentifier(targetId)
    local targetName = Bridge.GetName(targetId)
    if targetIdentifier then
        MySQL.Async.execute(
            'UPDATE users_online_time SET online_time = 0 WHERE identifier = @identifier',
            { ['@identifier'] = targetIdentifier },
            function()
                TriggerClientEvent('chat:addMessage', source, {
                    args = { 'SYSTEM', _L('admin_reset_success', targetName, targetId) }
                })
                AuditLog(source, 'reset_time', targetIdentifier, targetName, 'Reset online time to 0')
            end
        )
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_player_offline') } })
    end
end, false)

---------------------------------------------------------------------------
-- Admin Command: Set a player's online time
---------------------------------------------------------------------------
RegisterCommand('settime', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_no_permission') } })
        return
    end

    local targetId = tonumber(args[1])
    local minutes = tonumber(args[2])
    if not targetId or not minutes or minutes < 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_usage_settime') } })
        return
    end

    local targetIdentifier = Bridge.GetIdentifier(targetId)
    local targetName = Bridge.GetName(targetId)
    if targetIdentifier then
        MySQL.Async.execute(
            'INSERT INTO users_online_time (identifier, name, online_time) VALUES (@identifier, @name, @time) ON DUPLICATE KEY UPDATE online_time = @time',
            { ['@identifier'] = targetIdentifier, ['@name'] = targetName, ['@time'] = minutes },
            function()
                TriggerClientEvent('chat:addMessage', source, {
                    args = { 'SYSTEM', _L('admin_settime_success', targetName, targetId, FormatTime(minutes)) }
                })
                AuditLog(source, 'set_time', targetIdentifier, targetName, 'Set online time to ' .. minutes .. ' minutes')
            end
        )
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_player_offline') } })
    end
end, false)

---------------------------------------------------------------------------
-- Admin Command: Add time to a player
---------------------------------------------------------------------------
RegisterCommand('addtime', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_no_permission') } })
        return
    end

    local targetId = tonumber(args[1])
    local minutes = tonumber(args[2])
    if not targetId or not minutes or minutes <= 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_usage_addtime') } })
        return
    end

    local targetIdentifier = Bridge.GetIdentifier(targetId)
    local targetName = Bridge.GetName(targetId)
    if targetIdentifier then
        MySQL.Async.execute(
            'INSERT INTO users_online_time (identifier, name, online_time) VALUES (@identifier, @name, @time) ON DUPLICATE KEY UPDATE online_time = online_time + @time',
            { ['@identifier'] = targetIdentifier, ['@name'] = targetName, ['@time'] = minutes },
            function()
                TriggerClientEvent('chat:addMessage', source, {
                    args = { 'SYSTEM', _L('admin_addtime_success', targetName, targetId, FormatTime(minutes)) }
                })
                AuditLog(source, 'add_time', targetIdentifier, targetName, 'Added ' .. minutes .. ' minutes')
            end
        )
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_player_offline') } })
    end
end, false)

---------------------------------------------------------------------------
-- Admin Command: Server statistics
---------------------------------------------------------------------------
RegisterCommand('serverstats', function(source, args)
    if source == 0 then return end
    if not IsAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_no_permission') } })
        return
    end

    MySQL.Async.fetchAll('SELECT COUNT(*) as total, COALESCE(SUM(online_time), 0) as total_time FROM users_online_time', {}, function(allResult)
        MySQL.Async.fetchAll('SELECT COUNT(DISTINCT identifier) as today_active FROM users_online_daily WHERE date = CURDATE()', {}, function(todayResult)
            MySQL.Async.fetchAll('SELECT COUNT(DISTINCT identifier) as week_active FROM users_online_daily WHERE date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)', {}, function(weekResult)
                local totalPlayers = allResult[1] and allResult[1].total or 0
                local totalMinutes = allResult[1] and allResult[1].total_time or 0
                local todayActive = todayResult[1] and todayResult[1].today_active or 0
                local weekActive = weekResult[1] and weekResult[1].week_active or 0
                local onlineNow = #GetPlayers()

                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_title') } })
                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_online', onlineNow) } })
                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_today', todayActive) } })
                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_week', weekActive) } })
                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_total_players', totalPlayers) } })
                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_total_time', FormatTime(totalMinutes)) } })
                TriggerClientEvent('chat:addMessage', source, { args = { '', _L('serverstats_footer') } })
            end)
        end)
    end)
end, false)

---------------------------------------------------------------------------
-- Admin Command: Import txAdmin playtime data
---------------------------------------------------------------------------
RegisterCommand('importtxadmin', function(source, args)
    -- Only allow from server console or admin
    if source ~= 0 then
        if not IsAdmin(source) then
            TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', _L('admin_no_permission') } })
            return
        end
    end

    local filePath = args[1]
    if not filePath or filePath == '' then
        local msg = 'Usage: /importtxadmin [path_to_playersDB.json]'
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', msg } })
        end
        return
    end

    -- Read the txAdmin JSON file
    local file = io.open(filePath, 'r')
    if not file then
        local msg = 'Error: Cannot open file: ' .. filePath
        if source == 0 then print(msg) else TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', msg } }) end
        return
    end

    local content = file:read('*a')
    file:close()

    local data = json.decode(content)
    if not data then
        local msg = 'Error: Invalid JSON in file'
        if source == 0 then print(msg) else TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', msg } }) end
        return
    end

    local imported = 0
    for _, player in pairs(data) do
        if player.license and player.playTime and player.playTime > 0 then
            local identifier = player.license
            local name = player.displayName or player.name or 'Unknown'
            local minutes = math.floor(player.playTime) -- txAdmin stores in minutes

            MySQL.Async.execute(
                'INSERT INTO users_online_time (identifier, name, online_time) VALUES (@identifier, @name, @time) ON DUPLICATE KEY UPDATE online_time = GREATEST(online_time, @time)',
                { ['@identifier'] = identifier, ['@name'] = name, ['@time'] = minutes }
            )
            imported = imported + 1
        end
    end

    local msg = ('txAdmin import complete: %d players imported'):format(imported)
    if source == 0 then
        print('[tayer-uptime] ' .. msg)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { 'SYSTEM', msg } })
        AuditLog(source, 'txadmin_import', nil, nil, msg)
    end
end, false)

---------------------------------------------------------------------------
-- First-Join Welcome System
---------------------------------------------------------------------------
function ProcessFirstJoin(src, identifier, name)
    if not Config.FirstJoin or not Config.FirstJoin.enabled then return end

    MySQL.Async.fetchAll(
        'SELECT id FROM users_online_time WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
        function(result)
            if not result[1] then
                -- New player! Give welcome bonus
                if Config.FirstJoin.bonusMoney and Config.FirstJoin.bonusMoney > 0 then
                    Bridge.AddMoney(src, Config.FirstJoin.bonusMoney)
                    Bridge.Notify(src, _L('firstjoin_welcome', Config.FirstJoin.bonusMoney), 'success')
                end
                SendFirstJoinNotification(name)
            end
        end
    )
end

---------------------------------------------------------------------------
-- Discord Daily Report
---------------------------------------------------------------------------
if Config.Discord.enabled and Config.Discord.dailyReport then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- Check every minute
            local currentTime = os.date('%H:%M')
            if currentTime == (Config.Discord.reportTime or '00:00') then
                -- Generate daily report
                local yesterday = os.date('%Y-%m-%d', os.time() - 86400)
                MySQL.Async.fetchAll(
                    'SELECT COUNT(DISTINCT identifier) as players, COALESCE(SUM(online_time), 0) as total_time FROM users_online_daily WHERE date = @date',
                    { ['@date'] = yesterday },
                    function(result)
                        local players = result[1] and result[1].players or 0
                        local totalTime = result[1] and result[1].total_time or 0

                        MySQL.Async.fetchAll(
                            'SELECT COUNT(*) as new_players FROM users_login_streaks WHERE DATE(last_login_date) = @date AND total_logins = 1',
                            { ['@date'] = yesterday },
                            function(newResult)
                                local newPlayers = newResult[1] and newResult[1].new_players or 0

                                MySQL.Async.fetchAll(
                                    'SELECT name, online_time FROM users_online_daily WHERE date = @date ORDER BY online_time DESC LIMIT 5',
                                    { ['@date'] = yesterday },
                                    function(topResult)
                                        local topList = ''
                                        for i, row in ipairs(topResult) do
                                            topList = topList .. ('#%d %s - %s\n'):format(i, row.name or 'Unknown', FormatTime(row.online_time))
                                        end
                                        if topList == '' then topList = 'No data' end

                                        SendDailyReportNotification(yesterday, players, FormatTime(totalTime), newPlayers, topList)
                                    end
                                )
                            end
                        )
                    end
                )
                -- Wait 61 seconds to avoid double-trigger
                Citizen.Wait(61000)
            end
        end
    end)
end

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
            local identifier = Bridge.GetIdentifier(src)
            if identifier then
                -- Skip AFK players if AFK detection is enabled
                if Config.AFK.enabled and PlayerAFK[src] then
                    goto continue
                end

                local name = Bridge.GetName(src)

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
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return 0 end
    local result = MySQL.Sync.fetchAll(
        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
        { ['@identifier'] = identifier }
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
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return 0 end
    local result = MySQL.Sync.fetchAll(
        'SELECT online_time FROM users_online_daily WHERE identifier = @identifier AND date = CURDATE()',
        { ['@identifier'] = identifier }
    )
    return (result[1] and result[1].online_time) or 0
end)

-- Get a player's weekly online time (minutes)
exports('GetWeeklyPlaytime', function(source)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return 0 end
    local result = MySQL.Sync.fetchAll(
        'SELECT COALESCE(SUM(online_time), 0) as total FROM users_online_daily WHERE identifier = @identifier AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
        { ['@identifier'] = identifier }
    )
    return (result[1] and result[1].total) or 0
end)

-- Get player's login streak info
exports('GetLoginStreak', function(source)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return { streak = 0, maxStreak = 0 } end
    local result = MySQL.Sync.fetchAll(
        'SELECT current_streak, max_streak FROM users_login_streaks WHERE identifier = @identifier',
        { ['@identifier'] = identifier }
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

-- Process login rewards when player is fully loaded (framework-agnostic)
Bridge.OnPlayerLoaded(function(src, identifier, name)
    ProcessFirstJoin(src, identifier, name)
    ProcessDailyLogin(src, identifier)

    -- Record session start in DB
    MySQL.Async.execute(
        'INSERT INTO users_sessions (identifier, name) VALUES (@identifier, @name)',
        { ['@identifier'] = identifier, ['@name'] = name }
    )

    -- Check playtime roles on login
    MySQL.Async.fetchAll(
        'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
        { ['@identifier'] = identifier },
        function(result)
            if result[1] then
                CheckPlaytimeRoles(src, identifier, result[1].online_time)
            end
        end
    )
end)

AddEventHandler('playerDropped', function(reason)
    local src        = source
    local identifier = Bridge.GetIdentifier(src)
    local name       = Bridge.GetName(src)

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
    if identifier then
        MySQL.Async.execute(
            'UPDATE users_sessions SET disconnected_at = NOW(), duration_minutes = @duration, disconnect_reason = @reason WHERE identifier = @identifier AND disconnected_at IS NULL ORDER BY id DESC LIMIT 1',
            { ['@identifier'] = identifier, ['@duration'] = sessionMinutes, ['@reason'] = reason }
        )
    end

    -- Fetch total time and send Discord notification
    if identifier then
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
