import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Full-screen dimmed overlay with lock / suspend / logout / reboot / off.
// h/l or arrows to move, Enter to pick, Esc or a click outside to leave.
PanelWindow {
    id: menu

    // Lock is the shell's own lock screen (LockScreen.qml); sleep locks
    // first so the machine wakes up locked.  Logout uses the Lua dispatcher
    // Hyprland 0.55 expects.
    readonly property var actions: [
        { icon: "lock",               label: "lock",      lock: true },
        { icon: "bedtime",            label: "sleep",     lock: true, cmd: ["sh", "-c", "sleep 0.8; systemctl suspend"] },
        { icon: "logout",             label: "log out",   cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { icon: "restart_alt",        label: "restart",   cmd: ["systemctl", "reboot"] },
        { icon: "power_settings_new", label: "shut down", cmd: ["systemctl", "poweroff"] },
    ]
    property int selected: 0

    function run(i) {
        Shell.sessionOpen = false;
        if (actions[i].lock) Shell.locked = true;
        if (actions[i].cmd) Quickshell.execDetached(actions[i].cmd);
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Shell.sessionOpen
    onVisibleChanged: if (visible) { selected = 0; keys.forceActiveFocus(); }
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "qs-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.82)
        opacity: Shell.sessionOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Shell.sessionOpen = false
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape || e.key === Qt.Key_Q) Shell.sessionOpen = false;
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Backtab)
                menu.selected = (menu.selected + menu.actions.length - 1) % menu.actions.length;
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab)
                menu.selected = (menu.selected + 1) % menu.actions.length;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                menu.run(menu.selected);
            e.accepted = true;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 36

        scale: Shell.sessionOpen ? 1 : 0.94
        opacity: Shell.sessionOpen ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.fgBright
                font { family: Theme.mono; pixelSize: 72; weight: Font.Light }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase()
                color: Theme.accent
                font { family: Theme.mono; pixelSize: 15; letterSpacing: 1 }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22

            Repeater {
                model: menu.actions

                delegate: Column {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool active: menu.selected === index
                    spacing: 12

                    Rectangle {
                        width: 92; height: 92
                        radius: 28
                        color: btn.active ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.85)
                        border.width: btn.active ? 2 : 1
                        border.color: btn.active ? Theme.accent : Theme.alpha(Theme.fg, 0.08)
                        scale: btn.active ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 160 } }

                        Icon {
                            anchors.centerIn: parent
                            icon: btn.modelData.icon
                            size: 34
                            filled: btn.active
                            color: btn.active ? Theme.accent : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: menu.selected = btn.index
                            onClicked: menu.run(btn.index)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.label
                        color: btn.active ? Theme.fgBright : Theme.muted
                        font { family: Theme.mono; pixelSize: 12; letterSpacing: 0.5 }
                    }
                }
            }
        }
    }
}
