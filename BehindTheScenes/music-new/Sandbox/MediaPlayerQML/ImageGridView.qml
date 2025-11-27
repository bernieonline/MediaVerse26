import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    //property var xmlDetails
    property var xmlDetails   // declare here, but DO NOT shadow with a local assignment

    color: "transparent"

    signal imageClicked(string filePath)
    property string _pendingImagePath: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // -----------------------
        // GRID VIEW
        // -----------------------
        GridView {
            id: imageGridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

            anchors.margins: 10
            model: fileSystemManager.imageFiles
            cellWidth: imageGridView.width / 6
            cellHeight: (imageGridView.width / 6) * 1.5

            delegate: ImageHolder {
                width: imageGridView.width / 6
                height: (imageGridView.width / 6) * 1.5
                source: modelData.filePath

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Image clicked:", modelData.filePath)
                        root.imageClicked(modelData.filePath)
                    }
                }
            }
        }

        // -----------------------
        // LOADER FOR DETAIL VIEW
        // -----------------------
        Loader {
            id: detailLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: false
            source: ""

            onLoaded: {
                console.log("Loader onLoaded triggered")
                console.log("xmlDetails object:", xmlDetails)
                console.log("Pending image path:", root._pendingImagePath)

                if (!item) {
                    console.log("Warning: Loader.item is null")
                    return
                }

                if (!xmlDetails) {
                    console.log("Warning: Python xmlDetails object is undefined")
                    return
                }

                // Assign Python object and image path
                item.xmlDetails = xmlDetails
                item.imagePath = root._pendingImagePath

                console.log("Assigned xmlDetails to detail view")
                console.log("Detail view imagePath:", item.imagePath)

                // Connect signal dynamically
                xmlDetails.xml_detail_view.connect(function(text) {
                    console.log("Received XML text from Python signal")

                    if (item.xmlTextArea) {
                        item.xmlTextArea.text = text
                        console.log("Updated xmlTextArea text:", text)
                    } else {
                        console.log("Warning: item.xmlTextArea not found")
                    }
                })

                // Trigger XML load
                console.log("Calling xmlDetails.loadXML with:", root._pendingImagePath)
                xmlDetails.loadXML(root._pendingImagePath)
            }
        }
    }

    // -----------------------
    // CONNECT GRIDVIEW SIGNAL TO LOADER
    // -----------------------
    Connections {
        target: root
        function onImageClicked(filePath) {
            console.log("Loading detail view for:", filePath)

            // Store path temporarily for Loader
            root._pendingImagePath = filePath

            // Reset and reload Loader
            detailLoader.active = false
            detailLoader.source = "Detail_View.qml"
            detailLoader.active = true
        }
    }
}
