import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 600
    color: "#1e1e1e"

    Column {
        anchors.fill: parent

        // Top bar for button
        Rectangle {
            id: topBar
            width: parent.width
            height: 60
            color: "#1e1e1e"

            Rectangle {
                id: triggerButton
                width: 120; height: 40
                color: "gold"; radius: 6
                anchors.centerIn: parent

                Text {
                    anchors.centerIn: parent
                    text: "Toggle Panel"
                    color: "#1e1e1e"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (slider.y === bottomArea.height) {
                            slideAnim.to = bottomArea.height - slider.height
                        } else {
                            slideAnim.to = bottomArea.height
                        }
                        slideAnim.start()
                    }
                }
            }
        }

        // Bottom area for image
        Rectangle {
            id: bottomArea
            width: parent.width
            height: parent.height - topBar.height
            color: "#000000"

            Image {
                anchors.fill: parent
                source: "file:///C:/Users/berna/pythonproject2026/BehindTheScenes/BehindTheScenes/music-new/images/Gemini_Generated_dark_theme.png"
                fillMode: Image.PreserveAspectCrop
            }

            // Slider overlaps this area
            SliderPanel {
                id: slider
            }
        }
    }

    // Animation
    NumberAnimation {
        id: slideAnim
        target: slider
        property: "y"
        duration: 400
        easing.type: Easing.InOutQuad
    }
}