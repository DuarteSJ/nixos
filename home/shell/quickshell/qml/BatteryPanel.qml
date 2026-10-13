import QtQuick
import Quickshell
import Quickshell.Io

// Battery level + screen brightness (if there is a backlight to drive).
Column {
    id: p
    required property var drawer
    required property var stats
    spacing: 14
    readonly property real wantedHeight: implicitHeight + 32

    property real brightness: -1      // 0..1, -1 = no backlight
    Process {
        id: readB
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: { const v = parseInt(text.split(",")[3]); p.brightness = isNaN(v) ? -1 : v / 100; } }
        onExited: code => { if (code !== 0) p.brightness = -1; }
    }
    Connections { target: p.drawer; function onContentShownChanged() { if (p.drawer.contentShown) readB.running = true; } }

    readonly property bool charging: stats.batStatus === "Charging"
    readonly property bool full: stats.batStatus === "Full" || stats.batStatus === "Not charging"

    PanelHeader {
        width: parent.width
        opacity: p.drawer.stagger(0)
        icon: p.charging ? "battery_charging_full" : "battery_full"
        title: "Battery"
        detail: p.charging ? "Charging" : p.full ? "Plugged in" : "On battery"
        Text { text: p.stats.batPct + "%"; color: Theme.fgBright; font { family: Theme.font; pixelSize: 15; bold: true } }
    }

    Rectangle {
        width: parent.width; height: 14; radius: 7
        opacity: p.drawer.stagger(1)
        color: Theme.glassFill
        border.width: 1; border.color: Theme.glassEdge
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, p.stats.batPct / 100)); height: parent.height; radius: 7
            color: p.stats.batPct < 15 ? Theme.red : p.stats.batPct < 30 ? Theme.yellow : Theme.green
        }
    }

    Row {
        visible: p.brightness >= 0
        width: parent.width
        spacing: 10
        opacity: p.drawer.stagger(2)
        Icon { anchors.verticalCenter: parent.verticalCenter; icon: "brightness_6"; size: 18; color: Theme.fg }
        GlassSlider {
            width: parent.width - 28
            anchors.verticalCenter: parent.verticalCenter
            value: p.brightness
            fill: Theme.yellow
            onMoved: v => {
                p.brightness = Math.max(0.01, v);
                Quickshell.execDetached(["brightnessctl", "-q", "s", Math.round(p.brightness * 100) + "%"]);
            }
        }
    }
    Text {
        visible: p.brightness < 0
        opacity: p.drawer.stagger(2) * 0.8
        text: "No backlight on this display"
        color: Theme.subtle
        font { family: Theme.font; pixelSize: 12 }
    }
}
