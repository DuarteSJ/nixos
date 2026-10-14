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

    screen: Shell.focusedScreen
    visible: Shell.launcherOpen
    onVisibleChanged: if (visible) { query = ""; input.text = ""; selected = 0; input.forceActiveFocus(); }
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
        anchors.fill: parent
        onClicked: Shell.launcherOpen = false
    }

    Rectangle {
        id: box
        anchors.centerIn: parent
        width: 600
        height: 64 + Math.min(launcher.results.length, 8) * 52 + (launcher.results.length ? 12 : 0)
        radius: Theme.radius
        color: Theme.bg
        border.width: 2
        border.color: Theme.blue

        opacity: Shell.launcherOpen ? 1 : 0
        scale: Shell.launcherOpen ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        clip: true

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        // ── search row ──────────────────────────────────────────────────
        Rectangle {
            id: searchRow
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
            height: 40
            radius: 10
            color: Theme.surface

            Rectangle {
                id: chip
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 6 }
                width: chipText.implicitWidth + 20
                height: 28
                radius: 8
                color: Theme.blue
                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: "  Apps"
                    color: Theme.bg
                    font { family: Theme.font; pixelSize: Theme.fontSize - 1; bold: true }
                }
            }

            TextInput {
                id: input
                anchors { left: chip.right; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
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
            highlight: Rectangle { radius: 10; color: Theme.blue }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                width: list.width
                height: 50

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
                        color: row.current ? Theme.bg : Theme.fg
                        font { family: Theme.font; pixelSize: Theme.fontSize; bold: row.current }
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: row.modelData.genericName || row.modelData.comment || ""
                        elide: Text.ElideRight
                        color: row.current ? Theme.alpha(Theme.bg, 0.75) : Theme.subtle
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
