import QtQuick
import Quickshell
import Quickshell.Wayland

// Invisible strip that reserves space along one screen edge, so tiled
// windows sit inside the frame's hole instead of under the glass.
PanelWindow {
    required property var modelData
    property string edge: "top"     // top | bottom | left | right
    property int size: Theme.frameEdge

    screen: modelData
    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitWidth: size
    implicitHeight: size
    exclusiveZone: size
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "qs-reserve"
    WlrLayershell.layer: WlrLayer.Bottom
}
