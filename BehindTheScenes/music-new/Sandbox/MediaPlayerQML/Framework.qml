import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

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

    // --- Search Bar Connection (STABLE) ---
    Connections {
        target: searchController
        function onDetailRequested(result) {
            if (result && result.xml) {
                contentLoader.setSource("Detail_View_v2.qml", {
                    "imagePath": result.image,
                    "xmlPath": result.xml,
                    "moviePath": result.movie
                })
            }
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
            // Fix 1: Check preference on startup
            source: window.useCarouselView ? "CarouselView_v2.qml" : "ImageGridView_v2.qml"

            onLoaded: {
                // Fix 2: Safety check to prevent crashing if item is null
                if (!contentLoader.item) return;

                // A. CATEGORY MENU -> GALLERY
                if (contentLoader.source.toString().includes("CategoryMenu.qml")) {
                    contentLoader.item.categorySelected.connect(function(categoryKey) {
                        let filteredData = collectionLogic.get_collections_by_category(categoryKey)
                        contentLoader.setSource("CollectionsGallery.qml", { "collectionsModel": filteredData })
                    })
                }

                // B. GALLERY -> (GRID or CAROUSEL)
                if (contentLoader.source.toString().includes("CollectionsGallery.qml")) {
                    contentLoader.item.collectionSelected.connect(function(collectionItems) {
                        window.currentCollectionItems = collectionItems
                        // Fix 3: Restore the logic that picks the right view file
                        let targetFile = window.useCarouselView ? "CarouselView_v2.qml" : "ImageGridView_v2.qml"
                        contentLoader.setSource(targetFile, { "externalImageList": collectionItems })
                    })
                }

                // C. UNIFIED CLICK HANDLER (Single & Double Click)
                // This connects to ANY view that emits these signals
                try {
                    if (contentLoader.item.v2OpenDetail !== undefined) {
                        contentLoader.item.v2OpenDetail.connect(openMovieDetail)
                    }
                    if (contentLoader.item.launchVideoRequested !== undefined) {
                        contentLoader.item.launchVideoRequested.connect(playMovieNow)
                    }
                } catch(e) { console.log("Signal connection skipped: " + e) }
            }
        }
    }

    // --- RECOVERY LOGIC FUNCTIONS ---

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
        // This is where your JRiver/HTTP logic lives
        // If the crash happened here, it's likely because 'videoPanel' ID is missing
        console.log("Attempting to play:", cachePath)
        
        var decoded = decodeURIComponent(cachePath)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var filename = decoded.split("/").pop()
        
        var videoPath = fileSystemManager.findVideoInFolder(window.selectedFolderPath, filename)
        
        // Use a generic signal to Python instead of a direct ID call to avoid QML crashes
        if (videoPath) {
            playbackBridge.play_video_via_jriver(videoPath) 
        }
    }

    // Standard footer elements
    Column { id: buttonRows; width: parent.width * 0.75; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: centralMenu.bottom; anchors.topMargin: 30; spacing: 20; RowButton { id: rowButtons; width: parent.width - 100 } }
    UtilitySidebar { id: utilitySidebar; anchors.fill: parent }
    Shortcut { sequence: "Ctrl+T"; onActivated: utilitySidebar.isOpen = !utilitySidebar.isOpen }
}