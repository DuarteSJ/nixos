import QtQuick

// Hover panels for the status modules (sound, wifi, bluetooth, system,
// battery), growing out of the bar's right group (see AttachedDrawer.qml).
// The card buds out under the hovered icon, grows into the panel, and
// slides to the next icon when you move along the bar.  With the dashboard
// on (Shell.dashboard, Super+W) it shows every panel stacked instead.
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

    readonly property bool all: Shell.dashboard
    function shows(k) { return all || key === k; }
    readonly property real wantedH: stack.implicitHeight + 32

    drawer.anchorX: all ? winW : anchorX
    drawer.openWidth: panelW
    drawer.openHeight: wantedH
    drawer.open: hold || hovered || all

    // ── hover logic: short delay to open, grace period to reach the card ─
    Timer { id: openDelay; interval: 150; onTriggered: if (popup.status.hoverKey !== "") { popup.key = popup.status.hoverKey; popup.hold = true; } }
    Timer { id: stay; interval: 250; onTriggered: if (popup.status.hoverKey === "") popup.hold = false }
    Timer { id: swap; interval: 110; onTriggered: { popup.key = popup.status.hoverKey; popup.drawer.contentShown = true; } }
    Connections {
        target: popup.status
        function onHoverKeyChanged() {
            const k = popup.status.hoverKey;
            if (popup.all) return;          // dashboard: hovering doesn't switch
            if (k === "") { openDelay.stop(); stay.restart(); return; }
            stay.stop();
            if (!popup.drawer.open) { openDelay.restart(); return; }
            if (k !== popup.key) { popup.drawer.contentShown = false; swap.restart(); }
        }
    }

    Column {
        id: stack
        x: 16; y: 12
        width: popup.panelW - 32
        spacing: 22
        AudioPanel {
            id: audioPanel; drawer: popup.drawer
            width: parent.width
            visible: popup.shows("audio")
        }
        NetworkPanel {
            id: netPanel; drawer: popup.drawer
            width: parent.width
            visible: popup.shows("network")
        }
        BluetoothPanel {
            id: btPanel; drawer: popup.drawer
            width: parent.width
            visible: popup.shows("bluetooth")
        }
        SystemPanel {
            id: sysPanel; drawer: popup.drawer; stats: popup.status
            width: parent.width
            visible: popup.shows("system")
        }
        BatteryPanel {
            id: batPanel; drawer: popup.drawer; stats: popup.status
            width: parent.width
            visible: popup.shows("battery")
        }
    }
}
