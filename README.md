# Tayer Uptime

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/uucz/tayer-uptime/blob/main/LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-ESX-orange.svg)](https://fivem.net)
[![GitHub Stars](https://img.shields.io/github/stars/uucz/tayer-uptime?style=social)](https://github.com/uucz/tayer-uptime)

A feature-rich **FiveM ESX** resource for player online time tracking with server-side AFK detection, milestone rewards, daily login streaks, playtime-gated roles, session history, admin audit logging, and Discord webhook notifications.

> **中文文档见下方** / Chinese documentation below

---

## Features

- **Automatic Time Tracking** — Records each player's online time every minute
- **NUI Dashboard** — Beautiful in-game panel (`/uptime`) with Overview, Leaderboard, Milestones, and Login Streak tabs
- **Server-Side AFK Detection** — Fully server-authoritative position tracking, no client trust
- **AFK Kick** — Optional auto-kick after extended AFK period
- **Milestone Rewards** — Configurable playtime milestones with automatic money rewards
- **Daily Login Rewards** — Streak-based login rewards with grace period and 7-day cycles
- **First-Join Welcome** — Configurable welcome bonus for new players
- **Playtime-Gated Roles** — Auto-assign ESX groups based on total playtime
- **Daily/Weekly/Monthly Stats** — Track and view time breakdowns by period
- **Session History** — Full session recording with connect/disconnect times and reasons
- **Leaderboard** — View top players ranked by online time
- **Admin Commands** — Check, reset, set, or add time for any player with audit logging
- **Multi-Language** — Built-in support for zh-CN, en, es, fr, de, pt-BR
- **Discord Webhooks** — Notifications for connect, disconnect, milestones, login rewards, role promotions, AFK kicks, admin actions, first-join, daily reports
- **Discord Daily Report** — Automated daily server stats summary at configurable time
- **Exports API** — 7 exports for other resources to query playtime data
- **Data Maintenance** — Auto-cleanup of old daily records
- **Crash-Safe** — Saves unsaved time on disconnect; handles resource restarts

## Requirements

| Dependency | Link |
|---|---|
| ESX Framework | [es_extended](https://github.com/esx-framework/esx-legacy) |
| Oxmysql | [oxmysql](https://github.com/overextended/oxmysql) |

## Installation

1. Download or clone the repository:
   ```bash
   git clone https://github.com/uucz/tayer-uptime.git
   ```
2. Place the `tayer-uptime` folder into your server's `resources/` directory.
3. Add the following to your `server.cfg`:
   ```
   ensure tayer-uptime
   ```
4. All database tables are created automatically on first start.

## Configuration

Edit [`config.lua`](config.lua) to customize:

```lua
Config.Locale         = 'zh-CN'  -- 'zh-CN', 'en', 'es', 'fr', 'de', 'pt-BR'
Config.UpdateInterval = 60000    -- Tracking interval (ms)

-- AFK Detection (fully server-side)
Config.AFK = {
    enabled       = true,
    timeout       = 300,    -- 5 minutes before AFK
    checkInterval = 15,     -- Server check every 15s
    minDistance    = 5.0,    -- Minimum movement (meters)
    kickEnabled   = false,  -- Optional AFK kick
    kickTimeout   = 1800,   -- 30 minutes before kick
}

-- Daily Login Rewards
Config.DailyLogin = {
    enabled     = true,
    gracePeriod = 1,  -- Days allowed to miss before streak resets
    rewards = {
        { day = 1, money = 1000  },
        { day = 2, money = 2000  },
        -- ... up to day 7 (cycles)
        { day = 7, money = 10000 },
    },
}

-- Playtime-Gated Roles
Config.PlaytimeRoles = {
    enabled = true,
    roles = {
        { hours = 10,  group = 'regular',  label = 'Regular' },
        { hours = 50,  group = 'veteran',  label = 'Veteran' },
        { hours = 100, group = 'trusted',  label = 'Trusted' },
    },
}

-- Data Maintenance
Config.Maintenance = {
    cleanupEnabled = false,
    inactiveDays   = 90,
    cleanupTime    = '04:00',
}
```

## Commands

| Command | Description | Permission |
|---|---|---|
| `/onlinetime` | Check your total online time | Everyone |
| `/toptime` | View online time leaderboard | Everyone |
| `/dailytime` | Check today's online time | Everyone |
| `/weeklytime` | Check this week's online time | Everyone |
| `/monthlytime` | Check this month's online time | Everyone |
| `/rewards` | View milestone rewards progress | Everyone |
| `/loginreward` | View daily login reward status | Everyone |
| `/uptime` | Open NUI dashboard panel | Everyone |
| `/admintime [id]` | Check a specific player's online time | Admin |
| `/resettime [id]` | Reset a player's online time (audited) | Admin |
| `/settime [id] [min]` | Set a player's online time (audited) | Admin |
| `/addtime [id] [min]` | Add time to a player (audited) | Admin |
| `/serverstats` | View server-wide statistics | Admin |

## Exports API

```lua
-- Get total online time (minutes)
local minutes = exports['tayer-uptime']:GetPlaytime(source)

-- Check if player is AFK
local afk = exports['tayer-uptime']:IsPlayerAFK(source)

-- Check if player has minimum hours
local has100h = exports['tayer-uptime']:HasPlaytimeHours(source, 100)

-- Get top N players
local top = exports['tayer-uptime']:GetTopPlayers(10)

-- Get daily/weekly playtime (minutes)
local daily = exports['tayer-uptime']:GetDailyPlaytime(source)
local weekly = exports['tayer-uptime']:GetWeeklyPlaytime(source)

-- Get login streak info
local info = exports['tayer-uptime']:GetLoginStreak(source)
-- Returns: { streak = 5, maxStreak = 12 }
```

## Database Tables

| Table | Purpose |
|---|---|
| `users_online_time` | Total cumulative online time per player |
| `users_online_daily` | Daily online time breakdown |
| `users_online_monthly` | Monthly online time breakdown |
| `users_online_rewards` | Claimed milestone rewards |
| `users_login_streaks` | Daily login streaks and history |
| `users_sessions` | Session history (connect/disconnect times) |
| `users_playtime_roles` | Granted playtime-based roles |
| `uptime_audit_log` | Admin action audit trail |

## Security

- **Server-authoritative AFK detection** — Uses `GetEntityCoords(GetPlayerPed())` server-side; no client events to exploit
- **Parameterized SQL queries** — All database operations use `@parameters` to prevent injection
- **Admin audit logging** — All admin actions are logged to database and Discord
- **No client-to-server trust** — All rewards, role changes, and time tracking are server-side only

## Project Structure

```
tayer-uptime/
├── config.lua              # Configuration
├── client.lua              # Client-side commands, AFK display, NUI control
├── server.lua              # Server-side logic, AFK detection, rewards, roles
├── fxmanifest.lua          # Resource manifest
├── shared/
│   └── locale.lua          # Locale system
├── locales/
│   ├── zh-CN.lua           # Chinese
│   ├── en.lua              # English
│   ├── es.lua              # Spanish
│   ├── fr.lua              # French
│   ├── de.lua              # German
│   └── pt-BR.lua           # Portuguese (Brazil)
├── server/
│   └── discord.lua         # Discord webhook module
├── ui/
│   ├── index.html          # NUI dashboard HTML
│   ├── style.css           # NUI dashboard styles
│   └── script.js           # NUI dashboard logic
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).

---

# Tayer Uptime（中文）

一个功能丰富的 **FiveM ESX** 资源，具备服务端 AFK 检测、里程碑奖励、每日登录奖励、时长门控角色、会话历史、管理员审计日志和 Discord Webhook 通知。

## 功能特点

- **自动时长追踪** — 每分钟自动记录在线时间
- **NUI 面板** — 精美游戏内面板 (`/uptime`)，含概览、排行榜、里程碑、登录连续四个标签页
- **服务端 AFK 检测** — 完全服务端权威位置追踪，无客户端信任
- **AFK 踢出** — 可选长时间 AFK 自动踢出
- **里程碑奖励** — 可配置时长里程碑自动发放金钱
- **每日登录奖励** — 连续登录奖励，支持宽限期和 7 天循环
- **新玩家欢迎** — 可配置首次加入奖励金
- **时长门控角色** — 根据总时长自动分配 ESX 权限组
- **每日/每周/每月统计** — 分时段查看在线时长
- **会话历史** — 完整记录每次连接/断开时间和原因
- **排行榜** — 在线时长排名
- **管理员命令** — 查看/重置/设置/增加时长，带审计日志
- **多语言** — 支持 zh-CN、en、es、fr、de、pt-BR
- **Discord Webhook** — 上线、下线、里程碑、登录奖励、角色晋升、AFK 踢出、管理操作、新玩家、每日报告通知
- **Discord 每日报告** — 可配置时间自动发送服务器每日统计摘要
- **Exports API** — 7 个接口供其他脚本查询
- **数据维护** — 自动清理过期每日记录
- **防崩溃** — 断线时保存未记录时间，支持资源重启

## 命令

| 命令 | 说明 | 权限 |
|---|---|---|
| `/onlinetime` | 查看总在线时长 | 所有玩家 |
| `/toptime` | 查看排行榜 | 所有玩家 |
| `/dailytime` | 查看今日在线时长 | 所有玩家 |
| `/weeklytime` | 查看本周在线时长 | 所有玩家 |
| `/monthlytime` | 查看本月在线时长 | 所有玩家 |
| `/rewards` | 查看里程碑奖励进度 | 所有玩家 |
| `/loginreward` | 查看每日登录状态 | 所有玩家 |
| `/uptime` | 打开 NUI 统计面板 | 所有玩家 |
| `/admintime [ID]` | 查看指定玩家时长 | 管理员 |
| `/resettime [ID]` | 重置指定玩家时长 (有审计) | 管理员 |
| `/settime [ID] [分钟]` | 设置指定玩家时长 (有审计) | 管理员 |
| `/addtime [ID] [分钟]` | 增加指定玩家时长 (有审计) | 管理员 |
| `/serverstats` | 查看服务器总体统计 | 管理员 |

## Exports API

```lua
-- 获取总在线时长（分钟）
local minutes = exports['tayer-uptime']:GetPlaytime(source)

-- 检查 AFK 状态
local afk = exports['tayer-uptime']:IsPlayerAFK(source)

-- 检查是否达到指定时长
local has100h = exports['tayer-uptime']:HasPlaytimeHours(source, 100)

-- 获取前 N 名
local top = exports['tayer-uptime']:GetTopPlayers(10)

-- 获取每日/每周时长
local daily = exports['tayer-uptime']:GetDailyPlaytime(source)
local weekly = exports['tayer-uptime']:GetWeeklyPlaytime(source)

-- 获取登录连续信息
local info = exports['tayer-uptime']:GetLoginStreak(source)
```

## 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
