--- Discord Webhook Integration for tayer-uptime
--- Sends embed messages to a Discord channel via webhook

--- Send an embed message to Discord
--- @param title string The embed title
--- @param message string The embed description
--- @param color number The embed color (decimal)
function SendToDiscord(title, message, color)
    if not Config.Discord.enabled then return end
    if Config.Discord.webhookUrl == '' then return end

    local embed = {
        {
            ['title']       = title,
            ['description'] = message,
            ['color']       = color or Config.Discord.color,
            ['footer']      = {
                ['text'] = os.date('%Y-%m-%d %H:%M:%S'),
            },
        }
    }

    PerformHttpRequest(Config.Discord.webhookUrl, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print(('[tayer-uptime] ^1Discord webhook error: HTTP %s^0'):format(tostring(err)))
        end
    end, 'POST',
        json.encode({
            username = Config.Discord.botName,
            embeds   = embed,
        }),
        { ['Content-Type'] = 'application/json' }
    )
end

--- Send a player connect notification to Discord
--- @param playerName string The player's name
function SendConnectNotification(playerName)
    local title = _L('discord_connect')
    local message = ('**%s:** %s'):format(_L('discord_player'), playerName)
    SendToDiscord(title, message, 3066993) -- Green
end

--- Send a player disconnect notification with session time to Discord
--- @param playerName string The player's name
--- @param sessionTime string Formatted session duration
--- @param totalTime string Formatted total online time
function SendDisconnectNotification(playerName, sessionTime, totalTime)
    local title = _L('discord_disconnect')
    local message = ('**%s:** %s\n**%s:** %s\n**%s:** %s'):format(
        _L('discord_player'), playerName,
        _L('discord_session_time'), sessionTime,
        _L('discord_total_time'), totalTime
    )
    SendToDiscord(title, message, 15158332) -- Red
end

--- Send a milestone reward notification to Discord
--- @param playerName string The player's name
--- @param milestone string The milestone label (e.g., "100h")
--- @param reward number The reward amount
function SendMilestoneNotification(playerName, milestone, reward)
    local title = _L('discord_milestone')
    local message = ('**%s:** %s\n**%s:** %s\n**%s:** $%s'):format(
        _L('discord_player'), playerName,
        _L('discord_milestone_reached'), milestone,
        _L('discord_milestone_reward'), tostring(reward)
    )
    SendToDiscord(title, message, 16766720) -- Gold
end
