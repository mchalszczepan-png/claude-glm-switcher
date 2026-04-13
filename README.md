# claude-glm-switcher

> Switch between [Z.ai GLM](https://z.ai) models and Anthropic Claude models in Claude Code — with a single command or desktop click.

Built for developers using the [GLM Coding Plan](https://z.ai/subscribe) as a cost-effective alternative to Claude Max, this tool lets you instantly toggle between GLM-5.1 (via Z.ai) and Claude (via Anthropic) across:

- **Claude Code CLI**
- **Cursor IDE** (Claude Code extension)
- **Antigravity IDE** (Claude Code extension)

Works on **Linux** and **Windows 11**.

---

## Why this exists

The [GLM Coding Plan](https://z.ai/subscribe) gives you access to GLM-5.1 — which scores 94.6% of Claude Opus on coding benchmarks — starting from $3/month. Z.ai's API is Anthropic-compatible, so Claude Code routes through it seamlessly.

The catch: switching between GLM and Claude normally means manually editing config files. This tool makes it a single command or desktop double-click, and handles key rotation too.

---

## What gets switched

| File | GLM mode | Claude mode |
|------|----------|-------------|
| `~/.claude/settings.json` | Z.ai endpoint + GLM models | Your original Anthropic settings |
| `~/.config/Cursor/User/settings.json` | GLM env vars injected | Original restored |
| `~/.config/Antigravity/User/settings.json` | GLM env vars injected | Original restored |
| Windows equivalents | Same | Same |

MCPs, permissions, custom commands — all untouched. Only the API routing changes.

---

## Setup

### Linux

1. Copy the contents of `linux/bashrc_additions.sh` into the bottom of your `~/.bashrc`
2. Run `source ~/.bashrc`
3. Copy `templates/glm.settings.template.json` to:
   - `~/.claude/glm.settings.json`
   - `~/.config/Cursor/User/glm.settings.json`
   - `~/.config/Antigravity/User/glm.settings.json`
4. Copy `templates/claude.settings.template.json` to:
   - `~/.claude/claude.settings.json` (or `settings.bak.json` if you prefer)
   - `~/.config/Cursor/User/claude.settings.json`
   - `~/.config/Antigravity/User/claude.settings.json`
5. Run `update-glm-key` and paste your Z.ai API key

### Windows

1. Run `windows/Setup-ClaudeSwitcher.ps1` once (right-click → Run with PowerShell)
2. Double-click `Update Z.ai API Key.bat` on your Desktop and paste your Z.ai API key
3. Done — two more icons on your Desktop let you switch modes

---

## Commands (Linux)

| Command | What it does |
|---------|-------------|
| `claude-glm-mode` | Switch all apps to GLM via Z.ai |
| `claude-claude-mode` | Switch all apps back to Claude |
| `update-glm-key` | Rotate your Z.ai API key across all files |
| `my-commands` | List all your custom aliases and functions |

## Desktop shortcuts (Windows)

| Shortcut | What it does |
|----------|-------------|
| `Switch to GLM Mode.bat` | Switch all apps to GLM via Z.ai |
| `Switch to Claude Mode.bat` | Switch all apps back to Claude |
| `Update Z.ai API Key.bat` | Rotate your Z.ai API key across all files |

---

## Models used in GLM mode

| Claude Code slot | GLM model |
|-----------------|-----------|
| Opus | GLM-5.1 |
| Sonnet | GLM-5 |
| Haiku | GLM-4.7 |

---

## Rotating your API key

If your Z.ai key is exposed or recycled:

**Linux:** run `update-glm-key` in any terminal  
**Windows:** double-click `Update Z.ai API Key.bat` on your Desktop

Both update every relevant file in one shot — templates and active settings.

---

## Adding more IDEs

To add Roo Code, Cline, or any other tool:

**Linux:** add the relevant settings file paths to the `FILES` array in `update-glm-key` and to the `claude-glm-mode` / `claude-claude-mode` aliases in your `.bashrc`.

**Windows:** add the paths to the `$allFiles` array in `~/.claude-switcher/update-key.ps1` and the copy commands in `switch-glm.ps1` / `switch-claude.ps1`.

---

## Security

- **Never commit your filled-in settings files.** The `.gitignore` in this repo excludes `settings.json`, `glm.settings.json`, `claude.settings.json`, and `settings.bak.json`.
- Template files use `YOUR_ZAI_API_KEY_HERE` as a placeholder — safe to commit.
- If you accidentally expose a key, run `update-glm-key` / `Update Z.ai API Key.bat` after regenerating it on [z.ai](https://z.ai).
- See [SECURITY.md](SECURITY.md) for responsible disclosure.

---

## Z.ai quota tips

- Peak hours (14:00–18:00 UTC+8) cost **3×** quota
- Off-peak costs **2×** (promotional **1×** through April 2026)
- Schedule heavy agentic sessions outside peak hours
- Run `/compact` every 10–15 turns — context pollution is faster with non-Claude models

---

## Requirements

**Linux**
- Claude Code CLI
- Cursor and/or Antigravity IDE with Claude Code extension
- bash

**Windows**
- Windows 11
- Claude Code CLI
- Antigravity IDE with Claude Code extension
- PowerShell 5.1+ (built in)

---

## License

MIT — do whatever you want with it.

---

## Contributing

PRs welcome, especially for:
- Additional IDE support (Roo Code, Cline, VS Code, Windsurf)
- Additional OS support (macOS)
- Shell support beyond bash (zsh, fish)
