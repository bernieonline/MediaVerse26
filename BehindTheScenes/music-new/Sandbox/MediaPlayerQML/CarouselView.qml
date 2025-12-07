import QtQuick 2.15
import QtQuick.Controls 2.15
import "."
import Qt5Compat.GraphicalEffects 6.0
//import UltraGlowFrame.qml

FocusScope {
    id: root
    width: parent.width
    height: parent.height

    signal imageClicked(string filePath)
    signal launchVideoRequested(string cachePath)

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
            spacing: 100
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

                    UltraGlowFrame {
                        anchors.fill: parent
                        source: valid ? imageList[imageIndex].filePath : ""
                        glowRadius: (Math.abs(offset) === 0) ? 60 : 30
                        glowColor: "#256c40"
                        smooth: true
                        opacity: 0.3
                    }

                    MouseArea {
                        property bool doubleClickActive: false
                        property var singleClickTimer: null

                        anchors.fill: parent
                        enabled: valid

                        onClicked: {
                            if (!valid) return
                            let idx = imageIndex
                            if (singleClickTimer) singleClickTimer.stop()
                            singleClickTimer = Qt.createQmlObject(
                                'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                                root
                            )
                            singleClickTimer.triggered.connect(function() {
                                if (!doubleClickActive) {
                                    console.log("✅ Single click confirmed in CarouselView")
                                    root.imageClicked(imageList[idx].filePath)
                                }
                                doubleClickActive = false
                            })
                            singleClickTimer.start()
                            currentIndex = idx
                            console.log("Clicked image:", imageList[idx].filePath)
                        }
                        onDoubleClicked: {
                            if (!valid) return
                            let idx = imageIndex
                            console.log("🎯 Double‑clicked in CarouselView:", imageList[idx].filePath)
                            doubleClickActive = true
                            if (singleClickTimer) singleClickTimer.stop()
                            root.launchVideoRequested(imageList[idx].filePath)
                        }
                    }
                }
            }
        }
    }

    // Scroll buttons wrapped in a Row
    Row {
        id: scrollButtonsRow
        anchors.horizontalCenter: carouselFrame.horizontalCenter
        anchors.verticalCenter: carouselFrame.verticalCenter
        anchors.verticalCenterOffset: baseHeight * 0.9
        spacing: 50

        Button {
            id: leftScrollButton
            text: "◀"
            width: 400
            height: 60
            onClicked: scrollLeft()

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

        Button {
            id: rightScrollButton
            text: "▶"
            width: 400
            height: 60
            onClicked: scrollRight()

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