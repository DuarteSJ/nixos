import QtQuick

// Mute button + volume slider for one PipeWire node (output or mic).
Row {
    id: r

    required property var node
    required property string icon
    required property string mutedIcon
    required property color fill
    readonly property var audio: node?.audio ?? null
    readonly property bool muted: audio?.muted ?? false

    spacing: 10

    Rectangle {
        width: 30; height: 30; radius: 15
        color: muteMouse.containsMouse ? Theme.glassFillStrong : Theme.glassFill
        Icon { anchors.centerIn: parent; icon: r.muted ? r.mutedIcon : r.icon; size: 17; color: r.muted ? Theme.red : Theme.fg }
        MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (r.audio) r.audio.muted = !r.audio.muted }
    }
    GlassSlider {
        width: parent.width - 40
        anchors.verticalCenter: parent.verticalCenter
        value: r.audio?.volume ?? 0
        fill: r.muted ? Theme.subtle : r.fill
        onMoved: v => { if (r.audio) r.audio.volume = v; }
    }
}
