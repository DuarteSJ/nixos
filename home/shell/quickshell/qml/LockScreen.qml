import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen (replaces hyprlock).  What it draws is LockContent.qml.
//
//   Shell.locked       the real lock: ext-session-lock (WlSessionLock), so
//                      Hyprland keeps the session locked even if this
//                      process dies.
//   Shell.lockPreview  the same screen as a plain overlay, no lock -- for
//                      trying it out safely.  Esc or the right password
//                      closes it, and it closes itself after 45 s.
//
// The password is checked by PAM service "qs-lock" (system/default.nix).
//
// If the shell crashes while locked: Hyprland's
// misc.allow_session_lock_restore lets a new client take the lock over, and
// a marker file in $XDG_RUNTIME_DIR makes the restarted shell lock again
// straight away.
Scope {
    id: scope

    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qs-shell-locked"

    // ── auth, shared by every monitor's surface ─────────────────────────
    QtObject {
        id: authCtl
        property string state: "idle"     // idle | checking | failed
        property string pending: ""
        signal failed()

        function submit(text) {
            if (state === "checking" || text === "") return;
            pending = text;
            state = "checking";
            // A PAM that can't even start (e.g. no /etc/pam.d/qs-lock) must
            // not leave the pill stuck in "checking": fail, so it can retry.
            if (!pam.start()) fail();
            else stuck.restart();
        }
        function fail() {
            stuck.stop();
            pending = "";
            state = "failed";
            failed();
            failReset.restart();
        }
        function unlock() {
            stuck.stop();
            Shell.locked = false;
            Shell.lockPreview = false;
            state = "idle";
        }
    }

    PamContext {
        id: pam
        config: "qs-lock"
        onPamMessage: {
            if (responseRequired) {
                respond(authCtl.pending);
                authCtl.pending = "";
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) authCtl.unlock();
            else authCtl.fail();
        }
        onError: authCtl.fail()
    }
    Timer { id: failReset; interval: 1600; onTriggered: if (authCtl.state === "failed") authCtl.state = "idle" }
    // Last resort: a check that never finishes gives the pill back.
    Timer {
        id: stuck
        interval: 15000
        onTriggered: if (authCtl.state === "checking") { pam.abort(); authCtl.fail(); }
    }

    // ── marker file (crash recovery) ────────────────────────────────────
    Connections {
        target: Shell
        function onLockedChanged() {
            Quickshell.execDetached(Shell.locked ? ["touch", scope.marker] : ["rm", "-f", scope.marker]);
        }
    }
    Process {
        running: true
        command: ["test", "-e", scope.marker]
        onExited: code => { if (code === 0) Shell.locked = true; }
    }

    // ── the real lock ───────────────────────────────────────────────────
    WlSessionLock {
        locked: Shell.locked
        WlSessionLockSurface {
            color: Theme.bg
            LockContent { anchors.fill: parent; auth: authCtl; preview: false }
        }
    }

    // ── preview (no lock) ───────────────────────────────────────────────
    Timer { running: Shell.lockPreview; interval: 45000; onTriggered: Shell.lockPreview = false }
    PanelWindow {
        id: previewWin
        visible: Shell.lockPreview && !Shell.locked
        screen: Shell.focusedScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        WlrLayershell.namespace: "qs-lockpreview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Loader {
            anchors.fill: parent
            active: previewWin.visible
            sourceComponent: LockContent { auth: authCtl; preview: true }
        }
    }
}
