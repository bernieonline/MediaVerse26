import QtQuick 2.15
import QtQuick.Controls 2.15

Row {
    id: buttonRow

    anchors.left: parent.left
    anchors.margins: 50   // adds 50px padding left and right

    property int buttonWidth: 150
    property int buttonHeight: 60
    property int buttonCount: 4
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
            if (libraryPanel.x === 0 && libraryPanel.categoryCombo.currentIndex !== -1) {
                libraryPanel.categoryCombo.activated(libraryPanel.categoryCombo.currentIndex)
            }
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