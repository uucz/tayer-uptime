_LoadLocale('es', {
    -- Player messages
    ['online_time']          = 'Tu tiempo en linea: ~g~%s',
    ['online_time_chat']     = 'Tu tiempo en linea: %s',
    ['no_data']              = 'No hay datos de tiempo en linea disponibles',
    ['daily_time']           = 'Tiempo en linea hoy: ~g~%s',
    ['weekly_time']          = 'Tiempo en linea esta semana: ~g~%s',
    ['monthly_time']         = 'Tiempo en linea este mes: ~g~%s',

    -- Time formatting
    ['time_format']          = '%d horas %d minutos',
    ['time_format_minutes']  = '%d minutos',

    -- Leaderboard
    ['leaderboard_title']    = '========== Ranking de Tiempo en Linea ==========',
    ['leaderboard_entry']    = '#%d  %s - %s',
    ['leaderboard_footer']   = '=================================================',
    ['leaderboard_empty']    = 'No hay datos de ranking disponibles',

    -- Admin commands
    ['admin_no_permission']  = 'No tienes permiso para usar este comando',
    ['admin_usage_check']    = 'Uso: /%s [ID del jugador]',
    ['admin_usage_reset']    = 'Uso: /%s [ID del jugador]',
    ['admin_player_time']    = 'Jugador %s (ID: %s) tiempo en linea: %s',
    ['admin_player_offline'] = 'El jugador esta desconectado o no existe',
    ['admin_reset_success']  = 'Tiempo reiniciado para el jugador %s (ID: %s)',
    ['admin_reset_fail']     = 'Error al reiniciar, verifica el ID del jugador',

    -- AFK
    ['afk_warning']          = 'Se ha detectado que estas AFK. El seguimiento de tiempo esta pausado.',
    ['afk_detected']         = '~r~AFK detectado~s~ - Seguimiento pausado',
    ['afk_returned']         = '~g~Bienvenido de vuelta~s~ - Seguimiento reanudado',

    -- Rewards
    ['reward_claimed']       = '~g~Recompensa!~s~ %s alcanzado - +$%s',
    ['rewards_title']        = '========== Recompensas por Hitos ==========',
    ['rewards_current_time'] = 'Tu tiempo total: %s',
    ['rewards_entry']        = '  %s - $%s - %s',
    ['rewards_status_claimed']   = '[Reclamado]',
    ['rewards_status_available'] = '[Disponible - reclamado automaticamente!]',
    ['rewards_status_locked']    = '[Faltan %d horas]',
    ['rewards_footer']       = '===========================================',
    ['rewards_disabled']     = 'Las recompensas por hitos estan desactivadas',

    -- Daily Login
    ['login_reward_claimed'] = '~g~Recompensa diaria!~s~ Dia %d de racha - +$%s',
    ['login_title']          = '========== Estado de Inicio Diario ==========',
    ['login_streak']         = 'Racha actual: %d dias',
    ['login_max_streak']     = 'Mejor racha: %d dias',
    ['login_total']          = 'Inicios totales: %d',
    ['login_claimed_today']  = 'Recompensa de hoy: [Reclamada]',
    ['login_not_claimed']    = 'Recompensa de hoy: [Sin reclamar - reconecta para reclamar]',
    ['login_footer']         = '=============================================',
    ['login_disabled']       = 'Las recompensas de inicio diario estan desactivadas',

    -- Playtime Roles
    ['role_promoted']        = '~g~Felicidades!~s~ Has sido promovido a: %s',

    -- Discord
    ['discord_connect']      = 'Jugador Conectado',
    ['discord_disconnect']   = 'Jugador Desconectado',
    ['discord_player']       = 'Jugador',
    ['discord_session_time'] = 'Duracion de Sesion',
    ['discord_total_time']   = 'Tiempo Total en Linea',
    ['discord_milestone']         = 'Hito Alcanzado!',
    ['discord_milestone_reached'] = 'Hito',
    ['discord_milestone_reward']  = 'Recompensa',
    ['discord_login_reward']        = 'Recompensa de Inicio Diario',
    ['discord_login_streak']        = 'Racha de Inicio',
    ['discord_login_reward_amount'] = 'Recompensa',
    ['discord_role_promotion']  = 'Promocion de Rol',
    ['discord_new_role']        = 'Nuevo Rol',
    ['discord_required_hours']  = 'Horas Requeridas',
    ['discord_afk_kick']        = 'Expulsion por AFK',
    ['discord_audit']           = 'Accion de Admin',
    ['discord_admin']           = 'Admin',
    ['discord_action']          = 'Accion',
    ['discord_target']          = 'Objetivo',
    ['discord_details']         = 'Detalles',

    -- System
    ['db_table_created']     = '[tayer-uptime] Tabla de base de datos creada',
    ['db_new_user']          = '[tayer-uptime] Nuevo registro de usuario: %s',
})
