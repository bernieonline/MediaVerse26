import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"
    
    property var xmlDetails: xmlDetails
    property string selectedFolderPath: ""
    property string selectedImageFile: ""
    property var currentCollectionItems: []
    property bool useCarouselView: false
    property var xmlController: _xmlController
    property bool isVideoPanelVisible: false

    Material.theme: Material.Dark
    Material.accent: Material.Yellow

    Rectangle { 
        id: background
        anchors.fill: parent
        color: "#1e1e1e"
    }

    StyledMenu {
        id: centralMenu
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        menuData: centralMenuData
    }

    // --- Global Connections ---
    Connections {
        target: manifestUpdater
        onRefreshStarted: { refreshIndicator.running = true; refreshIndicator.visible = true }
        onRefreshFinished: { refreshIndicator.running = false; refreshIndicator.visible = false }
    }

    Connections {
        target: SettingsManager
        function onSettingsChanged() {
            let settings = SettingsManager.get_settings()
            currentPlayerIndex = settings["Preferred Player"]
        }
        function onVideoLaunchRequested(videoPath) {
            miniPlayer.play(videoPath)
        }
    }

    Connections {
        target: playbackBridge
        onPlaybackFinished: {
            window.raise()
            window.requestActivate()
            isVideoPanelVisible = false 
        }
    }

    // --- Search Controller Connection (Moved out of Loader) ---
    Connections {
        target: searchController
        function onDetailRequested(result) {
            console.log("🔥 DETAIL REQUEST RECEIVED:", JSON.stringify(result))
            if (result.error || !result.xml) {
                contentLoader.setSource("NoDetails.qml")
            } else {
                contentLoader.setSource("Detail_View_v2.qml", {
                    imagePath: result.image,
                    xmlPath: result.xml,
                    moviePath: result.movie
                })
            }
        }
    }

    // --- UI Elements ---
    Rectangle {
        id: logoFrame
        width: buttonRows.height * 1.5
        height: buttonRows.height * 1.5
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        color: "transparent"

        Image {
            anchors.fill: parent
            anchors.margins: 10
            source: imagesPath + "/mediaverse2.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    } // Correctly closed logoFrame

    SlidingPanel {
        id: libraryPanel
        onFolderSelected: function(folderPath) {
            fileSystemManager.list_image_files_in_folder(folderPath)
            window.selectedFolderPath = folderPath
        }
    }

    Column {
        id: buttonRows
        width: parent.width * 0.75
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: centralMenu.bottom
        anchors.topMargin: 30
        spacing: 20

        RowButton {
            id: rowButtons
            width: parent.width - 100
        }
    }

    Rectangle {
        id: contentContainer
        anchors.top: buttonRows.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 50
        radius: 25
        color: "transparent"
        border.color: "#2566c2"
        border.width: 1

        Loader {
            id: contentLoader
            anchors.fill: parent
            source: "ImageGridView_v2.qml"
            property bool loaderReady: false

            onLoaded: {
                loaderReady = true

                // Handle Collection Logic
                if (contentLoader.source.toString().includes("CategoryMenu.qml")) {
                    contentLoader.item.categorySelected.connect(function(categoryKey) {
                        let filteredData = collectionLogic.get_collections_by_category(categoryKey)
                        contentLoader.setSource("CollectionsGallery.qml", { "collectionsModel": filteredData })
                    })
                }

                if (contentLoader.source.toString().includes("CollectionsGallery.qml")) {
                    contentLoader.item.collectionSelected.connect(function(collectionItems) {
                        window.currentCollectionItems = collectionItems
                        contentLoader.setSource("ImageGridView_v2.qml", { externalImageList: collectionItems })
                    })
                }
            }
        }
    }

    UtilitySidebar {
        id: utilitySidebar
        anchors.fill: parent
    }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: utilitySidebar.isOpen = !utilitySidebar.isOpen
    }
}