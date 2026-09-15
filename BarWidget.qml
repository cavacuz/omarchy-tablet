import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cavacuz.tablet"

  property bool tabletOn: false
  property bool rotateLocked: false

  function refresh() {
    tabletStatusProc.running = true
    lockStatusProc.running = true
  }

  Process {
    id: tabletStatusProc
    command: ["bash", "-lc", "$HOME/.config/hypr/scripts/tablet-mode.sh status"]
    stdout: StdioCollector { waitForEnd: true }
    onStreamFinished: root.tabletOn = (text.trim() === "on")
  }

  Process {
    id: lockStatusProc
    command: ["bash", "-lc",
      "test -f \"$HOME/.local/state/omarchy/toggles/hypr/rotate-lock\" \
       && echo locked || echo free"]
    stdout: StdioCollector { waitForEnd: true }
    onStreamFinished: root.rotateLocked = (text.trim() === "locked")
  }

  Timer {
    id: refreshTimer
    interval: 600
    repeat: false
    onTriggered: root.refresh()
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(2)

    BarIconButton {
      id: tabletButton
      bar: root.bar
      text: "\uf10a"
      active: root.tabletOn
      tooltipText: root.tabletOn ? "Tablet mode ON (click to exit)" : "Tablet mode OFF (click to enter)"
      onPressed: function(button) {
        if (button !== Qt.LeftButton || !root.bar) return
        root.bar.run("~/.config/hypr/scripts/tablet-mode.sh toggle")
        refreshTimer.restart()
      }
    }

    BarIconButton {
      id: rotateButton
      bar: root.bar
      text: "\uf023"
      active: root.rotateLocked
      tooltipText: root.rotateLocked ? "Auto-rotate LOCKED (click to unlock)" : "Auto-rotate live (click to lock)"
      onPressed: function(button) {
        if (button !== Qt.LeftButton || !root.bar) return
        root.bar.run(
          "L=\"$HOME/.local/state/omarchy/toggles/hypr/rotate-lock\"; " +
          "if [[ -f $L ]]; then rm -f \"$L\"; else mkdir -p \"$(dirname \"$L\")\"; : > \"$L\"; fi; " +
          "systemctl --user restart auto-rotate.service")
        refreshTimer.restart()
      }
    }
  }

  implicitWidth: row.implicitWidth
  implicitHeight: bar ? bar.barSize : Style.bar.sizeHorizontal

  Component.onCompleted: refresh()
}