import QtQuick

// Icon badge + title (+ optional right-hand item) at the top of a panel.
Item {
    id: h
    property string icon
    property string title
    property string detail: ""
    default property alias trailing: rightSlot.data

    implicitHeight: 30

    Rectangle {
        id: badge
        width: 30; height: 30; radius: 9
        color: Theme.glassFill
        Icon { anchors.centerIn: parent; icon: h.icon; size: 18; color: Theme.accent }
    }
    Column {
        anchors { left: badge.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
        Text { text: h.title; color: Theme.fgBright; font { family: Theme.font; pixelSize: 14; bold: true } }
        Text {
            visible: h.detail !== ""
            width: h.width - 50 - rightSlot.width
            text: h.detail; elide: Text.ElideRight
            color: Theme.muted; font { family: Theme.font; pixelSize: 11 }
        }
    }
    Item {
        id: rightSlot
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: childrenRect.width; height: childrenRect.height
    }
}
