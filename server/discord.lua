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

--- Send a login reward notification to Discord
--- @param playerName string The player's name
--- @param streak number The current login streak
--- @param reward number The reward amount
function SendLoginRewardNotification(playerName, streak, reward)
    local title = _L('discord_login_reward')
    local message = ('**%s:** %s\n**%s:** %d\n**%s:** $%s'):format(
        _L('discord_player'), playerName,
        _L('discord_login_streak'), streak,
        _L('discord_login_reward_amount'), tostring(reward)
    )
    SendToDiscord(title, message, 3447003) -- Blue
end

--- Send a role promotion notification to Discord
--- @param playerName string The player's name
--- @param roleLabel string The role display name
--- @param requiredHours number Hours required for this role
function SendRolePromotionNotification(playerName, roleLabel, requiredHours)
    local title = _L('discord_role_promotion')
    local message = ('**%s:** %s\n**%s:** %s\n**%s:** %dh'):format(
        _L('discord_player'), playerName,
        _L('discord_new_role'), roleLabel,
        _L('discord_required_hours'), requiredHours
    )
    SendToDiscord(title, message, 10181046) -- Purple
end

--- Send an AFK kick notification to Discord
--- @param playerName string The player's name
function SendAFKKickNotification(playerName)
    local title = _L('discord_afk_kick')
    local message = ('**%s:** %s'):format(_L('discord_player'), playerName)
    SendToDiscord(title, message, 15105570) -- Orange
end

--- Send a first-join welcome notification to Discord
--- @param playerName string The player's name
function SendFirstJoinNotification(playerName)
    local title = _L('discord_first_join')
    local message = ('**%s:** %s'):format(_L('discord_player'), playerName)
    SendToDiscord(title, message, 5763719) -- Green
end

--- Send a daily report notification to Discord
--- @param date string The report date
--- @param players number Number of active players
--- @param totalTime string Formatted total playtime
--- @param newPlayers number Number of new players
--- @param topList string Formatted top players list
function SendDailyReportNotification(date, players, totalTime, newPlayers, topList)
    local title = _L('discord_daily_report')
    local message = ('**%s:** %s\n**%s:** %d\n**%s:** %s\n**%s:** %d\n\n**%s:**\n%s'):format(
        _L('discord_report_date'), date,
        _L('discord_report_players'), players,
        _L('discord_report_total_time'), totalTime,
        _L('discord_report_new_players'), newPlayers,
        _L('discord_report_top_players'), topList
    )
    SendToDiscord(title, message, 3447003) -- Blue
end

--- Send an admin audit notification to Discord
--- @param adminName string The admin's name
--- @param action string The action performed
--- @param targetName string The target player's name
--- @param details string Additional details
function SendAuditNotification(adminName, action, targetName, details)
    local title = _L('discord_audit')
    local message = ('**%s:** %s\n**%s:** %s\n**%s:** %s\n**%s:** %s'):format(
        _L('discord_admin'), adminName,
        _L('discord_action'), action,
        _L('discord_target'), targetName or 'N/A',
        _L('discord_details'), details or 'N/A'
    )
    SendToDiscord(title, message, 9807270) -- Dark grey
end
