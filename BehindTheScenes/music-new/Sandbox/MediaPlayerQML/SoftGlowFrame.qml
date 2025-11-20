import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 120
    height: 180  // 2:3 portrait ratio

    property string imageSource  // External image path

    // Glow layer
    Rectangle {
        id: glow
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: 16
        color: "#FFD700"  // Gold
        opacity: 0.25
    }

    // Inner frame
    Rectangle {
        id: frame
        anchors.centerIn: parent
        width: parent.width - 12
        height: parent.height - 12
        radius: 12
        color: "#eeeeee"
        border.color: "#cccccc"
        border.width: 1

        // Image loader
        Image {
            id: image
            anchors.centerIn: parent
            source: root.imageSource
            fillMode: Image.PreserveAspectFit
            width: parent.width - 16
            height: parent.height - 16
            cache: true
            asynchronous: true
        }
    }
}