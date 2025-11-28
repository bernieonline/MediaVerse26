import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    property var xmlDetails   // Python object passed in
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
            Layout.margins: 10
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

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