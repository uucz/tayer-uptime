ESX = exports["es_extended"]:getSharedObject()

-- Initialize locale
_SetLocale(Config.Locale)

-- Session tracking table: stores connect time per player source
local PlayerSessions = {}

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
            function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('chat:addMessage', source, {
                        args = { 'SYSTEM', _L('admin_reset_success', xTarget.getName(), targetId) }
                    })
                else
                    TriggerClientEvent('chat:addMessage', source, {
                        args = { 'SYSTEM', _L('admin_reset_fail') }
                    })
                end
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
        for _, playerId in ipairs(GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer then
                local identifier = xPlayer.identifier
                local name       = xPlayer.getName() or 'Unknown'

                MySQL.Async.execute(
                    'UPDATE users_online_time SET online_time = online_time + 1, name = @name WHERE identifier = @identifier',
                    { ['@identifier'] = identifier, ['@name'] = name },
                    function(rowsChanged)
                        if rowsChanged == 0 then
                            MySQL.Async.execute(
                                'INSERT INTO users_online_time (identifier, name, online_time) VALUES (@identifier, @name, @online_time)',
                                { ['@identifier'] = identifier, ['@name'] = name, ['@online_time'] = 1 },
                                function()
                                    print(_L('db_new_user', identifier))
                                end
                            )
                        end
                    end
                )
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Player Connect / Disconnect Events (Session Tracking + Discord)
---------------------------------------------------------------------------
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

    -- Fetch total time and send Discord notification
    if xPlayer then
        MySQL.Async.fetchAll(
            'SELECT online_time FROM users_online_time WHERE identifier = @identifier',
            { ['@identifier'] = xPlayer.identifier },
            function(result)
                local totalTime = (result[1] and result[1].online_time) or 0
                SendDisconnectNotification(name, FormatTime(sessionMinutes), FormatTime(totalTime))
            end
        )
    else
        SendDisconnectNotification(name, FormatTime(sessionMinutes), _L('no_data'))
    end
end)
