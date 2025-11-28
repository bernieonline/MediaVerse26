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

        GridView {
            id: imageGridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

            model: fileSystemManager.imageFiles
            cellWidth: imageGridView.width / 6
            cellHeight: (imageGridView.width / 6) * 1.5

            delegate: ImageHolder {
                width: imageGridView.width / 6
                height: (imageGridView.width / 6) * 1.5
                source: modelData.filePath

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.imageClicked(modelData.filePath)
                }
            }
        }

        Loader {
            id: detailLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: false
            source: ""

            onLoaded: {
                if (!item || !xmlDetails) return
                item.xmlDetails = xmlDetails
                item.imagePath = root._pendingImagePath
                xmlDetails.loadXML(root._pendingImagePath)
            }
        }
    }

    Connections {
        target: root
        function onImageClicked(filePath) {
            root._pendingImagePath = filePath
            detailLoader.active = false
            detailLoader.source = "Detail_View.qml"
            detailLoader.active = true
        }
    }
}