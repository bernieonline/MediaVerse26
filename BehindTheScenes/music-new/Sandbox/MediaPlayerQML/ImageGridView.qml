import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    property var xmlDetails   // Python object passed in
    //model: fileSystemManager ? fileSystemManager.imageFiles : []

    color: "transparent"
    signal launchVideoRequested(string cachePath)//used by double click play video method
    signal imageClicked(string cachePath, string originalPath)
    property string _pendingImagePath: ""
    property string currentFolderPath: ""

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

                // Load thumbnail directly from cache
                source: modelData.filePath
               
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton

                    property bool doubleClickActive: false
                    property Timer singleClickTimer: Timer {
                        interval: 250
                        repeat: false
                        onTriggered: {
                            if (!doubleClickActive) {
                                console.log("✅ Single click confirmed")
                                root.imageClicked(modelData.filePath, modelData.originalPath)
                            }
                            doubleClickActive = false
                        }
                    }

                    onClicked: {
                        // restart the timer each click
                        singleClickTimer.stop()
                        singleClickTimer.start()
                    }

                    onDoubleClicked: {
                        doubleClickActive = true
                        singleClickTimer.stop()   // ✅ cancel pending single‑click

                        console.log("🎯 Image Double‑clicked in GridView:", modelData.fileName)

                        // ✅ Update the selected image file
                        window.selectedImageFile = modelData.fileName
                        let imageFile = window.selectedImageFile

                        // ✅ Resolve the actual video path
                        let folderPath = window.selectedFolderPath
                        let videoPath  = fileSystemManager.findVideoInFolder(folderPath, imageFile)

                        console.log("➡️ Double‑click resolved videoPath:", videoPath)

                        // ✅ Launch with preferred player using full path
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
            console.log("📂 imagegridview: connections:Cache Path (thumbnail URI):", cachePath)
            console.log("🖼️ imagegridview: connections:Original Path (server filename):", originalPath)




            root._pendingImagePath = cachePath

            detailLoader.active = false
            detailLoader.source = "Detail_View.qml"
            detailLoader.active = true

            detailLoader.item.imagePath = cachePath       // cached image
            detailLoader.item.originalXmlPath = originalPath // original server path

            // ✅ Call Python slot directly when image is clicked
            var vid = fileSystemManager.findVideoForImage(cachePath)

            detailLoader.item.videoPath = vid

            console.log("Video URL from Python:", vid)
            //playerPanel.videoPath = vid
        }
    }
}