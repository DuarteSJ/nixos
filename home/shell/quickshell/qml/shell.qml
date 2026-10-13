//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    // Per monitor: the glass frame, plus invisible strips reserving its
    // edges so tiled windows sit inside the hole.
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: perScreen
            required property var modelData
            Frame { modelData: perScreen.modelData }
            Reserve { modelData: perScreen.modelData; edge: "top"; size: Theme.barHeight; visible: Shell.barVisible }
            Reserve { modelData: perScreen.modelData; edge: "left"; visible: Shell.barVisible }
            Reserve { modelData: perScreen.modelData; edge: "right"; visible: Shell.barVisible }
            Reserve { modelData: perScreen.modelData; edge: "bottom"; visible: Shell.barVisible }
        }
    }

    SessionMenu {}
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
        function toggle(): void {
            if (!Shell.launcherOpen) Shell.launcherScreen = Hyprland.focusedMonitor?.name ?? "";
            Shell.launcherOpen = !Shell.launcherOpen;
        }
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
