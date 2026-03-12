ESX = exports["es_extended"]:getSharedObject()

-- Initialize locale
_SetLocale(Config.Locale)

-- Session tracking: stores connect time and last update time per player source
local PlayerSessions = {}
local PlayerLastUpdate = {}
local PlayerAFK = {} -- AFK state: true = currently AFK

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
-- AFK Management
---------------------------------------------------------------------------
RegisterNetEvent('tayer-uptime:setAFKStatus')
AddEventHandler('tayer-uptime:setAFKStatus', function(isAFK)
    local src = source
    if type(isAFK) ~= 'boolean' then return end

    local wasAFK = PlayerAFK[src]
    PlayerAFK[src] = isAFK

    if isAFK and not wasAFK then
        -- Player just went AFK
        if Config.AFK.enabled then
            TriggerClientEvent('chat:addMessage', src, { args = { 'SYSTEM', _L('afk_warning') } })
        end
    end
end)

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
                    -- Grant reward
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
-- Server Callback: Get player's own online time
---------------------------------------------------------------------------
ESX.RegisterServerCallback('tayer-uptime:getOnlineTime', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.identifier
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = identifier },
            function(result)
                if result[1] then
                    cb(result[1].online_time)
                else
                    cb(0)
                end
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
-- Admin Command: Reset a player's online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.resettime, function(source, args)
    if source == 0 then return end -- Console not supported
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

                -- Check milestone rewards
                MySQL.Async.fetchAll(
                    'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
                    { ['@identifier'] = identifier },
                    function(result)
                        if result[1] then
                            CheckMilestones(src, identifier, result[1].online_time)
                        end
                    end
                )

                ::continue::
            end
        end
    end
end)

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
        -- Player connected but tracking loop never ran for them
        unsavedMinutes = sessionMinutes
    end

    -- Clean up AFK state
    PlayerAFK[src] = nil

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
