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
    // Transparent; the input mask is the card only.  A drawer that can grow
    // taller (the dashboard's panel stack) raises this to the screen height;
    // the shader below only covers what is drawn, so that costs nothing.
    property int winH: 640
    implicitHeight: winH
    color: "transparent"
    // Never without the bar it grows out of (Super+B, focus mode).
    visible: Shell.barShown && (drawer.open || drawer.active || drawer.rw > 17)
    mask: Region { item: drawer.hit }

    // The shader runs over the box around the group and the card (plus the
    // smooth-union margin), not the whole window: the dashboard window is
    // screen-tall, but most of it is empty.
    ShaderEffect {
        id: shape
        readonly property real pad: k + 2
        readonly property bool hasCard: drawer.rect.z >= 1 && drawer.rect.w >= 1
        readonly property real gx0: Math.max(0, win.groupRect.x)
        readonly property real gx1: Math.min(win.width, win.groupRect.x + win.groupRect.z)
        readonly property real x0: Math.max(0, Math.floor((hasCard ? Math.min(gx0, drawer.rect.x) : gx0) - pad))
        readonly property real x1: Math.min(win.width, Math.ceil((hasCard ? Math.max(gx1, drawer.rect.x + drawer.rect.z) : gx1) + pad))
        readonly property real y1: Math.min(win.height, Math.ceil(Math.max(Theme.barHeight, hasCard ? drawer.rect.y + drawer.rect.w : 0) + pad))
        x: x0; y: 0
        width: Math.max(1, x1 - x0); height: Math.max(1, y1)

        // Uniforms, in this item's coordinates.
        property vector2d res: Qt.vector2d(width, height)
        property vector4d group: Qt.vector4d(win.groupRect.x - x0, win.groupRect.y, win.groupRect.z, win.groupRect.w)
        property real groupR: Theme.barRadius
        property vector4d card: Qt.vector4d(drawer.rect.x - x0, drawer.rect.y, drawer.rect.z, drawer.rect.w)
        property real cardR: drawer.rr
        property real k: 16
        property color color: Theme.bg
        fragmentShader: Qt.resolvedUrl("shaders/attach.frag.qsb")
    }

    Drawer {
        id: drawer
        openRadius: 14
        // Right edge stops exactly at the window's (= screen's) right edge.
        maxX: win.winW
    }
    Item {
        x: drawer.hit.x; y: drawer.hit.y; width: drawer.hit.width; height: drawer.hit.height
        // Disabled while the bar is hidden: that clears `hovered`, which a
        // hidden surface would otherwise keep (it never sees the pointer leave).
        HoverHandler { id: cardHover; enabled: Shell.barShown }
    }
}
