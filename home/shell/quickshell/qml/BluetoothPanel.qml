import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth: power, then paired + nearby devices (click to connect,
// disconnect or pair).  Scans only while the panel is open.
Column {
    id: p
    required property var drawer
    spacing: 10
    readonly property real wantedHeight: implicitHeight + 32

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var devices: (adapter?.devices?.values ?? [])
        .filter(d => d.name || d.deviceName)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)
                        || (a.name || a.deviceName).localeCompare(b.name || b.deviceName))
        .slice(0, 6)
    readonly property var connected: devices.filter(d => d.connected)

    Binding {
        target: p.adapter; property: "discovering"
        value: p.drawer.contentShown && p.on
        when: p.adapter !== null
    }

    function iconFor(d) {
        const i = d.icon ?? "";
        return i.includes("headset") || i.includes("headphone") ? "headphones"
             : i.includes("audio") ? "speaker"
             : i.includes("mouse") ? "mouse"
             : i.includes("keyboard") ? "keyboard"
             : i.includes("phone") ? "smartphone"
             : i.includes("game") ? "sports_esports"
             : "bluetooth";
    }

    PanelHeader {
        width: parent.width
        opacity: p.drawer.stagger(0)
        icon: !p.on ? "bluetooth_disabled" : p.connected.length ? "bluetooth_connected" : "bluetooth"
        title: "Bluetooth"
        detail: !p.adapter ? "No adapter"
              : !p.on ? "Off"
              : p.connected.length ? p.connected.map(d => d.name || d.deviceName).join(", ")
              : (p.adapter.discovering ? "Searching…" : "On")
        GlassToggle {
            visible: p.adapter !== null
            checked: p.on
            onToggled: p.adapter.enabled = !p.adapter.enabled
        }
    }

    Text {
        visible: p.on && p.devices.length > 0
        opacity: p.drawer.stagger(1)
        text: "DEVICES"
        color: Theme.subtle
        font { family: Theme.font; pixelSize: 11; bold: true; letterSpacing: 1.5 }
    }

    Repeater {
        model: p.on ? p.devices : []
        delegate: Rectangle {
            id: dev
            required property var modelData
            required property int index
            readonly property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                                      || modelData.state === BluetoothDeviceState.Disconnecting
            width: p.width; height: 38; radius: 12
            opacity: p.drawer.stagger(2 + index)
            color: modelData.connected ? Theme.glassFillStrong : devMouse.containsMouse ? Theme.glassFill : "transparent"

            Icon {
                id: devIcon
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                icon: p.iconFor(dev.modelData)
                size: 18
                color: dev.modelData.connected ? Theme.accent : Theme.fg
            }
            Text {
                anchors { left: devIcon.right; leftMargin: 10; right: tag.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: dev.modelData.name || dev.modelData.deviceName
                elide: Text.ElideRight
                color: dev.modelData.connected ? Theme.fgBright : Theme.fg
                font { family: Theme.font; pixelSize: 13; bold: dev.modelData.connected }
            }
            Text {
                id: tag
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: dev.busy ? "…"
                    : dev.modelData.connected
                        ? (dev.modelData.batteryAvailable ? Math.round(dev.modelData.battery * 100) + "%" : "connected")
                    : dev.modelData.paired ? "paired" : ""
                color: dev.modelData.connected ? Theme.accent : Theme.subtle
                font { family: Theme.font; pixelSize: 11 }
            }
            MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const d = dev.modelData;
                    if (d.connected) d.disconnect();
                    else if (d.paired) d.connect();
                    else d.pair();
                }
            }
        }
    }

    Text {
        opacity: p.drawer.stagger(8) * 0.8
        text: "Bluetooth settings  ›"
        color: Theme.accent
        font { family: Theme.font; pixelSize: 12 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["blueman-manager"]) }
    }
}
