import QtQuick

// CPU / memory / temperature rings (numbers from Stats.qml).  Fixed rings
// bound to the stats, so a poll animates them instead of rebuilding them.
Column {
    id: p
    required property var drawer
    spacing: 14
    readonly property real wantedHeight: implicitHeight + 32

    component StatRing: Ring {
        required property int order
        opacity: p.drawer.stagger(1 + order)
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theme.term(["btop"]) }
    }

    PanelHeader {
        width: parent.width
        opacity: p.drawer.stagger(0)
        icon: "memory"
        title: "System"
        detail: "click a ring for btop"
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16
        StatRing {
            order: 0
            value: Stats.cpuPct / 100; text: Stats.cpuPct + "%"; caption: "CPU"; color: Theme.accent
        }
        StatRing {
            order: 1
            value: Stats.memPct / 100; text: Stats.memPct + "%"; caption: "MEMORY"; color: Theme.blue
        }
        StatRing {
            order: 2
            value: Stats.tempC / 100; text: Stats.tempC + "°"; caption: "TEMP"
            color: Stats.tempC >= 90 ? Theme.red : Stats.tempC >= 80 ? Theme.yellow : Theme.teal
        }
    }
}
