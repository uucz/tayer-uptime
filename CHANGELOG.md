# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-12

### Added
- **AFK Detection** — Client-side distance-based detection pauses time tracking for idle players
- **Milestone Rewards** — Configurable playtime milestones with automatic money rewards and Discord notifications
- **Daily/Weekly Stats** — New `/dailytime` and `/weeklytime` commands with per-day database tracking
- **Rewards Command** (`/rewards`) — View milestone progress, claimed/available/locked status
- **Exports API** — `GetPlaytime(source)`, `IsPlayerAFK(source)`, `GetTopPlayers(limit)` for other resources
- **Crash-Safe Tracking** — Saves unsaved time on disconnect; initializes sessions on resource restart
- **Discord Milestone Notifications** — Gold embed when players reach playtime milestones

### Fixed
- **Race Condition** — Replaced UPDATE+INSERT with atomic UPSERT to prevent duplicate key errors
- **Time Loss on Disconnect** — Track last update time per player, save remaining minutes on disconnect
- **Discord Error Handling** — Log HTTP errors instead of silently ignoring webhook failures
- **Reset Command False Failure** — Removed incorrect `rowsChanged` check that reported failure when time was already 0
- **Resource Restart Handling** — Initialize PlayerSessions for already-connected players via `onResourceStart`

### Changed
- Bumped version to 2.0.0
- Added new database tables: `users_online_daily`, `users_online_rewards`
- Expanded config.lua with AFK, Rewards, and new command settings
- Updated all locale files with new strings for AFK, rewards, daily/weekly features
- Updated README with comprehensive documentation for all new features

## [1.1.0] - 2026-02-28

### Added
- **Configuration System** — Centralized `config.lua` for all settings
- **Multi-Language Support** — Built-in Chinese (zh-CN) and English (en) locales
- **Leaderboard Command** (`/toptime`) — View top players by online time
- **Admin Commands** — `/admintime [id]` to check and `/resettime [id]` to reset player time
- **Discord Webhook Integration** — Optional connect/disconnect notifications with session details
- **Time Formatting** — Display as hours & minutes instead of raw minutes
- **Session Tracking** — Track per-session online duration
- **Player Name Storage** — Store player names in database for leaderboard display
- **Project Documentation** — CHANGELOG.md, CONTRIBUTING.md, GitHub issue/PR templates
- **Author Field** — Added author info to fxmanifest.lua

### Changed
- Refactored `server.lua` to use config-driven settings and locale strings
- Refactored `client.lua` to use dynamic command registration and locale support
- Updated `fxmanifest.lua` with new file references and metadata
- Rewrote `README.md` with proper Markdown formatting and bilingual content
- Database table now includes `name` and `last_seen` columns

## [1.0.0] - 2026-02-24

### Added
- Initial release
- Automatic per-minute online time tracking
- `/onlinetime` command for players to check their online duration
- Oxmysql database storage
- Auto-creation of database table on first run
