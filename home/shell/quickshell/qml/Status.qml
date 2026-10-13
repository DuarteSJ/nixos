import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// Right-hand modules: volume, network, bluetooth, system (memory + temperature), battery.
// Each shows its state through its icon alone; hover for the numbers.
// Hovering one reports it (hoverKey/hoverItem) so StatusPopup.qml can open the
// matching status drawer under it.
Row {
    id: root

    spacing: 16

    // Which module the pointer is on ("" = none), for the status drawer.
    property string hoverKey: ""
    property var hoverItem: null
    function track(key, item, on) {
        if (on) { hoverKey = key; hoverItem = item; }
        else if (hoverItem === item) { hoverKey = ""; }
    }

    // ── sysfs / procfs poll (CPU %, memory %, CPU temp, battery) ────────
    property int cpuPct: 0
    property var cpuPrev: [0, 0]          // idle, total from the last poll
    property int memPct: 0
    property int tempC: 0
    // Running average for the icon: the package temperature spikes past
    // 90 C for a moment on short bursts, and a single sample would flash
    // the chip red.  ~15 s to settle at a 3 s poll.
    property real tempSmooth: 0
    property int batPct: -1
    property string batStatus: ""

    Process {
        id: poll
        command: ["sh", "-c",
            "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print int((t-a)*100/t)}' /proc/meminfo;" +
            "{ cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null || echo 0; } | head -1;" +
            "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo -1;" +
            "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo none;" +
            "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.memPct = parseInt(l[0]) || 0;
                root.tempC = Math.round((parseInt(l[1]) || 0) / 1000);
                root.tempSmooth = root.tempSmooth === 0 ? root.tempC
                                : root.tempSmooth * 0.75 + root.tempC * 0.25;
                root.batPct = parseInt(l[2]);
                root.batStatus = l[3] ?? "";
                const f = (l[4] ?? "").trim().split(/\s+/).slice(1).map(Number);
                if (f.length >= 4) {
                    const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
                    const dt = total - root.cpuPrev[1], di = idle - root.cpuPrev[0];
                    if (root.cpuPrev[1] > 0 && dt > 0) root.cpuPct = Math.round(100 * (1 - di / dt));
                    root.cpuPrev = [idle, total];
                }
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

    // Icons carry the state (numbers live in the hover panels).  Each module
    // keeps its own colour; warnings shift it, and red means act now.

    // ── volume: glyph by level; a thin level bar while it changes ────────
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Module {
        id: volMod
        onHoveredChanged: root.track("audio", volMod, hovered)
        readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
        readonly property int vol: Math.round((audio?.volume ?? 0) * 100)
        readonly property bool muted: audio?.muted ?? false
        glyph: muted ? "" : vol < 34 ? "" : vol < 67 ? "" : ""
        glyphColor: muted ? Theme.subtle : Theme.red
        level: muted ? 0 : (audio?.volume ?? 0)
        levelShown: volShow.running

        Timer { id: volShow; interval: 1300 }
        Connections {
            target: volMod.audio
            function onVolumeChanged() { volShow.restart(); }
            function onMutedChanged() { volShow.restart(); }
        }

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

    // ── network: ethernet, or wifi bars from the real signal strength ────
    Module {
        id: netMod
        onHoveredChanged: root.track("network", netMod, hovered)
        readonly property var devices: Networking.devices?.values ?? []
        readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
        readonly property var wifiDev: devices.find(d => d.type === DeviceType.Wifi) ?? null
        readonly property bool connecting: wifiDev?.state === ConnectionState.Connecting
        readonly property var net: wifiDev?.connected ? (wifiDev.networks?.values ?? []).find(n => n.connected) : null
        readonly property real sig: net?.signalStrength ?? 0
        glyph: wired ? "\u{f0201}"
             : net ? (sig < 0.25 ? "\u{f091f}" : sig < 0.5 ? "\u{f0922}" : sig < 0.75 ? "\u{f0925}" : "\u{f0928}")
             : connecting ? "\u{f092f}"
             : !Networking.wifiEnabled ? "\u{f092e}"
             : "\u{f092b}"
        glyphColor: wired || net ? Theme.orange
                  : connecting ? Theme.orange
                  : !Networking.wifiEnabled ? Theme.subtle
                  : Theme.red
        busy: connecting
        onClicked: root.term(["nmtui"])
    }

    // ── bluetooth: off / on / connected; dot = a device's battery is low ─
    Module {
        id: btMod
        onHoveredChanged: root.track("bluetooth", btMod, hovered)
        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property bool on: adapter?.enabled ?? false
        readonly property var linked: (adapter?.devices?.values ?? []).filter(d => d.connected)
        readonly property real lowest: linked.filter(d => d.batteryAvailable)
                                             .reduce((m, d) => Math.min(m, d.battery), 1)
        glyph: !on ? "\u{f00b2}" : linked.length ? "\u{f00b1}" : "\u{f00af}"
        glyphColor: !on ? Theme.subtle : linked.length ? Theme.teal : Theme.blue
        badge: lowest < 0.15 ? Theme.red : lowest < 0.3 ? Theme.yellow : "transparent"
        onClicked: Quickshell.execDetached(["blueman-manager"])
    }

    // ── system: memory + CPU temperature, worst of the two.  This CPU idles
    // in the 70s (TjMax ~100), so temperature only warns from 80 / 90.
    Module {
        id: sysMod
        onHoveredChanged: root.track("system", sysMod, hovered)
        readonly property bool hot: root.memPct >= 90 || root.tempSmooth >= 90
        readonly property bool warm: root.memPct >= 75 || root.tempSmooth >= 80
        glyph: ""
        glyphColor: warm ? Theme.orange : Theme.yellow
        critical: hot
        onClicked: root.term(["btop"])
    }

    // ── battery: the glyph fills in 10 steps; bolt while charging ───────
    Module {
        id: batMod
        onHoveredChanged: root.track("battery", batMod, hovered)
        readonly property bool charging: root.batStatus === "Charging"
        readonly property bool plugged: root.batStatus === "Full" || root.batStatus === "Not charging"
        // empty, 10..90, full
        readonly property var levels: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
                                       "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
        readonly property var chargingLevels: ["\u{f089c}", "\u{f089c}", "\u{f0086}", "\u{f0087}", "\u{f0088}", "\u{f089d}",
                                               "\u{f0089}", "\u{f089e}", "\u{f008a}", "\u{f008b}", "\u{f0085}"]
        readonly property int step: Math.max(0, Math.min(10, Math.round(root.batPct / 10)))
        visible: root.batPct >= 0
        glyph: plugged ? "" : charging ? chargingLevels[step] : levels[step]
        glyphColor: charging || plugged ? Theme.blue
                  : root.batPct < 15 ? Theme.red
                  : root.batPct < 30 ? Theme.yellow : Theme.green
        critical: root.batPct < 15 && !charging && !plugged
    }
}
