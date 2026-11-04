#!/bin/bash
# tablet-services.sh — enable the tablet-companion user services whose
# runtime dependency is present; keep the others stopped + disabled.
#
# Optional features (never a deployment blocker — the plugin installs and
# runs on a stock Omarchy without them; they switch on by themselves on
# the next shell load once the package is installed):
#   auto-rotate.service     needs monitor-sensor (iio-sensor-proxy, official repo)
#   lisgd-gestures.service  needs lisgd (AUR — externally managed, never auto-installed)
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

ENABLED=()
for entry in "${UNITS[@]}"; do
  u=${entry%%:*}
  need=${entry#*:}
  if [[ -z $need ]] || command -v "$need" >/dev/null 2>&1; then
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
    echo "INFO: $u off — optional; needs '$need' (see README → Optional features)"
  fi
done

if (( RESTART )) && (( ${#ENABLED[@]} > 0 )); then
  systemctl --user try-restart "${ENABLED[@]}" && echo "OK: services restarted"
fi

systemctl --user is-active --quiet touch-cursor.service
