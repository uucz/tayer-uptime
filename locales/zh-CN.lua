_LoadLocale('zh-CN', {
    -- Player messages
    ['online_time']          = '您的在线时长: ~g~%s',
    ['online_time_chat']     = '您的在线时长: %s',
    ['no_data']              = '暂无在线时间数据',
    ['daily_time']           = '今日在线时长: ~g~%s',
    ['weekly_time']          = '本周在线时长: ~g~%s',
    ['monthly_time']         = '本月在线时长: ~g~%s',

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

    -- Daily Login
    ['login_reward_claimed'] = '~g~每日登录奖励！~s~ 连续第 %d 天 — +$%s',
    ['login_title']          = '========== 每日登录状态 ==========',
    ['login_streak']         = '当前连续登录: %d 天',
    ['login_max_streak']     = '最高连续记录: %d 天',
    ['login_total']          = '总登录次数: %d',
    ['login_claimed_today']  = '今日奖励: [已领取]',
    ['login_not_claimed']    = '今日奖励: [未领取 - 重新登录可领取]',
    ['login_footer']         = '==================================',
    ['login_disabled']       = '每日登录奖励系统当前未启用',

    -- Playtime Roles
    ['role_promoted']        = '~g~恭喜！~s~ 您已晋升为: %s',

    -- Discord
    ['discord_connect']      = '玩家上线',
    ['discord_disconnect']   = '玩家下线',
    ['discord_player']       = '玩家',
    ['discord_session_time'] = '本次在线时长',
    ['discord_total_time']   = '累计在线时长',
    ['discord_milestone']         = '达成里程碑！',
    ['discord_milestone_reached'] = '里程碑',
    ['discord_milestone_reward']  = '奖励',
    ['discord_login_reward']        = '每日登录奖励',
    ['discord_login_streak']        = '连续登录',
    ['discord_login_reward_amount'] = '奖励',
    ['discord_role_promotion']  = '角色晋升',
    ['discord_new_role']        = '新角色',
    ['discord_required_hours']  = '所需时长',
    ['discord_afk_kick']        = 'AFK 踢出',
    ['discord_audit']           = '管理员操作',
    ['discord_admin']           = '管理员',
    ['discord_action']          = '操作',
    ['discord_target']          = '目标',
    ['discord_details']         = '详情',

    -- Admin v2.2.0
    ['admin_usage_settime']  = '用法: /settime [玩家ID] [分钟数]',
    ['admin_settime_success'] = '已将玩家 %s (ID: %s) 的在线时长设为 %s',
    ['admin_usage_addtime']  = '用法: /addtime [玩家ID] [分钟数]',
    ['admin_addtime_success'] = '已为玩家 %s (ID: %s) 增加时长: +%s',

    -- Server Stats
    ['serverstats_title']         = '========== 服务器统计 ==========',
    ['serverstats_online']        = '当前在线: %d 名玩家',
    ['serverstats_today']         = '今日活跃: %d 名玩家',
    ['serverstats_week']          = '本周活跃: %d 名玩家',
    ['serverstats_total_players'] = '总注册玩家: %d',
    ['serverstats_total_time']    = '总在线时长: %s',
    ['serverstats_footer']        = '================================',

    -- First Join
    ['firstjoin_welcome']    = '欢迎来到服务器！这是您的新手礼包: +$%s',

    -- Discord v2.2.0
    ['discord_first_join']          = '新玩家加入！',
    ['discord_daily_report']        = '每日服务器报告',
    ['discord_report_date']         = '日期',
    ['discord_report_players']      = '活跃玩家',
    ['discord_report_total_time']   = '总在线时长',
    ['discord_report_new_players']  = '新玩家',
    ['discord_report_top_players']  = '活跃排行',

    -- System
    ['db_table_created']     = '[tayer-uptime] 数据表创建成功',
    ['db_new_user']          = '[tayer-uptime] 新用户记录: %s',
})
