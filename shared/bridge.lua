--- Framework Bridge for tayer-uptime
--- Auto-detects ESX, QBCore, QBOX, or Standalone mode
--- All framework-specific calls go through this bridge

Bridge = {}
Bridge.Framework = nil -- 'esx', 'qbcore', 'qbox', 'standalone'

---------------------------------------------------------------------------
-- Framework Detection
---------------------------------------------------------------------------
local function DetectFramework()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qbcore'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    else
        return 'standalone'
    end
end

Bridge.Framework = DetectFramework()
print(('[tayer-uptime] ^2Framework detected: %s^0'):format(Bridge.Framework))

---------------------------------------------------------------------------
-- ox_lib Detection
---------------------------------------------------------------------------
Bridge.HasOxLib = GetResourceState('ox_lib') == 'started'
if Bridge.HasOxLib then
    print('[tayer-uptime] ^2ox_lib detected — using enhanced notifications^0')
end

---------------------------------------------------------------------------
-- Framework Object Cache
---------------------------------------------------------------------------
local FrameworkObj = nil

local function GetFrameworkObj()
    if FrameworkObj then return FrameworkObj end

    if Bridge.Framework == 'esx' then
        FrameworkObj = exports['es_extended']:getSharedObject()
    elseif Bridge.Framework == 'qbcore' then
        FrameworkObj = exports['qb-core']:GetCoreObject()
    elseif Bridge.Framework == 'qbox' then
        FrameworkObj = exports['qbx_core']:GetCoreObject()
    end

    return FrameworkObj
end

---------------------------------------------------------------------------
-- Server-Side Bridge Functions
---------------------------------------------------------------------------
if IsDuplicityVersion() then

    --- Get a player wrapper object
    --- @param source number Player server ID
    --- @return table|nil Player data or nil
    function Bridge.GetPlayer(source)
        local fw = GetFrameworkObj()
        if Bridge.Framework == 'esx' and fw then
            return fw.GetPlayerFromId(source)
        elseif (Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox') and fw then
            return fw.Functions.GetPlayer(source)
        end
        return nil
    end

    --- Get player identifier
    --- @param source number Player server ID
    --- @return string|nil Identifier
    function Bridge.GetIdentifier(source)
        if Bridge.Framework == 'esx' then
            local xPlayer = Bridge.GetPlayer(source)
            return xPlayer and xPlayer.identifier
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local player = Bridge.GetPlayer(source)
            return player and player.PlayerData.citizenid
        else
            -- Standalone: use license identifier
            for i = 0, GetNumPlayerIdentifiers(source) - 1 do
                local id = GetPlayerIdentifier(source, i)
                if id and id:find('license:') then
                    return id
                end
            end
            return nil
        end
    end

    --- Get player name
    --- @param source number Player server ID
    --- @return string Player name
    function Bridge.GetName(source)
        if Bridge.Framework == 'esx' then
            local xPlayer = Bridge.GetPlayer(source)
            return xPlayer and xPlayer.getName() or GetPlayerName(source) or 'Unknown'
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local player = Bridge.GetPlayer(source)
            if player then
                local charInfo = player.PlayerData.charinfo
                return ('%s %s'):format(charInfo.firstname or '', charInfo.lastname or '')
            end
            return GetPlayerName(source) or 'Unknown'
        else
            return GetPlayerName(source) or 'Unknown'
        end
    end

    --- Add money to player
    --- @param source number Player server ID
    --- @param amount number Amount to add
    function Bridge.AddMoney(source, amount)
        if Bridge.Framework == 'esx' then
            local xPlayer = Bridge.GetPlayer(source)
            if xPlayer then xPlayer.addMoney(amount) end
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local player = Bridge.GetPlayer(source)
            if player then player.Functions.AddMoney('cash', amount) end
        else
            -- Standalone: no money system
            print(('[tayer-uptime] ^3Standalone mode: Cannot add $%d to player %d^0'):format(amount, source))
        end
    end

    --- Get player's permission group
    --- @param source number Player server ID
    --- @return string Group name
    function Bridge.GetGroup(source)
        if Bridge.Framework == 'esx' then
            local xPlayer = Bridge.GetPlayer(source)
            return xPlayer and xPlayer.getGroup() or 'user'
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local fw = GetFrameworkObj()
            if fw and fw.Functions.HasPermission(source, 'god') then
                return 'superadmin'
            elseif fw and fw.Functions.HasPermission(source, 'admin') then
                return 'admin'
            end
            return 'user'
        else
            -- Standalone: check FiveM ace permissions
            if IsPlayerAceAllowed(source, 'command.tayer_admin') then
                return 'admin'
            end
            return 'user'
        end
    end

    --- Set player's permission group
    --- @param source number Player server ID
    --- @param group string Group name
    function Bridge.SetGroup(source, group)
        if Bridge.Framework == 'esx' then
            local xPlayer = Bridge.GetPlayer(source)
            if xPlayer then xPlayer.setGroup(group) end
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            -- QBCore doesn't use setGroup the same way; playtime roles
            -- would need custom permission handling per server
            print(('[tayer-uptime] ^3QBCore: SetGroup not directly supported, skipping group "%s" for player %d^0'):format(group, source))
        end
    end

    --- Add item to player inventory
    --- @param source number Player server ID
    --- @param item string Item name
    --- @param count number Amount
    --- @return boolean Success
    function Bridge.AddItem(source, item, count)
        count = count or 1

        -- Try ox_inventory first (works across all frameworks)
        if GetResourceState('ox_inventory') == 'started' then
            local success = exports.ox_inventory:AddItem(source, item, count)
            return success ~= false
        end

        if Bridge.Framework == 'esx' then
            local xPlayer = Bridge.GetPlayer(source)
            if xPlayer then
                xPlayer.addInventoryItem(item, count)
                return true
            end
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local player = Bridge.GetPlayer(source)
            if player then
                return player.Functions.AddItem(item, count)
            end
        end

        return false
    end

    --- Register a server callback (framework-agnostic)
    --- @param name string Callback name
    --- @param cb function Callback function(source, cb, ...)
    function Bridge.RegisterServerCallback(name, cb)
        if Bridge.HasOxLib then
            lib.callback.register(name, function(source, ...)
                local p = promise.new()
                cb(source, function(result)
                    p:resolve(result)
                end, ...)
                return Citizen.Await(p)
            end)
        elseif Bridge.Framework == 'esx' then
            local fw = GetFrameworkObj()
            fw.RegisterServerCallback(name, cb)
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local fw = GetFrameworkObj()
            fw.Functions.CreateCallback(name, cb)
        else
            -- Standalone: use events-based callback system
            RegisterNetEvent(name .. ':request')
            AddEventHandler(name .. ':request', function(...)
                local src = source
                cb(src, function(result)
                    TriggerClientEvent(name .. ':response', src, result)
                end, ...)
            end)
        end
    end

    --- Send notification to player (server-side)
    --- @param source number Player server ID
    --- @param msg string Message
    --- @param type string|nil Notification type ('success', 'error', 'info')
    function Bridge.Notify(source, msg, type)
        if Bridge.HasOxLib then
            TriggerClientEvent('ox_lib:notify', source, {
                description = msg,
                type = type or 'info',
            })
        elseif Bridge.Framework == 'esx' then
            TriggerClientEvent('esx:showNotification', source, msg)
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            TriggerClientEvent('QBCore:Notify', source, msg, type or 'primary')
        else
            TriggerClientEvent('chat:addMessage', source, { args = { 'UPTIME', msg } })
        end
    end

    --- Register player loaded event handler
    --- @param cb function Callback(source, identifier, name)
    function Bridge.OnPlayerLoaded(cb)
        if Bridge.Framework == 'esx' then
            RegisterNetEvent('esx:playerLoaded')
            AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
                local src = source
                if xPlayer then
                    cb(src, xPlayer.identifier, xPlayer.getName() or 'Unknown')
                end
            end)
        elseif Bridge.Framework == 'qbcore' then
            RegisterNetEvent('QBCore:Server:PlayerLoaded')
            AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
                local src = source
                if player then
                    cb(src, player.PlayerData.citizenid, ('%s %s'):format(
                        player.PlayerData.charinfo.firstname or '',
                        player.PlayerData.charinfo.lastname or ''
                    ))
                end
            end)
        elseif Bridge.Framework == 'qbox' then
            RegisterNetEvent('QBCore:Server:PlayerLoaded')
            AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
                local src = source
                if player then
                    cb(src, player.PlayerData.citizenid, ('%s %s'):format(
                        player.PlayerData.charinfo.firstname or '',
                        player.PlayerData.charinfo.lastname or ''
                    ))
                end
            end)
        else
            -- Standalone: use playerConnecting as the "loaded" event
            AddEventHandler('playerConnecting', function()
                local src = source
                local identifier = Bridge.GetIdentifier(src)
                local name = GetPlayerName(src) or 'Unknown'
                if identifier then
                    cb(src, identifier, name)
                end
            end)
        end
    end

