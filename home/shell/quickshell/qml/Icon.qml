import QtQuick

// A Material Symbols Rounded glyph, addressed by ligature name ("lock").
Text {
    property string icon
    property real size: 18
    property bool filled: false

    text: icon
    color: Theme.fg
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "GRAD": 0, "opsz": 24 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color { ColorAnimation { duration: 160 } }
}
