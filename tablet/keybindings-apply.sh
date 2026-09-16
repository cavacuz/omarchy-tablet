#!/bin/bash
# keybindings-apply.sh — apply tablet keybindings from conf file.
# Reads ~/.config/hypr/tablet-keybindings.conf, regenerates the tablet
# section in bindings.lua, and reloads Hyprland.
set -u

CONF="$HOME/.config/hypr/tablet-keybindings.conf"
BINDINGS="$HOME/.config/hypr/bindings.lua"
TMP=""

if [[ ! -f "$CONF" ]]; then
  echo "keybindings-apply: $CONF not found" >&2; exit 1
fi

cleanup() {
  [[ -n $TMP && -f $TMP ]] && rm -f "$TMP"
}
trap cleanup EXIT

# Map conf names to (description, command).
declare -A DESCS CMDS
DESCS[tablet_toggle]="Tablet mode toggle"
CMDS[tablet_toggle]="~/.config/hypr/scripts/tablet-mode.sh toggle"
DESCS[osk_toggle]="On-screen keyboard"
CMDS[osk_toggle]="~/.config/hypr/scripts/osk-toggle.sh"
DESCS[pen_toggle]="Finger touch toggle"
CMDS[pen_toggle]="~/.config/hypr/scripts/touch-toggle.sh toggle"

# Parse conf: NAME=MODS+KEY → hyprland mods string "MOD1 + MOD2 + KEY".
to_hypr_mods() {
  local raw="$1"
  local result=""
  local IFS='+'
  for part in $raw; do
    case "$part" in
      SUPER)  result="${result:+$result + }SUPER" ;;
      SHIFT)  result="${result:+$result + }SHIFT" ;;
      CTRL)   result="${result:+$result + }CTRL" ;;
      ALT)    result="${result:+$result + }ALT" ;;
      *)      result="${result:+$result + }$part" ;;
    esac
  done
  printf '%s' "$result"
}

# Build new tablet binding lines.
NEW_BLOCK="-- Tablet mode + OSK (tablet-companion package — editable via the bar-widget gear)."
while IFS='=' read -r name keys; do
  name="${name%%#*}"     # strip comments
  name="$(echo "$name" | tr -d '[:space:]')"
  [[ -z "$name" ]] && continue
  [[ -z "${DESCS[$name]+x}" ]] && continue
  hypr_keys=$(to_hypr_mods "$keys")
  NEW_BLOCK="${NEW_BLOCK}
o.bind(\"${hypr_keys}\", \"${DESCS[$name]}\", \"${CMDS[$name]}\")"
done < "$CONF"
NEW_BLOCK="${NEW_BLOCK}
"

# Remove the OLD tablet bindings + marker comment, keeping all user bindings.
# Surgical: only our own tablet lines are removed, anything else is kept.
TMP=$(mktemp)
awk '/^-- Tablet mode \+ OSK / ||
     /tablet-mode\.sh toggle/ ||
     /osk-toggle\.sh/ ||
     /touch-toggle\.sh toggle/ { next }
     { print }' "$BINDINGS" > "$TMP"

# Append a separator + new block.
printf '\n%s\n' "$NEW_BLOCK" >> "$TMP"

if ! luac -p "$TMP" 2>/dev/null; then
  echo "keybindings-apply: generated bindings.lua fails syntax check" >&2
  rm -f "$TMP"; exit 1
fi

mv "$TMP" "$BINDINGS"
hyprctl reload >/dev/null 2>&1
echo "keybindings applied"
