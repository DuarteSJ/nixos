import QtQuick

// A module group hanging from the top edge: square where it meets a screen
// edge, rounded where it floats free (like the old waybar groups).
Item {
    id: root

    property bool roundLeft: true
    property bool roundRight: true
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 28
    implicitHeight: Theme.barHeight

    // Body plus two square patches that cancel the rounding on top (and on
    // whichever bottom side touches a screen edge).
    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius
        color: Theme.bg
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.barRadius
        color: Theme.bg
    }
    Rectangle {
        visible: !root.roundLeft
        anchors { left: parent.left; bottom: parent.bottom }
        width: Theme.barRadius; height: Theme.barRadius
        color: Theme.bg
    }
    Rectangle {
        visible: !root.roundRight
        anchors { right: parent.right; bottom: parent.bottom }
        width: Theme.barRadius; height: Theme.barRadius
        color: Theme.bg
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 16
    }
}
