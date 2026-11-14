import QtQuick
import Quickshell

Item {
    id: root

    readonly property bool hovered: timeMod.hovered || dateMod.hovered

    SystemClock { id: clock; precision: SystemClock.Minutes }  // label shows HH:mm

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    function copyDate() {
        Quickshell.execDetached(["sh", "-c",
            "d=$(date +'%d-%m-%Y · %H:%M'); printf %s \"$d\" | wl-copy && notify-send '📋 Date copied' \"$d\""]);
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        Module {
            id: timeMod
            glyph: ""
            glyphColor: Theme.blue
            label: Qt.formatDateTime(clock.date, "HH:mm")
            labelColor: Theme.fg
            onClicked: root.copyDate()
        }
        Module {
            id: dateMod
            glyph: ""
            glyphColor: Theme.blue
            label: Qt.formatDateTime(clock.date, "MMM dd")
            labelColor: Theme.fg
            onClicked: root.copyDate()
        }
    }
}
