import QtQuick
import Quickshell.Hyprland

// Workspace numbers with a sliding underline under the active one.  The
// configured set (monitors.workspaces) is always shown, plus any other
// non-special workspace that currently exists.
Item {
    id: root

    required property var monitor   // HyprlandMonitor for this bar

    readonly property var ids: {
        const set = new Set(Theme.persistentWorkspaces);
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0) set.add(ws.id);
        return Array.from(set).sort((a, b) => a - b);
    }
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    function wsById(id) {
        return Hyprland.workspaces.values.find(w => w.id === id) ?? null;
    }

    function focus(id) {
        const ws = wsById(id);
        if (ws) ws.activate();
        else Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = ${id} })`
            : `workspace ${id}`);
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.ids

            delegate: Item {
                id: cell
                required property int modelData
                readonly property var ws: root.wsById(modelData)
                readonly property bool active: modelData === root.activeId
                readonly property bool occupied: (ws?.toplevels?.values?.length ?? 0) > 0

                width: 24
                height: Theme.barHeight

                Text {
                    anchors.centerIn: parent
                    text: cell.modelData
                    color: cell.ws?.urgent ? Theme.red
                         : cell.active ? Theme.fgBright
                         : cell.occupied || mouse.containsMouse ? Theme.fg
                         : Theme.subtle
                    font { family: Theme.font; pixelSize: Theme.fontSize; bold: cell.active }
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focus(cell.modelData)
                }
            }
        }
    }

    // Sliding indicator.
    Rectangle {
        readonly property int idx: root.ids.indexOf(root.activeId)
        visible: idx >= 0
        y: Theme.barHeight - 5
        x: idx * 26 + 6
        width: 12
        height: 2
        radius: 1
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    // Scroll to walk workspaces.
    WheelHandler {
        onWheel: e => {
            const i = root.ids.indexOf(root.activeId);
            const next = root.ids[Math.max(0, Math.min(root.ids.length - 1, i + (e.angleDelta.y < 0 ? 1 : -1)))];
            if (next !== undefined && next !== root.activeId) root.focus(next);
        }
    }
}
