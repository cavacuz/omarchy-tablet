#!/bin/bash
# tablet-services.sh — enable the tablet-companion user services whose
# runtime dependency is present; keep the others stopped + disabled.
#
# Optional features (never a deployment blocker — the plugin installs and
# runs on a stock Omarchy without them; they switch on by themselves on
# the next shell load once the package is installed):
#   auto-rotate.service     needs monitor-sensor (iio-sensor-proxy, official repo)
#   lisgd-gestures.service  needs lisgd (AUR — externally managed, never auto-installed)
#                           AND input-group membership: lisgd reads the raw
#                           touchscreen node (/dev/input/eventN, root:input
#                           0660). Without it the gesture script exits
#                           silently and systemd restarts it forever.
# Core (always enabled):
#   touch-cursor.service    python3 only (stock)
#
# Usage: tablet-services.sh [--restart]
#   --restart  also restart the running enabled services (after an update).
# Exit 0 when the core service is active.
set -u

RESTART=0
[[ ${1:-} == --restart ]] && RESTART=1

# unit:command-it-needs ("" = core, always enabled)
UNITS=(
  "touch-cursor.service:"
  "auto-rotate.service:monitor-sensor"
  "lisgd-gestures.service:lisgd"
)

# Input-group state: "ok" (effective in this session), "relogin" (added
# in /etc/group but this session predates it), or "missing".
input_group_state() {
  if id -nG | tr ' ' '\n' | grep -qx input; then
    echo ok
  elif id -nG "$(id -un)" 2>/dev/null | tr ' ' '\n' | grep -qx input; then
    echo relogin
  else
    echo missing
  fi
}

# Prints why a unit cannot run, or nothing when it can.
blocker() {
  local need=$1
  [[ -z $need ]] && return 0
  if ! command -v "$need" >/dev/null 2>&1; then
    echo "needs '$need' (see README → Optional features)"
    return 0
  fi
  if [[ $need == lisgd ]]; then
    case $(input_group_state) in
      relogin) echo "you were added to the 'input' group — log out and back in" ;;
      missing) echo "needs 'input' group membership: sudo usermod -aG input $(id -un), then log out and back in" ;;
    esac
  fi
}

ENABLED=()
for entry in "${UNITS[@]}"; do
  u=${entry%%:*}
  need=${entry#*:}
  why=$(blocker "$need")
  if [[ -z $why ]]; then
    if systemctl --user enable --now "$u" >/dev/null 2>&1; then
      echo "OK: enabled $u"
      ENABLED+=("$u")
    else
      echo "WARN: cannot enable $u (see: journalctl --user -u $u)"
    fi
  else
    # Dependency absent: a started unit would only fail/restart-loop.
    if systemctl --user is-enabled "$u" >/dev/null 2>&1 || \
       systemctl --user is-active "$u" >/dev/null 2>&1; then
      systemctl --user disable --now "$u" >/dev/null 2>&1
    fi
    echo "INFO: $u off — optional; $why"
  fi
done

if (( RESTART )) && (( ${#ENABLED[@]} > 0 )); then
  systemctl --user try-restart "${ENABLED[@]}" && echo "OK: services restarted"
fi

systemctl --user is-active --quiet touch-cursor.service
