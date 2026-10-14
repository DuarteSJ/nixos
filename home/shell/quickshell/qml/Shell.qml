pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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

    // Screen of the focused Hyprland monitor (popups open there).
    readonly property var focusedScreen:
        Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // Pick up a recording already running when the shell (re)starts.  The
    // screenrec script sends `rec stop` whenever its recorder exits.
    Process {
        running: true
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => recording = code === 0
    }
}
