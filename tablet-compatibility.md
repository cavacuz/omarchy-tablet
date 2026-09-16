# Tablet compatibility list

Tested devices for the Tablet Companion stack (SAM OSK, tablet mode,
auto-rotate, page scrolling). Add yours with a PR — see
[Adding a device](#adding-a-device).

## Tested

| Device | Touch device (Hyprland name) | Internal display | Tablet mode | Auto-rotate | Page scroll | Notes |
|--------|------------------------------|-----------------|:-----------:|:-----------:|:-----------:|-------|
| Lenovo IdeaPad Duet 3 10IGL5 (82AT) | `ftsc1015:00-2808:1015` (kernel `ftsc1015`) | `DSI-1` (1200×1920) | ✅ | ✅ | ✅ | OSK backend `custom` (SAM). Detachable keyboard reports as `hailuck-co.-ltd-duet-3-usb-composite-device` (+ `-touchpad`); keyboard/touchpad come and go with the cover. |

## Untested / reported

*None yet — be the first to add a row.*

## Adding a device

1. Run the detection and grab the values the plugin actually sees:

   ```sh
   source tablet/tablet-devices.sh && echo "$TABLET_FINGER $TABLET_KBD $TABLET_OUTPUT"
   ```

   (cross-check with `hyprctl devices` → `Touch devices` / `Monitors`.)
2. Add a row to the **Tested** table with your device name, the detected
   touch/kernel name, the internal display, and what works. Use `⚠️` for a
   partially working feature instead of ✅.
3. Open a PR against `tablet-compatibility.md`. Keep the table sorted by
   vendor/model.