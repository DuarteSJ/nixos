import QtQuick

// Pill switch.
Rectangle {
    id: t

    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.accent : Theme.glassFill
    border.width: 1
    border.color: checked ? "transparent" : Theme.glassEdge
    Behavior on color { ColorAnimation { duration: 160 } }

    Rectangle {
        x: t.checked ? t.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16; height: 16; radius: 8
        color: t.checked ? Theme.bg : Theme.fgBright
        Behavior on x { SpringAnimation { spring: 5; damping: 0.4 } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }
}
