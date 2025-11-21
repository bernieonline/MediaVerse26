

import QtQuick 2.15

Item {
    id: root

    property string source: ""
    property string fallbackSource: "file:///D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new/images/No_image_available_small.jpg"
    signal clicked()

    property bool loadFailed: false

    SoftGlowFrame {
        id: frame
        anchors.fill: parent
        imageSource: root.loadFailed ? root.fallbackSource : root.source
    }

    // This invisible loader checks whether the real image fails
    Image {
        id: realImageCheck
        source: root.source
        visible: false
        asynchronous: true

        onStatusChanged: {
            if (status === Image.Error)
                root.loadFailed = true
            else if (status === Image.Ready)
                root.loadFailed = false
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
