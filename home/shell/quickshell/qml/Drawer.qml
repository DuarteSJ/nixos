import QtQuick

// A liquid drawer: a rounded rectangle that grows out of the bar.
//
// It never pops in.  It is always some rectangle (rx, ry, rw, rh, rr) that
// shaders/attach.frag melts into the bar, and every field chases its target
// on a spring, so retargeting mid-flight keeps momentum.  States:
//
//   0 hidden   tiny, tucked inside the bar (melted in: nothing shows)
//   1 bud      a circle bulging out under the trigger
//   2 grown    full size, hanging from the bar
//
// Content fades in once the glass has arrived.  `reveal` runs 0..1 as
// content appears, so children can stagger themselves (see stagger()).
Item {
    id: d

    property bool open: false
    property real anchorX: 0              // centre x of the trigger
    property real attachY: Theme.barHeight
    property real openWidth: 320
    property real openHeight: 300
    property real openRadius: 22
    property real minX: 0
    property real maxX: 10000
    // How far a grown drawer reaches up into the bar (0: flush under it).
    property real overlap: 0

    property int stage: 0
    property bool contentShown: false
    readonly property bool active: stage > 0

    // 0..1 as content appears; rows can use stagger(i) for a cascade.
    property real reveal: contentShown ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: d.contentShown ? 460 : 110; easing.type: Easing.OutCubic } }
    function stagger(i) { return Math.max(0, Math.min(1, reveal * 1.8 - i * 0.09)); }

    default property alias content: holder.data

    // ── targets ─────────────────────────────────────────────────────────
    readonly property real tw: stage === 0 ? 16 : stage === 1 ? 46 : openWidth
    readonly property real th: stage === 0 ? 16 : stage === 1 ? 46 : openHeight
    readonly property real tTop: stage === 0 ? attachY - 26
                              : stage === 1 ? attachY - 22
                              : attachY - overlap
    readonly property real tLeft: Math.max(minX, Math.min(maxX - tw, anchorX - tw / 2))
    readonly property real tRad: stage <= 1 ? tw / 2 : openRadius

    // ── animated rectangle (what the shader draws) ──────────────────────
    property real rx: tLeft
    property real ry: tTop
    property real rw: tw
    property real rh: th
    property real rr: tRad

    // Width/height/position: lively but settling.
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
        PauseAnimation { duration: 150 }
        ScriptAction { script: d.contentShown = true }
    }

    SequentialAnimation {
        id: closing
        ScriptAction { script: { opening.stop(); d.contentShown = false; } }
        PauseAnimation { duration: 90 }
        ScriptAction { script: d.stage = 1 }
        PauseAnimation { duration: 150 }
        ScriptAction { script: d.stage = 0 }
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
