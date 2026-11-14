import QtQuick
import Quickshell
import Quickshell.Wayland

// Full-screen dimmed overlay with lock / suspend / hibernate / logout / reboot / off.
// Type what you want ("off", "reboot", "sleep"...): the first action with a
// word starting with the text is picked, Enter runs it.  Everything but lock
// asks first: Enter (or y) again to confirm, Esc to back out.  Arrows/Tab
// still move, clicks still work (one that needs confirming asks the same way).  Esc or a
// click outside leaves.
PanelWindow {
    id: menu

    // Suspend and hibernate lock on their own (hypridle locks before every
    // sleep, see hypridle.nix), lock is the shell's own (LockScreen.qml), and
    // logout uses the Lua dispatcher Hyprland 0.55 expects.  `words` are
    // what typing matches against.
    readonly property var actions: [
        { icon: "lock",               label: "lock",      needsConfirm: false, words: ["lock"],
          run: () => Shell.locked = true },
        { icon: "bedtime",            label: "sleep",     needsConfirm: true,  words: ["sleep", "suspend"],
          cmd: ["systemctl", "suspend"] },
        { icon: "save",               label: "hibernate", needsConfirm: true,  words: ["hibernate"],
          cmd: ["systemctl", "hibernate"] },
        { icon: "logout",             label: "log out",   needsConfirm: true,  words: ["log out", "logout", "exit", "quit"],
          cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { icon: "restart_alt",        label: "restart",   needsConfirm: true,  words: ["restart", "reboot"],
          cmd: ["systemctl", "reboot"] },
        { icon: "power_settings_new", label: "shut down", needsConfirm: true,  words: ["shut down", "shutdown", "power off", "poweroff", "off"],
          cmd: ["systemctl", "poweroff"] },
    ]
    property int selected: 0
    property string query: ""
    property int confirming: -1           // index waiting for a second Enter

    function matches(i) {
        const q = query.trim().toLowerCase();
        return q === "" || actions[i].words.some(w => w.startsWith(q));
    }
    onQueryChanged: {
        confirming = -1;
        selected = actions.findIndex((a, i) => matches(i));
    }

    function pick(i) {
        if (i < 0) return;
        if (actions[i].needsConfirm && confirming !== i) {
            selected = i;
            confirming = i;
            return;
        }
        Shell.sessionOpen = false;
        if (actions[i].run) actions[i].run(); else Quickshell.execDetached(actions[i].cmd);
    }
    // Saying no starts over: the typed text goes too.
    function cancel() {
        confirming = -1;
        input.text = "";
    }
    function step(d) {
        confirming = -1;
        const n = actions.length;
        let i = selected < 0 ? (d > 0 ? -1 : 0) : selected;
        for (let k = 0; k < n; k++) {
            i = (i + d + n) % n;
            if (matches(i)) { selected = i; return; }
        }
    }

    screen: Shell.focusedScreen
    visible: Shell.sessionOpen
    onVisibleChanged: if (visible) { input.text = ""; query = ""; confirming = -1; selected = 0; input.forceActiveFocus(); }
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
                font { family: Theme.font; pixelSize: 72; weight: Font.Light }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase()
                color: Theme.accent
                font { family: Theme.font; pixelSize: 15; letterSpacing: 1 }
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
                    readonly property bool asking: menu.confirming === index
                    readonly property color tint: asking ? Theme.red : Theme.accent
                    spacing: 12
                    // Typed text that doesn't fit this one fades it back.
                    opacity: menu.matches(index) ? 1 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    Rectangle {
                        width: 92; height: 92
                        radius: 28
                        color: btn.active ? Theme.alpha(btn.tint, 0.16) : Theme.alpha(Theme.surface, 0.85)
                        border.width: btn.active ? 2 : 1
                        border.color: btn.active ? btn.tint : Theme.alpha(Theme.fg, 0.08)
                        scale: btn.active ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 160 } }

                        Icon {
                            anchors.centerIn: parent
                            icon: btn.modelData.icon
                            size: 34
                            filled: btn.active
                            color: btn.active ? btn.tint : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                if (menu.confirming !== btn.index) menu.confirming = -1;
                                menu.selected = btn.index;
                            }
                            onClicked: menu.pick(btn.index)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.label
                        color: btn.active ? Theme.fgBright : Theme.muted
                        font { family: Theme.font; pixelSize: 12; letterSpacing: 0.5 }
                    }
                }
            }
        }

        // ── what you type / the confirmation ────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 420
            height: 26

            TextInput {
                id: input
                anchors.fill: parent
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                visible: menu.confirming < 0
                color: menu.selected < 0 ? Theme.red : Theme.fgBright
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                font { family: Theme.font; pixelSize: 18; letterSpacing: 0.5 }
                onTextChanged: menu.query = text

                Keys.onPressed: e => {
                    const asking = menu.confirming >= 0;
                    if (e.key === Qt.Key_Escape) {
                        if (asking) menu.cancel(); else Shell.sessionOpen = false;
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        menu.pick(asking ? menu.confirming : menu.selected);
                    } else if (asking && e.key === Qt.Key_Y) {
                        menu.pick(menu.confirming);
                    } else if (asking && e.key === Qt.Key_N) {
                        menu.cancel();
                    } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                        menu.step(1);
                    } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                        menu.step(-1);
                    } else {
                        // While asking, other keys don't type; Backspace backs out.
                        if (asking && e.key === Qt.Key_Backspace) menu.cancel();
                        e.accepted = asking;
                        return;
                    }
                    e.accepted = true;
                }
            }

            Row {
                anchors.centerIn: parent
                visible: menu.confirming >= 0
                spacing: 14
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.confirming >= 0 ? menu.actions[menu.confirming].label + "?" : ""
                    color: Theme.red
                    font { family: Theme.font; pixelSize: 18; bold: true; letterSpacing: 0.5 }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵ / y confirm   ·   esc / n cancel"
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: 13; letterSpacing: 0.5 }
                }
            }
        }
    }
}
