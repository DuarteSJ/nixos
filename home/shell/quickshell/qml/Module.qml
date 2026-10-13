import QtQuick

// Coloured nerd-font glyph + muted label, optionally clickable.  An optional
// second glyph/label pair (glyph2/label2) shares the same hover/click area,
// for modules that show two related readings.
Item {
    id: root

    property string glyph
    property color glyphColor: Theme.fg
    property string label
    property color labelColor: Theme.muted
    property bool critical: false
    property string glyph2: ""
    property color glyph2Color: Theme.fg
    property string label2: ""
    property bool critical2: false
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
            font { family: Theme.font; pixelSize: Theme.barFontSize }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.critical ? Theme.red : (mouse.containsMouse ? Theme.fg : root.labelColor)
            font { family: Theme.font; pixelSize: Theme.barFontSize }
            Behavior on color { ColorAnimation { duration: 140 } }

            SequentialAnimation on opacity {
                running: root.critical
                loops: Animation.Infinite
                onRunningChanged: if (!running) parent.opacity = 1
                NumberAnimation { to: 0.35; duration: 500 }
                NumberAnimation { to: 1; duration: 500 }
            }
        }

        Item { width: 4; height: 1; visible: root.glyph2 !== "" }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph2 !== ""
            text: root.glyph2
            color: root.critical2 ? Theme.red : root.glyph2Color
            font { family: Theme.font; pixelSize: Theme.barFontSize }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label2 !== ""
            text: root.label2
            color: root.critical2 ? Theme.red : (mouse.containsMouse ? Theme.fg : root.labelColor)
            font { family: Theme.font; pixelSize: Theme.barFontSize }
            Behavior on color { ColorAnimation { duration: 140 } }

            SequentialAnimation on opacity {
                running: root.critical2
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
