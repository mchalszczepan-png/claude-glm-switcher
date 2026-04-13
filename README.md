# claude-glm-switcher

> Switch between AI provider backends in Claude Code — with a single command or desktop click.

Built for developers who want to use cost-effective or diverse AI models in Claude Code, this tool lets you instantly toggle between providers across:

- **Claude Code CLI**
- **Cursor IDE** (Claude Code extension)
- **Antigravity IDE** (Claude Code extension)

Works on **Linux** and **Windows 11**.

---

## Supported providers

| Provider | Backend | Proxy needed? | API key location |
|----------|---------|---------------|-----------------|
| **Claude (Anthropic)** | Native Anthropic API | No | Built-in Claude Code auth |
| **GLM (Z.ai)** | Anthropic-compatible endpoint | No | Claude Code settings |
| **OpenRouter** | Native Anthropic-compatible endpoint | No | Claude Code settings |
| **Requesty** | Anthropic-compatible gateway | No | Claude Code settings |
| **LiteLLM** | Local proxy (multi-provider) | Yes | Claude Code settings (master key) |
| **OpenAI / ChatGPT** | Via LiteLLM proxy | Yes | `~/.litellm/config.yaml` |

---

## Why this exists

The [GLM Coding Plan](https://z.ai/subscribe) gives you access to GLM-5.1 — which scores 94.6% of Claude Opus on coding benchmarks — starting from $3/month. Z.ai's API is Anthropic-compatible, so Claude Code routes through it seamlessly.

OpenRouter gives you access to 500+ models (Claude, GPT-4o, Gemini, Llama, and more) through a single API key, also with native Anthropic compatibility.

For providers like OpenAI that don't speak the Anthropic API format natively, LiteLLM acts as a local translation proxy.

The catch: switching between providers normally means manually editing config files. This tool makes it a single command or desktop double-click, and handles key rotation too.

---

## What gets switched

| File | Provider mode | Claude mode |
|------|--------------|-------------|
| `~/.claude/settings.json` | Provider endpoint + models | Your original Anthropic settings |
| `~/.config/Cursor/User/settings.json` | Env vars injected | Original restored |
| `~/.config/Antigravity/User/settings.json` | Env vars injected | Original restored |
| Windows equivalents | Same | Same |

MCPs, permissions, custom commands — all untouched. Only the API routing changes.

---

## Setup

### Linux

1. Copy `CONFIG.sh` to `~/.claude-switcher/CONFIG.sh` and edit the API keys
2. Run `bash linux/setup.sh`
3. Run `source ~/.bashrc`
4. Set your keys with `update-api-key`

### Windows

1. Run `windows/Setup-ClaudeSwitcher.ps1` once (right-click -> Run with PowerShell)
2. Double-click `Update API Key.bat` on your Desktop and paste your API keys
3. Done — desktop shortcuts let you switch modes

---

## Commands (Linux)

| Command | What it does |
|---------|-------------|
| `claude-mode` | Switch back to Anthropic Claude |
| `glm-mode` | Switch to GLM via Z.ai |
| `openrouter-mode` | Switch to OpenRouter |
| `openai-mode` | Switch to OpenAI / ChatGPT (via LiteLLM) |
| `requesty-mode` | Switch to Requesty |
| `litellm-mode` | Switch to LiteLLM local proxy |
| `update-api-key` | Interactive key rotation for any service |
| `update-glm-key` | Rotate Z.ai key (shorthand) |
| `update-openai-key` | Update OpenAI key in `~/.litellm/config.yaml` |
| `my-commands` | List all available commands |

## Desktop shortcuts (Windows)

| Shortcut | What it does |
|----------|-------------|
| `Switch to <Provider>.bat` | One per configured provider |
| `Update API Key.bat` | Interactive key rotation for any service |

---

## Provider-specific setup

### OpenRouter

OpenRouter provides a native Anthropic-compatible endpoint — no proxy needed. Just add your OpenRouter API key.

The default models are set to Claude Opus/Sonnet/Haiku, but you can swap them to **any** OpenRouter model ID. Edit the model strings in `CONFIG.sh` or `CONFIG.ps1`:

```
# Example: use GPT-4o instead of Claude
SERVICE_openrouter_OPUS="openai/gpt-4o"
SERVICE_openrouter_SONNET="openai/gpt-4o-mini"
SERVICE_openrouter_HAIKU="openai/gpt-4o-mini"
```

Browse 500+ available models at [openrouter.ai/models](https://openrouter.ai/models).

**Important:** `ANTHROPIC_API_KEY` is set to an empty string to prevent Claude Code from falling back to a cached Anthropic key. Authentication goes through `ANTHROPIC_AUTH_TOKEN` only.

### OpenAI / ChatGPT

OpenAI does not natively speak the Anthropic API format, so Claude Code cannot connect to it directly. This mode uses **LiteLLM** as a local translation proxy.

**Setup:**
1. Install LiteLLM: `pip install litellm`
2. Copy `templates/litellm-config.yaml` to `~/.litellm/config.yaml`
3. Fill in your OpenAI API key in that file
4. Start LiteLLM: `litellm --config ~/.litellm/config.yaml`
5. Switch to OpenAI mode: `openai-mode`

**Key management:** The OpenAI API key lives in `~/.litellm/config.yaml`, not in Claude Code settings. Use `update-openai-key` to rotate it.

### GLM via Z.ai

The [GLM Coding Plan](https://z.ai/subscribe) gives access to GLM-5.1 from $3/month.

| Claude Code slot | GLM model |
|-----------------|-----------|
| Opus | GLM-5.1 |
| Sonnet | GLM-5 |
| Haiku | GLM-4.7 |

### Requesty

Anthropic-compatible gateway with 300+ models. See [docs.requesty.ai](https://docs.requesty.ai) for model IDs.

### LiteLLM (generic)

For any other provider (Gemini, Groq, Mistral, etc.), use the generic LiteLLM mode. Configure models in `~/.litellm/config.yaml` and point Claude Code at `localhost:4000`.

See `templates/litellm-config.yaml` for an example with OpenAI, Gemini, and Groq entries.

---

## Rotating your API key

**Linux:** run `update-api-key` and pick a service, or use `update-glm-key` / `update-openai-key`

**Windows:** double-click `Update API Key.bat` on your Desktop

Both update every relevant file in one shot — templates and active settings.

---

## Models used

| Mode | Opus slot | Sonnet slot | Haiku slot |
|------|-----------|-------------|------------|
| Claude | (Anthropic default) | (Anthropic default) | (Anthropic default) |
| GLM | GLM-5.1 | GLM-5 | GLM-4.7 |
| OpenRouter | anthropic/claude-opus-4-6 | anthropic/claude-sonnet-4-6 | anthropic/claude-haiku-4-5 |
| OpenAI | gpt-4o | gpt-4o-mini | gpt-4o-mini |
| Requesty | anthropic/claude-opus-4-6 | anthropic/claude-sonnet-4-6 | anthropic/claude-haiku-4-5 |
| LiteLLM | (your config) | (your config) | (your config) |

All model strings can be changed in `CONFIG.sh` / `CONFIG.ps1`.

---

## Adding more IDEs

To add Roo Code, Cline, VS Code, or any other tool:

**Linux:** add the settings file paths to `SETTINGS_FILES` and `TEMPLATE_DIRS` in `~/.claude-switcher/CONFIG.sh`.

**Windows:** add the paths to `$SettingsFiles` and `$TemplateDirs` in `windows/CONFIG.ps1`.

Then re-run setup.

---

## Security

- **Never commit your filled-in settings files.** The `.gitignore` excludes `settings.json`, `*.settings.json`, and `settings.bak.json`.
- Template files use `YOUR_*_API_KEY_HERE` placeholders — safe to commit.
- If you accidentally expose a key, use `update-api-key` after regenerating it.
- See [SECURITY.md](SECURITY.md) for responsible disclosure.

---

## Z.ai quota tips

- Peak hours (14:00–18:00 UTC+8) cost **3x** quota
- Off-peak costs **2x** (promotional **1x** through April 2026)
- Schedule heavy agentic sessions outside peak hours
- Run `/compact` every 10–15 turns — context pollution is faster with non-Claude models

---

## Requirements

**Linux**
- Claude Code CLI
- Cursor and/or Antigravity IDE with Claude Code extension
- bash
- python3 (for JSON merging in setup)

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
