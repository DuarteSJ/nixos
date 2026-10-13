import QtQuick
import Quickshell

// Hover panels for the status modules (sound, wifi, bluetooth, system,
// battery), attached to the bar's right group.
//
// The card is a Drawer (shared with the liquid-glass branch): it buds out
// of the group under the hovered icon, grows into the panel, and slides to
// the next icon when you move along the bar.  shaders/attach.frag paints
// it smooth-unioned with the group, so card and group read as one shape
// with soft concave joins -- but only outside the group, which the bar
// itself draws (icons included).
//
// The popup covers the top of the screen from y = 0 so the drawer can grow
// out of the group; its input mask is just the card, so the bar under it
// keeps working.
PopupWindow {
    id: popup

    required property var barWindow
    required property var status          // Status.qml
    required property var group           // the right Group in Bar.qml

    readonly property int popupW: 520
    readonly property int panelW: 340
    readonly property real originX: barWindow.width - popupW   // popup x in bar coords

    property string key: ""               // panel shown
    property bool hold: false

    // Centre of the last hovered icon, in popup coordinates (kept while the
    // pointer is on the card, so the card doesn't chase itself).
    property real anchorX: popupW - 120
    Connections {
        target: popup.status
        function onHoverItemChanged() {
            const it = popup.status.hoverItem;
            if (it) popup.anchorX = it.mapToItem(popup.barWindow.contentItem, it.width / 2, 0).x - popup.originX;
        }
    }

    readonly property real wantedH: (key === "audio" ? audioPanel.wantedHeight
                                  : key === "network" ? netPanel.wantedHeight
                                  : key === "bluetooth" ? btPanel.wantedHeight
                                  : key === "system" ? sysPanel.wantedHeight
                                  : batPanel.wantedHeight)

    anchor.window: barWindow
    anchor.rect.x: originX
    anchor.rect.y: 0
    implicitWidth: popupW
    implicitHeight: 620
    color: "transparent"
    visible: drawer.active || drawer.rw > 17
    mask: Region { item: drawer.hit }

    // ── hover logic: short delay to open, grace period to reach the card ─
    Timer { id: openDelay; interval: 150; onTriggered: if (popup.status.hoverKey !== "") { popup.key = popup.status.hoverKey; popup.hold = true; } }
    Timer { id: stay; interval: 250; onTriggered: if (popup.status.hoverKey === "") popup.hold = false }
    Timer { id: swap; interval: 110; onTriggered: { popup.key = popup.status.hoverKey; drawer.contentShown = true; } }
    Connections {
        target: popup.status
        function onHoverKeyChanged() {
            const k = popup.status.hoverKey;
            if (k === "") { openDelay.stop(); stay.restart(); return; }
            stay.stop();
            if (!drawer.open) { openDelay.restart(); return; }
            if (k !== popup.key) { drawer.contentShown = false; swap.restart(); }
        }
    }

    // ── shape ───────────────────────────────────────────────────────────
    ShaderEffect {
        anchors.fill: parent

        property vector2d res: Qt.vector2d(width, height)
        // The group, extended past the top and right screen edges so only
        // its free (bottom-left) corner is rounded -- like Group.qml.
        property vector4d group: Qt.vector4d(popup.group.x - popup.originX, -60,
                                             popup.group.width + 60, Theme.barHeight + 60)
        property real groupR: Theme.barRadius
        property vector4d card: drawer.rect
        property real cardR: drawer.rr
        property real k: 16
        property color color: Theme.bg
        property color rim: Theme.overlay

        fragmentShader: Qt.resolvedUrl("shaders/attach.frag.qsb")
    }

    // ── the drawer and its panels ───────────────────────────────────────
    Drawer {
        id: drawer
        anchorX: popup.anchorX
        attachY: Theme.barHeight
        overlap: 0
        minX: 6
        maxX: popup.popupW - 6
        openWidth: popup.panelW
        openHeight: popup.wantedH
        openRadius: 14
        open: popup.hold || cardHover.hovered

        Item {
            width: popup.panelW
            height: popup.wantedH
            AudioPanel {
                id: audioPanel; drawer: drawer
                x: 16; y: 12; width: parent.width - 32
                visible: popup.key === "audio"
            }
            NetworkPanel {
                id: netPanel; drawer: drawer
                x: 16; y: 12; width: parent.width - 32
                visible: popup.key === "network"
            }
            BluetoothPanel {
                id: btPanel; drawer: drawer
                x: 16; y: 12; width: parent.width - 32
                visible: popup.key === "bluetooth"
            }
            SystemPanel {
                id: sysPanel; drawer: drawer; stats: popup.status
                x: 16; y: 12; width: parent.width - 32
                visible: popup.key === "system"
            }
            BatteryPanel {
                id: batPanel; drawer: drawer; stats: popup.status
                x: 16; y: 12; width: parent.width - 32
                visible: popup.key === "battery"
            }
        }
    }
    Item {
        x: drawer.hit.x; y: drawer.hit.y; width: drawer.hit.width; height: drawer.hit.height
        HoverHandler { id: cardHover }
    }
}
