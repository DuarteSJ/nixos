import QtQuick

// Glass slider: translucent track, accent fill, white knob.  `value` is 0..1
// (values above 1 just show a full track); `moved(v)` fires while dragging,
// clicking or scrolling (1% per notch).
Item {
    id: s

    property real value: 0
    property color fill: Theme.accent
    signal moved(real v)

    implicitHeight: 22

    function setFromX(x) { s.moved(Math.max(0, Math.min(1, x / track.width))); }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 8
        radius: 4
        color: Theme.glassFill
        border.width: 1
        border.color: Theme.glassEdge

        Rectangle {
            width: Math.max(height, parent.width * Math.min(1, s.value))
            height: parent.height
            radius: 4
            color: s.fill
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
    Rectangle {
        x: track.width * Math.min(1, s.value) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: drag.pressed ? 18 : 16; height: width; radius: width / 2
        color: Theme.fgBright
        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onPressed: m => s.setFromX(m.x - 4)
        onPositionChanged: m => { if (pressed) s.setFromX(m.x - 4); }
        onWheel: w => s.moved(Math.max(0, Math.min(1, Math.round(s.value * 100 + (w.angleDelta.y > 0 ? 1 : -1)) / 100)))
    }
}