---------------------------------------------------------------------------
-- Client-Side Bridge Functions
---------------------------------------------------------------------------
else

    --- Trigger a server callback (framework-agnostic)
    --- @param name string Callback name
    --- @param cb function Response callback
    --- @param ... any Additional arguments
    function Bridge.TriggerServerCallback(name, cb, ...)
        if Bridge.HasOxLib then
            local result = lib.callback.await(name, false, ...)
            cb(result)
        elseif Bridge.Framework == 'esx' then
            local fw = GetFrameworkObj()
            fw.TriggerServerCallback(name, cb, ...)
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local fw = GetFrameworkObj()
            fw.Functions.TriggerCallback(name, cb, ...)
        else
            -- Standalone: events-based callback
            local args = {...}
            TriggerServerEvent(name .. ':request', table.unpack(args))
            RegisterNetEvent(name .. ':response')
            AddEventHandler(name .. ':response', function(result)
                cb(result)
            end)
        end
    end

    --- Show notification to local player
    --- @param msg string Message
    --- @param type string|nil Type ('success', 'error', 'info')
    function Bridge.Notify(msg, type)
        if Bridge.HasOxLib then
            lib.notify({
                description = msg,
                type = type or 'info',
            })
        elseif Bridge.Framework == 'esx' then
            local fw = GetFrameworkObj()
            fw.ShowNotification(msg)
        elseif Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            local fw = GetFrameworkObj()
            fw.Functions.Notify(msg, type or 'primary')
        else
            TriggerEvent('chat:addMessage', { args = { 'UPTIME', msg } })
        end
    end

end
