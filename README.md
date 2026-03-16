# Tayer Uptime

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/uucz/tayer-uptime/blob/main/LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Multi--Framework-orange.svg)](https://fivem.net)
[![GitHub Stars](https://img.shields.io/github/stars/uucz/tayer-uptime?style=social)](https://github.com/uucz/tayer-uptime)
[![Version](https://img.shields.io/badge/version-2.4.1-blue.svg)](https://github.com/uucz/tayer-uptime/releases)

A feature-rich **FiveM** player online time tracking resource. Supports **ESX, QBCore, QBOX, and Standalone** with automatic framework detection. Includes NUI dashboard, server-side AFK detection, milestone rewards (money/items/vehicles), daily login streaks, playtime-gated roles, session history, admin audit logging, HTTP REST API, ox_lib integration, activity heatmap, and Discord webhook notifications.

> **Chinese documentation below** / **中文文档见下方**

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Basic Settings](#basic-settings)
  - [AFK Detection](#afk-detection)
  - [Milestone Rewards](#milestone-rewards)
  - [Daily Login Rewards](#daily-login-rewards)
  - [Playtime-Gated Roles](#playtime-gated-roles)
  - [First-Join Welcome Bonus](#first-join-welcome-bonus)
  - [Discord Webhooks](#discord-webhooks)
  - [Discord Role Sync](#discord-role-sync)
  - [HTTP REST API](#http-rest-api-1)
  - [Data Maintenance](#data-maintenance)
- [Commands](#commands)
- [NUI Dashboard](#nui-dashboard)
- [Exports API](#exports-api)
- [HTTP REST API](#http-rest-api)
- [Database Tables](#database-tables)
- [Security](#security)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### Core Tracking
- **Automatic Time Tracking** — Records each player's online time every minute (configurable interval)
- **Daily/Weekly/Monthly Stats** — Track and view time breakdowns by period
- **Session History** — Full session recording with connect/disconnect times and disconnect reasons
- **Crash-Safe** — Saves unsaved time on disconnect; handles resource restarts gracefully

### AFK System
- **Server-Side AFK Detection** — Fully server-authoritative position tracking using `GetEntityCoords(GetPlayerPed())`, no client trust
- **AFK Kick** — Optional auto-kick after extended AFK period with configurable timeout

### Rewards & Progression
- **Milestone Rewards** — Configurable playtime milestones with rich rewards (money, items, vehicles)
- **Daily Login Rewards** — Streak-based login rewards with grace period and 7-day cycles
- **First-Join Welcome** — Configurable welcome bonus for new players
- **Playtime-Gated Roles** — Auto-assign framework permission groups based on total playtime

### User Interface
- **NUI Dashboard** — Beautiful in-game panel (`/uptime`) with 5 tabs: Overview, Leaderboard, Milestones, Login Streak, Activity
- **Activity Heatmap** — GitHub-style 7x24 grid showing play patterns by day of week and hour
- **Leaderboard** — View top players ranked by online time

### Administration
- **Admin Commands** — Check, reset, set, or add time for any player with full audit logging
- **Server Stats** — Server-wide statistics command for administrators
- **txAdmin Import** — Migrate existing playtime data from txAdmin

### Integrations
- **Multi-Framework** — Auto-detects ESX, QBCore, QBOX, or Standalone mode
- **ox_lib Integration** — Optional enhanced notifications and callbacks via ox_lib
- **Discord Webhooks** — Notifications for connect, disconnect, milestones, login rewards, role promotions, AFK kicks, admin actions, first-join, daily reports
- **Discord Daily Report** — Automated daily server stats summary at configurable time
- **Discord Role Sync** — Auto-assign Discord roles based on playtime using Discord Bot API
- **HTTP REST API** — JSON endpoints for external tools, web dashboards, and Discord bots with Bearer token authentication
- **Exports API** — 7 exports for other resources to query playtime data
- **Multi-Language** — Built-in support for zh-CN, en, es, fr, de, pt-BR

---

## Requirements

| Dependency | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/overextended/oxmysql) | **Yes** | Database driver |
| [es_extended](https://github.com/esx-framework/esx-legacy) | Auto-detected | ESX framework |
| [qb-core](https://github.com/qbcore-framework/qb-core) | Auto-detected | QBCore framework |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Auto-detected | QBOX framework |
| [ox_lib](https://github.com/overextended/ox_lib) | Optional | Enhanced notifications & callbacks |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Optional | Used for item rewards (auto-detected) |

> **Note:** No framework is required. The resource works in Standalone mode using FiveM's native `license:` identifiers and ace permissions.

---

## Installation

1. Download or clone the repository:
   ```bash
   git clone https://github.com/uucz/tayer-uptime.git
   ```
2. Place the `tayer-uptime` folder into your server's `resources/` directory.
3. Add to your `server.cfg`:
   ```cfg
   ensure tayer-uptime
   ```
4. All database tables are created automatically on first start.

### Framework-Specific Notes

**ESX** — No additional setup needed. Player identifier uses `xPlayer.identifier`.

**QBCore / QBOX** — No additional setup needed. Player identifier uses `citizenid`.

**Standalone** — Uses `license:` identifier. For admin commands, grant the ace permission:
```cfg
add_ace group.admin command.tayer_admin allow
```

---

## Configuration

All settings are in [`config.lua`](config.lua). Below are detailed examples for each feature.

### Basic Settings

```lua
Config.Locale = 'zh-CN'          -- Language: 'zh-CN', 'en', 'es', 'fr', 'de', 'pt-BR'
Config.UpdateInterval = 60000    -- Tracking interval in ms (default: 60000 = 1 min)

-- Customize command names
Config.Commands = {
    onlinetime  = 'onlinetime',
    toptime     = 'toptime',
    admintime   = 'admintime',
    resettime   = 'resettime',
    dailytime   = 'dailytime',
    weeklytime  = 'weeklytime',
    monthlytime = 'monthlytime',
    rewards     = 'rewards',
    loginreward = 'loginreward',
    uptime      = 'uptime',
}

-- Admin permission groups (players in these groups can use admin commands)
Config.AdminGroups = { 'admin', 'superadmin' }

-- Leaderboard settings
Config.Leaderboard = { maxEntries = 10 }
```

### AFK Detection

Server-authoritative AFK detection — checks player position server-side, no client trust involved.

```lua
Config.AFK = {
    enabled       = true,
    timeout       = 300,     -- Seconds before marking AFK (5 min)
    checkInterval = 15,      -- Server check interval in seconds
    minDistance    = 5.0,     -- Min movement in meters to count as active
    kickEnabled   = false,   -- Enable AFK kick
    kickTimeout   = 1800,    -- Seconds before kick (30 min)
    kickMessage   = 'You have been kicked for being AFK too long.',
}
```

When a player is AFK:
- Their time tracking is **paused** (AFK time is not counted)
- They receive a notification and the NUI dashboard shows "AFK - Tracking Paused"
- If `kickEnabled`, they are kicked after `kickTimeout` seconds

### Milestone Rewards

Automatic rewards when players reach playtime milestones. Supports three reward types.

```lua
Config.Rewards = {
    enabled = true,
    milestones = {
        -- Money reward (default type)
        { hours = 1,   money = 5000,   label = '1 Hour'   },
        { hours = 10,  money = 30000,  label = '10 Hours'  },
        { hours = 100, money = 150000, label = '100 Hours' },

        -- Item reward (requires ox_inventory or framework inventory)
        { hours = 10, type = 'item', item = 'bread', count = 5, money = 10000, label = '10h Item Pack' },

        -- Vehicle reward (custom callback)
        { hours = 500, type = 'vehicle', label = '500h Vehicle', callback = function(src, identifier)
            -- Your custom vehicle spawn/garage logic here
            -- Example: exports['qb-garage']:GiveVehicle(src, 'adder')
        end },
    },
}
```

- Rewards are automatically claimed when a player's total time exceeds the milestone
- Each milestone can only be claimed once per player
- The `money` field is always given if present, regardless of `type`
- Item rewards use ox_inventory first (if available), then fall back to framework inventory

### Daily Login Rewards

Streak-based daily rewards that cycle every 7 days.

```lua
Config.DailyLogin = {
    enabled     = true,
    gracePeriod = 1,  -- Days allowed to miss before streak resets (0 = strict)
    rewards = {
        { day = 1, money = 1000  },
        { day = 2, money = 2000  },
        { day = 3, money = 3000  },
        { day = 4, money = 4000  },
        { day = 5, money = 5000  },
        { day = 6, money = 7500  },
        { day = 7, money = 10000 },  -- Weekly bonus
    },
}
```

- Rewards cycle: after day 7, it goes back to day 1 rewards
- `gracePeriod = 1` means missing one day doesn't reset the streak
- Players can view their streak with `/loginreward` or in the NUI dashboard

### Playtime-Gated Roles

Automatically assign framework permission groups based on accumulated playtime.

```lua
Config.PlaytimeRoles = {
    enabled = true,
    roles = {
        { hours = 10,  group = 'regular',  label = 'Regular Player' },
        { hours = 50,  group = 'veteran',  label = 'Veteran'        },
        { hours = 100, group = 'trusted',  label = 'Trusted Member' },
    },
}
```

- Players are assigned the **highest** role they qualify for
- Only applies to players in the `user` group (will not demote admins)
- On ESX, uses `xPlayer.setGroup()`. On QBCore/QBOX, a console message is printed (custom permission handling needed per server)

### First-Join Welcome Bonus

Give new players a welcome bonus on their first connection.

```lua
Config.FirstJoin = {
    enabled    = true,
    bonusMoney = 5000,
}
```

### Discord Webhooks

Send notifications to a Discord channel for various events.

```lua
Config.Discord = {
    enabled     = true,
    webhookUrl  = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
    botName     = 'Tayer Uptime',
    color       = 3066993,       -- Default embed color (green, decimal)
    dailyReport = true,          -- Send daily server stats summary
    reportTime  = '00:00',       -- Time to send daily report (HH:MM, server time)
}
```

**Events sent to Discord:**

| Event | Color | Trigger |
|---|---|---|
| Player Connect | Green | Player joins server |
| Player Disconnect | Red | Player leaves (with session time) |
| Milestone Reached | Gold | Player claims a milestone reward |
| Login Reward | Blue | Player receives daily login reward |
| Role Promotion | Purple | Player is promoted to a new role |
| AFK Kick | Orange | Player is kicked for AFK |
| First Join | Green | New player joins for the first time |
| Daily Report | Blue | Automated daily summary (configurable time) |
| Admin Audit | Grey | Admin performs an action (reset/set/add time) |

### Discord Role Sync

Automatically assign Discord roles based on playtime. Requires a Discord Bot (not just a webhook).

```lua
Config.DiscordRoles = {
    enabled  = true,
    botToken = 'YOUR_BOT_TOKEN',   -- Discord Bot token
    guildId  = '123456789012345',   -- Your Discord server ID
    roles    = {
        { hours = 10,  roleId = '111111111111111111' },  -- 10h role
        { hours = 50,  roleId = '222222222222222222' },  -- 50h role
        { hours = 100, roleId = '333333333333333333' },  -- 100h role
    },
}
```

**Setup:**
1. Create a Discord Bot at [discord.com/developers](https://discord.com/developers/applications)
2. Enable the **Server Members** intent
3. Invite the bot to your server with the **Manage Roles** permission
4. Create roles in your Discord server and copy their IDs
5. Ensure the bot's role is **above** the roles it needs to assign in the role hierarchy

The resource uses the Discord API (`PUT /guilds/{guildId}/members/{userId}/roles/{roleId}`) to assign roles. It finds the player's Discord ID from their FiveM identifiers.

### HTTP REST API

Enable a JSON REST API for external tools, web dashboards, or Discord bots.

```lua
Config.API = {
    enabled = true,
    apiKey  = 'your-secret-api-key-here',  -- Leave empty for open access (not recommended)
}
```

See [HTTP REST API](#http-rest-api) section below for endpoint documentation.

### Data Maintenance

Automatically clean up data from inactive players.

```lua
Config.Maintenance = {
    cleanupEnabled = false,    -- Enable auto-cleanup
    inactiveDays   = 90,       -- Days of inactivity before cleanup
    cleanupTime    = '04:00',  -- Time to run (HH:MM, server time)
}
```

---

## Commands

### Player Commands

| Command | Description |
|---|---|
| `/onlinetime` | Check your total online time |
| `/toptime` | View online time leaderboard |
| `/dailytime` | Check today's online time |
| `/weeklytime` | Check this week's online time |
| `/monthlytime` | Check this month's online time |
| `/rewards` | View milestone rewards progress |
| `/loginreward` | View daily login reward status |
| `/uptime` | Open NUI dashboard panel |

### Admin Commands

| Command | Description |
|---|---|
| `/admintime [id]` | Check a specific player's online time |
| `/resettime [id]` | Reset a player's online time to zero (audited) |
| `/settime [id] [minutes]` | Set a player's online time to exact value (audited) |
| `/addtime [id] [minutes]` | Add time to a player's total (audited) |
| `/serverstats` | View server-wide statistics |
| `/importtxadmin [path]` | Import playtime data from txAdmin JSON |

All admin commands require the player to be in one of the `Config.AdminGroups` groups. All admin actions are logged to the `uptime_audit_log` database table and sent to Discord (if enabled).

---

## NUI Dashboard

Open the dashboard with `/uptime`. The panel has 5 tabs:

| Tab | Content |
|---|---|
| **Overview** | Total time, daily/weekly/monthly stats, current session, AFK status, your rank |
| **Leaderboard** | Top players with your position highlighted |
| **Milestones** | Reward progress with progress bars, claimed/available/locked status |
| **Login Streak** | Current streak with flame animation, best streak, total logins, reward status |
| **Activity** | GitHub-style 7x24 heatmap showing your play patterns by day and hour |

Press **ESC** or click the **X** button to close.

---

## Exports API

Use these exports from other resources to query playtime data:

```lua
-- Get total online time in minutes
local minutes = exports['tayer-uptime']:GetPlaytime(source)

-- Check if player is currently AFK
local isAFK = exports['tayer-uptime']:IsPlayerAFK(source)

-- Check if player has at least N hours of playtime
local has100h = exports['tayer-uptime']:HasPlaytimeHours(source, 100)

-- Get top N players (returns array of {name, online_time})
local top10 = exports['tayer-uptime']:GetTopPlayers(10)

-- Get today's playtime in minutes
local dailyMinutes = exports['tayer-uptime']:GetDailyPlaytime(source)

-- Get this week's playtime in minutes
local weeklyMinutes = exports['tayer-uptime']:GetWeeklyPlaytime(source)

-- Get login streak info
local streakInfo = exports['tayer-uptime']:GetLoginStreak(source)
-- Returns: { streak = 5, maxStreak = 12 }
```

### Usage Example: Gate Access by Playtime

```lua
-- In another resource's server.lua
RegisterCommand('viparea', function(source)
    local has50h = exports['tayer-uptime']:HasPlaytimeHours(source, 50)
    if has50h then
        TriggerClientEvent('myresource:openVIPDoor', source)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'SYSTEM', 'You need 50 hours of playtime to access VIP area.' }
        })
    end
end, false)
```

---

## HTTP REST API

When enabled (`Config.API.enabled = true`), the resource registers HTTP endpoints accessible from outside FiveM.

**Base URL:** `http://your-server-ip:30120/tayer-uptime/api/`

**Authentication:** Include the API key in the `Authorization` header:
```
Authorization: Bearer YOUR_API_KEY
```

### Endpoints

#### `GET /api/leaderboard`

Returns top players ranked by online time.

```
GET /api/leaderboard      — Default limit (Config.Leaderboard.maxEntries)
GET /api/leaderboard/20   — Top 20 players (max 100)
```

**Response:**
```json
{
  "success": true,
  "count": 10,
  "data": [
    {
      "rank": 1,
      "name": "Player Name",
      "minutes": 6000,
      "hours": 100.0,
      "last_seen": "2026-03-15 22:30:00"
    }
  ]
}
```

#### `GET /api/player/:identifier`

Returns detailed information for a specific player.

```
GET /api/player/license:abc123def456
GET /api/player/char1:abc123
```

**Response:**
```json
{
  "success": true,
  "data": {
    "identifier": "license:abc123def456",
    "name": "Player Name",
    "totalTime": 6000,
    "totalHours": 100.0,
    "lastSeen": "2026-03-15 22:30:00",
    "dailyTime": 120,
    "weeklyTime": 840,
    "loginStreak": 5,
    "maxStreak": 12,
    "totalLogins": 45
  }
}
```

#### `GET /api/stats`

Returns server-wide statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "onlineNow": 32,
    "totalPlayers": 1250,
    "totalMinutes": 5000000,
    "totalHours": 83333.33,
    "todayActive": 85,
    "weekActive": 320
  }
}
```

#### `GET /api/online`

Returns currently online players with session info.

**Response:**
```json
{
  "success": true,
  "count": 32,
  "data": [
    {
      "id": 1,
      "name": "Player Name",
      "identifier": "license:abc123",
      "session": 45,
      "isAFK": false
    }
  ]
}
```

**Error Response:**
```json
{
  "error": "Unauthorized: Invalid or missing API key"
}
```

All endpoints support CORS (OPTIONS preflight).

---

## Database Tables

All tables are created automatically on first start.

| Table | Purpose |
|---|---|
| `users_online_time` | Total cumulative online time per player |
| `users_online_daily` | Daily online time breakdown |
| `users_online_monthly` | Monthly online time breakdown |
| `users_online_rewards` | Claimed milestone rewards |
| `users_login_streaks` | Daily login streaks and history |
| `users_sessions` | Session history (connect/disconnect times, reasons) |
| `users_playtime_roles` | Granted playtime-based roles |
| `uptime_audit_log` | Admin action audit trail |
| `users_activity_hourly` | Hourly activity data (for heatmap) |

---

## Security

- **Server-authoritative AFK detection** — Uses `GetEntityCoords(GetPlayerPed())` server-side; no client events to exploit
- **Parameterized SQL queries** — All database operations use `@parameters` to prevent SQL injection
- **Admin audit logging** — All admin actions are logged to database and Discord
- **No client-to-server trust** — All rewards, role changes, and time tracking are server-side only
- **API authentication** — HTTP API requires Bearer token; no key = open access (configurable)
- **CORS support** — API includes proper CORS headers for web dashboard integration

---

## Project Structure

```
tayer-uptime/
├── config.lua              # All configuration options
├── client.lua              # Client-side: commands, AFK display, NUI control
├── server.lua              # Server-side: tracking, AFK, rewards, roles, sessions
├── fxmanifest.lua          # Resource manifest (v2.4.1)
├── shared/
│   ├── bridge.lua          # Multi-framework bridge (ESX/QBCore/QBOX/Standalone)
│   └── locale.lua          # Locale/i18n system
├── locales/
│   ├── zh-CN.lua           # Chinese (Simplified)
│   ├── en.lua              # English
│   ├── es.lua              # Spanish
│   ├── fr.lua              # French
│   ├── de.lua              # German
│   └── pt-BR.lua           # Portuguese (Brazil)
├── server/
│   ├── api.lua             # HTTP REST API endpoints
│   └── discord.lua         # Discord webhook module
├── ui/
│   ├── index.html          # NUI dashboard HTML
│   ├── style.css           # NUI dashboard styles (dark glassmorphism)
│   └── script.js           # NUI dashboard logic (heatmap, leaderboard, etc.)
├── CHANGELOG.md            # Version history
├── CONTRIBUTING.md         # Contribution guidelines
└── LICENSE                 # MIT License
```

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).

---

# Tayer Uptime（中文文档）

一个功能丰富的 **FiveM** 玩家在线时长追踪资源。支持 **ESX、QBCore、QBOX 和 Standalone** 自动检测。具备 NUI 面板、服务端 AFK 检测、里程碑奖励（金钱/物品/载具）、每日登录奖励、时长门控角色、会话历史、管理员审计日志、HTTP REST API、ox_lib 集成、活跃度热力图和 Discord Webhook 通知。

## 功能特点

### 核心追踪
- **自动时长追踪** — 每分钟自动记录在线时间（可配置间隔）
- **每日/每周/每月统计** — 分时段查看在线时长
- **会话历史** — 完整记录每次连接/断开时间和原因
- **防崩溃** — 断线时保存未记录时间，支持资源重启

### AFK 系统
- **服务端 AFK 检测** — 完全服务端权威位置追踪，无客户端信任
- **AFK 踢出** — 可选长时间 AFK 自动踢出

### 奖励与进阶
- **里程碑奖励** — 可配置时长里程碑，支持金钱/物品/载具奖励
- **每日登录奖励** — 连续登录奖励，支持宽限期和 7 天循环
- **新玩家欢迎** — 可配置首次加入奖励金
- **时长门控角色** — 根据总时长自动分配权限组

### 用户界面
- **NUI 面板** — 精美游戏内面板 (`/uptime`)，含概览、排行榜、里程碑、登录连续、活跃度 5 个标签页
- **活跃度热力图** — GitHub 风格 7x24 网格，展示每周每时段活跃模式
- **排行榜** — 在线时长排名

### 管理功能
- **管理员命令** — 查看/重置/设置/增加时长，带完整审计日志
- **服务器统计** — 管理员专用服务器统计命令
- **txAdmin 导入** — 从 txAdmin 迁移现有时长数据

### 集成
- **多框架** — 自动检测 ESX、QBCore、QBOX 或独立模式
- **ox_lib 集成** — 可选增强通知和回调
- **Discord Webhook** — 上线、下线、里程碑、登录奖励、角色晋升、AFK 踢出、管理操作、新玩家、每日报告通知
- **Discord 每日报告** — 可配置时间自动发送服务器每日统计摘要
- **Discord 角色同步** — 基于时长自动分配 Discord 角色（需 Bot Token）
- **HTTP REST API** — JSON 接口供外部工具、Web 面板和 Discord 机器人使用，支持 Token 认证
- **Exports API** — 7 个接口供其他脚本查询
- **多语言** — 支持 zh-CN、en、es、fr、de、pt-BR

---

## 安装

1. 下载或克隆仓库：
   ```bash
   git clone https://github.com/uucz/tayer-uptime.git
   ```
2. 将 `tayer-uptime` 文件夹放入服务器的 `resources/` 目录。
3. 在 `server.cfg` 中添加：
   ```cfg
   ensure tayer-uptime
   ```
4. 所有数据库表在首次启动时自动创建。

### 框架说明

**ESX** — 无需额外配置。使用 `xPlayer.identifier` 作为标识符。

**QBCore / QBOX** — 无需额外配置。使用 `citizenid` 作为标识符。

**独立模式** — 使用 `license:` 标识符。管理员权限需要设置 ace：
```cfg
add_ace group.admin command.tayer_admin allow
```

---

## 配置

所有设置均在 [`config.lua`](config.lua) 中。

### AFK 检测

```lua
Config.AFK = {
    enabled       = true,
    timeout       = 300,     -- AFK 判定时间（秒）
    checkInterval = 15,      -- 服务端检查间隔（秒）
    minDistance    = 5.0,     -- 最小移动距离（米）
    kickEnabled   = false,   -- 是否启用 AFK 踢出
    kickTimeout   = 1800,    -- 踢出前等待时间（秒）
    kickMessage   = 'You have been kicked for being AFK too long.',
}
```

### 里程碑奖励

```lua
Config.Rewards = {
    enabled = true,
    milestones = {
        -- 金钱奖励
        { hours = 1,   money = 5000,   label = '1小时'  },
        { hours = 10,  money = 30000,  label = '10小时' },
        { hours = 100, money = 150000, label = '100小时' },

        -- 物品奖励（需要 ox_inventory 或框架背包）
        { hours = 10, type = 'item', item = 'bread', count = 5, money = 10000, label = '10小时物品包' },

        -- 载具奖励（自定义回调）
        { hours = 500, type = 'vehicle', label = '500小时载具', callback = function(src, identifier)
            -- 在这里实现你的载具发放逻辑
        end },
    },
}
```

### Discord Webhook

```lua
Config.Discord = {
    enabled     = true,
    webhookUrl  = 'https://discord.com/api/webhooks/你的Webhook地址',
    botName     = 'Tayer Uptime',
    color       = 3066993,
    dailyReport = true,       -- 每日统计报告
    reportTime  = '00:00',    -- 报告发送时间
}
```

### Discord 角色同步

```lua
Config.DiscordRoles = {
    enabled  = true,
    botToken = '你的Bot Token',
    guildId  = '你的服务器ID',
    roles    = {
        { hours = 10,  roleId = 'Discord角色ID' },
        { hours = 50,  roleId = 'Discord角色ID' },
        { hours = 100, roleId = 'Discord角色ID' },
    },
}
```

**配置步骤：**
1. 在 [Discord 开发者门户](https://discord.com/developers/applications) 创建 Bot
2. 开启 **Server Members** Intent
3. 以 **管理角色** 权限邀请 Bot 到你的服务器
4. 确保 Bot 的角色在需要分配的角色 **上方**

### HTTP REST API

```lua
Config.API = {
    enabled = true,
    apiKey  = '你的API密钥',
}
```

**接口地址：** `http://服务器IP:30120/tayer-uptime/api/`

| 接口 | 说明 |
|---|---|
| `GET /api/leaderboard` | 排行榜（支持 `/api/leaderboard/20` 指定数量） |
| `GET /api/player/:identifier` | 玩家详情（时长、连续登录等） |
| `GET /api/stats` | 服务器统计 |
| `GET /api/online` | 当前在线玩家 |

认证方式：在请求头中添加 `Authorization: Bearer 你的API密钥`

---

## 命令

### 玩家命令

| 命令 | 说明 |
|---|---|
| `/onlinetime` | 查看总在线时长 |
| `/toptime` | 查看排行榜 |
| `/dailytime` | 查看今日在线时长 |
| `/weeklytime` | 查看本周在线时长 |
| `/monthlytime` | 查看本月在线时长 |
| `/rewards` | 查看里程碑奖励进度 |
| `/loginreward` | 查看每日登录状态 |
| `/uptime` | 打开 NUI 统计面板 |

### 管理员命令

| 命令 | 说明 |
|---|---|
| `/admintime [ID]` | 查看指定玩家时长 |
| `/resettime [ID]` | 重置指定玩家时长（有审计） |
| `/settime [ID] [分钟]` | 设置指定玩家时长（有审计） |
| `/addtime [ID] [分钟]` | 增加指定玩家时长（有审计） |
| `/serverstats` | 查看服务器总体统计 |
| `/importtxadmin [路径]` | 从 txAdmin 导入时长数据 |

---

## Exports API

```lua
-- 获取总在线时长（分钟）
local minutes = exports['tayer-uptime']:GetPlaytime(source)

-- 检查 AFK 状态
local isAFK = exports['tayer-uptime']:IsPlayerAFK(source)

-- 检查是否达到指定时长
local has100h = exports['tayer-uptime']:HasPlaytimeHours(source, 100)

-- 获取前 N 名
local top10 = exports['tayer-uptime']:GetTopPlayers(10)

-- 获取每日/每周时长（分钟）
local daily = exports['tayer-uptime']:GetDailyPlaytime(source)
local weekly = exports['tayer-uptime']:GetWeeklyPlaytime(source)

-- 获取登录连续信息
local info = exports['tayer-uptime']:GetLoginStreak(source)
-- 返回: { streak = 5, maxStreak = 12 }
```

### 使用示例：根据时长限制访问

```lua
-- 在其他资源的 server.lua 中
RegisterCommand('vip', function(source)
    local has50h = exports['tayer-uptime']:HasPlaytimeHours(source, 50)
    if has50h then
        TriggerClientEvent('myresource:openVIP', source)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'SYSTEM', '需要 50 小时在线时长才能进入 VIP 区域' }
        })
    end
end, false)
```

---

## 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
