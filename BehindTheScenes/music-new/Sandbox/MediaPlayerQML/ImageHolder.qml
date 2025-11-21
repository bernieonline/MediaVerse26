import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property alias source: image.source
    property alias fillMode: image.fillMode
    property alias smooth: image.smooth

    signal clicked()

    Image {
        id: image
        //anchors.fill: parent

        anchors.centerIn: parent

        width: isFallback ? parent.width * 0.5 : parent.width - 40
        height: isFallback ? parent.height * 0.5 : parent.height - 40



        //anchors.centerIn: parent
        //width: parent.width * 0.5
        //height: parent.height * 0.5

        anchors.margins: 20
        fillMode: Image.PreserveAspectCrop
        smooth: true
        z: 2
        property bool isFallback: false

        onStatusChanged: {
            if (status === Image.Error && source !== "" && source !== "about:blank") {
                console.warn("Image failed to load:", source)
                source = "file:///D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new/images/No_image_available_small.jpg"
                isFallback = true
            }
        }
    }

    SubtleGlowStyling {
        target: image
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
