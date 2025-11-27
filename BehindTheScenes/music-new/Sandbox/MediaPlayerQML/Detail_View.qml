import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5

Rectangle {
    id: detailViewRoot
    anchors.fill: parent
    color: "transparent"

    // Properties assigned by Loader
    property string imagePath: ""
    property var xmlDetails

    // --- NEW: call Python slot when view loads ---
    Component.onCompleted: {
        if (xmlDetails) {
            console.log("Detail_View: calling xmlDetails.loadXML with", imagePath)
            xmlDetails.loadXML(imagePath)
        } else {
            console.warn("Detail_View: xmlDetails is undefined")
        }
    }

    // --- NEW: listen for Python signal and update TextArea ---
    Connections {
        target: xmlDetails
        function onXml_detail_view(text) {
            console.log("Detail_View received XML text")
            xmlTextArea.text = text
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // -----------------------
        // LEFT PANEL: IMAGE
        // -----------------------
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: leftPanel.height * 2 / 3
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            radius: 15
            color: "transparent"

            Image {
                id: posterImage
                anchors.fill: parent
                source: detailViewRoot.imagePath
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
        }

        // -----------------------
        // RIGHT PANEL: TAB BAR + STACK
        // -----------------------
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

                // -----------------------
                // DETAILS TAB
                // -----------------------
                Rectangle {
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: xmlTextArea
                        anchors.fill: parent
                        readOnly: true
                        wrapMode: Text.Wrap
                        text: "No details available"
                        color: "black"
                        font.pixelSize: 16
                    }
                }

                // -----------------------
                // ACTORS TAB
                // -----------------------
                Rectangle {
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text { anchors.centerIn: parent; text: "Actors content"; color: "white" }
                }

                // -----------------------
                // DIRECTOR TAB
                // -----------------------
                Rectangle {
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text { anchors.centerIn: parent; text: "Director content"; color: "white" }
                }

                // -----------------------
                // FILMING TAB
                // -----------------------
                Rectangle {
                    color: "transparent"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text { anchors.centerIn: parent; text: "Filming content"; color: "white" }
                }
            }
        }
    }
}