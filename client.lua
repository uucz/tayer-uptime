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
-- AFK Detection (client-side distance tracking)
---------------------------------------------------------------------------
local lastPos = nil
local afkSeconds = 0
local isAFK = false

if Config.AFK.enabled then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.AFK.checkInterval)

            local ped = PlayerPedId()
            local currentPos = GetEntityCoords(ped)

            if lastPos then
                local distance = #(currentPos - lastPos)
                if distance < Config.AFK.minDistance then
                    afkSeconds = afkSeconds + (Config.AFK.checkInterval / 1000)
                    if afkSeconds >= Config.AFK.timeout and not isAFK then
                        isAFK = true
                        TriggerServerEvent('tayer-uptime:setAFKStatus', true)
                        ESX.ShowNotification(_L('afk_detected'))
                    end
                else
                    if isAFK then
                        isAFK = false
                        TriggerServerEvent('tayer-uptime:setAFKStatus', false)
                        ESX.ShowNotification(_L('afk_returned'))
                    end
                    afkSeconds = 0
                end
            end

            lastPos = currentPos
        end
    end)
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
