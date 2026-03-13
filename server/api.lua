--- HTTP API Endpoints for tayer-uptime
--- Provides JSON REST API for external tools, web dashboards, and Discord bots

if not Config.API or not Config.API.enabled then return end

local apiKey = Config.API.apiKey or ''

---------------------------------------------------------------------------
-- Helper: Validate API key from Authorization header
---------------------------------------------------------------------------
local function ValidateAuth(req)
    if apiKey == '' then return true end -- No key configured = open access
    local auth = req.headers['Authorization'] or req.headers['authorization'] or ''
    return auth == ('Bearer ' .. apiKey)
end

---------------------------------------------------------------------------
-- Helper: Send JSON response
---------------------------------------------------------------------------
local function SendJSON(res, data, status)
    res.writeHead(status or 200, { ['Content-Type'] = 'application/json', ['Access-Control-Allow-Origin'] = '*' })
    res.send(json.encode(data))
end

---------------------------------------------------------------------------
-- Helper: Send error response
---------------------------------------------------------------------------
local function SendError(res, status, message)
    SendJSON(res, { error = message }, status)
end

---------------------------------------------------------------------------
-- Route: Parse URL path and query
---------------------------------------------------------------------------
local function ParsePath(path)
    -- Remove query string
    local cleanPath = path:match('^([^?]*)') or path
    -- Split path segments
    local segments = {}
    for segment in cleanPath:gmatch('[^/]+') do
        segments[#segments + 1] = segment
    end
    return segments
end

---------------------------------------------------------------------------
-- Register HTTP handler
---------------------------------------------------------------------------
SetHttpHandler(function(req, res)
    -- Handle CORS preflight
    if req.method == 'OPTIONS' then
        res.writeHead(200, {
            ['Access-Control-Allow-Origin'] = '*',
            ['Access-Control-Allow-Methods'] = 'GET, OPTIONS',
            ['Access-Control-Allow-Headers'] = 'Authorization, Content-Type',
        })
        res.send('')
        return
    end

    -- Only allow GET requests
    if req.method ~= 'GET' then
        SendError(res, 405, 'Method not allowed')
        return
    end

    -- Validate authentication
    if not ValidateAuth(req) then
        SendError(res, 401, 'Unauthorized: Invalid or missing API key')
        return
    end

    local segments = ParsePath(req.path)

    -- All routes start with /api
    if not segments[1] or segments[1] ~= 'api' then
        SendError(res, 404, 'Not found')
        return
    end

    local route = segments[2]

    ---------------------------------------------------------------------------
    -- GET /api/leaderboard
    ---------------------------------------------------------------------------
    if route == 'leaderboard' then
        local limit = tonumber(segments[3]) or Config.Leaderboard.maxEntries
        if limit > 100 then limit = 100 end

        MySQL.Async.fetchAll(
            'SELECT name, online_time, last_seen FROM users_online_time ORDER BY online_time DESC LIMIT @limit',
            { ['@limit'] = limit },
            function(result)
                local data = {}
                for i, row in ipairs(result) do
                    data[i] = {
                        rank       = i,
                        name       = row.name,
                        minutes    = row.online_time,
                        hours      = math.floor(row.online_time / 60 * 100) / 100,
                        last_seen  = row.last_seen,
                    }
                end
                SendJSON(res, { success = true, count = #data, data = data })
            end
        )

    ---------------------------------------------------------------------------
    -- GET /api/player/:identifier
    ---------------------------------------------------------------------------
    elseif route == 'player' then
        local identifier = segments[3]
        if not identifier or identifier == '' then
            SendError(res, 400, 'Missing identifier parameter')
            return
        end

        -- URL decode the identifier
        identifier = identifier:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)

        MySQL.Async.fetchAll(
            'SELECT name, online_time, last_seen FROM users_online_time WHERE identifier = @id',
            { ['@id'] = identifier },
            function(totalResult)
                if not totalResult[1] then
                    SendError(res, 404, 'Player not found')
                    return
                end

                local playerData = {
                    identifier = identifier,
                    name       = totalResult[1].name,
                    totalTime  = totalResult[1].online_time,
                    totalHours = math.floor(totalResult[1].online_time / 60 * 100) / 100,
                    lastSeen   = totalResult[1].last_seen,
                }

                -- Get daily time
                MySQL.Async.fetchAll(
                    'SELECT online_time FROM users_online_daily WHERE identifier = @id AND date = CURDATE()',
                    { ['@id'] = identifier },
                    function(dailyResult)
                        playerData.dailyTime = (dailyResult[1] and dailyResult[1].online_time) or 0

                        -- Get weekly time
                        MySQL.Async.fetchAll(
                            'SELECT COALESCE(SUM(online_time), 0) as total FROM users_online_daily WHERE identifier = @id AND date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)',
                            { ['@id'] = identifier },
                            function(weeklyResult)
                                playerData.weeklyTime = (weeklyResult[1] and weeklyResult[1].total) or 0

                                -- Get login streak
                                MySQL.Async.fetchAll(
                                    'SELECT current_streak, max_streak, total_logins FROM users_login_streaks WHERE identifier = @id',
                                    { ['@id'] = identifier },
                                    function(streakResult)
                                        if streakResult[1] then
                                            playerData.loginStreak = streakResult[1].current_streak
                                            playerData.maxStreak   = streakResult[1].max_streak
                                            playerData.totalLogins = streakResult[1].total_logins
                                        else
                                            playerData.loginStreak = 0
                                            playerData.maxStreak   = 0
                                            playerData.totalLogins = 0
                                        end

                                        SendJSON(res, { success = true, data = playerData })
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )

    ---------------------------------------------------------------------------
    -- GET /api/stats
    ---------------------------------------------------------------------------
    elseif route == 'stats' then
        MySQL.Async.fetchAll(
            'SELECT COUNT(*) as total_players, COALESCE(SUM(online_time), 0) as total_time FROM users_online_time', {},
            function(allResult)
                MySQL.Async.fetchAll(
                    'SELECT COUNT(DISTINCT identifier) as today_active FROM users_online_daily WHERE date = CURDATE()', {},
                    function(todayResult)
                        MySQL.Async.fetchAll(
                            'SELECT COUNT(DISTINCT identifier) as week_active FROM users_online_daily WHERE date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)', {},
                            function(weekResult)
                                local onlineNow = #GetPlayers()
                                SendJSON(res, {
                                    success = true,
                                    data = {
                                        onlineNow     = onlineNow,
                                        totalPlayers  = allResult[1] and allResult[1].total_players or 0,
                                        totalMinutes  = allResult[1] and allResult[1].total_time or 0,
                                        totalHours    = math.floor((allResult[1] and allResult[1].total_time or 0) / 60 * 100) / 100,
                                        todayActive   = todayResult[1] and todayResult[1].today_active or 0,
                                        weekActive    = weekResult[1] and weekResult[1].week_active or 0,
                                    }
                                })
                            end
                        )
                    end
                )
            end
        )

    ---------------------------------------------------------------------------
    -- GET /api/online
    ---------------------------------------------------------------------------
    elseif route == 'online' then
        local players = {}
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local identifier = Bridge.GetIdentifier(src)
            local name = Bridge.GetName(src)
            local sessionTime = 0
            if PlayerSessions and PlayerSessions[src] then
                sessionTime = math.floor((os.time() - PlayerSessions[src]) / 60)
            end
            players[#players + 1] = {
                id         = src,
                name       = name,
                identifier = identifier,
                session    = sessionTime,
                isAFK      = PlayerAFK and PlayerAFK[src] == true or false,
            }
        end
        SendJSON(res, { success = true, count = #players, data = players })

    else
        SendError(res, 404, 'Unknown endpoint: /api/' .. (route or ''))
    end
end)

print('[tayer-uptime] ^2HTTP API enabled — endpoints available at /api/*^0')
