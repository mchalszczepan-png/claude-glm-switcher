# Security Policy

## Keeping your API keys safe

This tool manages API keys for Z.ai (GLM) and Anthropic (Claude). Please follow these practices:

### Never commit real settings files

The following files are excluded by `.gitignore` and must stay that way:

- `settings.json`
- `glm.settings.json`
- `claude.settings.json`
- `settings.bak.json`

Only commit template files that contain `YOUR_ZAI_API_KEY_HERE` as a placeholder.

### If you accidentally expose a key

1. Immediately regenerate your key on [z.ai](https://z.ai) or [console.anthropic.com](https://console.anthropic.com)
2. Run `update-glm-key` (Linux) or `Update Z.ai API Key.bat` (Windows) with your new key
3. If the key was committed to a public repo, assume it is compromised — regenerate regardless

### Reporting a vulnerability

If you find a security issue in this tool (e.g. a code path that could leak keys), please open a GitHub issue marked **[SECURITY]** or contact the maintainer directly before disclosing publicly.
