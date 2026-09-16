import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cavacuz.tablet"

  property bool tabletOn: false
  property bool rotateLocked: false

  property string tabletKeys: "SUPER+SHIFT+T"
  property string oskKeys: "SUPER+B"
  property string penKeys: "SUPER+SHIFT+P"
  property bool popupOpen: false

  readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

  function refresh() {
    tabletStatusProc.running = true
    lockStatusProc.running = true
  }

  function toggleSettings() {
    root.popupOpen = !root.popupOpen
    if (root.popupOpen) loadBindingsProc.running = true
  }

  function resetDefaults() {
    root.tabletKeys = "SUPER+SHIFT+T"
    root.oskKeys = "SUPER+B"
    root.penKeys = "SUPER+SHIFT+P"
  }

  function close() {
    root.popupOpen = false
  }

  function save() {
    applyProc.command = [
      "bash", root.scriptsDir + "/keybindings-set.sh",
      root.tabletKeys, root.oskKeys, root.penKeys
    ]
    applyProc.running = true
  }

  function toggleTablet() {
    if (!root.bar) return
    root.bar.run("~/.config/hypr/scripts/tablet-mode.sh toggle")
    refreshTimer.restart()
  }

  function toggleRotateLock() {
    if (!root.bar) return
    root.bar.run(
      "L=\"$HOME/.local/state/omarchy/toggles/hypr/rotate-lock\"; " +
      "if [[ -f $L ]]; then rm -f \"$L\"; else mkdir -p \"$(dirname \"$L\")\"; : > \"$L\"; fi; " +
      "systemctl --user restart auto-rotate.service")
    refreshTimer.restart()
  }

  Process {
    id: tabletStatusProc
    command: ["bash", "-lc", "$HOME/.config/hypr/scripts/tablet-mode.sh status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.tabletOn = (text.trim() === "on")
    }
  }

  Process {
    id: lockStatusProc
    command: ["bash", "-lc",
      "test -f \"$HOME/.local/state/omarchy/toggles/hypr/rotate-lock\" \
       && echo locked || echo free"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.rotateLocked = (text.trim() === "locked")
    }
  }

  Process {
    id: loadBindingsProc
    command: ["bash", "-lc",
      "CONF=\"$HOME/.config/hypr/tablet-keybindings.conf\"; " +
      "[[ -f $CONF ]] || exit 0; " +
      "grep -E '^(tablet_toggle|osk_toggle|pen_toggle)=' \"$CONF\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.split('\n')
        for (var i = 0; i < lines.length; i++) {
          var kv = lines[i].split('=')
          if (kv.length < 2) continue
          var name = kv[0].trim()
          var value = kv.slice(1).join('=').trim()
          if (name === "tablet_toggle") root.tabletKeys = value
          else if (name === "osk_toggle") root.oskKeys = value
          else if (name === "pen_toggle") root.penKeys = value
        }
      }
    }
  }

  Process {
    id: applyProc
    onExited: function(code) {
      if (code === 0) {
        root.popupOpen = false
        root.refresh()
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 600
    repeat: false
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: menuButton
    bar: root.bar
    text: "\uf10a"
    active: root.tabletOn
    tooltipText: root.tabletOn ? "Tablet mode ON — click for controls" : "Tablet Companion — click for controls"
    onPressed: function(button) {
      if (button !== Qt.LeftButton || !root.bar) return
      root.toggleSettings()
    }
  }

  PopupCard {
    id: popup
    owner: root
    anchorItem: root
    bar: root.bar
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(controlColumn.implicitHeight)

    Column {
      id: controlColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        width: parent.width
        text: "Tablet Companion"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Button {
        width: parent.width
        leftAlign: true
        bordered: true
        active: root.tabletOn
        selected: root.tabletOn
        iconText: "\uf10a"
        text: root.tabletOn ? "Tablet mode — ON (tap to exit)" : "Tablet mode — OFF (tap to enter)"
        foreground: root.bar.foreground
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.toggleTablet()
      }

      Button {
        width: parent.width
        leftAlign: true
        bordered: true
        active: root.rotateLocked
        selected: root.rotateLocked
        iconText: "\uf023"
        text: root.rotateLocked ? "Auto-rotate — LOCKED (tap to unlock)" : "Auto-rotate — live (tap to lock)"
        foreground: root.bar.foreground
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.toggleRotateLock()
      }

      PanelSeparator {
        width: parent.width
        foreground: root.bar.foreground
      }

      Text {
        width: parent.width
        text: "Keybindings"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }

      Row {
        spacing: Style.space(10)
        width: controlColumn.width

        Text {
          width: Style.space(150)
          anchors.verticalCenter: parent.verticalCenter
          text: "Tablet mode toggle"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }

        TextField {
          width: parent.width - Style.space(160)
          anchors.verticalCenter: parent.verticalCenter
          foreground: root.bar.foreground
          text: root.tabletKeys
          onTextChanged: root.tabletKeys = text
        }
      }

      Row {
        spacing: Style.space(10)
        width: controlColumn.width

        Text {
          width: Style.space(150)
          anchors.verticalCenter: parent.verticalCenter
          text: "On-screen keyboard"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }

        TextField {
          width: parent.width - Style.space(160)
          anchors.verticalCenter: parent.verticalCenter
          foreground: root.bar.foreground
          text: root.oskKeys
          onTextChanged: root.oskKeys = text
        }
      }

      Row {
        spacing: Style.space(10)
        width: controlColumn.width

        Text {
          width: Style.space(150)
          anchors.verticalCenter: parent.verticalCenter
          text: "Finger touch toggle"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
        }

        TextField {
          width: parent.width - Style.space(160)
          anchors.verticalCenter: parent.verticalCenter
          foreground: root.bar.foreground
          text: root.penKeys
          onTextChanged: root.penKeys = text
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Format: MODS+KEY — SUPER, SHIFT, CTRL, ALT (combine with +), e.g. SUPER+SHIFT+T"
        color: Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
      }

      Row {
        spacing: Style.space(8)
        anchors.horizontalCenter: parent.horizontalCenter

        Button {
          iconText: "\uf0e2"
          text: "Reset"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: root.resetDefaults()
        }

        Button {
          iconText: "\uf00c"
          text: "Save"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: root.save()
        }
      }
    }
  }

  implicitWidth: menuButton.implicitWidth
  implicitHeight: bar ? bar.barSize : Style.bar.sizeHorizontal

  Component.onCompleted: refresh()
}