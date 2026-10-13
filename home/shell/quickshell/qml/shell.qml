//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    SessionMenu {}
    Launcher {}
    Notifications {}
    Osd { id: osd }

    // qs -c shell ipc call <target> <function>
    IpcHandler {
        target: "bar"
        function toggle(): void { Shell.barVisible = !Shell.barVisible; }
        function reveal(): void { Shell.barVisible = true; }
        function hide(): void { Shell.barVisible = false; }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Shell.sessionOpen = !Shell.sessionOpen; }
        function open(): void { Shell.sessionOpen = true; }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Shell.launcherOpen = !Shell.launcherOpen; }
    }
    IpcHandler {
        target: "osd"
        function brightness(): void { osd.showBrightness(); }
    }
    IpcHandler {
        target: "rec"
        function start(): void { Shell.recording = true; }
        function stop(): void { Shell.recording = false; }
    }
}
