# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.0] - 2026-03-13

### Added
- **HTTP REST API** — JSON endpoints at `/api/leaderboard`, `/api/player/:identifier`, `/api/stats`, `/api/online` with Bearer token authentication for external tools, web dashboards, and Discord bots
- **Discord Role Sync** — Auto-assign Discord roles based on playtime thresholds using Discord Bot API. Configurable role-to-hours mapping via `Config.DiscordRoles`
- **Activity Heatmap** — New NUI tab showing GitHub-style 7x24 grid (day-of-week x hour) visualizing play patterns. Data stored in `users_activity_hourly` table
- **Activity Data Collection** — Tracking loop now records hourly activity buckets for heatmap visualization
- **API Configuration** — `Config.API` settings (enabled, apiKey) for HTTP endpoint control
- **Discord Roles Configuration** — `Config.DiscordRoles` settings (botToken, guildId, roles array)

### Changed
- Dashboard callback now includes heatmap data
- Tracking loop records activity hourly data alongside daily/monthly stats
- Milestone/role checks now also trigger Discord role sync
- `server/api.lua` added to server_scripts in fxmanifest

## [2.3.0] - 2026-03-13

### Added
- **Multi-Framework Support** — Auto-detects ESX, QBCore, QBOX, or Standalone mode via `shared/bridge.lua`. No longer locked to ESX.
- **Framework Bridge System** — All player operations (identifier, money, items, groups, notifications, callbacks) go through `Bridge.*` functions
- **Rich Reward Types** — Milestones now support `type = 'money'|'item'|'vehicle'` with item name/count and custom callback support
- **ox_lib Integration** (optional) — When ox_lib is present, uses `lib.notify()` for notifications and `lib.callback` for server callbacks. Falls back gracefully.
- **txAdmin Data Import** — `/importtxadmin [path]` admin command to import historical playtime from txAdmin's `playersDB.json`
- **Standalone Mode** — Works with just oxmysql, using license identifier and FiveM ace permissions for admin checks
- **QBCore/QBOX Support** — Full compatibility including `citizenid` identifiers, `charinfo` names, QB money system, and QB callbacks

### Changed
- `es_extended` is no longer a hard dependency — only `oxmysql` is required
- All `ESX.*` calls replaced with `Bridge.*` equivalents throughout server.lua and client.lua
- `fxmanifest.lua` dependencies simplified to just `oxmysql`
- Description updated to "Multi-Framework Online Time Tracker"
- Milestone rewards now support mixed types (money + item in same milestone)

### Removed
- Direct ESX dependency in `fxmanifest.lua` (auto-detected at runtime instead)

## [2.2.0] - 2026-03-13

### Added
- **NUI Dashboard** — Full in-game HTML/CSS/JS panel with `/uptime` command, featuring 4 tabs: Overview, Leaderboard, Milestones, and Login Streak
- **Dark Glassmorphism UI** — Modern translucent panel design with backdrop blur, smooth animations, and responsive layout
- **Admin `/settime` Command** — Set a player's online time to a specific value with audit logging
- **Admin `/addtime` Command** — Add minutes to a player's online time with audit logging
- **Admin `/serverstats` Command** — View server-wide statistics (online count, daily/weekly active, total players, total playtime)
- **First-Join Welcome System** — Configurable welcome bonus money for new players with Discord notification
- **Discord Daily Report** — Automated daily server stats report (active players, total playtime, new players, top 5) at configurable time
- **Real-Time AFK Status** — Dashboard shows live AFK status, synced from server-side detection

### Changed
- Added `Config.Commands.uptime` for NUI dashboard command
- Added `Config.FirstJoin` settings (enabled, bonusMoney)
- Added `Config.Discord.dailyReport` and `Config.Discord.reportTime` settings
- Updated all 6 locale files with new keys for admin commands, server stats, first join, and Discord reports
- ProcessFirstJoin now wired into `esx:playerLoaded` handler

## [2.1.0] - 2026-03-13

### Added
- **Server-Side AFK Detection** — Moved AFK detection entirely to server using `GetEntityCoords(GetPlayerPed())`, eliminating client-side exploitation
- **AFK Kick** — Implemented `Config.AFK.kickEnabled` with configurable timeout and Discord notification
- **Daily Login Rewards** — 7-day reward cycle with configurable streak tracking, grace period, and auto-claim on connect
- **Playtime-Gated Roles** — Auto-assign ESX groups when players reach configured playtime thresholds (won't demote admins)
- **Monthly Statistics** — New `/monthlytime` command and `users_online_monthly` database table
- **Session History** — Full session recording in `users_sessions` table with connect/disconnect times and reasons
- **Admin Audit Logging** — All admin actions logged to `uptime_audit_log` table and Discord webhook
- **Data Maintenance** — Configurable auto-cleanup of old daily records for inactive players
- **4 New Locales** — Spanish (es), French (fr), German (de), Portuguese-Brazil (pt-BR)
- **4 New Exports** — `HasPlaytimeHours()`, `GetDailyPlaytime()`, `GetWeeklyPlaytime()`, `GetLoginStreak()`
- **5 New Discord Notifications** — Login rewards, role promotions, AFK kicks, admin audits
- **New Commands** — `/monthlytime`, `/loginreward`

### Changed
- AFK detection is now fully server-authoritative (removed exploitable client event `tayer-uptime:setAFKStatus`)
- Client only receives display-only AFK status via `tayer-uptime:afkStatus` event
- Milestone and role checks now run every 5 minutes instead of every minute to reduce DB load
- Login rewards process on `esx:playerLoaded` instead of `playerConnecting` for reliability

### Security
- Eliminated client-to-server AFK trust vulnerability
- Added rate-limiting protection on server-side AFK state changes
- Added admin audit trail for all administrative actions
- All sensitive operations (rewards, roles, time tracking) are server-side only

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
