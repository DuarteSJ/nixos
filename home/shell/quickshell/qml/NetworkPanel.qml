import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi: on/off, what we're on, nearby networks (click to connect).
Column {
    id: p
    required property var drawer
    spacing: 10
    readonly property real wantedHeight: implicitHeight + 32

    readonly property var wired: Stats.wired
    readonly property var wifi: Stats.wifi
    readonly property var nets: (wifi?.networks?.values ?? [])
        .filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
        .slice(0, 6)
    readonly property var current: nets.find(n => n.connected) ?? null

    // Scan only while the panel is open.
    Binding { target: p.wifi; property: "scannerEnabled"; value: p.drawer.contentShown; when: p.wifi !== null }

    PanelHeader {
        width: parent.width
        opacity: p.drawer.stagger(0)
        icon: p.wired ? "lan" : (Networking.wifiEnabled ? "wifi" : "wifi_off")
        title: p.wired ? "Ethernet" : "Wi-Fi"
        detail: p.wired ? "Connected" : p.current ? p.current.name : (Networking.wifiEnabled ? "Not connected" : "Off")
        GlassToggle {
            visible: !p.wired
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    SectionLabel {
        visible: Networking.wifiEnabled && p.nets.length > 0
        opacity: p.drawer.stagger(1)
        text: "NETWORKS"
    }

    Repeater {
        model: Networking.wifiEnabled ? p.nets : []
        delegate: ListRow {
            required property var modelData
            required property int index
            readonly property real sig: modelData.signalStrength ?? 0
            width: p.width; height: 36
            opacity: p.drawer.stagger(2 + index)
            selected: modelData.connected
            icon: sig > 0.75 ? "network_wifi" : sig > 0.5 ? "network_wifi_3_bar" : sig > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
            iconFilled: true
            text: modelData.name
            bold: modelData.connected
            tag: modelData.connected ? "connected" : modelData.known ? "saved" : ""
            onClicked: if (!modelData.connected)
                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.name])
        }
    }

    PanelLink {
        opacity: p.drawer.stagger(8) * 0.8
        text: "Network settings  ›"
        command: ["nm-connection-editor"]
    }
}
