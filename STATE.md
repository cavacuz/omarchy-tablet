# omarchy-tablet — project state

## Current version: 0.3.1

## What this plugin does

Omarchy plugin for 2-in-1 convertible laptops. Provides:
- **SAM OSK** — custom GTK4 on-screen keyboard (`kbd/`)
- **Tablet mode** — disable keyboard/touchpad, auto-rotate, touch gestures, cursor warp (`tablet/`)
- **Page scrolling** — 3-finger workspace switching (`tablet/page-switch.sh`)
- **Bar widget** — single tablet icon → group popup with controls + keybinding editor
- **Systemd services** — `auto-rotate`, `lisgd-gestures`, `touch-cursor`
- **Health check** — `tablet-verify.sh` (read-only) + `--fix` mode

## Machine status (cavacuz)

- Plugin installed at `~/.config/omarchy/plugins/cavacuz.tablet/` ✅
- All 3 systemd services active + enabled ✅
- Device detection: touch=`ftsc1015:00-2808:1015`, display=`DSI-1` (1200×1920 portrait)
- OSK backend: `custom` (SAM OSK)
- Keybindings: `SUPER+SHIFT+T` (tablet), `SUPER+B` (OSK), `SUPER+SHIFT+P` (pen)
- `tablet-verify.sh` → ALL GREEN
- Shell restarted (`omarchy-restart-shell`): quickshell by-id dir `lcvn58glt`, widget loads with 1 icon, no errors in log
- Plugin page image: `preview.png` (copy of `omarchy-tablet.png`) at repo root, synced to live plugin dir — marketplace convention requires the root file be named `preview.{png,jpg,jpeg,webp,avif}`
- Compatibility list: `tablet-compatibility.md` (Lenovo IdeaPad Duet 3 10IGL5 = first tested row; PR instructions included) — linked from README

## What changed in this session

### 1. Fixed the missing bar widget (compile bug)
`BarWidget.qml` had `onStreamFinished` on the `Process` object instead of inside `StdioCollector`. That made the widget fail to compile (`BarWidget.qml:22:5`), so the shell fell back to a zero-size invisible slot.

**Fix:** moved handlers inside collectors:
```qml
Process {
  stdout: StdioCollector {
    waitForEnd: true
    onStreamFinished: root.tabletOn = (text.trim() === "on")
  }
}
```

### 2. Added keybinding editor (gear button → now integrated into group popup)
- `tablet/tablet-keybindings.conf` — user-editable shortcut list (`NAME=MODS+KEY`)
- `tablet/keybindings-apply.sh` — regenerates the tablet block in `bindings.lua` + `hyprctl reload`
- `tablet/keybindings-set.sh` — writes conf + calls apply (used by Save button in the popup)
- Popup shows current bindings, lets user edit and save; changes apply live via `hyprctl reload`

### 3. Grouped into single bar button
Replaced 3 separate bar buttons (tablet toggle, rotate lock, gear) with:
- **One tablet icon** in the bar (highlights when tablet mode is ON)
- **Tap** → opens a group popup with:
  - Tablet mode toggle row (full-width `Button`, `leftAlign`, bordered, highlighted when active)
  - Auto-rotate lock toggle row (same style)
  - `PanelSeparator`
  - Keybindings editor (3 TextFields + Reset/Save + format hint)
- Helper functions `toggleTablet()` / `toggleRotateLock()` hold the toggle logic that used to live on the 3 buttons.
- Live widget deployed + shell restarted → confirmed 1 icon in bar, no widget errors in the log.

### 4. install.sh updates
- Deploys new scripts (`keybindings-apply.sh`, `keybindings-set.sh`)
- Deploys `tablet-keybindings.conf` (created once on first install, never overwritten on reinstall)
- Bindings in `bindings.lua` now generated from the conf file (single source of truth)

## Key gotchas from this session

