import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen (replaces hyprlock).
//
//   Shell.locked       real lock: ext-session-lock via WlSessionLock, so
//                      the compositor keeps the session locked even if
//                      this process dies (see the restore note below).
//   Shell.lockPreview  the same screen as an ordinary overlay, no lock --
//                      for previews / screenshots.  Esc or any password
//                      that checks out closes it.
//
// Passwords are checked with PAM service "qs-lock" (system config).
//
// Crash safety: a marker file exists while locked.  Hyprland's
// misc.allow_session_lock_restore lets a fresh client take over a lock
// whose client died, and on start-up we re-lock if the marker is there,
// so a crash + systemd restart lands straight back on this screen.
Scope {
    id: scope

    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qs-shell-locked"

    // ── auth (shared by every monitor's surface) ────────────────────────
    QtObject {
        id: authCtl
        property string state: "idle"        // idle | checking | failed | ok
        property string message: ""
        property string pending: ""
        signal failed()
        signal succeeded()

        function submit(text) {
            if (pam.active) return;
            pending = text;
            message = "";
            state = "checking";
            pam.active = true;
        }
        function cancelPreview() { if (Shell.lockPreview) Shell.lockPreview = false; }
    }

    PamContext {
        id: pam
        config: "qs-lock"
        onPamMessage: {
            if (responseRequired) { respond(authCtl.pending); authCtl.pending = ""; }
            else if (messageIsError) authCtl.message = message;
        }
        onCompleted: result => {
            authCtl.pending = "";
            if (result === PamResult.Success) {
                authCtl.state = "ok";
                authCtl.succeeded();
                release.restart();
            } else {
                authCtl.state = "failed";
                authCtl.failed();
                resetFail.restart();
            }
        }
        onError: err => {
            authCtl.pending = "";
            authCtl.state = "failed";
            authCtl.message = "authentication error";
            authCtl.failed();
        }
    }
    Timer { id: resetFail; interval: 2200; onTriggered: if (authCtl.state === "failed") authCtl.state = "idle" }
    // Let the exit animation play, then actually unlock.
    Timer {
        id: release
        interval: 420
        onTriggered: {
            Shell.locked = false;
            Shell.lockPreview = false;
            authCtl.state = "idle";
        }
    }

    // ── marker file ─────────────────────────────────────────────────────
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
            LockContent { anchors.fill: parent; auth: authCtl }
        }
    }

    // ── preview (no lock) ───────────────────────────────────────────────
    // Closes itself after 45 s so a broken preview can never trap the
    // keyboard (it takes exclusive keyboard focus).
    Timer { running: Shell.lockPreview; interval: 45000; onTriggered: Shell.lockPreview = false }
    PanelWindow {
        id: previewWin
        visible: Shell.lockPreview && !Shell.locked
        screen: Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        WlrLayershell.namespace: "qs-lockpreview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Loader {
            anchors.fill: parent
            active: previewWin.visible
            sourceComponent: LockContent { auth: authCtl }
        }
    }
}
