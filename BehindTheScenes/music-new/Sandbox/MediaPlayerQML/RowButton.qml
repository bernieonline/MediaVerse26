// RowButton.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
//new component

RowLayout {
    id: buttonRow
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 80
    spacing: 20
    width: parent.width - 40   // total available width

    // Shared properties for consistent sizing
    property int buttonHeight: 60

    // --- Menu Button ---
    Button {
        id: menuButton
        text: "Menu"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
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
        }
    }

    // --- Video Button ---
    Button {
        id: videoButton
        text: "Video"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
            radius: 8
            color: "#333"
            border.color: "yellow"
            border.width: 1
        }
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
    Button {
        id: viewToggleButton
        property bool isGridView: true
        text: isGridView ? "Carousel View" : "Grid View"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
            radius: 8
            color: "#333"
            border.color: "yellow"
            border.width: 1
        }
        onClicked: {
            isGridView = !isGridView
            if (isGridView) {
                contentLoader.setSource("ImageGridView.qml", { xmlDetails: xmlDetails })
            } else {
                contentLoader.source = "CarouselView.qml"
            }
        }
    }

    // --- Collections Button ---
    Button {
        text: "Collections"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
            radius: 8
            color: "#333"
            border.color: "yellow"
            border.width: 1
        }
        onClicked: console.log("Collections clicked (no functionality yet)")
    }

    // --- Utilities Button ---
    Button {
        text: "Utilities"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
            radius: 8
            color: "#333"
            border.color: "yellow"
            border.width: 1
        }
        onClicked: console.log("Utilities clicked (no functionality yet)")
    }

    // --- Settings Button ---
    Button {
        text: "Settings"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
            radius: 8
            color: "#333"
            border.color: "yellow"
            border.width: 1
        }
        onClicked: console.log("Settings clicked (no functionality yet)")
    }

    // --- Close Button ---
    Button {
        text: "Close"
        Layout.fillWidth: true
        Layout.preferredHeight: buttonRow.buttonHeight
        background: Rectangle {
            radius: 8
            color: "#333"
            border.color: "yellow"
            border.width: 1
        }
        contentItem: Text {
            text: parent.text
            font: parent.font
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: Qt.quit()
    }
}