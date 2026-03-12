# Contributing to Tayer Uptime

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/uucz/tayer-uptime/issues) to avoid duplicates.
2. Use the **Bug Report** issue template.
3. Include detailed steps to reproduce the issue.
4. Mention your ESX version, Oxmysql version, and server artifacts version.

### Suggesting Features

1. Use the **Feature Request** issue template.
2. Clearly describe the feature and its use case.
3. Explain why this would benefit other users.

### Submitting Code

1. **Fork** the repository.
2. Create a **feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes and **test** them on a FiveM server.
4. **Commit** with clear, descriptive messages:
   ```bash
   git commit -m "feat: add daily online time report"
   ```
5. **Push** and open a **Pull Request** against `main`.

## Code Style

- Use 4-space indentation in Lua files.
- Add comments for complex logic.
- Use the locale system (`_L()`) for all user-facing strings.
- Add new configuration options to `config.lua` with sensible defaults.
- Keep functions focused and reasonably sized.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Usage |
|---|---|
| `feat:` | New features |
| `fix:` | Bug fixes |
| `docs:` | Documentation changes |
| `refactor:` | Code improvements |
| `chore:` | Maintenance tasks |

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
