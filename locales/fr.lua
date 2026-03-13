_LoadLocale('fr', {
    -- Player messages
    ['online_time']          = 'Votre temps en ligne: ~g~%s',
    ['online_time_chat']     = 'Votre temps en ligne: %s',
    ['no_data']              = 'Aucune donnee de temps en ligne disponible',
    ['daily_time']           = 'Temps en ligne aujourd\'hui: ~g~%s',
    ['weekly_time']          = 'Temps en ligne cette semaine: ~g~%s',
    ['monthly_time']         = 'Temps en ligne ce mois: ~g~%s',

    -- Time formatting
    ['time_format']          = '%d heures %d minutes',
    ['time_format_minutes']  = '%d minutes',

    -- Leaderboard
    ['leaderboard_title']    = '========== Classement Temps en Ligne ==========',
    ['leaderboard_entry']    = '#%d  %s - %s',
    ['leaderboard_footer']   = '================================================',
    ['leaderboard_empty']    = 'Aucune donnee de classement disponible',

    -- Admin commands
    ['admin_no_permission']  = 'Vous n\'avez pas la permission d\'utiliser cette commande',
    ['admin_usage_check']    = 'Usage: /%s [ID du joueur]',
    ['admin_usage_reset']    = 'Usage: /%s [ID du joueur]',
    ['admin_player_time']    = 'Joueur %s (ID: %s) temps en ligne: %s',
    ['admin_player_offline'] = 'Le joueur est hors ligne ou n\'existe pas',
    ['admin_reset_success']  = 'Temps reinitialise pour le joueur %s (ID: %s)',
    ['admin_reset_fail']     = 'Echec de la reinitialisation, verifiez l\'ID du joueur',

    -- AFK
    ['afk_warning']          = 'Vous avez ete detecte comme AFK. Le suivi du temps est en pause.',
    ['afk_detected']         = '~r~AFK detecte~s~ - Suivi en pause',
    ['afk_returned']         = '~g~Bienvenue~s~ - Suivi repris',

    -- Rewards
    ['reward_claimed']       = '~g~Recompense!~s~ %s atteint - +$%s',
    ['rewards_title']        = '========== Recompenses par Etapes ==========',
    ['rewards_current_time'] = 'Votre temps total: %s',
    ['rewards_entry']        = '  %s - $%s - %s',
    ['rewards_status_claimed']   = '[Reclame]',
    ['rewards_status_available'] = '[Disponible - reclame automatiquement!]',
    ['rewards_status_locked']    = '[%d heures restantes]',
    ['rewards_footer']       = '============================================',
    ['rewards_disabled']     = 'Les recompenses par etapes sont desactivees',

    -- Daily Login
    ['login_reward_claimed'] = '~g~Recompense quotidienne!~s~ Jour %d de serie - +$%s',
    ['login_title']          = '========== Statut Connexion Quotidienne ==========',
    ['login_streak']         = 'Serie actuelle: %d jours',
    ['login_max_streak']     = 'Meilleure serie: %d jours',
    ['login_total']          = 'Connexions totales: %d',
    ['login_claimed_today']  = 'Recompense du jour: [Reclamee]',
    ['login_not_claimed']    = 'Recompense du jour: [Non reclamee - reconnectez-vous]',
    ['login_footer']         = '===================================================',
    ['login_disabled']       = 'Les recompenses de connexion quotidienne sont desactivees',

    -- Playtime Roles
    ['role_promoted']        = '~g~Felicitations!~s~ Vous avez ete promu: %s',

    -- Discord
    ['discord_connect']      = 'Joueur Connecte',
    ['discord_disconnect']   = 'Joueur Deconnecte',
    ['discord_player']       = 'Joueur',
    ['discord_session_time'] = 'Duree de Session',
    ['discord_total_time']   = 'Temps Total en Ligne',
    ['discord_milestone']         = 'Etape Atteinte!',
    ['discord_milestone_reached'] = 'Etape',
    ['discord_milestone_reward']  = 'Recompense',
    ['discord_login_reward']        = 'Recompense Quotidienne',
    ['discord_login_streak']        = 'Serie de Connexion',
    ['discord_login_reward_amount'] = 'Recompense',
    ['discord_role_promotion']  = 'Promotion de Role',
    ['discord_new_role']        = 'Nouveau Role',
    ['discord_required_hours']  = 'Heures Requises',
    ['discord_afk_kick']        = 'Expulsion AFK',
    ['discord_audit']           = 'Action Admin',
    ['discord_admin']           = 'Admin',
    ['discord_action']          = 'Action',
    ['discord_target']          = 'Cible',
    ['discord_details']         = 'Details',

    -- System
    ['db_table_created']     = '[tayer-uptime] Table de base de donnees creee',
    ['db_new_user']          = '[tayer-uptime] Nouvel enregistrement: %s',
})
