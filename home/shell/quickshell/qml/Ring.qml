import QtQuick
import QtQuick.Shapes

// Progress ring with the value in the middle and a caption under it.
Item {
    id: r

    property real value: 0          // 0..1
    property string text: ""
    property string caption: ""
    property color color: Theme.accent

    implicitWidth: 74
    implicitHeight: 74 + 18

    Shape {
        width: 74; height: 74
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.glassFillStrong
            strokeWidth: 6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 37; centerY: 37; radiusX: 32; radiusY: 32; startAngle: 135; sweepAngle: 270 }
        }
        ShapePath {
            strokeColor: r.color
            strokeWidth: 6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 37; centerY: 37; radiusX: 32; radiusY: 32; startAngle: 135
                sweepAngle: 270 * Math.max(0.001, Math.min(1, r.value))
                Behavior on sweepAngle { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
    }
    Text {
        x: 0; width: 74; y: 26
        horizontalAlignment: Text.AlignHCenter
        text: r.text
        color: Theme.fgBright
        font { family: Theme.font; pixelSize: 16; bold: true }
    }
    Text {
        x: 0; width: 74; y: 76
        horizontalAlignment: Text.AlignHCenter
        text: r.caption
        color: Theme.muted
        font { family: Theme.font; pixelSize: 11; letterSpacing: 1 }
    }
}
