import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    visible: true
    title: "MediaVerse"
    
    // --------------------------------------------------------
    // Global Properties
    // --------------------------------------------------------
    property var xmlDetails: null
    property string selectedFolderPath: ""
    property string selectedImageFile: ""
    property var currentCollectionItems: []
    property bool useCarouselView: false 
    property var xmlController: _xmlController
    property bool isVideoPanelVisible: false
    property string previousLoaderSource: ""   // remembers what was showing before Detail_View

    property alias splashAlias: splash

    Material.theme: Material.Dark
    Material.accent: Material.Yellow

    // --- Background Layer ---
    Rectangle { 
        id: background
        anchors.fill: parent
        color: "#1e1e1e"
    }

    // --- Global Shortcuts ---
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: utilitySidebar.isOpen = !utilitySidebar.isOpen
    }

    Shortcut {
        sequence: "Escape"
        enabled: window.isVideoPanelVisible
        onActivated: closePlayer()
    }

    // --------------------------------------------------------
    // UI Components & Logic
    // --------------------------------------------------------

    FileDialog {
        id: playerExeBrowser
        title: "Select Media Player Executable"
        nameFilters: ["Executable files (*.exe)"]
        onAccepted: {
            console.log("File selected: " + selectedFile)
            SettingsManager.add_new_player(selectedFile.toString())
        }
    }

    StyledMenu {
        id: centralMenu
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        menuData: centralMenuData

        onMenuItemTriggered: function(label) { 
            console.log("qml: Clicked: " + label)
            
            if (label === "Manage Players ...") {
                playerExeBrowser.open()
            } 
            // --- THE NEW HANDLER ---
            else if (label === "Categories") {
                console.log("🛠️ Architect: Opening Category_Edit panel")
                categoryEditPanel.open()
            }
        }
    }

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

    // --- Connect the RowButton to the Loader ---
    Connections {
        target: rowButtons
        // Assuming your RowButton emits a signal like 'architectClicked'
        // or 'modeChanged'
        function onArchitectClicked() {
            console.log("🚀 Switching to Architect Gallery Mode")
            if (splash) splash.deactivate() // Hide splash if active
            
            // This is the swap that loads our new premium view
            contentLoader.setSource("ArchitectGallery.qml")
            
            // Close other panels just in case
            //libraryPanel.isOpen = false
        }
    }





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

    // ----------------------------------------------------
    // Playback Logic Functions
    // ----------------------------------------------------
    
    function closePlayer() {
        if (videoPanel.videoPlayer) {
            videoPanel.videoPlayer.stop()
        }
        videoPanel.isPlaying = false
        window.isVideoPanelVisible = false
        console.log("🛑 MiniPlayer closed via Framework-1")
    }
    
    function openMiniPlayer(path) {
        if (splash) splash.deactivate()

        videoPanel.videoPath = path
        window.isVideoPanelVisible = true
        videoPanel.isPlaying = true

        console.log("🎬 MiniPlayer launched via Framework-1:", path)
    }

    function playMovieNow(cachePath) {
        var decoded = decodeURIComponent(cachePath)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var filename = decoded.split("/").pop()
        
        var videoPath = fileSystemManager.findVideoInFolder(window.selectedFolderPath, filename)
        
        if (videoPath) {
            // Open internal player
            openMiniPlayer(videoPath)
            // Send to JRiver (External)
            playbackBridge.play_video_via_jriver(videoPath)
        }
    }

    function openMovieDetail(movie) {
        let resolved = _xmlController.resolve_paths(movie.display)
        if (resolved && resolved.xml) {
            window.previousLoaderSource = contentLoader.source.toString()
            contentLoader.setSource("Detail_View_v2.qml", {
                "imagePath": resolved.image,
                "xmlPath": resolved.xml,
                "moviePath": resolved.video
            })
            // backRequested is wired in onLoaded below
        }
    }

    // ----------------------------------------------------
    // Main UI Layout
    // ----------------------------------------------------

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
        border.width: 2
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

                // Handle category/collection signals from loaded items
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
                    if (contentLoader.item.backRequested !== undefined) {
                        contentLoader.item.backRequested.connect(function() {
                            if (window.previousLoaderSource !== "")
                                contentLoader.source = window.previousLoaderSource
                        })
                    }
                } catch(e) { console.log("Connection warning: " + e) }
            }
        }
    }

    // --- THE MINI VIDEO PLAYER PANEL ---
    PlayerPanel {
        id: videoPanel
        rootWindow: window
        width: parent.width * 0.70
        height: parent.height * 0.85
        anchors.horizontalCenter: parent.horizontalCenter
        z: 1000 // Ensure it's on top of contentContainer
    }

    UtilitySidebar { 
        id: utilitySidebar
        anchors.fill: parent 
    }
    ArchitectHUD {
        id: architectHUD
        anchors.fill: parent
        visible: false // Hidden by default
    }
    Category_Edit {
        id: categoryEditPanel
    }
    
}