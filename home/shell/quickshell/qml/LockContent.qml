import QtQuick
import Quickshell

// What the lock screen shows (one per monitor): the wallpaper blurred, a
// big soft clock + date, and a frosted password pill.
//
// Motion: the clock rises in on a spring, the pill buds from a circle into
// a pill like the shell's drawers, dots pop in as you type, a wrong
// password shakes the pill and flushes its rim coral, and on success
// everything floats up and fades before the lock is released.
Item {
    id: root

    required property var auth        // LockScreen.qml: submit(), state
    property bool shown: false         // drives the entrance
    property bool leaving: false       // drives the exit

    Component.onCompleted: { shown = true; input.forceActiveFocus(); }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ── background ──────────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: Theme.bg }
    // Pre-blurred at build time (smooth, and free at runtime).  Stays
    // solid while the content leaves: fading it would flash the lock's dark
    // backing before the desktop comes back.
    Image {
        anchors.fill: parent
        source: Theme.wallpaperBlurred
        fillMode: Image.PreserveAspectCrop
    }

    // ── clock + date ────────────────────────────────────────────────────
    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.5 - 300 + (root.shown && !root.leaving ? 0 : 40) - (root.leaving ? 80 : 0)
        opacity: root.shown && !root.leaving ? 1 : 0
        Behavior on y { SpringAnimation { spring: 2.6; damping: 0.28; epsilon: 0.2 } }
        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        spacing: -10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Qt.rgba(0.925, 0.957, 0.969, 0.72)
            font { family: "Quicksand"; weight: Font.Medium; pixelSize: 190 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.rgba(0.925, 0.957, 0.969, 0.65)
            font { family: "Quicksand"; weight: Font.Medium; pixelSize: 22 }
        }
    }

    // ── password pill ───────────────────────────────────────────────────
    TextInput {
        id: input
        visible: false
        echoMode: TextInput.Password
        enabled: root.auth.state !== "checking" && !root.leaving
        onAccepted: if (text !== "") root.auth.submit(text)
        Keys.onEscapePressed: { text = ""; Shell.lockPreview = false; }
    }
    // Keep focus even if something steals it.
    onActiveFocusChanged: if (!input.activeFocus) input.forceActiveFocus()

    Connections {
        target: root.auth
        function onFailed() { input.text = ""; shake.restart(); }
        function onSucceeded() { root.leaving = true; }
    }

    Item {
        id: pillHolder
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.5 + 70
        width: 340
        height: 54

        Rectangle {
            id: pill
            readonly property real fullW: 320
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: shakeX
            property real shakeX: 0
            // Bud: a circle that stretches into the pill.
            width: root.shown && !root.leaving ? fullW : height
            height: 50
            radius: height / 2
            scale: root.leaving ? 1.15 : (root.shown ? 1 : 0.6)
            opacity: root.shown && !root.leaving ? 1 : 0
            Behavior on width { SpringAnimation { spring: 3.2; damping: 0.3; epsilon: 0.3 } }
            Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.35; epsilon: 0.005 } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            color: Qt.rgba(0.55, 0.68, 0.74, root.auth.state === "checking" ? 0.48 : 0.38)
            border.width: 1
            border.color: root.auth.state === "failed" ? Theme.red : Qt.rgba(1, 1, 1, 0.55)
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // Checking: a soft pulse.
            SequentialAnimation on opacity {
                running: root.auth.state === "checking"
                loops: Animation.Infinite
                NumberAnimation { to: 0.75; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
            }

            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: root.auth.state === "failed" ? "try again" : "password"
                color: root.auth.state === "failed" ? Theme.red : Qt.rgba(1, 1, 1, 0.6)
                font { family: "Quicksand"; weight: Font.Medium; pixelSize: 16 }
            }

            Row {
                anchors.centerIn: parent
                spacing: 9
                Repeater {
                    model: Math.min(input.text.length, 20)
                    delegate: Rectangle {
                        width: 10; height: 10; radius: 5
                        color: Qt.rgba(1, 1, 1, 0.92)
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale { SpringAnimation { spring: 6; damping: 0.3; epsilon: 0.01 } }
                    }
                }
            }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: pill; property: "shakeX"; to: -16; duration: 60; easing.type: Easing.OutQuad }
            NumberAnimation { target: pill; property: "shakeX"; to: 13; duration: 80; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "shakeX"; to: -8; duration: 80; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "shakeX"; to: 4; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: pill; property: "shakeX"; to: 0; duration: 60; easing.type: Easing.OutQuad }
        }
    }

    // PAM's own words (e.g. account locked), when it has any.
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: pillHolder.bottom; topMargin: 14 }
        text: root.auth.message
        visible: text !== ""
        color: Qt.rgba(1, 1, 1, 0.65)
        font { family: "Quicksand"; weight: Font.Medium; pixelSize: 14 }
    }
}
