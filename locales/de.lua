_LoadLocale('de', {
    -- Player messages
    ['online_time']          = 'Deine Online-Zeit: ~g~%s',
    ['online_time_chat']     = 'Deine Online-Zeit: %s',
    ['no_data']              = 'Keine Online-Zeitdaten verfuegbar',
    ['daily_time']           = 'Heutige Online-Zeit: ~g~%s',
    ['weekly_time']          = 'Online-Zeit diese Woche: ~g~%s',
    ['monthly_time']         = 'Online-Zeit diesen Monat: ~g~%s',

    -- Time formatting
    ['time_format']          = '%d Stunden %d Minuten',
    ['time_format_minutes']  = '%d Minuten',

    -- Leaderboard
    ['leaderboard_title']    = '========== Online-Zeit Rangliste ==========',
    ['leaderboard_entry']    = '#%d  %s - %s',
    ['leaderboard_footer']   = '============================================',
    ['leaderboard_empty']    = 'Keine Ranglistendaten verfuegbar',

    -- Admin commands
    ['admin_no_permission']  = 'Du hast keine Berechtigung fuer diesen Befehl',
    ['admin_usage_check']    = 'Verwendung: /%s [Spieler-ID]',
    ['admin_usage_reset']    = 'Verwendung: /%s [Spieler-ID]',
    ['admin_player_time']    = 'Spieler %s (ID: %s) Online-Zeit: %s',
    ['admin_player_offline'] = 'Spieler ist offline oder existiert nicht',
    ['admin_reset_success']  = 'Online-Zeit zurueckgesetzt fuer Spieler %s (ID: %s)',
    ['admin_reset_fail']     = 'Zuruecksetzen fehlgeschlagen, bitte Spieler-ID pruefen',

    -- AFK
    ['afk_warning']          = 'Du wurdest als AFK erkannt. Zeiterfassung pausiert.',
    ['afk_detected']         = '~r~AFK erkannt~s~ - Zeiterfassung pausiert',
    ['afk_returned']         = '~g~Willkommen zurueck~s~ - Zeiterfassung fortgesetzt',

    -- Rewards
    ['reward_claimed']       = '~g~Meilenstein-Belohnung!~s~ %s erreicht - +$%s',
    ['rewards_title']        = '========== Meilenstein-Belohnungen ==========',
    ['rewards_current_time'] = 'Deine Gesamtzeit: %s',
    ['rewards_entry']        = '  %s - $%s - %s',
    ['rewards_status_claimed']   = '[Abgeholt]',
    ['rewards_status_available'] = '[Verfuegbar - automatisch abgeholt!]',
    ['rewards_status_locked']    = '[Noch %d Stunden]',
    ['rewards_footer']       = '=============================================',
    ['rewards_disabled']     = 'Meilenstein-Belohnungen sind derzeit deaktiviert',

    -- Daily Login
    ['login_reward_claimed'] = '~g~Taegliche Belohnung!~s~ Tag %d Serie - +$%s',
    ['login_title']          = '========== Taeglicher Login-Status ==========',
    ['login_streak']         = 'Aktuelle Serie: %d Tage',
    ['login_max_streak']     = 'Beste Serie: %d Tage',
    ['login_total']          = 'Gesamte Logins: %d',
    ['login_claimed_today']  = 'Heutige Belohnung: [Abgeholt]',
    ['login_not_claimed']    = 'Heutige Belohnung: [Noch nicht abgeholt]',
    ['login_footer']         = '=============================================',
    ['login_disabled']       = 'Taegliche Login-Belohnungen sind deaktiviert',

    -- Playtime Roles
    ['role_promoted']        = '~g~Glueckwunsch!~s~ Du wurdest befoerdert zu: %s',

    -- Discord
    ['discord_connect']      = 'Spieler Verbunden',
    ['discord_disconnect']   = 'Spieler Getrennt',
    ['discord_player']       = 'Spieler',
    ['discord_session_time'] = 'Sitzungsdauer',
    ['discord_total_time']   = 'Gesamte Online-Zeit',
    ['discord_milestone']         = 'Meilenstein Erreicht!',
    ['discord_milestone_reached'] = 'Meilenstein',
    ['discord_milestone_reward']  = 'Belohnung',
    ['discord_login_reward']        = 'Taegliche Belohnung',
    ['discord_login_streak']        = 'Login-Serie',
    ['discord_login_reward_amount'] = 'Belohnung',
    ['discord_role_promotion']  = 'Rollenaenderung',
    ['discord_new_role']        = 'Neue Rolle',
    ['discord_required_hours']  = 'Benoetigte Stunden',
    ['discord_afk_kick']        = 'AFK-Kick',
    ['discord_audit']           = 'Admin-Aktion',
    ['discord_admin']           = 'Admin',
    ['discord_action']          = 'Aktion',
    ['discord_target']          = 'Ziel',
    ['discord_details']         = 'Details',

    -- System
    ['db_table_created']     = '[tayer-uptime] Datenbanktabelle erstellt',
    ['db_new_user']          = '[tayer-uptime] Neuer Benutzereintrag: %s',
})
