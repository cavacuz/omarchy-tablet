import QtQuick
import Quickshell.Io

Item {
  id: root

  // Injected by omarchy-shell (service loader).
  property var shell: null
  property var manifest: null

  property bool deployed: false

  // The plugin root (same directory as this Service.qml). The shell strips
  // sourceDir from public manifests, so resolve from our own location.
  readonly property string pluginDir: {
    var u = Qt.resolvedUrl(".").toString()
    if (u.indexOf("file://") === 0) u = u.substring(7)
    return u
  }

  function run(cmd) {
    runner.command = ["bash", "-lc", cmd]
    runner.running = true
  }

  function deployCmd() {
    // File install + service enable. Runs once (marker in user state).
    // Otherwise never touches anything after the stack is up.
    return 'set -e; ' +
      'M="$HOME/.local/state/omarchy-tablet/deployed"; ' +
      'if [[ ! -f $M ]]; then ' +
      '  /bin/bash ' + JSON.stringify(pluginDir + "/install.sh") + ' --no-sudo --quiet; ' +
      '  mkdir -p "$(dirname "$M")"; : > "$M"; ' +
      'fi; ' +
      'systemctl --user enable --now auto-rotate.service lisgd-gestures.service touch-cursor.service && ' +
      'systemctl --user is-active auto-rotate.service'
  }

  Process {
    id: runner
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(code) { root.deployed = code === 0 }
  }

  Component.onCompleted: run(deployCmd())

  IpcHandler {
    target: "tablet"

    function status(): string {
      return JSON.stringify({ deployed: root.deployed })
    }

    function deploy(): string {
      run(deployCmd())
      return "deploying"
    }

    function restart(): string {
      run("systemctl --user restart auto-rotate.service lisgd-gestures.service touch-cursor.service")
      return "restarted"
    }
  }
}