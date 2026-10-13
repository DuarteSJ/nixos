import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

// Launcher body, living inside the launcher drawer (see Frame.qml).
//
// Modes, picked by the first character typed:
//   (none)  apps     fuzzy search over desktop entries; frequent apps rise
//   @       windows  jump to an open window
//   >       run      run the rest as a shell command
//   =       calc     arithmetic; Enter copies the result
// Up/Down (Ctrl+J/K, Tab) move, Enter runs, Esc closes.
Item {
    id: launcher

    required property var drawer          // for drawer.stagger(i)

    property string query: ""
    property int selected: 0
    property var counts: ({})             // desktop id -> launch count

    readonly property string mode: query.startsWith("@") ? "windows"
                                 : query.startsWith(">") ? "run"
                                 : query.startsWith("=") ? "calc"
                                 : "apps"
    readonly property string term: (mode === "apps" ? query : query.slice(1)).trim()

    readonly property int rowH: 52
    readonly property int maxRows: 7
    readonly property real wantedHeight: 176 + Math.min(results.length, maxRows) * rowH

    function reset() { input.text = ""; selected = 0; input.forceActiveFocus(); }

    // ── fuzzy scoring ───────────────────────────────────────────────────
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

    function calc(expr) {
        if (!/^[0-9+\-*/%^().,\s]+$/.test(expr) || expr === "") return null;
        try {
            const v = Function("return (" + expr.replace(/\^/g, "**").replace(/,/g, ".") + ")")();
            return (typeof v === "number" && isFinite(v)) ? +v.toPrecision(12) : null;
        } catch (e) { return null; }
    }

    // Every mode yields rows of { icon, name, sub, run() }.
    readonly property var results: {
        const q = term.toLowerCase();
        if (mode === "calc") {
            const v = calc(term);
            return v === null ? [] : [{
                glyph: "=", name: String(v), sub: "Enter to copy",
                run: () => Quickshell.execDetached(["sh", "-c", `printf %s '${v}' | wl-copy`])
            }];
        }
        if (mode === "run") {
            return term === "" ? [] : [{
                glyph: ">", name: term, sub: "Run in shell",
                run: () => Quickshell.execDetached(["sh", "-c", term])
            }];
        }
        if (mode === "windows") {
            const wins = Hyprland.toplevels.values.filter(t => t.title);
            return wins
                .map(t => ({ t, s: q === "" ? 0 : Math.max(fuzzy(q, t.title), fuzzy(q, t.lastIpcObject?.class ?? "")) }))
                .filter(x => x.s >= 0)
                .sort((a, b) => b.s - a.s)
                .map(x => ({
                    icon: Quickshell.iconPath((x.t.lastIpcObject?.class ?? "").toLowerCase(), "window"),
                    name: x.t.title,
                    sub: (x.t.lastIpcObject?.class ?? "") + "  ·  workspace " + (x.t.workspace?.id ?? "?"),
                    run: () => {
                        const a = String(x.t.address).startsWith("0x") ? x.t.address : "0x" + x.t.address;
                        Hyprland.dispatch(Hyprland.usingLua
                            ? `hl.dsp.focus({ window = "address:${a}" })`
                            : `focuswindow address:${a}`);
                    }
                }));
        }
        const scored = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            const freq = Math.log2(1 + (counts[e.id] ?? 0)) * 3;
            if (q === "") { scored.push({ e, s: freq }); continue; }
            const s = Math.max(fuzzy(q, e.name) * 2, fuzzy(q, e.genericName),
                               fuzzy(q, (e.keywords ?? []).join(" ")), fuzzy(q, e.comment) * 0.5);
            if (s >= 0) scored.push({ e, s: s + freq });
        }
        scored.sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name));
        return scored.map(x => ({
            icon: Quickshell.iconPath(x.e.icon, "application-x-executable"),
            name: x.e.name,
            sub: x.e.genericName || x.e.comment || "",
            run: () => launcher.launchApp(x.e)
        }));
    }
    onResultsChanged: selected = 0

    function launchApp(entry) {
        const c = Object.assign({}, counts);
        c[entry.id] = (c[entry.id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
        if (entry.runInTerminal)
            Quickshell.execDetached([Theme.terminal, "-e"].concat(entry.command));
        else
            entry.execute();
    }

    function activate(i) {
        const r = results[i];
        if (!r) return;
        Shell.launcherOpen = false;
        r.run();
    }

    FileView {
        id: store
        path: Quickshell.statePath("launcher-counts.json")
        printErrors: false
        onLoaded: { try { launcher.counts = JSON.parse(text()); } catch (e) {} }
    }

    // ── header ──────────────────────────────────────────────────────────
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16; topMargin: 14 }
        height: 30
        opacity: launcher.drawer.stagger(0)

        Rectangle {
            id: badge
            width: 30; height: 30; radius: 9
            color: Theme.glassFill
            Icon { anchors.centerIn: parent; icon: "apps"; size: 18; color: Theme.fgBright }
        }
        Text {
            id: title
            anchors { left: badge.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: "SEARCH"
            color: Theme.fgBright
            font { family: Theme.font; pixelSize: 13; bold: true; letterSpacing: 1.5 }
        }
        Rectangle {
            anchors { left: title.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
            width: modeText.implicitWidth + 18; height: 22; radius: 11
            color: Theme.glassFill
            Text {
                id: modeText
                anchors.centerIn: parent
                text: ({ apps: "Apps", windows: "Windows", run: "Run", calc: "Calc" })[launcher.mode]
                color: Theme.accent
                font { family: Theme.font; pixelSize: 12; bold: true }
            }
        }
        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 26; height: 26; radius: 13
            color: closeMouse.containsMouse ? Theme.glassFillStrong : "transparent"
            Icon { anchors.centerIn: parent; icon: "close"; size: 16; color: Theme.muted }
            MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Shell.launcherOpen = false }
        }
    }

    // ── search field ────────────────────────────────────────────────────
    Rectangle {
        id: field
        anchors { top: header.bottom; left: parent.left; right: parent.right; margins: 16; topMargin: 12 }
        height: 42
        radius: 14
        color: Theme.glassFill
        border.width: 1
        border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.5) : Theme.glassEdge
        opacity: launcher.drawer.stagger(1)

        Icon {
            id: lens
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            icon: "search"; size: 19; color: Theme.muted
        }
        TextInput {
            id: input
            anchors { left: lens.right; right: parent.right; leftMargin: 10; rightMargin: 14; verticalCenter: parent.verticalCenter }
            color: Theme.fgBright
            selectionColor: Theme.accent
            selectedTextColor: Theme.bg
            font { family: Theme.font; pixelSize: 16 }
            clip: true
            onTextChanged: launcher.query = text

            Text {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: "Search apps…"
                color: Theme.muted
                font: input.font
            }

            Keys.onPressed: e => {
                const n = launcher.results.length;
                const ctrl = e.modifiers & Qt.ControlModifier;
                const down = e.key === Qt.Key_Down || e.key === Qt.Key_Tab || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N));
                const up = e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P));
                if (e.key === Qt.Key_Escape) { Shell.launcherOpen = false; e.accepted = true; }
                else if (down && n) { launcher.selected = (launcher.selected + 1) % n; e.accepted = true; }
                else if (up && n) { launcher.selected = (launcher.selected + n - 1) % n; e.accepted = true; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { launcher.activate(launcher.selected); e.accepted = true; }
            }
        }
    }

    // ── mode chips ──────────────────────────────────────────────────────
    Row {
        id: chips
        anchors { top: field.bottom; left: parent.left; leftMargin: 20; topMargin: 9 }
        spacing: 16
        opacity: launcher.drawer.stagger(2) * 0.9
        Repeater {
            model: [["@", "windows"], [">", "run"], ["=", "calc"]]
            Row {
                required property var modelData
                spacing: 5
                Text { text: modelData[0]; color: Theme.accent; font { family: Theme.font; pixelSize: 12; bold: true } }
                Text { text: modelData[1]; color: Theme.muted; font { family: Theme.font; pixelSize: 12 } }
            }
        }
    }

    // ── results ─────────────────────────────────────────────────────────
    ListView {
        id: list
        anchors { top: chips.bottom; left: parent.left; right: parent.right; bottom: footer.top; margins: 10; topMargin: 8; bottomMargin: 4 }
        model: launcher.results
        currentIndex: launcher.selected
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 140
        highlightMoveVelocity: -1
        highlight: Rectangle {
            radius: 14
            color: Theme.glassFillStrong
            border.width: 1
            border.color: Theme.glassEdge
            Rectangle {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                width: 3; height: 20; radius: 1.5
                color: Theme.accent
            }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem
            readonly property real shown: launcher.drawer.stagger(3 + Math.min(index, 8))
            width: list.width
            height: launcher.rowH
            opacity: shown
            transform: Translate { y: (1 - row.shown) * 10 }

            Item {
                id: iconBox
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                width: 32; height: 32
                IconImage {
                    anchors.fill: parent
                    visible: !!row.modelData.icon
                    source: row.modelData.icon ?? ""
                }
                Text {
                    anchors.centerIn: parent
                    visible: !row.modelData.icon
                    text: row.modelData.glyph ?? ""
                    color: Theme.accent
                    font { family: Theme.font; pixelSize: 20; bold: true }
                }
            }

            Column {
                anchors { left: iconBox.right; right: parent.right; leftMargin: 14; rightMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 2
                Text {
                    width: parent.width
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: row.current ? Theme.fgBright : Theme.fg
                    font { family: Theme.font; pixelSize: 15; bold: row.current }
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.sub ?? ""
                    elide: Text.ElideRight
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: 12 }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: launcher.selected = row.index
                onClicked: launcher.activate(row.index)
            }
        }
    }

    // ── footer ──────────────────────────────────────────────────────────
    Item {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18; bottomMargin: 12 }
        height: 18
        opacity: launcher.drawer.stagger(4) * 0.8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "↑↓ move   ·   ↵ open   ·   esc close"
            color: Theme.muted
            font { family: Theme.font; pixelSize: 11 }
        }
        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: launcher.results.length ? (launcher.selected + 1) + " / " + launcher.results.length : "no matches"
            color: Theme.muted
            font { family: Theme.font; pixelSize: 11 }
        }
    }
}
