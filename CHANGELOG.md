# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
