import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// App launcher (replaces `rofi -show drun`).  Fuzzy search over name,
// generic name, keywords and comment; apps you launch often float up.
// Up/Down (or Ctrl+K/J, Tab) to move, Enter to launch, Esc to close.
PanelWindow {
    id: launcher

    property string query: ""
    property int selected: 0
    property var counts: ({})      // desktop id -> launch count

    // ── fuzzy scoring ───────────────────────────────────────────────────
    // Subsequence match; consecutive runs, word starts and an early first
    // hit score higher.  -1 = no match.
    function fuzzy(needle, hay) {
        if (!hay) return -1;
        hay = hay.toLowerCase();
        let score = 0, h = 0, run = 0, first = -1, prev = -2;
        for (let i = 0; i < needle.length; i++) {
            const c = needle[i];
            let found = -1;
            for (; h < hay.length; h++) if (hay[h] === c) { found = h; break; }
            if (found < 0) return -1;
            if (first < 0) first = found;
            const wordStart = found === 0 || " -_./".includes(hay[found - 1]);
            run = found === prev + 1 ? run + 1 : 0;
            score += 1 + run * 3 + (wordStart ? 4 : 0);
            prev = found;
            h = found + 1;
        }
        return score - first * 0.5 + (hay.startsWith(needle) ? 10 : 0);
    }

    readonly property var results: {
        const q = query.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const scored = [];
        for (const e of apps) {
            const freq = Math.log2(1 + (counts[e.id] ?? 0)) * 3;
            if (q === "") { scored.push({ e, s: freq }); continue; }
            const s = Math.max(
                fuzzy(q, e.name) * 2,
                fuzzy(q, e.genericName),
                fuzzy(q, (e.keywords ?? []).join(" ")),
                fuzzy(q, e.comment) * 0.5);
            if (s >= 0) scored.push({ e, s: s + freq });
        }
        scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name));
        return scored.map(x => x.e);
    }
    onResultsChanged: selected = 0

    function launch(entry) {
        if (!entry) return;
        Shell.launcherOpen = false;
        const c = Object.assign({}, counts);
        c[entry.id] = (c[entry.id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
        if (entry.runInTerminal)
            Theme.term(entry.command);
        else
            entry.execute();
    }

    // Launch counts persist across sessions.
    FileView {
        id: store
        path: Quickshell.statePath("launcher-counts.json")
        printErrors: false
        onLoaded: { try { launcher.counts = JSON.parse(text()); } catch (e) {} }
    }

    // Open/close motion.  The card follows `dropped`, not Shell.launcherOpen,
    // so each direction's easing is in place before its slide starts:
    // open overshoots and settles, close dips first and then shoots up.
    property bool mapped: false      // until the closing slide has left the screen
    property bool dropped: false
    property bool entering: false    // rows created now cascade in
    Connections {
        target: Shell
        function onLauncherOpenChanged() {
            if (Shell.launcherOpen) {
                launcher.entering = true; enterWindow.restart();
                launcher.query = ""; input.text = ""; launcher.selected = 0;
                launcher.mapped = true;
                slide.duration = 160; slide.easing.type = Easing.OutBack; slide.easing.overshoot = 1.3;
                fade.duration = 80; fade.easing.type = Easing.Linear;
                launcher.dropped = true;
                input.forceActiveFocus();
            } else {
                slide.duration = 80; slide.easing.type = Easing.InBack; slide.easing.overshoot = 1.6;
                fade.duration = 80; fade.easing.type = Easing.InQuad;
                launcher.dropped = false;
            }
        }
    }
    Timer { id: enterWindow; interval: 80; onTriggered: launcher.entering = false }

    screen: Shell.focusedScreen
    visible: mapped
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    // Let go of the keyboard as soon as it starts closing, not after the slide.
    WlrLayershell.keyboardFocus: Shell.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: Shell.launcherOpen = false
    }

    // Drops in from above the screen edge and comes to rest centred; slides
    // back up to close.  The top edge is fixed where a full (8-row) card is
    // centred, so typing only grows/shrinks it downward.
    Rectangle {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: launcher.dropped ? Math.round((launcher.height - (64 + 8 * 52 + 12)) / 2) : -height - 2
        width: 600
        height: 64 + Math.min(launcher.results.length, 8) * 52 + (launcher.results.length ? 12 : 0)
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.glassEdge

        opacity: launcher.dropped ? 1 : 0
        Behavior on y {
            NumberAnimation {
                id: slide
                onRunningChanged: if (!running && !launcher.dropped) launcher.mapped = false
            }
        }
        Behavior on opacity { NumberAnimation { id: fade } }
        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
        clip: true

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        // ── search row ──────────────────────────────────────────────────
        Rectangle {
            id: searchRow
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
            height: 40
            radius: 10
            color: Theme.glassFill

            Icon {
                id: glyph
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 10 }
                icon: "search"
                size: 20
                color: Theme.muted
            }

            TextInput {
                id: input
                anchors { left: glyph.right; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                color: Theme.fg
                selectionColor: Theme.blue
                selectedTextColor: Theme.bg
                font { family: Theme.font; pixelSize: Theme.fontSize }
                clip: true
                onTextChanged: launcher.query = text

                Text {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search…"
                    color: Theme.subtle
                    font: input.font
                }

                Keys.onPressed: e => {
                    const n = launcher.results.length;
                    const down = e.key === Qt.Key_Down || e.key === Qt.Key_Tab
                        || (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_J || e.key === Qt.Key_N));
                    const up = e.key === Qt.Key_Up || e.key === Qt.Key_Backtab
                        || (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_K || e.key === Qt.Key_P));
                    if (e.key === Qt.Key_Escape) { Shell.launcherOpen = false; e.accepted = true; }
                    else if (down && n) { launcher.selected = (launcher.selected + 1) % n; e.accepted = true; }
                    else if (up && n) { launcher.selected = (launcher.selected + n - 1) % n; e.accepted = true; }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        launcher.launch(launcher.results[launcher.selected]); e.accepted = true;
                    }
                }
            }
        }

        // ── results ─────────────────────────────────────────────────────
        ListView {
            id: list
            anchors { top: searchRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12; topMargin: 8 }
            model: launcher.results
            currentIndex: launcher.selected
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 90
            highlight: Rectangle {
                id: hl
                radius: 10
                color: Theme.glassFillStrong
                // Hidden while the rows cascade in, then fades in under them.
                Connections {
                    target: launcher
                    function onEnteringChanged() {
                        if (launcher.entering) { hlIn.stop(); hl.opacity = 0; }
                        else hlIn.restart();
                    }
                }
                NumberAnimation { id: hlIn; target: hl; property: "opacity"; to: 1; duration: 220 }
                Rectangle {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 3 }
                    width: 3
                    height: parent.height / 2
                    radius: 2
                    color: Theme.accent
                }
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                width: list.width
                height: 50

                // Cascade in, one row after the other, right after opening.
                transform: Translate { id: shift }
                function enter() { if (launcher.entering) cascade.restart(); }
                Component.onCompleted: enter()
                Connections { target: launcher; function onEnteringChanged() { row.enter(); } }
                SequentialAnimation {
                    id: cascade
                    PropertyAction { target: row; property: "opacity"; value: 0 }
                    PropertyAction { target: shift; property: "y"; value: 14 }
                    PauseAnimation { duration: 80 + row.index * 35 }
                    ParallelAnimation {
                        NumberAnimation { target: row; property: "opacity"; to: 1; duration: 220 }
                        NumberAnimation { target: shift; property: "y"; to: 0; duration: 220; easing.type: Easing.OutBack }
                    }
                }

                IconImage {
                    id: icon
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    implicitSize: 30
                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                }

                Column {
                    anchors { left: icon.right; right: parent.right; leftMargin: 12; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Text {
                        width: parent.width
                        text: row.modelData.name
                        elide: Text.ElideRight
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: Theme.fontSize; bold: row.current }
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: row.modelData.genericName || row.modelData.comment || ""
                        elide: Text.ElideRight
                        color: row.current ? Theme.muted : Theme.subtle
                        font { family: Theme.font; pixelSize: Theme.fontSize - 3 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: launcher.selected = row.index
                    onClicked: launcher.launch(row.modelData)
                }
            }
        }
    }
}
