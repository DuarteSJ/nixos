import QtQuick

// A selectable row in a panel list (output devices, wifi networks,
// bluetooth devices): icon, name, optional tag on the right.  `selected`
// highlights it (the default output, the connected network...).
Rectangle {
    id: row

    property bool selected: false
    property string icon
    property int iconSize: 17
    property bool iconFilled: false
    property color iconColor: selected ? Theme.accent : Theme.fg
    property string text
    property bool bold: false
    property string tag: ""
    property color tagColor: selected ? Theme.accent : Theme.subtle
    // Keep room for the tag column (rows whose tag can be set).
    property bool tagSlot: true
    signal clicked()

    radius: 12
    color: selected ? Theme.glassFillStrong : mouse.containsMouse ? Theme.glassFill : "transparent"

    Icon {
        id: rowIcon
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        icon: row.icon
        size: row.iconSize
        filled: row.iconFilled
        color: row.iconColor
    }
    Text {
        anchors {
            left: rowIcon.right; leftMargin: 10
            right: row.tagSlot ? tagText.left : parent.right; rightMargin: row.tagSlot ? 8 : 10
            verticalCenter: parent.verticalCenter
        }
        text: row.text
        elide: Text.ElideRight
        color: row.selected ? Theme.fgBright : Theme.fg
        font { family: Theme.font; pixelSize: 13; bold: row.bold }
    }
    Text {
        id: tagText
        visible: row.tagSlot
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: row.tag
        color: row.tagColor
        font { family: Theme.font; pixelSize: 11 }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
