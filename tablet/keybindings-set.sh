#!/bin/bash
# keybindings-set.sh — write tablet keybindings to conf and apply them live.
# Usage: keybindings-set.sh TABLET_KEYS OSK_KEYS PEN_KEYS
# Each argument is MODS+KEY (e.g. SUPER+SHIFT+T). Use "" to keep a value.
set -u

CONF="$HOME/.config/hypr/tablet-keybindings.conf"
APPLY="$(dirname "${BASH_SOURCE[0]}")/keybindings-apply.sh"

if [[ $# -ne 3 ]]; then
  echo "usage: keybindings-set.sh TABLET_KEYS OSK_KEYS PEN_KEYS" >&2
  exit 1
fi

mkdir -p "$(dirname "$CONF")"
cat > "$CONF" <<EOF
# tablet keybindings — format: NAME=MODS+KEY
# MODS: SUPER, SHIFT, CTRL, ALT (combine with +) · KEY: Hyprland key name
tablet_toggle=$1
osk_toggle=$2
pen_toggle=$3
EOF

exec "$APPLY"