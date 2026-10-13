import QtQuick
import Quickshell

// "HH:MM   Mon DD".  Click copies the date; hover shows a month calendar.
Item {
    id: root

    required property var barWindow

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

    property bool calWanted: mod.hovered || calMouse.containsMouse
    onCalWantedChanged: calWanted ? showTimer.restart() : (showTimer.stop(), hideTimer.restart())
    Timer { id: showTimer; interval: 450; onTriggered: { hideTimer.stop(); cal.visible = true; } }
    Timer { id: hideTimer; interval: 250; onTriggered: cal.visible = false }

    PopupWindow {
        id: cal
        anchor.window: root.barWindow
        anchor.item: root
        anchor.rect.x: root.width / 2 - implicitWidth / 2
        anchor.rect.y: Theme.barHeight + 8
        implicitWidth: 250
        implicitHeight: grid.implicitHeight + head.implicitHeight + 36
        color: "transparent"
        visible: false

        readonly property date today: clock.date
        readonly property int year: today.getFullYear()
        readonly property int month: today.getMonth()
        // Monday-first offset of the 1st, and month length.
        readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7
        readonly property int days: new Date(year, month + 1, 0).getDate()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius + 4
            color: Theme.bg
            border.width: 1
            border.color: Theme.overlay

            MouseArea { id: calMouse; anchors.fill: parent; hoverEnabled: true }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    id: head
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(cal.today, "MMMM yyyy")
                    color: Theme.fgBright
                    font { family: Theme.font; pixelSize: Theme.fontSize; bold: true }
                }

                Grid {
                    id: grid
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2

                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        Text {
                            required property string modelData
                            required property int index
                            width: 30; height: 22
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: index >= 5 ? Theme.purple : Theme.muted
                            font { family: Theme.font; pixelSize: Theme.fontSize - 2 }
                        }
                    }

                    Repeater {
                        model: cal.lead + cal.days
                        Rectangle {
                            required property int index
                            readonly property int day: index - cal.lead + 1
                            readonly property bool isToday: day === cal.today.getDate()
                            width: 30; height: 26
                            radius: 8
                            color: isToday ? Theme.accent : "transparent"
                            Text {
                                anchors.centerIn: parent
                                visible: parent.day > 0
                                text: parent.day
                                color: parent.isToday ? Theme.bg : Theme.fg
                                font { family: Theme.font; pixelSize: Theme.fontSize - 1; bold: parent.isToday }
                            }
                        }
                    }
                }
            }
        }
    }
}
