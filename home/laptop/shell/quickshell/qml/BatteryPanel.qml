import QtQuick
import Quickshell

// Battery level + screen brightness (if there is a backlight to drive).
Column {
    id: p
    required property var drawer
    spacing: 14
    readonly property real wantedHeight: implicitHeight + 32

    // Re-read the backlight each time the panel opens.
    Connections { target: p.drawer; function onContentShownChanged() { if (p.drawer.contentShown && p.visible) Stats.refreshBrightness(); } }

    PanelHeader {
        width: parent.width
        opacity: p.drawer.stagger(0)
        icon: Stats.charging ? "battery_charging_full" : "battery_full"
        title: "Battery"
        detail: Stats.charging ? "Charging" : Stats.plugged ? "Plugged in" : "On battery"
        Text { text: Stats.batPct + "%"; color: Theme.fgBright; font { family: Theme.font; pixelSize: 15; bold: true } }
    }

    Rectangle {
        width: parent.width; height: 14; radius: 7
        opacity: p.drawer.stagger(1)
        color: Theme.glassFill
        border.width: 1; border.color: Theme.glassEdge
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, Stats.batPct / 100)); height: parent.height; radius: 7
            color: Stats.batPct < 15 ? Theme.red : Stats.batPct < 30 ? Theme.yellow : Theme.green
        }
    }

    Row {
        visible: Stats.brightness >= 0
        width: parent.width
        spacing: 10
        opacity: p.drawer.stagger(2)
        Icon { anchors.verticalCenter: parent.verticalCenter; icon: "brightness_6"; size: 18; color: Theme.fg }
        GlassSlider {
            width: parent.width - 28
            anchors.verticalCenter: parent.verticalCenter
            value: Stats.brightness
            fill: Theme.yellow
            onMoved: v => {
                Stats.brightness = Math.max(0.01, v);
                Quickshell.execDetached(["brightnessctl", "-q", "s", Math.round(Stats.brightness * 100) + "%"]);
            }
        }
    }
    Text {
        visible: Stats.brightness < 0
        opacity: p.drawer.stagger(2) * 0.8
        text: "No backlight on this display"
        color: Theme.subtle
        font { family: Theme.font; pixelSize: 12 }
    }
}
