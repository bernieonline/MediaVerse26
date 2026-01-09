import QtQuick 2.15
import QtQuick.Controls 2.15

Row {
    id: buttonRow

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 50   
    //property var play_video_from_qml

    property int buttonWidth: 150
    property int buttonHeight: 60
    property int buttonCount: 7   // UPDATED: now 7 buttons total
    property real spacingCalc: (width - (buttonCount * buttonWidth)) / (buttonCount - 1)

    spacing: spacingCalc

    // --- Menu Button ---
    StyledButton {
        id: menuButton
        text: "Menu"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            libraryPanel.x = (libraryPanel.x === 0) ? -libraryPanel.width : 0
        }
    }

    // --- Video Button ---
    StyledButton {
        id: videoButton
        text: "Video"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            let folderPath = window.selectedFolderPath
            let imageFile  = window.selectedImageFile
            let videoPath = fileSystemManager.findVideoInFolder(folderPath, imageFile)
            videoPanel.videoPath = videoPath
            videoPanel.isPlaying = false
            isVideoPanelVisible = !isVideoPanelVisible
        }
    }

    // --- Collections Button ---
    StyledButton {
        id: collectionsButton
        text: "Collections"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            notificationManager.post_notification("Loading Collections...", false)
            contentLoader.setSource("CategoryMenu.qml")
        }
    }

    // --- Create Collection ---
    StyledButton {
        id: createCollectionButton
        text: "Create Collection"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            utilitySidebar.showCollectionCreator()
        }
    }

    // ============================================================
    //  TEMPORARY TEST BUTTON — loads Detail_View_v2 with poster
    // ============================================================
    StyledButton {
        id: viewToggleButton
        text: "Test Detail View"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight

        onClicked: {
            let manifestDisplayPath = "Cache/display/Chisum (1970).jpg"
            let resolved = _xmlController.resolve_paths(manifestDisplayPath)

            console.log("DEBUG: resolved.image =", resolved.image)
            console.log("DEBUG: resolved.xml   =", resolved.xml)

            contentLoader.setSource("Detail_View_v2.qml", {
                imagePath: resolved.image,
                xmlPath: resolved.xml
            })
        }
    }

    // ============================================================
    //  NEW — TEMPORARY PLAYBACK TEST BUTTON
    // ============================================================
    StyledButton {
        id: playbackTestButton
        text: "Playback Test"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight



        onClicked: {
            let testPath = "W:\\Collection\\Western HD\\For a Fistful of Dollars (1964).m2ts"
            console.log("Calling playVideo")

            playbackBridge.playVideo("W:/Collection/Western HD/For a Fistful of Dollars (1964).m2ts")


        }
    }

    // --- Close Button ---
    StyledButton {
        text: "Close"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: Qt.quit()
    }
}