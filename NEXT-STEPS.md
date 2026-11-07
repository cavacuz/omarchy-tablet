# Next steps — branch `omarchy-update-compat`

_Written 2026-11-07, after the Omarchy upgrade 4.0.6 → 4.5.0-3._

## Current state

- **Plugin works on the dev machine again.** `omarchy-shell tablet status` → `{"deployed":true}`;
  touch-cursor, auto-rotate and lisgd-gestures services active; `install.sh` ALL GREEN.
- **No code changes** on this branch yet (branched from `master` @ `7d73fde`, v0.3.6).
- **Marketplace:** update issue omacom/omarchy-plugin-marketplace#13770 (`7d73fde`) is still
  open, waiting on a maintainer. A bump comment is drafted but **not posted** — decision was to wait.

## What was fixed (machine only, no repo changes)

1. Upgrade left `cavacuz.tablet` out of `~/.config/omarchy/shell.json` → re-enabled with
   `omarchy plugin enable cavacuz.tablet`.
2. Installed copy was stale (`797b222`) vs live v0.3.6 scripts → `install.sh` hit the
   "live X is newer than repo copy" guard → `deployed:false`. Fixed with
   `omarchy plugin update cavacuz.tablet --yes` + `omarchy-restart-shell`
   (disable/enable does not reload Service.qml; the shell must restart).

## To do

- [ ] **Marketplace #13770** — re-check status; if still idle, decide whether to post the bump
      comment (similar issue #13811 was approved ~1h after a bump).
- [ ] **Root cause of the shell.json drop** — unconfirmed. The Elsewhen migration
      (`/usr/share/omarchy/migrations/1790528634.sh`) is ruled out. Next place to look:
      `/usr/share/omarchy/shell/services/PluginRegistry.qml` (how the shell prunes plugins it
      can't load at startup). If the shell drops plugins that fail to load, consider whether
      the plugin can do anything to avoid it; otherwise just document it in `README.md`.
- [ ] **Optional hardening** — `tablet/auto-rotate.sh` (~line 56): `_hyprctl_eval` / `resolve_sig`
      retry only when output mentions `HYPRLAND_INSTANCE_SIGNATURE`. Also retry on
      `Couldn't connect` so the first rotation at boot doesn't fail when Hyprland isn't ready yet.
- [ ] **Optional** — make `Service.qml` / `install.sh` surface the "live X is newer" failure
      more visibly (currently it only shows as `deployed:false`).
- [ ] If any code changes are made: bump version in `manifest.json`, test on device, and only
      then open a new marketplace update — **after** #13770 is resolved, so the two don't mix.

## After every Omarchy update

```sh
omarchy plugin list | grep tablet
omarchy-shell tablet status
```
