import QtQuick
import Quickshell

// Month calendar for the clock drawer (Monday first, today highlighted).
Item {
    id: cal

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property date today: clock.date
    readonly property int year: today.getFullYear()
    readonly property int month: today.getMonth()
    readonly property int lead: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int days: new Date(year, month + 1, 0).getDate()
    readonly property real wantedHeight: col.implicitHeight + 30

    Column {
        id: col
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 14 }
        spacing: 10

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Text {
                text: Qt.formatDateTime(cal.today, "HH:mm")
                color: Theme.fgBright
                font { family: Theme.font; pixelSize: 30; bold: true }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: Qt.formatDateTime(cal.today, "dddd")
                    color: Theme.accent
                    font { family: Theme.font; pixelSize: Theme.fontSize - 2; bold: true }
                }
                Text {
                    text: Qt.formatDateTime(cal.today, "d MMMM yyyy")
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontSize - 3 }
                }
            }
        }

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property string modelData
                    required property int index
                    width: 32; height: 22
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: index >= 5 ? Theme.purple : Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontSize - 3 }
                }
            }

            Repeater {
                model: cal.lead + cal.days
                Rectangle {
                    required property int index
                    readonly property int day: index - cal.lead + 1
                    readonly property bool isToday: day === cal.today.getDate()
                    width: 32; height: 28
                    radius: 14
                    color: isToday ? Theme.accent : "transparent"
                    Text {
                        anchors.centerIn: parent
                        visible: parent.day > 0
                        text: parent.day
                        color: parent.isToday ? Theme.bg : Theme.fg
                        font { family: Theme.font; pixelSize: Theme.fontSize - 2; bold: parent.isToday }
                    }
                }
            }
        }
    }
}
