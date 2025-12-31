import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    property var externalImageList: []
    property var xmlDetails
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
            // --- FIXED: Combined Priority Model ---
            model: (externalImageList && externalImageList.length > 0) 
                   ? externalImageList 
                   : (fileSystemManager ? fileSystemManager.imageFiles : [])
            
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

            cellWidth: imageGridView.width / 6
            cellHeight: (imageGridView.width / 6) * 1.5

            delegate: ImageHolder {
                width: imageGridView.width / 6
                height: (imageGridView.width / 6) * 1.5

                // Uses the filePath provided by either Python or FileSystemManager
                source: modelData.filePath

                property bool doubleClickActive: false

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton

                    property Timer singleClickTimer: Timer {
                        interval: 250
                        repeat: false
                        onTriggered: {
                            if (!parent.doubleClickActive) {
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
                        
                        // Use originalPath/videoPath logic
                        let videoPath = modelData.originalPath 
                        // Fallback to your old search if originalPath isn't direct
                        if (!videoPath && fileSystemManager) {
                             videoPath = fileSystemManager.findVideoInFolder(window.selectedFolderPath, modelData.fileName)
                        }

                        console.log("🎯 Launching:", videoPath)
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
            root._pendingImagePath = cachePath
            detailLoader.source = "Detail_View.qml"
            detailLoader.active = true
            
            if (detailLoader.item) {
                detailLoader.item.imagePath = cachePath
                detailLoader.item.originalXmlPath = originalPath
                var vid = fileSystemManager.findVideoForImage(cachePath)
                detailLoader.item.videoPath = vid
            }
        }
    }
}