import QtQuick
import Quickshell
import Quickshell.Wayland

// A drawer that grows out of one of the bar's groups, as one shape with it.
//
// A layer surface anchored to the top of the screen (not an xdg-popup:
// Hyprland places those a few px lower than asked, which leaves a gap
// under the group).  shaders/attach.frag smooth-unions the drawer with the
// group but only paints outside the group, which the bar draws itself.
// Input is the drawer card only, so the bar underneath keeps working.
//
// `side` picks where the window sits: "right" (flush with the screen's
// right edge, for the status group) or "center" (for the clock group).
PanelWindow {
    id: win

    required property var barWindow
    required property var group           // Group in Bar.qml it grows out of
    property string side: "center"
    property int winW: 520

    property alias drawer: drawer
    property alias hovered: cardHover.hovered
    default property alias content: drawer.content

    // Window x in bar coordinates.
    readonly property real originX: side === "right" ? barWindow.width - winW
                                                     : Math.round((barWindow.width - winW) / 2)
    // Group rect in window coordinates, extended up past the screen top (and
    // right past the edge for a right-flush group) so only its free corners
    // are rounded -- like Group.qml.
    readonly property vector4d groupRect: Qt.vector4d(
        group.x - originX, -60,
        group.width + (side === "right" ? 60 : 0), Theme.barHeight + 60)

    screen: barWindow.screen
    anchors { top: true; right: side === "right" }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-attached"
    WlrLayershell.layer: WlrLayer.Top
    implicitWidth: winW
    implicitHeight: 640
    color: "transparent"
    visible: drawer.open || drawer.active || drawer.rw > 17
    mask: Region { item: drawer.hit }

    ShaderEffect {
        anchors.fill: parent
        property vector2d res: Qt.vector2d(width, height)
        property vector4d group: win.groupRect
        property real groupR: Theme.barRadius
        property vector4d card: drawer.rect
        property real cardR: drawer.rr
        property real k: 16
        property color color: Theme.bg
        fragmentShader: Qt.resolvedUrl("shaders/attach.frag.qsb")
    }

    Drawer {
        id: drawer
        attachY: Theme.barHeight
        overlap: 0
        openRadius: 14
        minX: 0
        // Right edge stops exactly at the window's (= screen's) right edge.
        maxX: win.winW
    }
    Item {
        x: drawer.hit.x; y: drawer.hit.y; width: drawer.hit.width; height: drawer.hit.height
        HoverHandler { id: cardHover }
    }
}
