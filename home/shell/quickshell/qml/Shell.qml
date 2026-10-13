pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell-wide UI state, flipped over IPC (see shell.qml).
Singleton {
    property bool barVisible: true       // Super+B
    property bool focusMode: false       // focus mode (Super+/) hides it too
    readonly property bool barShown: barVisible && !focusMode
    property bool sessionOpen: false
    property bool launcherOpen: false
    property bool recording: false
    property bool dashboard: false       // every status panel open (Super+W)
    property string dashboardScreen: ""  // ...on this monitor (focused at toggle)

    // Pick up a recording already running when the shell (re)starts.
    Process {
        running: true
        command: ["test", "-e", "/tmp/screenrec-recording"]
        onExited: code => recording = code === 0
    }
}
