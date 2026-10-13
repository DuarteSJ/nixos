import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi: on/off, what we're on, nearby networks (click to connect).
Column {
    id: p
    required property var drawer
    spacing: 10
    readonly property real wantedHeight: implicitHeight + 32

    readonly property var devices: Networking.devices?.values ?? []
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
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

    Text {
        visible: Networking.wifiEnabled && p.nets.length > 0
        opacity: p.drawer.stagger(1)
        text: "NETWORKS"
        color: Theme.subtle
        font { family: Theme.font; pixelSize: 11; bold: true; letterSpacing: 1.5 }
    }

    Repeater {
        model: Networking.wifiEnabled ? p.nets : []
        delegate: Rectangle {
            id: net
            required property var modelData
            required property int index
            readonly property real sig: modelData.signalStrength ?? 0
            width: p.width; height: 36; radius: 12
            opacity: p.drawer.stagger(2 + index)
            color: modelData.connected ? Theme.glassFillStrong : netMouse.containsMouse ? Theme.glassFill : "transparent"
            Icon {
                id: bars
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                icon: net.sig > 0.75 ? "network_wifi" : net.sig > 0.5 ? "network_wifi_3_bar" : net.sig > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                size: 17; filled: true
                color: net.modelData.connected ? Theme.accent : Theme.fg
            }
            Text {
                anchors { left: bars.right; leftMargin: 10; right: tag.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: net.modelData.name
                elide: Text.ElideRight
                color: net.modelData.connected ? Theme.fgBright : Theme.fg
                font { family: Theme.font; pixelSize: 13; bold: net.modelData.connected }
            }
            Text {
                id: tag
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: net.modelData.connected ? "connected" : net.modelData.known ? "saved" : ""
                color: net.modelData.connected ? Theme.accent : Theme.subtle
                font { family: Theme.font; pixelSize: 11 }
            }
            MouseArea {
                id: netMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!net.modelData.connected)
                    Quickshell.execDetached(["nmcli", "device", "wifi", "connect", net.modelData.name])
            }
        }
    }

    Text {
        opacity: p.drawer.stagger(8) * 0.8
        text: "Network settings  ›"
        color: Theme.accent
        font { family: Theme.font; pixelSize: 12 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
    }
}
