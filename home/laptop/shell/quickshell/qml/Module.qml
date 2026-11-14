import QtQuick

// A bar module: a nerd-font glyph (+ optional label), clickable, with a
// few ways to show state without numbers:
//   badge      small dot on the glyph's top-right (transparent = none)
//   level      0..1 shown as a 2 px bar under the glyph while levelShown
//   busy       gentle breathing (e.g. wifi connecting)
//   critical   red + blinking
Item {
    id: root

    property string glyph
    property color glyphColor: Theme.fg
    property string label
    property color labelColor: Theme.muted
    property bool critical: false
    property bool busy: false
    property color badge: "transparent"
    property real level: -1
    property bool levelShown: false
    // The pointer is on it.  Not just containsMouse: a hidden bar gets no
    // pointer-leave, so that would stay stale (and reopen panels) when the
    // bar comes back.  Reset on hide; re-armed by real pointer motion.
    property bool hovered: false
    Connections {
        target: Shell
        function onBarShownChanged() { if (!Shell.barShown) root.hovered = false; }
    }

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        // Blinks when critical, breathes when busy.
        SequentialAnimation on opacity {
            running: root.critical || root.busy
            loops: Animation.Infinite
            onRunningChanged: if (!running) row.opacity = 1
            NumberAnimation { to: root.critical ? 0.35 : 0.45; duration: root.critical ? 500 : 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: root.critical ? 500 : 800; easing.type: Easing.InOutSine }
        }

        Text {
            id: glyphText
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: root.critical ? Theme.red : root.glyphColor
            font { family: Theme.font; pixelSize: Theme.barFontSize }
            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
                visible: root.badge.a > 0
                width: 6; height: 6; radius: 3
                color: root.badge
                border.width: 1
                border.color: Theme.bg
                x: parent.width - 3
                y: 2
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.critical ? Theme.red : (root.hovered ? Theme.fg : root.labelColor)
            font { family: Theme.font; pixelSize: Theme.barFontSize }
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    // Level bar under the glyph.
    Rectangle {
        x: glyphText.x
        y: parent.height - 4
        width: glyphText.width
        height: 2
        radius: 1
        color: Theme.glassFillStrong
        opacity: root.levelShown && root.level >= 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.levelShown ? 120 : 400 } }
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.level))
            height: parent.height
            radius: 1
            color: root.critical ? Theme.red : root.glyphColor
            Behavior on width { NumberAnimation { duration: 90 } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPositionChanged: root.hovered = true
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w)
    }
}
