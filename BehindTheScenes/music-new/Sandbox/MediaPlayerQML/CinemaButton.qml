import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Shapes 1.15

Item {
    id: root
    width: 600
    height: 260

    // --- BACKLIGHT GLOW ---------------------------------------------
    Rectangle {
        id: backlight
        anchors.fill: parent
        radius: 22
        color: "#00000000"

        Text {
            anchors.centerIn: parent
            text: "Hello"
            color: "black"
            font.pixelSize: 20
    }

        layer.enabled: true
        layer.smooth: true
        // Simulate glow using brightness + blur
        layer.effect: ShaderEffectSource {
            sourceItem: backlight
            hideSource: true
        }
    }

    // --- CINEMASCOPE SHAPE ------------------------------------------
    Shape {
        id: shape
        anchors.fill: parent
        anchors.margins: 6

        ShapePath {
            id: concave
            strokeWidth: 0
            fillColor: "transparent"
            fillRule: ShapePath.WindingFill

            // Top curve
            PathMove { x: 0; y: height * 0.28 }
            PathQuad {
                x: width; y: height * 0.28
                controlX: width / 2; controlY: height * 0.03
            }

            // Right edge
            PathLine { x: width; y: height * 0.72 }

            // Bottom curve
            PathQuad {
                x: 0; y: height * 0.72
                controlX: width / 2; controlY: height * 0.97
            }
        }
    }

    // --- SCREEN FILL ------------------------------------------------
    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 6
        radius: 18

        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(0,0,0,0.85) }
            GradientStop { position: 0.50; color: Qt.rgba(0.15,0.15,0.15,1.0) }
            GradientStop { position: 1.0;  color: Qt.rgba(0,0,0,0.85) }
        }

        border.color: Qt.rgba(1.0, 0.8, 0.2, 0.28)
        border.width: 2

        // Clip to curved shape
        clip: true
        layer.enabled: true
        layer.smooth: true
    }
}
