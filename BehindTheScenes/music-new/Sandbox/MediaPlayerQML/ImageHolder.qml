import QtQuick 2.15

Item {
    id: root

    property string source: ""
    property string fallbackSource: "file:///D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new/images/No_image_available_small.jpg"

    signal clicked()

    // True only when last load failed
    property bool loadFailed: false

    Image {
        id: realImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: root.source

        onStatusChanged: {
            if (status === Image.Error) {
                console.warn("Failed to load: ", root.source)
                root.loadFailed = true
            } else if (status === Image.Ready) {
                root.loadFailed = false
            }
        }
    }

    Image {
        id: fallbackImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: root.loadFailed
        source: root.fallbackSource
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
