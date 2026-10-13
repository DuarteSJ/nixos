import QtQuick

// A liquid drawer: a rounded rectangle that grows out of the bar.
//
// It never pops in.  It is always some rectangle (rx, ry, rw, rh, rr) the
// frame shader melts into the glass, and every field chases its target on
// a spring, so retargeting mid-flight keeps momentum.  States:
//
//   0 hidden   tiny, tucked inside the bar (melted in: nothing shows)
//   1 bud      a circle bulging out under the trigger
//   2 grown    full size, still hanging from the bar
//   3 floating moved down to floatY; a liquid strand (the "neck") keeps it
//              tied to the bar, thins out and snaps, leaving drips that
//              pull back into the bar
//
// Content fades in only once the glass has (mostly) arrived.
Item {
    id: d

    property bool open: false
    property real anchorX: 0              // centre x of the trigger
    property real attachY: Theme.barHeight
    property real openWidth: 320
    property real openHeight: 300
    property real floatY: -1              // >= 0: float free at this y once grown
    property real openRadius: 22
    property real minX: Theme.frameEdge + 8
    property real maxX: 10000

    property int stage: 0
    property bool contentShown: false
    readonly property bool active: stage > 0

    default property alias content: holder.data

    // Drips left behind when a floating drawer snaps off: x, y, r per drip.
    property var dripX: [0, 0, 0, 0]
    property var dripY: [0, 0, 0, 0]
    property var dripR: [0, 0, 0, 0]

    // ── targets ─────────────────────────────────────────────────────────
    readonly property real tw: stage === 0 ? 16 : stage === 1 ? 46 : openWidth
    readonly property real th: stage === 0 ? 16 : stage === 1 ? 46 : openHeight
    readonly property real tTop: stage === 0 ? attachY - 26
                              : stage === 1 ? attachY - 22
                              : stage === 2 ? attachY - 28
                              : floatY
    readonly property real tLeft: Math.max(minX, Math.min(maxX - tw, anchorX - tw / 2))
    readonly property real tRad: stage <= 1 ? tw / 2 : openRadius

    // ── animated rectangle (what the shader draws) ──────────────────────
    property real rx: tLeft
    property real ry: tTop
    property real rw: tw
    property real rh: th
    property real rr: tRad

    // Width/height/position: lively but settling; position a bit softer so
    // the float-away reads as a fall rather than a jump.
    Behavior on rw { SpringAnimation { spring: 4.2; damping: 0.30; epsilon: 0.2 } }
    Behavior on rh { SpringAnimation { spring: 4.2; damping: 0.30; epsilon: 0.2 } }
    Behavior on rx { SpringAnimation { spring: 4.0; damping: 0.34; epsilon: 0.2 } }
    Behavior on ry { SpringAnimation { spring: 3.2; damping: 0.26; epsilon: 0.2 } }
    Behavior on rr { SpringAnimation { spring: 4.0; damping: 0.40; epsilon: 0.2 } }

    readonly property vector4d rect: Qt.vector4d(rx, ry, active || rw > 17 ? rw : 0, active || rw > 17 ? rh : 0)

    // ── sequencing ──────────────────────────────────────────────────────
    onOpenChanged: open ? opening.restart() : closing.restart()

    SequentialAnimation {
        id: opening
        ScriptAction { script: { closing.stop(); d.stage = 1; } }
        PauseAnimation { duration: 85 }
        ScriptAction { script: d.stage = 2 }
        PauseAnimation { duration: d.floatY >= 0 ? 200 : 140 }
        ScriptAction {
            script: {
                if (d.floatY >= 0) { d.stage = 3; neckAnim.restart(); }
                d.contentShown = true;
            }
        }
    }

    SequentialAnimation {
        id: closing
        ScriptAction { script: { opening.stop(); neckAnim.stop(); d.neckW = 0; d.contentShown = false; } }
        PauseAnimation { duration: 90 }
        ScriptAction { script: if (d.stage === 3) d.stage = 2 }
        PauseAnimation { duration: d.floatY >= 0 ? 200 : 0 }
        ScriptAction { script: d.stage = 1 }
        PauseAnimation { duration: 150 }
        ScriptAction { script: d.stage = 0 }
    }

    // ── neck: a strand from the bar to the falling drawer ───────────────
    // Starts nearly as wide as the drawer and thins (accelerating, like a
    // stretching liquid) until it snaps; the drips start at the snap.
    property real neckW: 0
    readonly property real neckTop: attachY - 14
    readonly property vector4d neck: neckW > 1.5
        ? Qt.vector4d(rx + rw / 2 - neckW / 2, neckTop, neckW, Math.max(0, ry + 30 - neckTop))
        : Qt.vector4d(0, 0, 0, 0)
    SequentialAnimation {
        id: neckAnim
        ScriptAction { script: d.neckW = Math.min(d.openWidth * 0.4, 220) }
        NumberAnimation { target: d; property: "neckW"; to: 0; duration: 270; easing.type: Easing.InQuad }
        ScriptAction { script: drips.trigger() }
    }

    // ── drips: spawned where the neck snaps, then sucked back up ────────
    QtObject {
        id: drips
        function trigger() {
            const cx = d.rx + d.rw / 2;
            d.dripX = [cx - 46, cx - 6, cx + 30, cx + 64];
            d.dripY = [d.attachY + 7, d.attachY + 12, d.attachY + 8, d.attachY + 4];
            d.dripR = [9, 12, 8, 6];
            dripAnim.restart();
        }
    }
    property real dripT: 0
    onDripTChanged: {
        const t = dripT, ys = [7, 12, 8, 4], rs = [9, 12, 8, 6], lag = [0.0, 0.1, 0.05, 0.15];
        const y = [], r = [];
        for (let i = 0; i < 4; i++) {
            const u = Math.max(0, Math.min(1, (t - lag[i]) / (1 - lag[i])));
            const e = u * u * (3 - 2 * u);                      // smoothstep
            y.push(d.attachY + ys[i] * (1 - e) - 10 * e);       // rise into the bar
            r.push(rs[i] * (1 - e));
        }
        d.dripY = y;
        d.dripR = r;
    }
    NumberAnimation {
        id: dripAnim
        target: d; property: "dripT"
        from: 0; to: 1; duration: 460
        easing.type: Easing.InOutQuad
    }

    // ── what other code uses ────────────────────────────────────────────
    // Input region (only while there is something to click).
    Item {
        id: hitItem
        x: d.rx; y: Math.max(d.ry, d.attachY); width: d.active ? d.rw : 0
        height: d.active ? d.ry + d.rh - Math.max(d.ry, d.attachY) : 0
    }
    property alias hit: hitItem

    // Content lives in the part of the rectangle below the bar.
    Item {
        id: holder
        x: d.rx
        y: Math.max(d.ry, d.attachY)
        width: d.rw
        height: Math.max(0, d.ry + d.rh - y)
        clip: true
        opacity: d.contentShown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: d.contentShown ? 200 : 90 } }
    }
}
