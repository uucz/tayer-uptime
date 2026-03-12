_LoadLocale('zh-CN', {
    -- Player messages
    ['online_time']          = '您的在线时长: ~g~%s',
    ['online_time_chat']     = '您的在线时长: %s',
    ['no_data']              = '暂无在线时间数据',
    ['daily_time']           = '今日在线时长: ~g~%s',
    ['weekly_time']          = '本周在线时长: ~g~%s',

    -- Time formatting
    ['time_format']          = '%d 小时 %d 分钟',
    ['time_format_minutes']  = '%d 分钟',

    -- Leaderboard
    ['leaderboard_title']    = '========== 在线时长排行榜 ==========',
    ['leaderboard_entry']    = '#%d  %s - %s',
    ['leaderboard_footer']   = '====================================',
    ['leaderboard_empty']    = '暂无排行榜数据',

    -- Admin commands
    ['admin_no_permission']  = '你没有权限使用此命令',
    ['admin_usage_check']    = '用法: /%s [玩家ID]',
    ['admin_usage_reset']    = '用法: /%s [玩家ID]',
    ['admin_player_time']    = '玩家 %s (ID: %s) 的在线时长: %s',
    ['admin_player_offline'] = '该玩家不在线或不存在',
    ['admin_reset_success']  = '已重置玩家 %s (ID: %s) 的在线时长',
    ['admin_reset_fail']     = '重置失败，请检查玩家ID',

    -- AFK
    ['afk_warning']          = '检测到您处于挂机状态，在线时长追踪已暂停。',
    ['afk_detected']         = '~r~检测到挂机~s~ - 时长追踪已暂停',
    ['afk_returned']         = '~g~欢迎回来~s~ - 时长追踪已恢复',

    -- Rewards
    ['reward_claimed']       = '~g~里程碑奖励！~s~ 达成 %s — +$%s',
    ['rewards_title']        = '========== 里程碑奖励 ==========',
    ['rewards_current_time'] = '您的累计时长: %s',
    ['rewards_entry']        = '  %s — $%s — %s',
    ['rewards_status_claimed']   = '[已领取]',
    ['rewards_status_available'] = '[可领取 - 已自动发放！]',
    ['rewards_status_locked']    = '[还需 %d 小时]',
    ['rewards_footer']       = '================================',
    ['rewards_disabled']     = '里程碑奖励系统当前未启用',

    -- Discord
    ['discord_connect']      = '玩家上线',
    ['discord_disconnect']   = '玩家下线',
    ['discord_player']       = '玩家',
    ['discord_session_time'] = '本次在线时长',
    ['discord_total_time']   = '累计在线时长',
    ['discord_milestone']        = '达成里程碑！',
    ['discord_milestone_reached'] = '里程碑',
    ['discord_milestone_reward']  = '奖励',

    -- System
    ['db_table_created']     = '[tayer-uptime] 数据表创建成功',
    ['db_new_user']          = '[tayer-uptime] 新用户记录: %s',
})
