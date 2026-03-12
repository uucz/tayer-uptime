_LoadLocale('en', {
    -- Player messages
    ['online_time']          = 'Your online time: ~g~%s',
    ['online_time_chat']     = 'Your online time: %s',
    ['no_data']              = 'No online time data available',
    ['daily_time']           = 'Today\'s online time: ~g~%s',
    ['weekly_time']          = 'This week\'s online time: ~g~%s',

    -- Time formatting
    ['time_format']          = '%d hours %d minutes',
    ['time_format_minutes']  = '%d minutes',

    -- Leaderboard
    ['leaderboard_title']    = '========== Online Time Leaderboard ==========',
    ['leaderboard_entry']    = '#%d  %s - %s',
    ['leaderboard_footer']   = '=============================================',
    ['leaderboard_empty']    = 'No leaderboard data available',

    -- Admin commands
    ['admin_no_permission']  = 'You do not have permission to use this command',
    ['admin_usage_check']    = 'Usage: /%s [Player ID]',
    ['admin_usage_reset']    = 'Usage: /%s [Player ID]',
    ['admin_player_time']    = 'Player %s (ID: %s) online time: %s',
    ['admin_player_offline'] = 'Player is offline or does not exist',
    ['admin_reset_success']  = 'Reset online time for player %s (ID: %s)',
    ['admin_reset_fail']     = 'Reset failed, please check the player ID',

    -- AFK
    ['afk_warning']          = 'You have been detected as AFK. Online time tracking is paused.',
    ['afk_detected']         = '~r~AFK detected~s~ - Time tracking paused',
    ['afk_returned']         = '~g~Welcome back~s~ - Time tracking resumed',

    -- Rewards
    ['reward_claimed']       = '~g~Milestone reward!~s~ %s reached — +$%s',
    ['rewards_title']        = '========== Milestone Rewards ==========',
    ['rewards_current_time'] = 'Your total time: %s',
    ['rewards_entry']        = '  %s — $%s — %s',
    ['rewards_status_claimed']   = '[Claimed]',
    ['rewards_status_available'] = '[Available - auto claimed!]',
    ['rewards_status_locked']    = '[%d hours remaining]',
    ['rewards_footer']       = '=======================================',
    ['rewards_disabled']     = 'Milestone rewards are currently disabled',

    -- Discord
    ['discord_connect']      = 'Player Connected',
    ['discord_disconnect']   = 'Player Disconnected',
    ['discord_player']       = 'Player',
    ['discord_session_time'] = 'Session Duration',
    ['discord_total_time']   = 'Total Online Time',
    ['discord_milestone']        = 'Milestone Reached!',
    ['discord_milestone_reached'] = 'Milestone',
    ['discord_milestone_reward']  = 'Reward',

    -- System
    ['db_table_created']     = '[tayer-uptime] Database table created',
    ['db_new_user']          = '[tayer-uptime] New user record: %s',
})
