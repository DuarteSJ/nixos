import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Volume / brightness pop-up that slides up from the bottom edge.  Volume
// reacts to PipeWire on its own; brightness is pinged over IPC by the
// brightness keys (qs -c shell ipc call osd brightness).
PanelWindow {
    id: osd

    property string icon: "volume_up"
    property real value: 0
    property bool shown: false

    function flash(icon, value) {
        osd.icon = icon;
        osd.value = value;
        osd.shown = true;
        hide.restart();
    }

    function showBrightness() { brightness.running = true; }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 72
    implicitWidth: 280
    implicitHeight: 52
    exclusiveZone: 0
    color: "transparent"
    visible: shown || card.opacity > 0
    mask: Region {}

    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    Timer { id: hide; interval: 1400; onTriggered: osd.shown = false }

    // Ignore the burst of change signals while Pipewire binds at startup.
    property bool armed: false
    Timer { running: true; interval: 1500; onTriggered: osd.armed = true }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() { osd.fromSink(); }
        function onMutedChanged() { osd.fromSink(); }
    }
    function fromSink() {
        const a = Pipewire.defaultAudioSink?.audio;
        if (!a || !armed) return;
        flash(a.muted ? "volume_off" : a.volume < 0.34 ? "volume_mute" : a.volume < 0.67 ? "volume_down" : "volume_up",
              a.muted ? 0 : a.volume);
    }

    Process {
        id: brightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent%,max
                const pct = parseInt(text.split(",")[3]) / 100;
                if (!isNaN(pct)) osd.flash(pct < 0.5 ? "brightness_5" : "brightness_7", pct);
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.blue

        opacity: osd.shown ? 1 : 0
        transform: Translate { y: osd.shown ? 0 : 18; Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 18
            spacing: 14

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: osd.icon
                size: 22
                filled: true
                color: Theme.accent
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 22 - 36 - 28
                height: 6
                radius: 3
                color: Theme.surface

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, osd.value))
                    height: parent.height
                    radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.blue }
                        GradientStop { position: 1; color: Theme.teal }
                    }
                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(osd.value * 100)
                color: Theme.fg
                font { family: Theme.font; pixelSize: 13; bold: true }
            }
        }
    }
}
