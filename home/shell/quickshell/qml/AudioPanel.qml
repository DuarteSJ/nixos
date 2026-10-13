import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Sound: output volume + mute, mic, and which output device is default.
Column {
    id: p
    required property var drawer
    spacing: 12
    readonly property real wantedHeight: implicitHeight + 32

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    PwObjectTracker { objects: [p.sink, p.source] }

    PanelHeader {
        width: parent.width
        opacity: p.drawer.stagger(0)
        icon: p.sink?.audio?.muted ? "volume_off" : "volume_up"
        title: "Sound"
        detail: p.sink?.description ?? "No output"
        Text {
            text: Math.round((p.sink?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.fgBright
            font { family: Theme.font; pixelSize: 15; bold: true }
        }
    }

    Row {
        width: parent.width
        spacing: 10
        opacity: p.drawer.stagger(1)
        Rectangle {
            width: 30; height: 30; radius: 15
            color: muteMouse.containsMouse ? Theme.glassFillStrong : Theme.glassFill
            Icon { anchors.centerIn: parent; icon: p.sink?.audio?.muted ? "volume_off" : "volume_up"; size: 17; color: p.sink?.audio?.muted ? Theme.red : Theme.fg }
            MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (p.sink?.audio) p.sink.audio.muted = !p.sink.audio.muted }
        }
        GlassSlider {
            width: parent.width - 40
            anchors.verticalCenter: parent.verticalCenter
            value: p.sink?.audio?.volume ?? 0
            fill: p.sink?.audio?.muted ? Theme.subtle : Theme.accent
            onMoved: v => { if (p.sink?.audio) p.sink.audio.volume = v; }
        }
    }

    Row {
        width: parent.width
        spacing: 10
        visible: p.source !== null
        opacity: p.drawer.stagger(2)
        Rectangle {
            width: 30; height: 30; radius: 15
            color: micMouse.containsMouse ? Theme.glassFillStrong : Theme.glassFill
            Icon { anchors.centerIn: parent; icon: p.source?.audio?.muted ? "mic_off" : "mic"; size: 17; color: p.source?.audio?.muted ? Theme.red : Theme.fg }
            MouseArea { id: micMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (p.source?.audio) p.source.audio.muted = !p.source.audio.muted }
        }
        GlassSlider {
            width: parent.width - 40
            anchors.verticalCenter: parent.verticalCenter
            value: p.source?.audio?.volume ?? 0
            fill: p.source?.audio?.muted ? Theme.subtle : Theme.blue
            onMoved: v => { if (p.source?.audio) p.source.audio.volume = v; }
        }
    }

    Text {
        visible: p.sinks.length > 1
        opacity: p.drawer.stagger(3)
        text: "OUTPUT"
        color: Theme.subtle
        font { family: Theme.font; pixelSize: 11; bold: true; letterSpacing: 1.5 }
    }
    Repeater {
        model: p.sinks.length > 1 ? p.sinks : []
        delegate: Rectangle {
            id: out
            required property var modelData
            required property int index
            readonly property bool isDefault: modelData === p.sink
            width: p.width; height: 34; radius: 12
            opacity: p.drawer.stagger(4 + index)
            color: isDefault ? Theme.glassFillStrong : outMouse.containsMouse ? Theme.glassFill : "transparent"
            Icon { id: outIcon; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                icon: out.isDefault ? "radio_button_checked" : "radio_button_unchecked"; size: 16; color: out.isDefault ? Theme.accent : Theme.muted }
            Text {
                anchors { left: outIcon.right; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                text: out.modelData.description || out.modelData.nickname || out.modelData.name
                elide: Text.ElideRight
                color: out.isDefault ? Theme.fgBright : Theme.fg
                font { family: Theme.font; pixelSize: 13 }
            }
            MouseArea { id: outMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink = out.modelData }
        }
    }

    Text {
        opacity: p.drawer.stagger(6) * 0.8
        text: "Open mixer  ›"
        color: Theme.accent
        font { family: Theme.font; pixelSize: 12 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["pavucontrol"]) }
    }
}
