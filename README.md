# Tayer Uptime

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/uucz/tayer-uptime/blob/main/LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-ESX-orange.svg)](https://fivem.net)
[![GitHub Stars](https://img.shields.io/github/stars/uucz/tayer-uptime?style=social)](https://github.com/uucz/tayer-uptime)

A feature-rich **FiveM ESX** resource that automatically tracks player online time with AFK detection, milestone rewards, daily/weekly stats, leaderboard rankings, admin tools, and Discord webhook notifications.

> **中文文档见下方** / Chinese documentation below

---

## Features

- **Automatic Time Tracking** — Records each player's online time every minute
- **AFK Detection** — Distance-based detection pauses tracking for idle players
- **Milestone Rewards** — Configurable playtime milestones with automatic money rewards
- **Daily/Weekly Stats** — Track and view daily and weekly online time breakdowns
- **Leaderboard** — View top players ranked by online time
- **Admin Commands** — Check or reset any player's online time
- **Multi-Language** — Built-in Chinese (zh-CN) and English (en) support
- **Discord Webhooks** — Connect/disconnect notifications, milestone achievements
- **Exports API** — Other resources can query playtime data
- **Fully Configurable** — Customize commands, intervals, AFK settings, rewards, and more via `config.lua`
- **Oxmysql Storage** — Reliable database-backed persistence
- **Crash-Safe** — Saves unsaved time on player disconnect; handles resource restarts

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
4. The database tables will be created automatically on first start.

## Configuration

Edit [`config.lua`](config.lua) to customize the resource:

```lua
Config.Locale         = 'zh-CN'  -- Language: 'zh-CN' or 'en'
Config.UpdateInterval = 60000    -- Tracking interval (ms)

Config.Commands = {
    onlinetime = 'onlinetime',   -- Check own time
    toptime    = 'toptime',      -- Leaderboard
    admintime  = 'admintime',    -- Admin: check player time
    resettime  = 'resettime',    -- Admin: reset player time
    dailytime  = 'dailytime',    -- Check today's time
    weeklytime = 'weeklytime',   -- Check this week's time
    rewards    = 'rewards',      -- View milestone rewards
}

-- AFK Detection
Config.AFK = {
    enabled       = true,
    timeout       = 300,    -- 5 minutes before AFK
    checkInterval = 10000,  -- Client check every 10s
    minDistance    = 5.0,    -- Minimum movement (meters)
}

-- Milestone Rewards
Config.Rewards = {
    enabled = true,
    milestones = {
        { hours = 1,   money = 5000,   label = '1h'   },
        { hours = 5,   money = 15000,  label = '5h'   },
        { hours = 10,  money = 30000,  label = '10h'  },
        { hours = 24,  money = 50000,  label = '24h'  },
        { hours = 48,  money = 80000,  label = '48h'  },
        { hours = 100, money = 150000, label = '100h' },
        { hours = 200, money = 300000, label = '200h' },
        { hours = 500, money = 500000, label = '500h' },
    },
}

Config.Discord = {
    enabled    = false,
    webhookUrl = '',
    botName    = 'Tayer Uptime',
}
```

## Commands

| Command | Description | Permission |
|---|---|---|
| `/onlinetime` | Check your total online time | Everyone |
| `/toptime` | View online time leaderboard | Everyone |
| `/dailytime` | Check today's online time | Everyone |
| `/weeklytime` | Check this week's online time | Everyone |
| `/rewards` | View milestone rewards progress | Everyone |
| `/admintime [id]` | Check a specific player's online time | Admin |
| `/resettime [id]` | Reset a player's online time | Admin |

## Exports API

Other resources can use these exports to query playtime data:

```lua
-- Get a player's total online time (in minutes)
local minutes = exports['tayer-uptime']:GetPlaytime(source)

-- Check if a player is currently AFK
local afk = exports['tayer-uptime']:IsPlayerAFK(source)

-- Get top N players by online time
local topPlayers = exports['tayer-uptime']:GetTopPlayers(10)
-- Returns: { { name = "Player1", online_time = 1234 }, ... }
```

## Project Structure

```
tayer-uptime/
├── config.lua              # Configuration file
├── client.lua              # Client-side commands & AFK detection
├── server.lua              # Server-side logic, callbacks & exports
├── fxmanifest.lua          # Resource manifest
├── shared/
│   └── locale.lua          # Locale loading system
├── locales/
│   ├── zh-CN.lua           # Chinese translations
│   └── en.lua              # English translations
├── server/
│   └── discord.lua         # Discord webhook module
├── CHANGELOG.md            # Version history
├── CONTRIBUTING.md         # Contribution guide
└── LICENSE                 # MIT License
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).

---

# Tayer Uptime（中文）

一个功能丰富的 **FiveM ESX** 资源，用于自动追踪玩家在线时长，具备 AFK 检测、里程碑奖励、每日/每周统计、排行榜、管理员工具和 Discord Webhook 通知。

## 功能特点

- **自动时长追踪** — 每分钟自动记录每位玩家的在线时间
- **AFK 检测** — 基于距离的检测，暂停挂机玩家的时长追踪
- **里程碑奖励** — 可配置的在线时长里程碑，自动发放金钱奖励
- **每日/每周统计** — 查看每日和每周在线时长
- **排行榜** — 查看在线时长排行榜
- **管理员命令** — 查看或重置任意玩家的在线时长
- **多语言支持** — 内置中文（zh-CN）和英文（en）
- **Discord Webhook** — 上线/下线通知、里程碑达成通知
- **Exports API** — 其他脚本可查询在线时长数据
- **完全可配置** — 通过 `config.lua` 自定义命令、间隔、AFK 设置、奖励等
- **Oxmysql 存储** — 可靠的数据库持久化存储
- **防崩溃** — 玩家断开时保存未记录的时间，支持资源重启

## 依赖

- [ESX Framework](https://github.com/esx-framework/esx-legacy)
- [Oxmysql](https://github.com/overextended/oxmysql)

## 安装

1. 克隆仓库：
   ```bash
   git clone https://github.com/uucz/tayer-uptime.git
   ```
2. 将 `tayer-uptime` 文件夹放入服务器的 `resources/` 目录。
3. 在 `server.cfg` 中添加：
   ```
   ensure tayer-uptime
   ```
4. 数据库表会在首次启动时自动创建。

## 命令

| 命令 | 说明 | 权限 |
|---|---|---|
| `/onlinetime` | 查看自己的总在线时长 | 所有玩家 |
| `/toptime` | 查看在线时长排行榜 | 所有玩家 |
| `/dailytime` | 查看今日在线时长 | 所有玩家 |
| `/weeklytime` | 查看本周在线时长 | 所有玩家 |
| `/rewards` | 查看里程碑奖励进度 | 所有玩家 |
| `/admintime [ID]` | 查看指定玩家的在线时长 | 管理员 |
| `/resettime [ID]` | 重置指定玩家的在线时长 | 管理员 |

## Exports API

其他脚本可使用以下接口查询数据：

```lua
-- 获取玩家总在线时长（分钟）
local minutes = exports['tayer-uptime']:GetPlaytime(source)

-- 检查玩家是否处于 AFK 状态
local afk = exports['tayer-uptime']:IsPlayerAFK(source)

-- 获取在线时长前 N 名玩家
local topPlayers = exports['tayer-uptime']:GetTopPlayers(10)
```

## 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
