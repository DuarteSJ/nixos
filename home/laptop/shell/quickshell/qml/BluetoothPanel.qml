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

    readonly property var adapter: Stats.btAdapter
    readonly property bool on: Stats.btOn
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

    SectionLabel {
        visible: p.on && p.devices.length > 0
        opacity: p.drawer.stagger(1)
        text: "DEVICES"
    }

    Repeater {
        model: p.on ? p.devices : []
        delegate: ListRow {
            required property var modelData
            required property int index
            readonly property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                                      || modelData.state === BluetoothDeviceState.Disconnecting
            width: p.width; height: 38
            opacity: p.drawer.stagger(2 + index)
            selected: modelData.connected
            icon: p.iconFor(modelData)
            iconSize: 18
            text: modelData.name || modelData.deviceName
            bold: modelData.connected
            tag: busy ? "…"
                : modelData.connected
                    ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected")
                : modelData.paired ? "paired" : ""
            onClicked: {
                const d = modelData;
                if (d.connected) d.disconnect();
                else if (d.paired) d.connect();
                else d.pair();
            }
        }
    }

    PanelLink {
        opacity: p.drawer.stagger(8) * 0.8
        text: "Bluetooth settings  ›"
        command: ["blueman-manager"]
    }
}
