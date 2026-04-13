# =============================================================================
# claude-glm-switcher — Windows USER CONFIGURATION
# Edit this file to match your system. All other scripts read from here.
# =============================================================================

# -----------------------------------------------------------------------------
# SECTION 1: FILE PATHS
# Active settings.json files that get swapped when you switch mode.
# Comment out apps you don't use. Add new ones following the same pattern.
# -----------------------------------------------------------------------------

$SettingsFiles = @(
    "$env:USERPROFILE\.claude\settings.json",              # Claude Code CLI
    "$env:APPDATA\Antigravity\User\settings.json"          # Antigravity IDE
    # "$env:APPDATA\Cursor\User\settings.json",            # Cursor (uncomment if used)
    # "$env:APPDATA\Code\User\settings.json",              # VS Code (uncomment if used)
    # "$env:APPDATA\Windsurf\User\settings.json"           # Windsurf (uncomment if used)
)

# Template dirs — one per entry above, same order.
$TemplateDirs = @(
    "$env:USERPROFILE\.claude",
    "$env:APPDATA\Antigravity\User"
    # "$env:APPDATA\Cursor\User",
    # "$env:APPDATA\Code\User",
    # "$env:APPDATA\Windsurf\User"
)

# -----------------------------------------------------------------------------
# SECTION 2: SERVICE DEFINITIONS
# Each hashtable defines one service. Copy a block to add a custom service.
# Fields:
#   Name      — identifier, used in menus and template filenames
#   Label     — friendly display name
#   KeyField  — JSON field name for the API key in the env block
#   BaseURL   — ANTHROPIC_BASE_URL value (empty = Claude default, no env block)
#   Opus/Sonnet/Haiku — model IDs for each slot
#   IsProxy   — $true if a local proxy must be running first
# -----------------------------------------------------------------------------

$Services = @(
    @{
        Name     = "claude"
        Label    = "Claude (Anthropic official)"
        KeyField = ""
        BaseURL  = ""
    },
    @{
        Name     = "glm"
        Label    = "GLM via Z.ai"
        KeyField = "ANTHROPIC_AUTH_TOKEN"
        BaseURL  = "https://api.z.ai/api/anthropic"
        Opus     = "GLM-5.1"
        Sonnet   = "GLM-5"
        Haiku    = "GLM-4.7"
    },
    @{
        Name     = "openrouter"
        Label    = "OpenRouter"
        KeyField = "ANTHROPIC_AUTH_TOKEN"
        BaseURL  = "https://openrouter.ai/api"
        Opus     = "anthropic/claude-opus-4-6"
        Sonnet   = "anthropic/claude-sonnet-4-6"
        Haiku    = "anthropic/claude-haiku-4-5"
    },
    @{
        Name     = "requesty"
        Label    = "Requesty"
        KeyField = "ANTHROPIC_AUTH_TOKEN"
        BaseURL  = "https://router.requesty.ai"
        Opus     = "anthropic/claude-opus-4-6"
        Sonnet   = "anthropic/claude-sonnet-4-6"
        Haiku    = "anthropic/claude-haiku-4-5"
    },
    @{
        Name     = "litellm"
        Label    = "LiteLLM (local proxy)"
        KeyField = "ANTHROPIC_AUTH_TOKEN"
        BaseURL  = "http://localhost:4000"
        Opus     = "gpt-4o"
        Sonnet   = "gpt-4o-mini"
        Haiku    = "gpt-4o-mini"
        IsProxy  = $true
    }
    # To add a custom service, copy and paste a block above and fill in the values
)

# -----------------------------------------------------------------------------
# SECTION 3: API KEYS
# Fill these in using the "Update API Keys" desktop shortcut.
# Never commit this file with real keys.
# -----------------------------------------------------------------------------

$ApiKeys = @{
    glm        = "YOUR_ZAI_API_KEY_HERE"
    openrouter = "YOUR_OPENROUTER_API_KEY_HERE"
    requesty   = "YOUR_REQUESTY_API_KEY_HERE"
    litellm    = "YOUR_LITELLM_MASTER_KEY_HERE"
    # myservice = "YOUR_KEY_HERE"
}
