import QtQuick

// Hover panels for the status modules (sound, wifi, bluetooth, system,
// battery), growing out of the bar's right group (see AttachedDrawer.qml).
// The card buds out under the hovered icon, grows into the panel, and
// slides to the next icon when you move along the bar.
AttachedDrawer {
    id: popup

    required property var status          // Status.qml

    side: "right"
    winW: 520

    readonly property int panelW: 340
    property string key: ""               // panel shown
    property bool hold: false

    // Centre of the last hovered icon, in window coordinates (kept while
    // the pointer is on the card, so the card doesn't chase itself).
    property real anchorX: winW - 120
    Connections {
        target: popup.status
        function onHoverItemChanged() {
            const it = popup.status.hoverItem;
            if (it) popup.anchorX = it.mapToItem(popup.barWindow.contentItem, it.width / 2, 0).x - popup.originX;
        }
    }

    readonly property real wantedH: key === "audio" ? audioPanel.wantedHeight
                                  : key === "network" ? netPanel.wantedHeight
                                  : key === "bluetooth" ? btPanel.wantedHeight
                                  : key === "system" ? sysPanel.wantedHeight
                                  : batPanel.wantedHeight

    drawer.anchorX: anchorX
    drawer.openWidth: panelW
    drawer.openHeight: wantedH
    drawer.open: hold || hovered

    // ── hover logic: short delay to open, grace period to reach the card ─
    Timer { id: openDelay; interval: 150; onTriggered: if (popup.status.hoverKey !== "") { popup.key = popup.status.hoverKey; popup.hold = true; } }
    Timer { id: stay; interval: 250; onTriggered: if (popup.status.hoverKey === "") popup.hold = false }
    Timer { id: swap; interval: 110; onTriggered: { popup.key = popup.status.hoverKey; popup.drawer.contentShown = true; } }
    Connections {
        target: popup.status
        function onHoverKeyChanged() {
            const k = popup.status.hoverKey;
            if (k === "") { openDelay.stop(); stay.restart(); return; }
            stay.stop();
            if (!popup.drawer.open) { openDelay.restart(); return; }
            if (k !== popup.key) { popup.drawer.contentShown = false; swap.restart(); }
        }
    }

    Item {
        width: popup.panelW
        height: popup.wantedH
        AudioPanel {
            id: audioPanel; drawer: popup.drawer
            x: 16; y: 12; width: parent.width - 32
            visible: popup.key === "audio"
        }
        NetworkPanel {
            id: netPanel; drawer: popup.drawer
            x: 16; y: 12; width: parent.width - 32
            visible: popup.key === "network"
        }
        BluetoothPanel {
            id: btPanel; drawer: popup.drawer
            x: 16; y: 12; width: parent.width - 32
            visible: popup.key === "bluetooth"
        }
        SystemPanel {
            id: sysPanel; drawer: popup.drawer; stats: popup.status
            x: 16; y: 12; width: parent.width - 32
            visible: popup.key === "system"
        }
        BatteryPanel {
            id: batPanel; drawer: popup.drawer; stats: popup.status
            x: 16; y: 12; width: parent.width - 32
            visible: popup.key === "battery"
        }
    }
}
