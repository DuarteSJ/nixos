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

    VolumeRow {
        width: parent.width
        opacity: p.drawer.stagger(1)
        node: p.sink
        icon: "volume_up"; mutedIcon: "volume_off"
        fill: Theme.accent
    }
    VolumeRow {
        width: parent.width
        visible: p.source !== null
        opacity: p.drawer.stagger(2)
        node: p.source
        icon: "mic"; mutedIcon: "mic_off"
        fill: Theme.blue
    }

    SectionLabel {
        visible: p.sinks.length > 1
        opacity: p.drawer.stagger(3)
        text: "OUTPUT"
    }
    Repeater {
        model: p.sinks.length > 1 ? p.sinks : []
        delegate: ListRow {
            required property var modelData
            required property int index
            width: p.width; height: 34
            opacity: p.drawer.stagger(4 + index)
            selected: modelData === p.sink
            icon: selected ? "radio_button_checked" : "radio_button_unchecked"
            iconSize: 16
            iconColor: selected ? Theme.accent : Theme.muted
            text: modelData.description || modelData.nickname || modelData.name
            tagSlot: false
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    PanelLink {
        opacity: p.drawer.stagger(6) * 0.8
        text: "Open mixer  ›"
        command: ["pavucontrol"]
    }
}
