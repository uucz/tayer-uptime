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
-- AFK Status Display (server-authoritative, client only receives status)
---------------------------------------------------------------------------
local isAFK = false

RegisterNetEvent('tayer-uptime:afkStatus')
AddEventHandler('tayer-uptime:afkStatus', function(afkState)
    if isAFK ~= afkState then
        isAFK = afkState
        if isAFK then
            ESX.ShowNotification(_L('afk_detected'))
        else
            ESX.ShowNotification(_L('afk_returned'))
        end
    end
end)

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

---------------------------------------------------------------------------
-- Command: Check today's online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.dailytime, function()
    ESX.TriggerServerCallback('tayer-uptime:getDailyTime', function(dailyTime)
        ESX.ShowNotification(_L('daily_time', FormatTime(dailyTime)))
    end)
end, false)

---------------------------------------------------------------------------
-- Command: Check this week's online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.weeklytime, function()
    ESX.TriggerServerCallback('tayer-uptime:getWeeklyTime', function(weeklyTime)
        ESX.ShowNotification(_L('weekly_time', FormatTime(weeklyTime)))
    end)
end, false)

---------------------------------------------------------------------------
-- Command: Check this month's online time
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.monthlytime, function()
    ESX.TriggerServerCallback('tayer-uptime:getMonthlyTime', function(monthlyTime)
        ESX.ShowNotification(_L('monthly_time', FormatTime(monthlyTime)))
    end)
end, false)

---------------------------------------------------------------------------
-- Command: View milestone rewards progress
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.rewards, function()
    if not Config.Rewards.enabled then
        ESX.ShowNotification(_L('rewards_disabled'))
        return
    end

    ESX.TriggerServerCallback('tayer-uptime:getRewardsProgress', function(data)
        local totalMinutes = data.totalTime or 0
        local totalHours = totalMinutes / 60
        local claimedSet = {}
        for _, hours in ipairs(data.claimed or {}) do
            claimedSet[hours] = true
        end

        TriggerEvent('chat:addMessage', { args = { '', _L('rewards_title') } })
        TriggerEvent('chat:addMessage', { args = { '', _L('rewards_current_time', FormatTime(totalMinutes)) } })

        for _, milestone in ipairs(Config.Rewards.milestones) do
            local status
            if claimedSet[milestone.hours] then
                status = _L('rewards_status_claimed')
            elseif totalHours >= milestone.hours then
                status = _L('rewards_status_available')
            else
                local remaining = math.ceil(milestone.hours - totalHours)
                status = _L('rewards_status_locked', remaining)
            end
            TriggerEvent('chat:addMessage', {
                args = { '', _L('rewards_entry', milestone.label, milestone.money, status) }
            })
        end

        TriggerEvent('chat:addMessage', { args = { '', _L('rewards_footer') } })
    end)
end, false)

---------------------------------------------------------------------------
-- Command: View daily login reward status
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.loginreward, function()
    if not Config.DailyLogin.enabled then
        ESX.ShowNotification(_L('login_disabled'))
        return
    end

    ESX.TriggerServerCallback('tayer-uptime:getLoginStatus', function(data)
        if not data then return end

        TriggerEvent('chat:addMessage', { args = { '', _L('login_title') } })
        TriggerEvent('chat:addMessage', { args = { '', _L('login_streak', data.currentStreak) } })
        TriggerEvent('chat:addMessage', { args = { '', _L('login_max_streak', data.maxStreak) } })
        TriggerEvent('chat:addMessage', { args = { '', _L('login_total', data.totalLogins) } })

        if data.claimedToday then
            TriggerEvent('chat:addMessage', { args = { '', _L('login_claimed_today') } })
        else
            TriggerEvent('chat:addMessage', { args = { '', _L('login_not_claimed') } })
        end

        TriggerEvent('chat:addMessage', { args = { '', _L('login_footer') } })
    end)
end, false)

---------------------------------------------------------------------------
-- Command: Open NUI Dashboard
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.uptime, function()
    ESX.TriggerServerCallback('tayer-uptime:getDashboardData', function(data)
        if not data then return end
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openDashboard',
            data   = data,
        })
    end)
end, false)

---------------------------------------------------------------------------
-- NUI Callback: Close Dashboard
---------------------------------------------------------------------------
RegisterNUICallback('closeDashboard', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
