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
    property bool tenFootMode: false   // toggle for large display mode

    // Call Python slot when view loads
    Component.onCompleted: {
        if (xmlDetails && imagePath) {
            xmlDetails.loadXML(imagePath)
        }
        if (imagePath && imagePath.length > 0) {
            xmlController.loadXML(imagePath)
            var cats = xmlController.getCategories()
            if (cats.length > 0) {
                tabBar.currentIndex = 0
                xmlController.requestCategoryContent(cats[0])
            }
        }
    }

    // Listen for Python signal and update TextArea
    Connections {
        target: xmlController
        function onCategoryContentUpdated(category, lines) {
            xmlTextArea.text = lines.join("\n\n") // add spacing between lines

            // Font styling
            //font.pixelSize: detailViewRoot.tenFootMode ? 48 : 16
            //font.bold: true        // <--- makes text bold
            //padding: 20




        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // --- Left panel: image ---
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

        // --- Right panel: tabbed content ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                Repeater {
                    model: xmlController.getCategories()
                    TabButton {
                        text: modelData
                        onClicked: xmlController.requestCategoryContent(modelData)
                    }
                }
            }

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

                    // Dark theme adjustments
                    background: null
                    color: "white"

                    // Font styling
                    font.pixelSize: detailViewRoot.tenFootMode ? 48 : 16
                    font.bold: true        // <--- makes text bold
                    padding: 20


                    // Font scaling for 10ft mode
                    //font.pixelSize: detailViewRoot.tenFootMode ? 48 : 16

                    //padding: 20
                }
            }
        }
    }
}