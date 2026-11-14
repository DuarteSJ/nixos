import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Top bar: three groups hanging from the top edge.
//   left   workspaces · window title · REC
//   centre clock (click copies the date, hover for a calendar drawer)
//   right  volume · network · bluetooth · system · battery
//          (hover any of them for its panel, see StatusPopup.qml)
PanelWindow {
    id: bar

    required property var modelData
    readonly property var hyprMonitor: Hyprland.monitorFor(modelData)

    screen: modelData
    visible: Shell.barShown
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + 1
    color: "transparent"

    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top

    // ── left ────────────────────────────────────────────────────────────
    Group {
        anchors { left: parent.left; top: parent.top }
        roundLeft: false

        Workspaces { monitor: bar.hyprMonitor }

        Text {
            readonly property var win: Hyprland.activeToplevel
            readonly property bool here: win !== null && win.monitor === bar.hyprMonitor
            visible: here && win.title !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 320)
            elide: Text.ElideRight
            text: here ? "|  " + win.title : ""
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.barFontSize }
        }

        Rectangle {
            visible: Shell.recording
            anchors.verticalCenter: parent.verticalCenter
            width: rec.implicitWidth + 14
            height: Theme.barHeight - 8
            radius: 4
            color: Theme.red
            Text {
                id: rec
                anchors.centerIn: parent
                text: "■ REC"
                color: Theme.bg
                font { family: Theme.font; pixelSize: Theme.barFontSize - 1; bold: true }
            }
            SequentialAnimation on opacity {
                running: Shell.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["screenrec"])
            }
        }
    }

    // ── centre ──────────────────────────────────────────────────────────
    Group {
        id: centerGroup
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
        Clock { id: clock }
    }

    CalendarPopup {
        barWindow: bar
        group: centerGroup
        clock: clock
    }

    // ── right ───────────────────────────────────────────────────────────
    Group {
        id: rightGroup
        anchors { right: parent.right; top: parent.top }
        roundRight: false
        Status { id: status }
    }

    StatusPopup {
        barWindow: bar
        status: status
        group: rightGroup
    }
}
