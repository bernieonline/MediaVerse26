import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5
import QtQuick.Window 6.5

Rectangle {
    id: detailViewRoot
    width: 1000
    height: 600
    color: "black"

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // LEFT PANEL: Poster image
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            color: "transparent"

            Image {
                id: posterImage
                anchors.fill: parent
                source: imagePath   // context property from Python
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // RIGHT PANEL: Tab bar + stack
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true

                TabButton { text: "Details"; checked: true }
                TabButton { text: "Actors" }
                TabButton { text: "Director" }
                TabButton { text: "Filming" }
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // Details tab: show XML text
                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: xmlText        // context property from Python
                        color: "white"
                        wrapMode: Text.Wrap
                        readOnly: true
                        font.family: "Courier New"
                        font.pixelSize: 14
                    }
                }

                // Actors tab
                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: "Actors content"
                        color: "white"
                    }
                }

                // Director tab
                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: "Director content"
                        color: "white"
                    }
                }

                // Filming tab
                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: "Filming content"
                        color: "white"
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("Image path:", imagePath)
        console.log("XML text length:", xmlText.length)
    }
}