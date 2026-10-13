import QtQuick

// Month calendar that grows out of the clock group while the clock is
// hovered (150 ms delay; stays while the pointer is on it).
AttachedDrawer {
    id: cal

    required property var clock           // Clock.qml (has `hovered`)

    side: "center"
    winW: 420

    property bool hold: false
    drawer.anchorX: winW / 2
    drawer.openWidth: 300
    drawer.openHeight: calContent.wantedHeight
    drawer.open: hold || hovered || Shell.dashboard

    Timer { id: openDelay; interval: 150; onTriggered: if (cal.clock.hovered) cal.hold = true }
    Timer { id: stay; interval: 250; onTriggered: if (!cal.clock.hovered) cal.hold = false }
    Connections {
        target: cal.clock
        function onHoveredChanged() {
            if (cal.clock.hovered) { stay.stop(); openDelay.restart(); }
            else { openDelay.stop(); stay.restart(); }
        }
    }

    CalendarContent {
        id: calContent
        width: cal.drawer.openWidth
        height: calContent.wantedHeight
    }
}
