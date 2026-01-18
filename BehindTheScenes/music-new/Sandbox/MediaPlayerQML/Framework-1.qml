import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"
    
    property var xmlDetails: null
    property string selectedFolderPath: ""
    property string selectedImageFile: ""
    property var currentCollectionItems: []
    property bool useCarouselView: false 
    property var xmlController: _xmlController
    property bool isVideoPanelVisible: false

    // ⭐ SCOPE FIX: Create a reference to splash at the window level 
    // so RowButton can see it without a ReferenceError.
    property alias splashAlias: splash

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

    // --- Search Controller Connection ---
    Connections {
        target: searchController
        function onDetailRequested(result) {
            if (result.error || !result.xml) {
                contentLoader.setSource("NoDetails.qml")
            } else {
                contentLoader.setSource("Detail_View_v2.qml", {
                    "imagePath": result.image,
                    "xmlPath": result.xml,
                    "moviePath": result.movie
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
        }
    }

    SlidingPanel {
        id: libraryPanel
        libraryModel: myLibraryModel 
        folderModel: fileSystemManager.folders 

        onFolderSelected: function(folderPath) {
            window.selectedFolderPath = folderPath
            fileSystemManager.update_folders(folderPath)
            fileSystemManager.list_image_files_in_folder(folderPath)
        }
    }

    // --- THE VIDEO PLAYER PANEL ---
    // Placed here so it sits on top of the content but below the sidebar
    PlayerPanel {
        id: videoPanel
        //controls size of the main player componet
        width: parent.width * 0.66
        height: parent.height * 0.80
        anchors.horizontalCenter: parent.horizontalCenter
        
        // Use the property we defined at the top
        isVideoPanelVisible: window.isVideoPanelVisible 

        // Sliding logic
        y: window.isVideoPanelVisible ? window.height - height - 20 : window.height + 50
        z: 100 

        Behavior on y {
            NumberAnimation { duration: 600; easing.type: Easing.OutQuart }
        }
    }

    Column {
        id: buttonRows
        width: parent.width * 0.75
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: centralMenu.bottom
        anchors.topMargin: 30
        spacing: 20
        RowButton { id: rowButtons; width: parent.width - 100 }
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
        clip: true

        SplashScreen {
            id: splash
            anchors.fill: parent
            z: 9999
            visible: true
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            source: "ImageGridView_v2.qml"

            onLoaded: {
                if (!contentLoader.item) return;

                if (contentLoader.source.toString().includes("CategoryMenu.qml")) {
                    contentLoader.item.categorySelected.connect(function(categoryKey) {
                        let filteredData = collectionLogic.get_collections_by_category(categoryKey)
                        contentLoader.setSource("CollectionsGallery.qml", { "collectionsModel": filteredData })
                    })
                }

                if (contentLoader.source.toString().includes("CollectionsGallery.qml")) {
                    contentLoader.item.collectionSelected.connect(function(collectionItems) {
                        window.currentCollectionItems = collectionItems
                        let targetFile = (collectionItems.length <= 14) ? "CarouselView_v2.qml" : "ImageGridView_v2.qml"
                        contentLoader.setSource(targetFile, { "externalImageList": collectionItems })
                    })
                }

                try {
                    if (contentLoader.item.v2OpenDetail !== undefined) {
                        contentLoader.item.v2OpenDetail.connect(openMovieDetail)
                    }

                    if (contentLoader.item.launchVideoRequested !== undefined) {
                        contentLoader.item.launchVideoRequested.connect(playMovieNow)
                    }
                } catch(e) { console.log("Connection warning: " + e) }
            }
        }
    }

    function openMovieDetail(movie) {
        let resolved = _xmlController.resolve_paths(movie.display)
        if (resolved && resolved.xml) {
            contentLoader.setSource("Detail_View_v2.qml", {
                "imagePath": resolved.image,
                "xmlPath": resolved.xml,
                "moviePath": resolved.video
            })
        }
    }

    function playMovieNow(cachePath) {
        var decoded = decodeURIComponent(cachePath)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var filename = decoded.split("/").pop()
        
        var videoPath = fileSystemManager.findVideoInFolder(window.selectedFolderPath, filename)
        
        if (videoPath) {
            // Updated: Set the local videoPanel path and show it
            videoPanel.videoPath = videoPath
            window.isVideoPanelVisible = true
            // Also keep your JRiver call if you want dual playback or external control
            playbackBridge.play_video_via_jriver(videoPath)
        }
    }

    UtilitySidebar { id: utilitySidebar; anchors.fill: parent }
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: utilitySidebar.isOpen = !utilitySidebar.isOpen
    }
   
}