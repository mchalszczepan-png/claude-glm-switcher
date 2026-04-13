#!/usr/bin/env bash
# =============================================================================
# claude-glm-switcher — USER CONFIGURATION
# Edit this file to match your system. All other scripts read from here.
# =============================================================================

# -----------------------------------------------------------------------------
# SECTION 1: FILE PATHS
# These are the active settings.json files that get swapped when you switch.
# Add or remove paths to match the apps you actually use.
# -----------------------------------------------------------------------------

SETTINGS_FILES=(
  "$HOME/.claude/settings.json"                        # Claude Code CLI
  "$HOME/.config/Cursor/User/settings.json"            # Cursor IDE
  "$HOME/.config/Antigravity/User/settings.json"       # Antigravity IDE
  # "$HOME/.config/Code/User/settings.json"            # VS Code (uncomment if used)
  # "$HOME/.config/windsurf/User/settings.json"        # Windsurf (uncomment if used)
  # Add more paths here as needed
)

# These are the template directories — one per app above (same order).
# Templates live alongside the active settings.json in each app's config dir.
# You don't normally need to change these.
TEMPLATE_DIRS=(
  "$HOME/.claude"
  "$HOME/.config/Cursor/User"
  "$HOME/.config/Antigravity/User"
  # "$HOME/.config/Code/User"
  # "$HOME/.config/windsurf/User"
)

# -----------------------------------------------------------------------------
# SECTION 2: SERVICE DEFINITIONS
# Each service needs: a name, the env block to inject, and a key field name.
#
# To add a custom service, copy one of the blocks below and fill it in.
# The KEY_FIELD is the JSON field name that holds the API key in the env block.
# Leave BASE_URL empty for the default Claude/Anthropic mode (no env block).
# -----------------------------------------------------------------------------

# List of service names (used in menus and file naming)
SERVICES=(
  "claude"
  "glm"
  "openrouter"
  "requesty"
  "litellm"
  "openai"
)

# --- Claude (Anthropic default) ---
# No env block — Claude Code uses its own auth. Restores original settings.
SERVICE_claude_KEY_FIELD=""
SERVICE_claude_BASE_URL=""
SERVICE_claude_LABEL="Claude (Anthropic official)"

# --- GLM via Z.ai ---
SERVICE_glm_KEY_FIELD="ANTHROPIC_AUTH_TOKEN"
SERVICE_glm_BASE_URL="https://api.z.ai/api/anthropic"
SERVICE_glm_OPUS="GLM-5.1"
SERVICE_glm_SONNET="GLM-5"
SERVICE_glm_HAIKU="GLM-4.7"
SERVICE_glm_LABEL="GLM via Z.ai"

# --- OpenRouter ---
# Native Anthropic-compatible. Models: set to any OpenRouter model string.
# See https://openrouter.ai/models for the full list.
SERVICE_openrouter_KEY_FIELD="ANTHROPIC_AUTH_TOKEN"
SERVICE_openrouter_BASE_URL="https://openrouter.ai/api"
SERVICE_openrouter_OPUS="anthropic/claude-opus-4-6"
SERVICE_openrouter_SONNET="anthropic/claude-sonnet-4-6"
SERVICE_openrouter_HAIKU="anthropic/claude-haiku-4-5"
SERVICE_openrouter_LABEL="OpenRouter"

# --- Requesty ---
# Native Anthropic-compatible gateway. 300+ models.
# See https://docs.requesty.ai for model IDs.
SERVICE_requesty_KEY_FIELD="ANTHROPIC_AUTH_TOKEN"
SERVICE_requesty_BASE_URL="https://router.requesty.ai"
SERVICE_requesty_OPUS="anthropic/claude-opus-4-6"
SERVICE_requesty_SONNET="anthropic/claude-sonnet-4-6"
SERVICE_requesty_HAIKU="anthropic/claude-haiku-4-5"
SERVICE_requesty_LABEL="Requesty"

# --- LiteLLM (local proxy) ---
# Required for: OpenAI/ChatGPT, Gemini, Groq, and other non-Anthropic-native providers.
# Run LiteLLM first: pip install litellm && litellm --config ~/.litellm/config.yaml
# See templates/litellm-config.yaml for an example config.
# The key here is your LiteLLM master key (set in your LiteLLM config).
SERVICE_litellm_KEY_FIELD="ANTHROPIC_AUTH_TOKEN"
SERVICE_litellm_BASE_URL="http://localhost:4000"
SERVICE_litellm_OPUS="gpt-4o"            # Change to your preferred model
SERVICE_litellm_SONNET="gpt-4o-mini"     # Change to your preferred model
SERVICE_litellm_HAIKU="gpt-4o-mini"      # Change to your preferred model
SERVICE_litellm_LABEL="LiteLLM (local proxy)"

# --- OpenAI / ChatGPT (via LiteLLM) ---
# Dedicated OpenAI mode — uses LiteLLM as a local proxy.
# The OpenAI API key goes in ~/.litellm/config.yaml, NOT in this file.
# Use update-openai-key to rotate the OpenAI key.
# Run LiteLLM first: pip install litellm && litellm --config ~/.litellm/config.yaml
SERVICE_openai_KEY_FIELD="ANTHROPIC_AUTH_TOKEN"
SERVICE_openai_BASE_URL="http://localhost:4000"
SERVICE_openai_OPUS="gpt-4o"
SERVICE_openai_SONNET="gpt-4o-mini"
SERVICE_openai_HAIKU="gpt-4o-mini"
SERVICE_openai_LABEL="OpenAI / ChatGPT"

# -----------------------------------------------------------------------------
# SECTION 3: API KEYS
# Fill these in after running setup, or use the update-api-key command.
# Never commit this file with real keys in it.
# -----------------------------------------------------------------------------

API_KEY_glm="YOUR_ZAI_API_KEY_HERE"
API_KEY_openrouter="YOUR_OPENROUTER_API_KEY_HERE"
API_KEY_requesty="YOUR_REQUESTY_API_KEY_HERE"
API_KEY_litellm="YOUR_LITELLM_MASTER_KEY_HERE"
# API_KEY_openai — NOT here. OpenAI key goes in ~/.litellm/config.yaml
# Use update-openai-key to set it.
# API_KEY_myservice="YOUR_KEY_HERE"   # Add keys for custom services here
