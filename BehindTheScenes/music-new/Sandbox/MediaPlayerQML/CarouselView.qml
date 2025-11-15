import QtQuick 2.15
import QtQuick.Controls 2.15

FocusScope {
    id: root
    width: parent.width
    height: parent.height

    property var imageList: fileSystemManager.imageFiles
    property int currentIndex: 0

    property real baseWidth: root.width / 8
    property real baseHeight: baseWidth * 1.5

    function scrollLeft() {
        if (currentIndex > 0) currentIndex--
    }

    function scrollRight() {
        if (currentIndex < imageList.length - 1) currentIndex++
    }

    Rectangle {
        id: carouselFrame
        width: baseWidth * 10
        height: baseHeight * 1.4
        anchors.centerIn: parent
        color: "transparent"

        Row {
            id: imageRow
            spacing: 20
            anchors.centerIn: parent

            Repeater {
                model: 5
                delegate: Item {
                    property int offset: index - 2
                    property int imageIndex: currentIndex + offset
                    property bool valid: imageIndex >= 0 && imageIndex < imageList.length

                    width: {
                        switch (Math.abs(offset)) {
                            case 0: return baseWidth * 1.6
                            case 1: return baseWidth * 1.3
                            default: return baseWidth
                        }
                    }
                    height: width * 1.5

                    ImageHolder {
                        anchors.fill: parent
                        source: valid ? imageList[imageIndex].filePath : ""
                        smooth: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: valid
                        onClicked: {
                            currentIndex = imageIndex
                            console.log("Clicked image:", imageList[imageIndex]?.filePath)
                        }
                    }
                }
            }
        }
    }

    // Left scroll button (enlarged and styled)
    Button {
        id: leftScrollButton
        text: "◀"
        anchors.verticalCenter: carouselFrame.verticalCenter
        anchors.verticalCenterOffset: baseHeight * 0.6
        anchors.right: carouselFrame.horizontalCenter
        anchors.rightMargin: baseWidth * 1.6 + 20
        onClicked: scrollLeft()

        width: 300
        height: 120

        background: Rectangle {
            color: "transparent"
            border.color: "yellow"
            border.width: 3
            radius: 10
        }

        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 60
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Right scroll button (enlarged and styled)
    Button {
        id: rightScrollButton
        text: "▶"
        anchors.verticalCenter: carouselFrame.verticalCenter
        anchors.verticalCenterOffset: baseHeight * 0.6
        anchors.left: carouselFrame.horizontalCenter
        anchors.leftMargin: baseWidth * 1.6 + 20
        onClicked: scrollRight()

        width: 300
        height: 120

        background: Rectangle {
            color: "transparent"
            border.color: "yellow"
            border.width: 3
            radius: 10
        }

        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 60
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Message when no images are available
    Text {
        text: "No images to display."
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 24
        visible: !imageList || imageList.length === 0
    }
}