import QtQuick 2.15

Item {
    id: root
    width: 120
    height: 180

    property string imageSource: ""
    property string fallbackSource: "images/fallback.png"

    property bool loadFailed: false

    // Glow
    Rectangle {
        id: glow
        anchors.centerIn: parent
        width: parent.width + 20
        height: parent.height + 20
        radius: 20
        color: "transparent"
        opacity: 0.15
    }

    // Image with fallback
    Image {
        id: realImage
        anchors.fill: parent
        source: root.loadFailed ? root.fallbackSource : root.imageSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true

        onStatusChanged: {
            if (status === Image.Error) root.loadFailed = true
            else if (status === Image.Ready) root.loadFailed = false
        }
    }
}