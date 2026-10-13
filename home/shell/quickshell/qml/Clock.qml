import QtQuick
import Quickshell

// "HH:MM   Mon DD".  Click copies the date; hovering opens the calendar
// drawer (CalendarPopup.qml, which watches `hovered`).
Item {
    id: root

    readonly property alias hovered: mod.hovered

    SystemClock { id: clock; precision: SystemClock.Seconds }

    implicitWidth: mod.implicitWidth
    implicitHeight: Theme.barHeight

    Module {
        id: mod
        glyph: ""
        glyphColor: Theme.blue
        label: Qt.formatDateTime(clock.date, "HH:mm") + "   "
             + Qt.formatDateTime(clock.date, "MMM dd")
        labelColor: Theme.fg
        onClicked: Quickshell.execDetached(["sh", "-c",
            "d=$(date +'%d-%m-%Y · %H:%M'); printf %s \"$d\" | wl-copy && notify-send '📋 Date copied' \"$d\""])
    }
}
