import QtQuick

// Coloured nerd-font glyph + muted label, optionally clickable.
Item {
    id: root

    property string glyph
    property color glyphColor: Theme.fg
    property string label
    property color labelColor: Theme.muted
    property bool critical: false
    readonly property alias hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: root.critical ? Theme.red : root.glyphColor
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.critical ? Theme.red : (mouse.containsMouse ? Theme.fg : root.labelColor)
            font { family: Theme.font; pixelSize: Theme.fontSize }
            Behavior on color { ColorAnimation { duration: 140 } }

            SequentialAnimation on opacity {
                running: root.critical
                loops: Animation.Infinite
                onRunningChanged: if (!running) parent.opacity = 1
                NumberAnimation { to: 0.35; duration: 500 }
                NumberAnimation { to: 1; duration: 500 }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w)
    }
}
