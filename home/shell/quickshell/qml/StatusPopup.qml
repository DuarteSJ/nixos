import QtQuick
import Quickshell

// Hover panels for the status modules (sound, wifi, bluetooth, system,
// battery).  One card hangs under the bar's right group: it opens under the
// hovered icon, and moving to another icon slides it across and resizes it
// while the new panel cascades in.
//
// The panels (AudioPanel.qml etc.) only need `contentShown` and
// `stagger(i)` from their host, so they are shared with the liquid-glass
// branch, where a shader drawer hosts them instead of this card.
PopupWindow {
    id: popup

    required property var barWindow
    required property var status          // Status.qml

    // ── what the panels read ────────────────────────────────────────────
    property bool contentShown: false
    property real reveal: contentShown ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: popup.contentShown ? 420 : 100; easing.type: Easing.OutCubic } }
    function stagger(i) { return Math.max(0, Math.min(1, reveal * 1.8 - i * 0.09)); }

    // ── state ───────────────────────────────────────────────────────────
    property string key: ""                 // panel shown
    property bool hold: false
    readonly property bool open: hold || cardHover.hovered

    readonly property int popupW: 480
    readonly property int panelW: 340
    // Centre of the last hovered icon, in popup coordinates (kept when the
    // pointer moves onto the card, so the card doesn't chase itself).
    property real anchorX: popupW - 120
    Connections {
        target: popup.status
        function onHoverItemChanged() {
            const it = popup.status.hoverItem;
            if (it) popup.anchorX = it.mapToItem(popup.barWindow.contentItem, it.width / 2, 0).x
                                   - (popup.barWindow.width - popup.popupW);
        }
    }

    readonly property real wantedH: (key === "audio" ? audioPanel.wantedHeight
                                  : key === "network" ? netPanel.wantedHeight
                                  : key === "bluetooth" ? btPanel.wantedHeight
                                  : key === "system" ? sysPanel.wantedHeight
                                  : batPanel.wantedHeight)

    anchor.window: barWindow
    anchor.rect.x: barWindow.width - popupW
    anchor.rect.y: Theme.barHeight
    implicitWidth: popupW
    implicitHeight: 560
    color: "transparent"
    visible: open || card.height > 1
    mask: Region { item: card }

    onOpenChanged: {
        if (open) { showContent.restart(); }
        else { showContent.stop(); contentShown = false; }
    }
    Timer { id: showContent; interval: 130; onTriggered: popup.contentShown = true }

    // ── hover logic: short delay to open, grace period to reach the card ─
    Timer { id: openDelay; interval: 150; onTriggered: if (popup.status.hoverKey !== "") { popup.key = popup.status.hoverKey; popup.hold = true; } }
    Timer { id: stay; interval: 250; onTriggered: if (popup.status.hoverKey === "") popup.hold = false }
    Timer { id: swap; interval: 110; onTriggered: { popup.key = popup.status.hoverKey; popup.contentShown = true; } }
    Connections {
        target: popup.status
        function onHoverKeyChanged() {
            const k = popup.status.hoverKey;
            if (k === "") { openDelay.stop(); stay.restart(); return; }
            stay.stop();
            if (!popup.open) { openDelay.restart(); return; }
            if (k !== popup.key) { popup.contentShown = false; swap.restart(); }
        }
    }

    // ── the card ────────────────────────────────────────────────────────
    Rectangle {
        id: card
        y: 6
        x: Math.max(4, Math.min(popup.popupW - width - 4, popup.anchorX - width / 2))
        width: popup.open ? popup.panelW : 120
        height: popup.open ? popup.wantedH : 0
        radius: Theme.barRadius
        color: Theme.bg
        border.width: 1
        border.color: Theme.overlay
        clip: true

        Behavior on x { SpringAnimation { spring: 4.0; damping: 0.34; epsilon: 0.2 } }
        Behavior on width { SpringAnimation { spring: 4.2; damping: 0.32; epsilon: 0.2 } }
        Behavior on height { SpringAnimation { spring: 4.2; damping: 0.32; epsilon: 0.2 } }

        HoverHandler { id: cardHover }

        Item {
            width: popup.panelW
            height: popup.wantedH
            opacity: popup.contentShown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: popup.contentShown ? 180 : 90 } }

            AudioPanel {
                id: audioPanel; drawer: popup
                x: 16; y: 14; width: parent.width - 32
                visible: popup.key === "audio"
            }
            NetworkPanel {
                id: netPanel; drawer: popup
                x: 16; y: 14; width: parent.width - 32
                visible: popup.key === "network"
            }
            BluetoothPanel {
                id: btPanel; drawer: popup
                x: 16; y: 14; width: parent.width - 32
                visible: popup.key === "bluetooth"
            }
            SystemPanel {
                id: sysPanel; drawer: popup; stats: popup.status
                x: 16; y: 14; width: parent.width - 32
                visible: popup.key === "system"
            }
            BatteryPanel {
                id: batPanel; drawer: popup; stats: popup.status
                x: 16; y: 14; width: parent.width - 32
                visible: popup.key === "battery"
            }
        }
    }
}
