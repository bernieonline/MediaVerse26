   Row {
        id: buttonRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80
        spacing: 40

        Button {
            id: menuButton
            text: "Menu"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                libraryPanel.x = (libraryPanel.x === 0) ? -libraryPanel.width : 0
                if (libraryPanel.x === 0 && libraryPanel.categoryCombo.currentIndex !== -1) {
                    libraryPanel.categoryCombo.activated(libraryPanel.categoryCombo.currentIndex)
                }






                //sidePanel.x = (sidePanel.x === 0) ? -sidePanel.width : 0
                //if (sidePanel.x === 0 && categoryCombo.currentIndex !== -1) {
                    //categoryCombo.activated(categoryCombo.currentIndex)
                //}
                //contentLoader.source = ""
            }
        }

       


        Button {
            id: videoButton
            text: "Video"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                print("video button clicked")
                //console.log("🔍 displayPath available in QML:", displayPath)
                // Example: these should come from your UI state
                let folderPath = window.selectedFolderPath  // from side panel
 
                let imageFile  = window.selectedImageFile // from grid/detail

                // Debug prints to check accuracy
                console.log("📂 Folder Path passed to Python:", folderPath)
                console.log("🖼️ new Image File passed to Python:", imageFile)

                // Call Python slot with both values
                let videoPath = fileSystemManager.findVideoInFolder(folderPath, imageFile)
                console.log("🎬 Resolved Video Path:", videoPath)


                // ✅ Pass to PlayerPanel
                videoPanel.videoPath = videoPath
                videoPanel.isPlaying = false   // reset state so Play button works

                isVideoPanelVisible = !isVideoPanelVisible
            }
        }

       

        Button {
            id: viewToggleButton
            property bool isGridView: true
            text: isGridView ? "Carousel View" : "Grid View"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                isGridView = !isGridView;
                if (isGridView) {
                    //contentLoader.source = "ImageGridView.qml";
                    contentLoader.setSource("ImageGridView.qml", { xmlDetails: xmlDetails })

                } else {
                    contentLoader.source = "CarouselView.qml";
                }
            }
        }

        Button {
            text: "Close"
            width: 320
            height: 120

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: Qt.quit()
        }

    }