### Live reload NEVER picks up bar-widget source changes — restart the shell
The shell's "Local plugin changed, reloading" flow (`shell.qml` → `reloadPlugins()` →
`Qt.clearComponentCache()` + rescan → `syncPluginWidgets()`) does **not** rebuild a
widget whose entry point URL is unchanged. In `syncPluginWidgets` (shell.qml:1394-1428),
`existing.url === url` short-circuits to re-registering the same cached compiled
component. Copying a new `BarWidget.qml` over the old one therefore does nothing —
the bar keeps showing the previous widget.

**Fix: `omarchy-restart-shell`** (≈2s, equivalent to a reboot for the shell).
Confirmed working: copying the single-button file showed 3 icons until the shell
restart; after restart, 1 icon.

The `Qt.clearComponentCache()` + plugin-rescan path only works for plugin *enabled/disabled
state* and *manifest* changes, not for QML source edits of an already-loaded widget.

### QML engine stale-cache on first startup (superseded — see above)
The same restart requirement captured the original `onStreamFinished` compile bug:
an initial failed load keeps surfacing until the shell process restarts.

### install.sh + user-editable conf conflict
`tablet-keybindings.conf` is user-editable state — `sync_file` (which backs up newer-live) would FATAL on reinstall. **Treat it like `tablet-devices.conf`**: create-once (`if [[ ! -f ... ]]; then cp ...`), never overwrite.

## Architecture

```
omarchy-tablet/
├── manifest.json          # plugin manifest (kinds: service + bar-widget)
├── Service.qml            # one-time deploy + systemd service keepalive
├── BarWidget.qml          # single bar icon → group popup (controls + keybinding editor)
├── install.sh             # idempotent installer
├── hooks/
│   └── tablet-verify.hook # post-update safety hook (report-only)
├── kbd/                   # SAM OSK
│   ├── custom-kbd.py
│   ├── custom-kbd-toggle.sh
│   ├── osk-toggle.sh      # backend dispatcher
│   └── layouts/en.json
├── tablet/                # tablet wiring
│   ├── tablet-mode.sh     # core toggle (on/off/toggle/status)
│   ├── tablet-modwait.py  # quiescence wait before mode switch
│   ├── tablet-auto-exit.py
│   ├── touch-gestures.sh  # lisgd config
│   ├── auto-rotate.sh     # accelerometer-driven rotation
│   ├── touch-cursor.py    # double-tap focus
│   ├── touch-toggle.sh    # pen/finger toggle
│   ├── page-switch.sh     # 3-finger workspace switching
│   ├── tablet-devices.sh  # device detection
│   ├── tablet.lua         # Hyprland lua config
│   ├── tablet-verify.sh   # health check
│   ├── tablet-verify-interactive.sh
│   ├── tablet-keybindings.conf  # user-editable shortcuts
│   ├── keybindings-apply.sh     # regenerate bindings.lua + hyprctl reload
│   ├── keybindings-set.sh       # write conf + apply (called by Save button)
│   ├── tablet-kbd-uninstall.sh
│   ├── squeekboard-toggle.sh    # legacy fallback
│   ├── wvkbd-toggle.sh          # legacy fallback
│   └── units/
│       ├── auto-rotate.service
│       ├── lisgd-gestures.service
│       └── touch-cursor.service
└── LICENSE                # GPL-3.0
```

## User's stated goals

- A bar button that shows current keybindings and lets the user change them
- Single button in the bar (not three separate buttons) — user explicitly asked for this

## Next / potential work

- User may want to add more bindable shortcuts (OSK backend switching, page-scroll?)
- Keybinding presets could be a future feature
- Pen support: currently just a toggle; full pen support is parked
- The live-reload behavior (shell.qml syncPluginWidgets reusing same-URL components) could
  be improved upstream — e.g. compare a file mtime/hash when URL matches instead of always
  reusing the cached component — but `omarchy-restart-shell` is a reliable workaround.
