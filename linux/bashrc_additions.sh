# =============================================================================
# claude-glm-switcher — Linux bashrc additions
# Copy these into the bottom of your ~/.bashrc then run: source ~/.bashrc
#
# Paths assume:
#   Claude Code CLI:  ~/.claude/
#   Cursor IDE:       ~/.config/Cursor/User/
#   Antigravity IDE:  ~/.config/Antigravity/User/
#
# Edit the paths below if your setup differs.
# =============================================================================

# Switch all apps to GLM mode (Z.ai)
alias claude-glm-mode="\
  cp ~/.config/Cursor/User/glm.settings.json ~/.config/Cursor/User/settings.json && \
  cp ~/.config/Antigravity/User/glm.settings.json ~/.config/Antigravity/User/settings.json && \
  cp ~/.claude/glm.settings.json ~/.claude/settings.json && \
  echo 'Switched to GLM mode'"

# Switch all apps back to Claude mode (Anthropic)
alias claude-claude-mode="\
  cp ~/.config/Cursor/User/claude.settings.json ~/.config/Cursor/User/settings.json && \
  cp ~/.config/Antigravity/User/claude.settings.json ~/.config/Antigravity/User/settings.json && \
  cp ~/.claude/claude.settings.json ~/.claude/settings.json && \
  echo 'Switched to Claude mode'"

# Rotate Z.ai API key across all GLM settings files
update-glm-key() {
  read -rp "Paste new Z.ai API key: " NEW_KEY
  if [ -z "$NEW_KEY" ]; then
    echo "No key entered. Nothing changed."
    return 1
  fi

  local FILES=(
    "$HOME/.claude/glm.settings.json"
    "$HOME/.claude/settings.json"
    "$HOME/.config/Cursor/User/glm.settings.json"
    "$HOME/.config/Cursor/User/settings.json"
    "$HOME/.config/Antigravity/User/glm.settings.json"
    "$HOME/.config/Antigravity/User/settings.json"
  )

  for FILE in "${FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
      echo "  [SKIP] Not found: $FILE"
      continue
    fi
    if grep -q "ANTHROPIC_AUTH_TOKEN" "$FILE"; then
      sed -i "s|\"ANTHROPIC_AUTH_TOKEN\": \"[^\"]*\"|\"ANTHROPIC_AUTH_TOKEN\": \"$NEW_KEY\"|g" "$FILE"
      echo "  [OK]   Updated: $FILE"
    else
      echo "  [SKIP] No key field in: $FILE"
    fi
  done
}

# List all custom aliases and functions defined in ~/.bashrc
my-commands() {
  echo ""
  echo "=== Custom Aliases ==="
  grep -E "^alias " ~/.bashrc | sed 's/alias //' | cut -d'=' -f1 | sort
  echo ""
  echo "=== Custom Functions ==="
  grep -E "^\S+\(\)" ~/.bashrc | sed 's/().*//' | sort
  echo ""
}
