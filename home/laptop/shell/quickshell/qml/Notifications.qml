import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Notification daemon (replaces dunst).  Popups stack in the bottom-right
// corner of the focused monitor, newest nearest the corner.
//   left click   run the default action (if any) and close
//   middle click close
//   right click  close all
// Hovering a popup pauses its timeout.  Timeouts follow the old dunst
// config: low 2 s, normal 5 s, critical sticky -- unless the sender asks.
//
// Replace by tag (dunst's stack tags): a notification with the hint
// x-dunst-stack-tag (or x-canonical-private-synchronous) takes the place of
// the shown one with the same tag -- same card, countdown restarted.  The
// `notify -r KEY` wrapper sends these, so callers needn't track ids.
Scope {
    id: root

    readonly property int maxShown: 5

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            root.add(n);
        }
    }

    // One row per card, in arrival order: { n: Notification }.  A row keeps
    // its card when a tagged replacement swaps in a new notification.
    ListModel { id: cards }

    function tagOf(n) {
        const h = n?.hints ?? {};
        return String(h["x-dunst-stack-tag"] ?? h["x-canonical-private-synchronous"] ?? "");
    }
    function rowOf(n) {
        for (let i = 0; i < cards.count; i++) if (cards.get(i).n === n) return i;
        return -1;
    }
    function add(n) {
        n.closed.connect(() => { const i = root.rowOf(n); if (i >= 0) cards.remove(i); });
        const tag = tagOf(n);
        if (tag !== "") {
            for (let i = 0; i < cards.count; i++) {
                const old = cards.get(i).n;
                if (old && old !== n && tagOf(old) === tag) {
                    cards.set(i, { n: n });   // (setProperty can't hold a QObject)
                    old.expire();           // its row holds n now: the card stays
                    return;
                }
            }
        }
        cards.append({ n: n });
    }
    // Notifications kept across a shell reload (keepOnReload).
    Component.onCompleted: {
        for (const n of server.trackedNotifications.values) add(n);
    }

    function closeAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
    }

    PanelWindow {
        id: popups

        screen: Shell.focusedScreen
        visible: cards.count > 0
        anchors { bottom: true; right: true }
        margins { bottom: 15; right: 15 }
        implicitWidth: 440
        implicitHeight: Math.max(1, stack.implicitHeight)
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: stack
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            spacing: 8

            Repeater {
                model: cards

                delegate: Rectangle {
                    id: card

                    required property var n
                    required property int index
                    readonly property int total: cards.count
                    readonly property bool critical: n.urgency === NotificationUrgency.Critical
                    readonly property var defaultAction: (n.actions ?? []).find(a => a.identifier === "default") ?? null
                    readonly property var buttons: (n.actions ?? []).filter(a => a.identifier !== "default")
                    readonly property var progress: n.hints?.value
                    readonly property string iconSource: n.image
                        || (n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "")
                    readonly property int timeout: n.expireTimeout > 0 ? n.expireTimeout
                        : critical ? 0
                        : n.urgency === NotificationUrgency.Low ? 2000 : 5000

                    visible: index >= total - root.maxShown
                    width: stack.width
                    height: visible ? body.implicitHeight + 28 : 0
                    radius: Theme.radius
                    color: Theme.bg
                    border.width: 1
                    border.color: critical ? Theme.red
                        : n.urgency === NotificationUrgency.Low ? Theme.subtle : Theme.blue

                    // Slide in from the right.
                    x: shown ? 0 : width + 20
                    property bool shown: false
                    Component.onCompleted: shown = true
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Timer {
                        id: expiry
                        interval: Math.max(1, card.timeout)
                        running: card.timeout > 0 && !hover.hovered
                        onTriggered: card.n.expire()
                    }
                    // A replacement (same id; or same tag, i.e. a new `n`) restarts
                    // the countdown -- after the new timeout has been bound.
                    function rearm() {
                        expiry.stop();
                        if (card.timeout > 0 && !hover.hovered) expiry.start();
                    }
                    Timer { id: rearmSoon; interval: 0; onTriggered: card.rearm() }
                    onNChanged: rearmSoon.restart()
                    Connections {
                        target: card.n
                        function onSummaryChanged() { rearmSoon.restart(); }
                        function onBodyChanged() { rearmSoon.restart(); }
                    }

                    HoverHandler { id: hover }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: m => {
                            if (m.button === Qt.RightButton) root.closeAll();
                            else if (m.button === Qt.LeftButton && card.defaultAction) card.defaultAction.invoke();
                            else card.n.dismiss();
                        }
                    }

                    Row {
                        id: body
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14; leftMargin: 16; rightMargin: 16 }
                        spacing: 12

                        ClippingRectangle {
                            id: iconBox
                            visible: card.iconSource !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48; height: 48
                            radius: Theme.radius
                            color: "transparent"
                            Image {
                                anchors.fill: parent
                                source: card.iconSource
                                sourceSize: Qt.size(96, 96)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                        }

                        Column {
                            width: parent.width - (iconBox.visible ? iconBox.width + parent.spacing : 0)
                            spacing: 4

                            Row {
                                width: parent.width
                                spacing: 8
                                Text {
                                    width: parent.width - app.implicitWidth - 8
                                    text: card.n.summary
                                    elide: Text.ElideRight
                                    color: card.critical ? Theme.red : Theme.fgBright
                                    font { family: Theme.font; pixelSize: Theme.notifFontSize - 1; bold: true }
                                }
                                Text {
                                    id: app
                                    text: card.n.appName
                                    color: Theme.subtle
                                    font { family: Theme.font; pixelSize: Theme.notifFontSize - 4 }
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: card.n.body
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                color: card.critical ? Theme.red : Theme.fg
                                linkColor: Theme.blue
                                font { family: Theme.font; pixelSize: Theme.notifFontSize - 2 }
                                onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
                            }

                            // int:value:N hint -> progress bar
                            Rectangle {
                                visible: card.progress !== undefined
                                width: parent.width
                                height: 8
                                radius: 4
                                color: Theme.surface
                                border.width: 1
                                border.color: Theme.overlay
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(100, card.progress ?? 0)) / 100
                                    height: parent.height
                                    radius: 4
                                    color: card.critical ? Theme.red : Theme.blue
                                    Behavior on width { NumberAnimation { duration: 150 } }
                                }
                            }

                            Row {
                                visible: card.buttons.length > 0
                                spacing: 6
                                topPadding: 2
                                Repeater {
                                    model: card.buttons
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: label.implicitWidth + 18
                                        height: 26
                                        radius: Theme.radius
                                        color: btnMouse.containsMouse ? Theme.blue : Theme.surface
                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            text: parent.modelData.text
                                            color: btnMouse.containsMouse ? Theme.bg : Theme.fg
                                            font { family: Theme.font; pixelSize: Theme.notifFontSize - 3 }
                                        }
                                        MouseArea {
                                            id: btnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: parent.modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
