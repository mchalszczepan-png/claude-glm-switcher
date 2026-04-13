# =============================================================================
# claude-glm-switcher — Linux bashrc additions
# Copy these into the bottom of your ~/.bashrc then run: source ~/.bashrc
#
# Or let setup.sh do it for you — it adds a source line automatically.
#
# Paths come from CONFIG.sh and can be changed there without editing this file.
# =============================================================================

# Source the installed config (patched by setup.sh)
SWITCHER_CONFIG="$HOME/.claude-switcher/CONFIG.sh"
# shellcheck source=/dev/null
source "$SWITCHER_CONFIG" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Generic mode switcher — copies <service>.settings.json → settings.json
# for every app configured in CONFIG.sh.
# ---------------------------------------------------------------------------
switch-mode() {
  local mode="${1:?Usage: switch-mode <service>}"

  # Validate service exists in config
  local found=0
  for svc in "${SERVICES[@]}"; do
    if [ "$svc" = "$mode" ]; then
      found=1
      break
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "Unknown service: $mode"
    echo "Available: ${SERVICES[*]}"
    return 1
  fi

  local i=0
  for settings_file in "${SETTINGS_FILES[@]}"; do
    local template_dir="${TEMPLATE_DIRS[$i]}"
    local template="${template_dir}/${mode}.settings.json"

    if [ -f "$template" ]; then
      cp "$template" "$settings_file"
      echo "  [OK]   $settings_file"
    else
      echo "  [SKIP] Template not found: $template"
    fi
    i=$((i + 1))
  done

  # Look up friendly label
  local label_var="SERVICE_${mode}_LABEL"
  local label="${!label_var:-$mode}"
  echo "Switched to ${label}"
}

# ---------------------------------------------------------------------------
# Convenience aliases — one per service
# ---------------------------------------------------------------------------
for _svc in "${SERVICES[@]}"; do
  alias "${_svc}-mode"="switch-mode ${_svc}"
done
unset _svc

# ---------------------------------------------------------------------------
# update-api-key — rotate the API key for any service across all settings files
# ---------------------------------------------------------------------------
update-api-key() {
  echo "Which service key to update?"
  echo "Available: ${SERVICES[*]}"
  read -rp "Service: " SVC

  # Validate
  local found=0
  for s in "${SERVICES[@]}"; do
    [ "$s" = "$SVC" ] && found=1
  done
  [ "$found" -eq 0 ] && echo "Unknown service: $SVC" && return 1

  # Special case: openai — key lives in litellm config, not settings files
  if [ "$SVC" = "openai" ]; then
    update-openai-key
    return $?
  fi

  # Special case: claude — no key to update
  if [ "$SVC" = "claude" ]; then
    echo "Claude mode uses Anthropic's built-in auth. No key to update."
    return 0
  fi

  local key_field_var="SERVICE_${SVC}_KEY_FIELD"
  local key_field="${!key_field_var}"
  [ -z "$key_field" ] && echo "No key field defined for $SVC" && return 1

  read -rp "Paste new $SVC API key: " NEW_KEY
  if [ -z "$NEW_KEY" ]; then
    echo "No key entered. Nothing changed."
    return 1
  fi

  # Update CONFIG.sh
  local config_file="$SWITCHER_CONFIG"
  local key_var="API_KEY_${SVC}"
  if [ -f "$config_file" ] && grep -q "^${key_var}=" "$config_file"; then
    sed -i "s|^${key_var}=\"[^\"]*\"|${key_var}=\"${NEW_KEY}\"|" "$config_file"
    echo "  [OK]   Updated key in $config_file"
  fi

  # Update template + active settings files
  local i=0
  for settings_file in "${SETTINGS_FILES[@]}"; do
    local template_dir="${TEMPLATE_DIRS[$i]}"
    local svc_template="${template_dir}/${SVC}.settings.json"

    for f in "$svc_template" "$settings_file"; do
      if [ -f "$f" ]; then
        if grep -q "\"${key_field}\"" "$f"; then
          sed -i "s|\"${key_field}\": \"[^\"]*\"|\"${key_field}\": \"${NEW_KEY}\"|g" "$f"
          echo "  [OK]   Updated: $f"
        else
          echo "  [SKIP] No key field in: $f"
        fi
      fi
    done
    i=$((i + 1))
  done

  echo "  Done. $SVC key updated."
}

# ---------------------------------------------------------------------------
# update-glm-key — backward-compatible shorthand
# ---------------------------------------------------------------------------
update-glm-key() {
  SVC="glm"
  local key_field="ANTHROPIC_AUTH_TOKEN"

  read -rp "Paste new Z.ai API key: " NEW_KEY
  if [ -z "$NEW_KEY" ]; then
    echo "No key entered. Nothing changed."
    return 1
  fi

  local i=0
  for settings_file in "${SETTINGS_FILES[@]}"; do
    local template_dir="${TEMPLATE_DIRS[$i]}"
    local svc_template="${template_dir}/glm.settings.json"

    for f in "$svc_template" "$settings_file"; do
      if [ -f "$f" ]; then
        if grep -q "\"${key_field}\"" "$f"; then
          sed -i "s|\"${key_field}\": \"[^\"]*\"|\"${key_field}\": \"${NEW_KEY}\"|g" "$f"
          echo "  [OK]   Updated: $f"
        else
          echo "  [SKIP] No key field in: $f"
        fi
      fi
    done
    i=$((i + 1))
  done
}

# ---------------------------------------------------------------------------
# update-openai-key — update OpenAI key in ~/.litellm/config.yaml
# ---------------------------------------------------------------------------
update-openai-key() {
  read -rp "Paste new OpenAI API key: " NEW_KEY
  if [ -z "$NEW_KEY" ]; then
    echo "No key entered."
    return 1
  fi

  local LITELLM_CONFIG="$HOME/.litellm/config.yaml"
  if [ ! -f "$LITELLM_CONFIG" ]; then
    echo "  [ERROR] ~/.litellm/config.yaml not found."
    echo "  Copy templates/litellm-config.yaml there first."
    return 1
  fi

  sed -i "s|YOUR_OPENAI_API_KEY_HERE|$NEW_KEY|g" "$LITELLM_CONFIG"
  sed -i "s|api_key: \"sk-[^\"]*\"|api_key: \"$NEW_KEY\"|g" "$LITELLM_CONFIG"
  echo "  [OK]   OpenAI key updated in $LITELLM_CONFIG"
}

# ---------------------------------------------------------------------------
# my-commands — list available commands
# ---------------------------------------------------------------------------
my-commands() {
  echo ""
  echo "=== Mode Switching ==="
  for svc in "${SERVICES[@]}"; do
    printf "  %-20s # switch to %s\n" "${svc}-mode" "$svc"
  done
  echo ""
  echo "=== Key Management ==="
  echo "  update-api-key            # interactive — pick a service"
  echo "  update-glm-key            # shorthand for Z.ai key"
  echo "  update-openai-key         # update OpenAI key in litellm config"
  echo ""
}
