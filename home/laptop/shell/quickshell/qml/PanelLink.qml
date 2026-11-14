import QtQuick
import Quickshell

// "Settings  ›" link at the foot of a panel; runs `command` when clicked.
Text {
    id: link
    required property var command
    color: Theme.accent
    font { family: Theme.font; pixelSize: 12 }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(link.command) }
}
