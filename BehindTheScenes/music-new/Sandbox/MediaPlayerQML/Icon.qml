import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    property string name: ""
    property color iconColor: "white"

    width: 22
    height: 22

    Image {
        id: iconImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: "file:///" + _paths["svg_solid"] + "/" + name + ".svg"
        layer.enabled: true

        layer.effect: ColorOverlay {
            anchors.fill: iconImg
            source: iconImg
            color: iconColor
        }
    }
}