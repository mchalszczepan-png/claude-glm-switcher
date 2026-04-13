#!/usr/bin/env bash
# =============================================================================
# claude-glm-switcher — Linux Setup Script
# Run once: bash linux/setup.sh
# =============================================================================

set -e

SWITCHER_DIR="$HOME/.claude-switcher"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "=== claude-glm-switcher Setup ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Install CONFIG.sh into ~/.claude-switcher
# ---------------------------------------------------------------------------
mkdir -p "$SWITCHER_DIR"

if [ -f "$SWITCHER_DIR/CONFIG.sh" ]; then
  echo "[SKIP] CONFIG.sh already exists at $SWITCHER_DIR/CONFIG.sh"
  echo "       Edit it there to change paths or services."
else
  cp "$REPO_DIR/CONFIG.sh" "$SWITCHER_DIR/CONFIG.sh"
  echo "[OK]   CONFIG.sh installed to $SWITCHER_DIR/CONFIG.sh"
fi

# ---------------------------------------------------------------------------
# 2. Source CONFIG.sh
# ---------------------------------------------------------------------------
# shellcheck source=/dev/null
source "$SWITCHER_DIR/CONFIG.sh"

# ---------------------------------------------------------------------------
# 3. For each settings file, snapshot current state as claude.settings.json
#    (only if it doesn't already exist)
# ---------------------------------------------------------------------------
echo ""
echo "Snapshotting current settings as Claude (default) templates..."

i=0
for SETTINGS_FILE in "${SETTINGS_FILES[@]}"; do
  TEMPLATE_DIR="${TEMPLATE_DIRS[$i]}"
  CLAUDE_TEMPLATE="${TEMPLATE_DIR}/claude.settings.json"
  i=$((i + 1))

  mkdir -p "$TEMPLATE_DIR"

  if [ -f "$CLAUDE_TEMPLATE" ]; then
    echo "  [SKIP] $CLAUDE_TEMPLATE already exists"
  elif [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$CLAUDE_TEMPLATE"
    echo "  [OK]   $CLAUDE_TEMPLATE (from current settings)"
  else
    echo '{ "effortLevel": "medium" }' > "$CLAUDE_TEMPLATE"
    echo "  [WARN] $SETTINGS_FILE not found — minimal template created"
  fi
done

# ---------------------------------------------------------------------------
# 4. Create service templates from the repo templates dir,
#    merged with the Claude template so MCPs etc. are preserved.
#    Uses Python for JSON merging (available on all Linux systems).
# ---------------------------------------------------------------------------
echo ""
echo "Creating service templates..."

MERGE_SCRIPT=$(cat <<'PYEOF'
import json, sys, os

claude_path = sys.argv[1]
service     = sys.argv[2]
dest_path   = sys.argv[3]
config_path = sys.argv[4]
is_ide      = sys.argv[5] == "true"

# Load the CONFIG.sh values we need via environment variables
# (passed by the caller as env vars)
base_url    = os.environ.get("SVC_BASE_URL", "")
opus        = os.environ.get("SVC_OPUS", "")
sonnet      = os.environ.get("SVC_SONNET", "")
haiku       = os.environ.get("SVC_HAIKU", "")
key_field   = os.environ.get("SVC_KEY_FIELD", "ANTHROPIC_AUTH_TOKEN")
placeholder = f"YOUR_{service.upper()}_API_KEY_HERE"

# Load base (claude template)
try:
    with open(claude_path) as f:
        base = json.load(f)
except Exception:
    base = {}

# Build env block
env = {
    key_field: placeholder,
    "ANTHROPIC_BASE_URL": base_url,
    "API_TIMEOUT_MS": "3000000",
}
if opus:   env["ANTHROPIC_DEFAULT_OPUS_MODEL"]   = opus
if sonnet: env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = sonnet
if haiku:  env["ANTHROPIC_DEFAULT_HAIKU_MODEL"]  = haiku

base["env"] = env

# For IDE settings files, also add claudeCode.* keys
if is_ide:
    base["claudeCode.disableLoginPrompt"] = True
    base["claudeCode.environmentVariables"] = [
        {"name": k, "value": v} for k, v in env.items()
    ]

with open(dest_path, "w") as f:
    json.dump(base, f, indent=2)
    f.write("\n")

print(f"  [OK]   {dest_path}")
PYEOF
)

for SERVICE in "${SERVICES[@]}"; do
  # Skip claude — it's just the snapshot
  [ "$SERVICE" = "claude" ] && continue

  base_url_var="SERVICE_${SERVICE}_BASE_URL"
  opus_var="SERVICE_${SERVICE}_OPUS"
  sonnet_var="SERVICE_${SERVICE}_SONNET"
  haiku_var="SERVICE_${SERVICE}_HAIKU"
  key_field_var="SERVICE_${SERVICE}_KEY_FIELD"

  i=0
  for SETTINGS_FILE in "${SETTINGS_FILES[@]}"; do
    TEMPLATE_DIR="${TEMPLATE_DIRS[$i]}"
    CLAUDE_TEMPLATE="${TEMPLATE_DIR}/claude.settings.json"
    SERVICE_TEMPLATE="${TEMPLATE_DIR}/${SERVICE}.settings.json"
    # Treat first entry (Claude Code CLI) as non-IDE, rest as IDE
    IS_IDE="true"
    [ "$i" -eq 0 ] && IS_IDE="false"
    i=$((i + 1))

    if [ -f "$SERVICE_TEMPLATE" ]; then
      echo "  [SKIP] $SERVICE_TEMPLATE already exists"
      continue
    fi

    SVC_BASE_URL="${!base_url_var}" \
    SVC_OPUS="${!opus_var}" \
    SVC_SONNET="${!sonnet_var}" \
    SVC_HAIKU="${!haiku_var}" \
    SVC_KEY_FIELD="${!key_field_var}" \
    python3 -c "$MERGE_SCRIPT" \
      "$CLAUDE_TEMPLATE" "$SERVICE" "$SERVICE_TEMPLATE" "$SWITCHER_DIR/CONFIG.sh" "$IS_IDE"
  done
done

# ---------------------------------------------------------------------------
# 5. Add source line to ~/.bashrc if not already present
# ---------------------------------------------------------------------------
echo ""
BASHRC_LINE="source \"$REPO_DIR/linux/bashrc_additions.sh\""
if grep -qF "$BASHRC_LINE" "$HOME/.bashrc" 2>/dev/null; then
  echo "[SKIP] bashrc_additions.sh already sourced in ~/.bashrc"
else
  echo "" >> "$HOME/.bashrc"
  echo "# claude-glm-switcher" >> "$HOME/.bashrc"
  echo "$BASHRC_LINE" >> "$HOME/.bashrc"
  echo "[OK]   Added to ~/.bashrc"
fi

# Update the SWITCHER_CONFIG path in bashrc_additions.sh to point to installed config
sed -i "s|SWITCHER_CONFIG=.*|SWITCHER_CONFIG=\"$SWITCHER_DIR/CONFIG.sh\"|" \
  "$REPO_DIR/linux/bashrc_additions.sh" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 6. Done
# ---------------------------------------------------------------------------
echo ""
echo "=== Setup Complete ==="
echo ""
echo "NEXT STEP: Set your API keys."
echo "Run: source ~/.bashrc && update-api-key"
echo ""
echo "Then switch modes with:"
echo "  glm-mode          # GLM via Z.ai"
echo "  openrouter-mode   # OpenRouter"
echo "  requesty-mode     # Requesty"
echo "  litellm-mode      # LiteLLM local proxy"
echo "  claude-mode       # Back to Anthropic"
echo ""
