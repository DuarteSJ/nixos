import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire

// Right-hand modules: volume, network, memory, temperature, battery.
Row {
    id: root

    spacing: 16

    // ── sysfs / procfs poll (memory %, CPU temp, battery) ───────────────
    property int memPct: 0
    property int tempC: 0
    property int batPct: -1
    property string batStatus: ""

    Process {
        id: poll
        command: ["sh", "-c",
            "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print int((t-a)*100/t)}' /proc/meminfo;" +
            "cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 || echo 0;" +
            "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo -1;" +
            "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo none"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.memPct = parseInt(l[0]) || 0;
                root.tempC = Math.round((parseInt(l[1]) || 0) / 1000);
                root.batPct = parseInt(l[2]);
                root.batStatus = l[3] ?? "";
            }
        }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    function term(cmd) {
        Quickshell.execDetached([Theme.terminal, "-e"].concat(cmd));
    }

    // ── volume ──────────────────────────────────────────────────────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Module {
        readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
        readonly property int vol: Math.round((audio?.volume ?? 0) * 100)
        readonly property bool muted: audio?.muted ?? false
        glyph: muted ? "" : vol < 34 ? "" : vol < 67 ? "" : ""
        glyphColor: muted ? Theme.subtle : Theme.red
        onClicked: m => {
            if (m.button === Qt.RightButton && audio) audio.muted = !audio.muted;
            else Quickshell.execDetached(["pavucontrol"]);
        }
        // 1% per notch, capped at 100% going up.  Only this control (and the
        // volume keys) cap: pavucontrol can still push past 100%, and
        // scrolling up from there leaves it alone instead of pulling it back.
        onWheel: w => {
            if (!audio) return;
            const v = audio.volume;
            if (w.angleDelta.y > 0) {
                if (v < 1) audio.volume = Math.min(1, Math.round(v * 100 + 1) / 100);
            } else {
                audio.volume = Math.max(0, Math.round(v * 100 - 1) / 100);
            }
        }
    }

    // ── network ─────────────────────────────────────────────────────────
    Module {
        readonly property var devices: Networking.devices?.values ?? []
        readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected)
        readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected)
        glyph: wired ? "\u{f0201}" : wifi ? "" : ""
        glyphColor: wired || wifi ? Theme.orange : Theme.red
        label: wired ? "wired" : wifi ? "" : "offline"
        onClicked: root.term(["nmtui"])
    }

    // ── memory ──────────────────────────────────────────────────────────
    Module {
        glyph: ""
        glyphColor: root.memPct >= 70 ? Theme.orange : Theme.yellow
        label: root.memPct + "%"
        critical: root.memPct >= 90
        onClicked: root.term(["btop"])
    }

    // ── temperature ─────────────────────────────────────────────────────
    Module {
        glyph: root.tempC >= 80 ? "" : root.tempC >= 60 ? "" : ""
        glyphColor: Theme.teal
        label: root.tempC + "°C"
        critical: root.tempC >= 80
        onClicked: root.term(["btop"])
    }

    // ── battery ─────────────────────────────────────────────────────────
    Module {
        readonly property bool charging: root.batStatus === "Charging"
        readonly property bool plugged: root.batStatus === "Full" || root.batStatus === "Not charging"
        readonly property var levels: ["\u{f007a}", "\u{f007c}", "\u{f007e}", "\u{f0080}", "\u{f0079}"]
        visible: root.batPct >= 0
        glyph: charging ? "\u{f0084}" : plugged ? ""
             : levels[Math.max(0, Math.min(4, Math.floor(root.batPct / 20)))]
        glyphColor: charging || plugged ? Theme.blue : root.batPct < 30 ? Theme.yellow : Theme.green
        label: root.batPct + "%"
        critical: root.batPct < 15 && !charging && !plugged
    }
}
