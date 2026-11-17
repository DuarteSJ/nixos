import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

// What the lock screen shows (LockScreen.qml puts one on every monitor),
// in the session menu's style: the lock wallpaper blurred and dimmed, a
// thin clock with the date in accent, a password pill, the battery in the
// corner and, while Spotify has a track, a now-playing card with controls.
//
// Type the password and Enter.  Each character pops in as a dot; while
// it is checked the dots breathe and the rim turns orange; a wrong one
// shakes the pill red and clears it.  Esc clears it (and closes a preview).
Item {
    id: root

    required property var auth           // LockScreen.qml's authCtl
    required property bool preview

    readonly property bool failed: auth.state === "failed"
    readonly property bool checking: auth.state === "checking"

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Connections {
        target: root.auth
        function onFailed() { input.text = ""; shake.restart(); }
    }

    // Clicking anywhere gives the keyboard back to the pill.
    MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }

    // ── background ──────────────────────────────────────────────────────
    Image {
        id: wall
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/Pictures/lock-screen/minimal-mountain.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: -0.15
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.bg, 0.25) }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.bg, 0.65) }
        }
    }

    // Everything on top fades in when the screen appears.
    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        Component.onCompleted: enter.start()
        NumberAnimation { id: enter; target: stage; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }

        // ── battery (top right) ─────────────────────────────────────────
        // A chip like the media card: a drawn battery that fills with the
        // level (green / yellow / red, accent on mains, bolt while charging),
        // then the percentage and what the power is doing.
        Rectangle {
            id: battery
            readonly property bool onMains: Stats.charging || Stats.plugged
            readonly property real level: Math.max(0, Math.min(100, Stats.batPct)) / 100
            readonly property color tone: onMains ? Theme.accent
                                        : Stats.batPct < 15 ? Theme.red
                                        : Stats.batPct < 30 ? Theme.yellow : Theme.green

            anchors { top: parent.top; right: parent.right; margins: 24 }
            visible: Stats.batPct >= 0
            width: batRow.implicitWidth + 28
            height: 40
            radius: height / 2
            color: Theme.alpha(Theme.surface, 0.72)
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.08)

            Row {
                id: batRow
                anchors.centerIn: parent
                spacing: 10

                // body + nub
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 15
                    Rectangle {
                        id: body
                        width: 27; height: 15
                        radius: 4
                        color: "transparent"
                        border.width: 1.5
                        border.color: Theme.alpha(Theme.fg, 0.55)
                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 3 }
                            width: Math.max(2, (parent.width - 6) * battery.level)
                            radius: 1.5
                            color: battery.tone
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: Stats.charging
                            icon: "bolt"
                            size: 13
                            filled: true
                            color: Theme.fgBright
                            style: Text.Outline
                            styleColor: Theme.alpha(Theme.bg, 0.8)
                        }
                    }
                    Rectangle {
                        anchors { left: body.right; leftMargin: 1; verticalCenter: body.verticalCenter }
                        width: 2; height: 6
                        radius: 1
                        color: Theme.alpha(Theme.fg, 0.55)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Stats.batPct + "%"
                    color: Theme.fgBright
                    font { family: Theme.font; pixelSize: 14; bold: true }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Stats.charging ? "charging" : Stats.plugged ? "plugged in" : "on battery"
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: 12; letterSpacing: 0.5 }
                }
            }
        }

        // ── clock, date, password ───────────────────────────────────────
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: -40 }
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.fgBright
                font { family: Theme.font; pixelSize: 132; weight: Font.Light }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase()
                color: Theme.accent
                font { family: Theme.font; pixelSize: 17; letterSpacing: 1.5 }
            }

            Item { width: 1; height: 54 }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300; height: 54
                radius: height / 2
                color: Theme.alpha(Theme.surface, 0.72)
                border.width: root.failed || root.checking || input.activeFocus ? 2 : 1
                border.color: root.failed ? Theme.red
                            : root.checking ? Theme.orange
                            : input.activeFocus ? Theme.alpha(Theme.accent, 0.6)
                            : Theme.alpha(Theme.fg, 0.08)
                Behavior on border.color { ColorAnimation { duration: 160 } }
                transform: Translate { id: shift }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shift; property: "x"; to: -14; duration: 45 }
                    NumberAnimation { target: shift; property: "x"; to: 11; duration: 70 }
                    NumberAnimation { target: shift; property: "x"; to: -7; duration: 70 }
                    NumberAnimation { target: shift; property: "x"; to: 4; duration: 60 }
                    NumberAnimation { target: shift; property: "x"; to: 0; duration: 50 }
                }

                Icon {
                    anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                    icon: "lock"
                    size: 19
                    filled: root.checking
                    color: root.failed ? Theme.red : root.checking ? Theme.orange : Theme.muted
                }

                // The real input stays invisible; the dots below stand in.
                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0
                    echoMode: TextInput.Password
                    cursorVisible: false
                    readOnly: root.checking
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            root.auth.submit(input.text);
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Escape) {
                            if (root.preview && input.text === "") Shell.lockPreview = false;
                            input.text = "";
                            e.accepted = true;
                        }
                    }
                }

                Row {
                    id: dots
                    anchors.centerIn: parent
                    spacing: 7
                    // Breathe while the password is being checked.
                    SequentialAnimation on opacity {
                        running: root.checking
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) dots.opacity = 1
                        NumberAnimation { to: 0.35; duration: 450; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 450; easing.type: Easing.InOutSine }
                    }
                    Repeater {
                        model: Math.min(input.text.length, 18)
                        Rectangle {
                            width: 9; height: 9; radius: 4.5
                            color: Theme.fgBright
                            scale: 0
                            Component.onCompleted: pop.start()
                            NumberAnimation on scale { id: pop; running: false; to: 1; duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: input.text === "" && !root.checking
                    text: root.failed ? "wrong password" : "password"
                    color: root.failed ? Theme.red : Theme.muted
                    font { family: Theme.font; pixelSize: 14; letterSpacing: 1 }
                }
            }
        }

        // ── now playing ─────────────────────────────────────────────────
        readonly property var player: Mpris.players.values.find(p =>
            p.identity.toLowerCase().includes("spotify") || p.dbusName.toLowerCase().includes("spotify")) ?? null

        Rectangle {
            id: card
            readonly property var player: stage.player
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 44 }
            visible: player !== null && player.trackTitle !== "" && player.playbackState !== MprisPlaybackState.Stopped
            width: row.implicitWidth + 24
            height: 80
            radius: 22
            color: Theme.alpha(Theme.surface, 0.72)
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.08)

            Row {
                id: row
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 14

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 56; height: 56
                    radius: 14
                    color: Theme.alpha(Theme.bg, 0.6)
                    Image {
                        anchors.fill: parent
                        source: card.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize { width: 112; height: 112 }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Math.max(title.implicitWidth, artist.implicitWidth), 260)
                    spacing: 3
                    Text {
                        id: title
                        width: parent.width
                        text: card.player?.trackTitle ?? ""
                        elide: Text.ElideRight
                        color: Theme.fgBright
                        font { family: Theme.font; pixelSize: 15; bold: true }
                    }
                    Text {
                        id: artist
                        width: parent.width
                        text: card.player?.trackArtist ?? ""
                        elide: Text.ElideRight
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: 13 }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: [
                            { icon: "skip_previous", ok: card.player?.canGoPrevious ?? false, act: () => card.player.previous() },
                            { icon: card.player?.isPlaying ? "pause" : "play_arrow", ok: card.player?.canTogglePlaying ?? false, act: () => card.player.togglePlaying() },
                            { icon: "skip_next", ok: card.player?.canGoNext ?? false, act: () => card.player.next() },
                        ]
                        Rectangle {
                            required property var modelData
                            required property int index
                            width: 38; height: 38; radius: 19
                            color: btnMouse.containsMouse && modelData.ok ? Theme.glassFillStrong : "transparent"
                            opacity: modelData.ok ? 1 : 0.35
                            Icon {
                                anchors.centerIn: parent
                                icon: parent.modelData.icon
                                size: parent.index === 1 ? 26 : 22
                                filled: true
                                color: parent.index === 1 ? Theme.fgBright : Theme.fg
                            }
                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: parent.modelData.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (parent.modelData.ok) parent.modelData.act();
                                    input.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
