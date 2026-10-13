pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell-wide UI state, flipped over IPC (see shell.qml).
Singleton {
    property bool barVisible: true
    property bool sessionOpen: false
    property bool recording: false

    // Pick up a recording already running when the shell (re)starts.
    Process {
        running: true
        command: ["test", "-e", "/tmp/screenrec-recording"]
        onExited: code => recording = code === 0
    }
}
