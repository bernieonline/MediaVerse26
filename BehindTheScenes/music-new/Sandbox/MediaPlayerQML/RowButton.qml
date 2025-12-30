import QtQuick 2.15
import QtQuick.Controls 2.15

Row {
    id: buttonRow

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 50   

    property int buttonWidth: 150
    property int buttonHeight: 60
    property int buttonCount: 6 // Increased to 6 to fit both Collection buttons
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

    // --- 1. VIEW COLLECTIONS ---
    StyledButton {
        id: viewCollectionsButton
        text: "View Collections"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            // This is the next big step: Loading the saved collections view
            notificationManager.post_notification("Opening Collections Gallery...", false)
            contentLoader.setSource("CollectionsGallery.qml") 
        }
    }

    // --- 2. CREATE COLLECTION (Formerly Quick Collection) ---
    StyledButton {
        id: createCollectionButton
        text: "Create Collection"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            // Only opens the side panel, doesn't change the main view
            utilitySidebar.showCollectionCreator()
        }
    }

    // --- View Toggle Button ---
    StyledButton {
        id: viewToggleButton
        property bool isGridView: true
        text: isGridView ? "Carousel View" : "Grid View"
        fixedWidth: buttonRow.buttonWidth
        fixedHeight: buttonRow.buttonHeight
        onClicked: {
            isGridView = !isGridView
            if (isGridView) {
                contentLoader.setSource("ImageGridView.qml", { xmlDetails: xmlDetails })
            } else {
                contentLoader.source = "CarouselView.qml"
            }
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