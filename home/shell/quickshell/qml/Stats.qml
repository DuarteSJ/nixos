pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth

// System state shared by every bar (one per screen) and the status panels:
// one poll, one set of derived values.
//   CPU / memory / CPU temperature / battery  read from procfs + sysfs every 3 s
//   brightness                                 brightnessctl, on demand (refreshBrightness)
//   network devices, bluetooth adapter         derived from the Quickshell services
Singleton {
    id: s

    // ── CPU %, memory %, CPU temperature, battery ───────────────────────
    property int cpuPct: 0
    property var cpuPrev: [0, 0]          // idle, total from the last poll
    property int memPct: 0
    property int tempC: 0
    // Running average for the icon: the package temperature spikes past
    // 90 C for a moment on short bursts, and a single sample would flash
    // the chip red.  ~15 s to settle at a 3 s poll.
    property real tempSmooth: 0
    property int batPct: -1               // -1 = no battery
    property string batStatus: "none"
    readonly property bool charging: batStatus === "Charging"
    readonly property bool plugged: batStatus === "Full" || batStatus === "Not charging"

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            meminfo.reload();
            stat.reload();
            if (tempFile.path !== "") tempFile.reload();
            batCap.reload();
            batStat.reload();
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const t = parseInt(text().match(/^MemTotal:\s+(\d+)/m)?.[1]);
            const a = parseInt(text().match(/^MemAvailable:\s+(\d+)/m)?.[1]);
            s.memPct = t > 0 && !isNaN(a) ? Math.floor((t - a) * 100 / t) : 0;
        }
        onLoadFailed: s.memPct = 0
    }

    FileView {
        id: stat
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const f = text().split("\n", 1)[0].trim().split(/\s+/).slice(1).map(Number);
            if (f.length < 4) return;
            const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
            const dt = total - s.cpuPrev[1], di = idle - s.cpuPrev[0];
            if (s.cpuPrev[1] > 0 && dt > 0) s.cpuPct = Math.round(100 * (1 - di / dt));
            s.cpuPrev = [idle, total];
        }
    }

    // coretemp's hwmon index isn't stable across boots: resolve it once.
    Process {
        running: true
        command: ["sh", "-c", "for f in /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input; do [ -e \"$f\" ] && echo \"$f\" && break; done"]
        stdout: StdioCollector { onStreamFinished: tempFile.path = text.trim() }
    }
    FileView {
        id: tempFile
        path: ""
        printErrors: false
        onLoaded: s.setTemp(parseInt(text()) || 0)
        onLoadFailed: s.setTemp(0)
    }
    function setTemp(milli) {
        tempC = Math.round(milli / 1000);
        tempSmooth = tempSmooth === 0 ? tempC : tempSmooth * 0.75 + tempC * 0.25;
    }

    FileView {
        id: batCap
        path: "/sys/class/power_supply/BAT0/capacity"
        printErrors: false
        onLoaded: { const v = parseInt(text()); s.batPct = isNaN(v) ? -1 : v; }
        onLoadFailed: s.batPct = -1
    }
    FileView {
        id: batStat
        path: "/sys/class/power_supply/BAT0/status"
        printErrors: false
        onLoaded: s.batStatus = text().trim()
        onLoadFailed: s.batStatus = "none"
    }

    // ── backlight (0..1, -1 = none to drive) ────────────────────────────
    property real brightness: -1
    // Every read, changed or not (the OSD flashes on it).
    signal brightnessRead(real value)
    Component.onCompleted: refreshBrightness()

    function refreshBrightness() {
        if (readB.running) readB.again = true;
        else readB.running = true;
    }
    Process {
        id: readB
        property bool again: false
        command: ["brightnessctl", "-m"]
        // name,class,current,percent%,max
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.split(",")[3]);
                s.brightness = isNaN(v) ? -1 : v / 100;
                if (s.brightness >= 0) s.brightnessRead(s.brightness);
            }
        }
        onExited: code => {
            if (code !== 0) s.brightness = -1;
            if (again) { again = false; running = true; }
        }
    }

    // ── network / bluetooth ─────────────────────────────────────────────
    readonly property var netDevices: Networking.devices?.values ?? []
    readonly property var wired: netDevices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: netDevices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter?.enabled ?? false
}
