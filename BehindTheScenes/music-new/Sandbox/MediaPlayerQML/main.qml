import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: "Effects Test"
    
    Rectangle {
        id: myRect
        width: 200
        height: 200
        color: "blue"
        anchors.centerIn: parent
    }
    
    DropShadow {
        anchors.fill: myRect
        source: myRect
        horizontalOffset: 3
        verticalOffset: 3
        radius: 8.0
        samples: 16
        color: "#80000000"
    }
}