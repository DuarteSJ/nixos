import QtQuick
import Quickshell

// CPU / memory / temperature rings (numbers come from Status.qml's poll).
Column {
    id: p
    required property var drawer
    required property var stats
    spacing: 14
    readonly property real wantedHeight: implicitHeight + 32

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
        Repeater {
            model: [
                { v: p.stats.cpuPct / 100, t: p.stats.cpuPct + "%", c: "CPU", col: Theme.accent },
                { v: p.stats.memPct / 100, t: p.stats.memPct + "%", c: "MEMORY", col: Theme.blue },
                { v: p.stats.tempC / 100, t: p.stats.tempC + "°", c: "TEMP", col: p.stats.tempC >= 80 ? Theme.red : Theme.yellow }
            ]
            delegate: Ring {
                required property var modelData
                required property int index
                opacity: p.drawer.stagger(1 + index)
                value: modelData.v; text: modelData.t; caption: modelData.c; color: modelData.col
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached([Theme.terminal, "-e", "btop"]) }
            }
        }
    }
}
