# Tayer Uptime

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/uucz/tayer-uptime/blob/main/LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-ESX-orange.svg)](https://fivem.net)
[![GitHub Stars](https://img.shields.io/github/stars/uucz/tayer-uptime?style=social)](https://github.com/uucz/tayer-uptime)

A lightweight **FiveM ESX** resource that automatically tracks player online time, provides leaderboard rankings, admin management tools, and optional Discord webhook notifications.

> **中文文档见下方** / Chinese documentation below

---

## ✨ Features

- ⏱️ **Automatic Time Tracking** — Records each player's online time every minute
- 🏆 **Leaderboard** — View top players ranked by online time
- 🔧 **Admin Commands** — Check or reset any player's online time
- 🌐 **Multi-Language** — Built-in Chinese (zh-CN) and English (en) support
- 📢 **Discord Webhooks** — Optional connect/disconnect notifications with session details
- ⚙️ **Fully Configurable** — Customize commands, intervals, language, and more via `config.lua`
- 💾 **Oxmysql Storage** — Reliable database-backed persistence

## 📋 Requirements

| Dependency | Link |
|---|---|
| ESX Framework | [es_extended](https://github.com/esx-framework/esx-legacy) |
| Oxmysql | [oxmysql](https://github.com/overextended/oxmysql) |

## 🚀 Installation

1. Download or clone the repository:
   ```bash
   git clone https://github.com/uucz/tayer-uptime.git
   ```
2. Place the `tayer-uptime` folder into your server's `resources/` directory.
3. Add the following to your `server.cfg`:
   ```
   ensure tayer-uptime
   ```
4. The database table will be created automatically on first start.

## ⚙️ Configuration

Edit [`config.lua`](config.lua) to customize the resource:

```lua
Config.Locale         = 'zh-CN'  -- Language: 'zh-CN' or 'en'
Config.UpdateInterval = 60000    -- Tracking interval (ms)

Config.Commands = {
    onlinetime = 'onlinetime',   -- Check own time
    toptime    = 'toptime',      -- Leaderboard
    admintime  = 'admintime',    -- Admin: check player time
    resettime  = 'resettime',    -- Admin: reset player time
}

Config.Discord = {
    enabled    = false,
    webhookUrl = '',              -- Your Discord webhook URL
    botName    = 'Tayer Uptime',
}
```

## 🎮 Commands

| Command | Description | Permission |
|---|---|---|
| `/onlinetime` | Check your own online time | Everyone |
| `/toptime` | View online time leaderboard | Everyone |
| `/admintime [id]` | Check a specific player's online time | Admin |
| `/resettime [id]` | Reset a player's online time | Admin |

## 📁 Project Structure

```
tayer-uptime/
├── config.lua              # Configuration file
├── client.lua              # Client-side commands
├── server.lua              # Server-side logic & callbacks
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

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

# Tayer Uptime（中文）

一个轻量级的 **FiveM ESX** 资源，用于自动追踪玩家在线时长，提供排行榜、管理员工具和可选的 Discord Webhook 通知。

## ✨ 功能特点

- ⏱️ **自动时长追踪** — 每分钟自动记录每位玩家的在线时间
- 🏆 **排行榜** — 查看在线时长排行榜
- 🔧 **管理员命令** — 查看或重置任意玩家的在线时长
- 🌐 **多语言支持** — 内置中文（zh-CN）和英文（en）
- 📢 **Discord Webhook** — 可选的玩家上线/下线通知，附带本次在线时长
- ⚙️ **完全可配置** — 通过 `config.lua` 自定义命令、间隔、语言等
- 💾 **Oxmysql 存储** — 可靠的数据库持久化存储

## 📋 依赖

- [ESX Framework](https://github.com/esx-framework/esx-legacy)
- [Oxmysql](https://github.com/overextended/oxmysql)

## 🚀 安装

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

## 🎮 命令

| 命令 | 说明 | 权限 |
|---|---|---|
| `/onlinetime` | 查看自己的在线时长 | 所有玩家 |
| `/toptime` | 查看在线时长排行榜 | 所有玩家 |
| `/admintime [ID]` | 查看指定玩家的在线时长 | 管理员 |
| `/resettime [ID]` | 重置指定玩家的在线时长 | 管理员 |

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
