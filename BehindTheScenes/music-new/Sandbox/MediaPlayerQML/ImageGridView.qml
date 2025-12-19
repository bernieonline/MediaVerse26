import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    property var xmlDetails   // Python object passed in
    property string _pendingImagePath: ""
    property string currentFolderPath: ""

    color: "transparent"

    signal launchVideoRequested(string cachePath)
    signal imageClicked(string cachePath, string originalPath)

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

            // Guard against null fileSystemManager
            model: fileSystemManager ? fileSystemManager.imageFiles : []

            cellWidth: imageGridView.width / 6
            cellHeight: (imageGridView.width / 6) * 1.5

            delegate: ImageHolder {
                width: imageGridView.width / 6
                height: (imageGridView.width / 6) * 1.5

                source: modelData.filePath

                // Define doubleClickActive at delegate level
                property bool doubleClickActive: false

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton

                    property Timer singleClickTimer: Timer {
                        interval: 250
                        repeat: false
                        onTriggered: {
                            if (!parent.doubleClickActive) {
                                console.log("✅ Single click confirmed")
                                root.imageClicked(modelData.filePath, modelData.originalPath)
                            }
                            parent.doubleClickActive = false
                        }
                    }

                    onClicked: {
                        singleClickTimer.stop()
                        singleClickTimer.start()
                    }

                    onDoubleClicked: {
                        parent.doubleClickActive = true
                        singleClickTimer.stop()

                        console.log("🎯 Image Double‑clicked:", modelData.fileName)

                        window.selectedImageFile = modelData.fileName
                        let folderPath = window.selectedFolderPath
                        let videoPath  = fileSystemManager.findVideoInFolder(folderPath, window.selectedImageFile)

                        console.log("➡️ Double‑click resolved videoPath:", videoPath)
                        SettingsManager.launch_video_with_preferred_player(videoPath)
                    }
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
        function onImageClicked(cachePath, originalPath) {
            console.log("📂 imagegridview: Cache Path:", cachePath)
            console.log("🖼️ imagegridview: Original Path:", originalPath)

            root._pendingImagePath = cachePath

            detailLoader.active = false
            detailLoader.source = "Detail_View.qml"
            detailLoader.active = true

            detailLoader.item.imagePath = cachePath
            detailLoader.item.originalXmlPath = originalPath

            var vid = fileSystemManager.findVideoForImage(cachePath)
            detailLoader.item.videoPath = vid

            console.log("Video URL from Python:", vid)
        }
    }
}