import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// The liquid-glass frame: one full-screen layer per monitor.
//
// A shader (shaders/frame.frag) paints the glass as a single distance
// field -- top bar, thin left/right/bottom rim, and every open drawer --
// smooth-unioned so drawers bud out of the bar and pinch off like liquid.
// Hyprland blurs behind whatever it paints (layer_rule on "qs-frame").
// Input is only taken on the bar and on open drawers (`mask`), so the
// transparent middle stays click-through.
PanelWindow {
    id: frame

    required property var modelData
    readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
    readonly property bool launcherHere: Shell.launcherOpen && Shell.launcherScreen === modelData.name

    screen: modelData
    visible: Shell.barVisible
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "qs-frame"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: launcherHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: barStrip
        Region { item: calendar.hit }
        Region { item: launcher.hit }
        Region { item: catcher }
    }

    // ── glass ───────────────────────────────────────────────────────────
    ShaderEffect {
        anchors.fill: parent

        property vector2d res: Qt.vector2d(width, height)
        property vector4d hole: Qt.vector4d(Theme.frameEdge, Theme.barHeight,
                                            width - 2 * Theme.frameEdge,
                                            height - Theme.barHeight - Theme.frameEdge)
        property real holeR: Theme.frameRadius
        property real k: Theme.gooey
        property vector4d d0: calendar.rect
        property vector4d d1: launcher.rect
        property vector4d d2: launcher.neck
        property vector4d d3: Qt.vector4d(0, 0, 0, 0)
        property vector4d radii: Qt.vector4d(calendar.rr, launcher.rr, Math.min(launcher.neckW / 2, 26), 0)
        property vector4d dripX: Qt.vector4d(launcher.dripX[0], launcher.dripX[1], launcher.dripX[2], launcher.dripX[3])
        property vector4d dripY: Qt.vector4d(launcher.dripY[0], launcher.dripY[1], launcher.dripY[2], launcher.dripY[3])
        property vector4d dripR: Qt.vector4d(launcher.dripR[0], launcher.dripR[1], launcher.dripR[2], launcher.dripR[3])
        property color tint: Theme.glassTint
        property color rim: Theme.glassRim

        fragmentShader: Qt.resolvedUrl("shaders/frame.frag.qsb")
    }

    // Clicking anywhere outside the launcher closes it.
    MouseArea {
        id: catcher
        x: 0; y: 0
        width: frame.launcherHere ? frame.width : 0
        height: frame.launcherHere ? frame.height : 0
        onClicked: Shell.launcherOpen = false
    }

    // ── bar ─────────────────────────────────────────────────────────────
    Item {
        id: barStrip
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.barHeight

        Row {
            anchors { left: parent.left; leftMargin: Theme.frameEdge + 12; verticalCenter: parent.verticalCenter }
            spacing: 14

            Workspaces { monitor: frame.hyprMonitor }

            Text {
                readonly property var win: Hyprland.activeToplevel
                readonly property bool here: win !== null && win.monitor === frame.hyprMonitor
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

        Clock {
            id: clock
            anchors.centerIn: parent
        }

        Status {
            anchors { right: parent.right; rightMargin: Theme.frameEdge + 12; verticalCenter: parent.verticalCenter }
        }
    }

    // ── drawers ─────────────────────────────────────────────────────────

    // Calendar: hangs from the bar under the clock while hovered.
    Drawer {
        id: calendar
        anchorX: clock.x + clock.width / 2
        maxX: frame.width - Theme.frameEdge - 8
        openWidth: 300
        openHeight: 28 + calContent.wantedHeight
        open: calHold || calHover.hovered
        property bool calHold: false

        CalendarContent {
            id: calContent
            width: calendar.openWidth
            height: calContent.wantedHeight
        }
    }
    // Open after a short hover (so sweeping across the bar doesn't pop it),
    // and stay open briefly while the pointer travels from clock to drawer.
    Timer { id: calDelay; interval: 150; onTriggered: if (clock.hovered) calendar.calHold = true }
    Timer { id: calStay; interval: 250; onTriggered: if (!clock.hovered) calendar.calHold = false }
    Connections {
        target: clock
        function onHoveredChanged() {
            if (clock.hovered) { calStay.stop(); calDelay.restart(); }
            else { calDelay.stop(); calStay.restart(); }
        }
    }
    Item {
        x: calendar.hit.x; y: calendar.hit.y; width: calendar.hit.width; height: calendar.hit.height
        HoverHandler { id: calHover }
    }

    // Launcher: buds out of the top centre, grows, then pinches off and
    // floats down to the middle of the screen.
    Drawer {
        id: launcher
        anchorX: frame.width / 2
        maxX: frame.width - Theme.frameEdge - 8
        openWidth: 600
        openHeight: launcherContent.wantedHeight
        floatY: Math.round(frame.height * 0.2)
        openRadius: 24
        open: frame.launcherHere
        onOpenChanged: if (open) launcherContent.reset()

        LauncherContent {
            id: launcherContent
            width: launcher.openWidth
            height: launcher.openHeight
        }
    }
}
