ESX = exports["es_extended"]:getSharedObject()

-- Initialize locale
_SetLocale(Config.Locale)

---------------------------------------------------------------------------
-- Helper: Format minutes to human-readable string (client-side)
---------------------------------------------------------------------------
local function FormatTime(minutes)
    if minutes < 60 then
        return _L('time_format_minutes', minutes)
    end
    local hours = math.floor(minutes / 60)
    local mins  = minutes % 60
    return _L('time_format', hours, mins)
end

---------------------------------------------------------------------------
-- Command: Check your own online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.onlinetime, function()
    ESX.TriggerServerCallback('tayer-uptime:getOnlineTime', function(onlineTime)
        ESX.ShowNotification(_L('online_time', FormatTime(onlineTime)))
    end)
end, false)

---------------------------------------------------------------------------
-- Command: View online time leaderboard
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.toptime, function()
    ESX.TriggerServerCallback('tayer-uptime:getLeaderboard', function(data)
        if not data or #data == 0 then
            TriggerEvent('chat:addMessage', { args = { 'UPTIME', _L('leaderboard_empty') } })
            return
        end

        TriggerEvent('chat:addMessage', { args = { '', _L('leaderboard_title') } })
        for i, entry in ipairs(data) do
            local name = entry.name or 'Unknown'
            local time = FormatTime(entry.online_time or 0)
            TriggerEvent('chat:addMessage', { args = { '', _L('leaderboard_entry', i, name, time) } })
        end
        TriggerEvent('chat:addMessage', { args = { '', _L('leaderboard_footer') } })
    end)
end, false)

---------------------------------------------------------------------------
-- Command: Admin check another player's online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.admintime, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerEvent('chat:addMessage', { args = { 'SYSTEM', _L('admin_usage_check', Config.Commands.admintime) } })
        return
    end

    ESX.TriggerServerCallback('tayer-uptime:getPlayerTime', function(data)
        if data then
            TriggerEvent('chat:addMessage', {
                args = { 'ADMIN', _L('admin_player_time', data.name, targetId, FormatTime(data.time)) }
            })
        else
            TriggerEvent('chat:addMessage', { args = { 'SYSTEM', _L('admin_no_permission') } })
        end
    end, targetId)
end, false)
