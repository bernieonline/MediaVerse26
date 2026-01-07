import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick
import QtQuick.Controls
//import "CinemaButton.qml" as Custom
//import QtQuick.Controls 2.15
// adding toolbar

//version 1.0.1 border edge added to left panel
//1.o.2 sliding video panel added
//1.0.3 centre button moved to toolbar
//1.0.4 final adjustments made before applying styling to panels
//1.0.5 Glow effects added to main window
//simple bug fix

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"
    //property var xmlDetails  // will be set by Python as a dynamic property
    property var xmlDetails: xmlDetails   // bind the context property into the window’s property
    //property var menuData: menuData  // bind to context property


    // 🔑 Add these two here from signals emitted on clicking a folder
    property string selectedFolderPath: ""
    property string selectedImageFile: ""

    // 🔑 NEW: collection-driven display state
    property var currentCollectionItems: []
    property bool useCarouselView: false

    property var xmlController: _xmlController

    Material.theme: Material.Dark
    Material.accent: Material.Yellow

    // The colors used in this file are standard hex color codes.
    // If your editor is highlighting them as invalid, it might be a linter configuration issue.

    Rectangle { //sets theme colour
        id: background
        anchors.fill: parent
        color: "#1e1e1e"
    }

    GlowStyling {
        //target: border
    }

    StyledMenu {
        id: centralMenu
        anchors.top: parent.top
        anchors.topMargin: 20        // <-- push it down from the top
        anchors.horizontalCenter: parent.horizontalCenter
        menuData: centralMenuData   // <- bind directly to Python property
    }
    Connections {
        target: manifestUpdater
        onRefreshStarted: {
            //console.log("Manifest refresh started")
            refreshIndicator.running = true
            refreshIndicator.visible = true
        }
        onRefreshFinished: {
            //console.log("Manifest refresh finished")
            refreshIndicator.running = false
            refreshIndicator.visible = false
        }
    }

    
    BusyIndicator {
        id: refreshIndicator
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12   // add a little padding from the edges
        running: false
        visible: false
    }
   

    Connections {
        target: SettingsManager

        // Refresh UI when settings change
        function onSettingsChanged() {
            let settings = SettingsManager.get_settings()
            currentPlayerIndex = settings["Preferred Player"]
            //console.log("Settings refreshed, Preferred Player:", currentPlayerIndex)
        }

        // Play video when Python emits the launch signal
        function onVideoLaunchRequested(videoPath) {
            //console.log("🎬 MiniPlayer received videoPath:", videoPath)
            miniPlayer.play(videoPath)   // call your MiniPlayer’s play() method
        }
    }
    // A "Breadcrumb" style back button
    Button {
        text: "📁 Back to Gallery"
        visible: contentLoader.source.toString().includes("ImageGridView_v2.qml") && 
                contentLoader.item && contentLoader.item.externalImageList &&
                contentLoader.item.externalImageList.length > 0
        
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10
        z: 100 // High Z-index to stay above the grid
        
        onClicked: contentLoader.setSource("CollectionsGallery.qml")
    }

    Rectangle {
        id: logoFrame
        width: buttonRows.height * 1.5      // make it square
        height: buttonRows.height * 1.5
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20           // margin around the edge
        color: "transparent"
        border.color: "transparent"
        border.width: 2

        Image {
            anchors.fill: parent
            anchors.margins: 10       // inner margin inside the frame
            //source: imagesPath + "/mediaverse.png"
            source: imagesPath + "/mediaverse2.png"

            
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
}

    Rectangle { //subdued glow
        id: border
        anchors.fill: parent
        anchors.margins: 10
        radius: 25
        color: "transparent"
        border.color: "yellow"
        border.width: 1
        z: 2
    }

    GlowStyling {
        //target: sidePanel
    }

    SlidingPanel {
        id: libraryPanel
        libraryModel: myLibraryModel
        folderModel: fileSystemManager.folders

        //onFolderSelected: fileSystemManager.list_image_files_in_folder(folderPath)
        onFolderSelected: function(folderPath) {
            fileSystemManager.list_image_files_in_folder(folderPath)
            window.selectedFolderPath = folderPath   // ✅ store selection

        }

        onViewRequested: function(viewType) {
            if (viewType === "grid") {
                contentLoader.setSource("ImageGridView_v2.qml", { xmlDetails: xmlDetails })
            } else {
                contentLoader.source = "CarouselView_v2.qml"
            }
        }

        /*
        onViewRequested: {
            if (viewType === "grid")
                contentLoader.setSource("ImageGridView_v2.qml", { xmlDetails: xmlDetails })
            else
                contentLoader.source = "CarouselView_v2.qml"
        }
        */
    }


    
    
    PlayerPanel {
        id: videoPanel
        anchors.horizontalCenter: parent.horizontalCenter
        y: isVideoPanelVisible ? window.height - height : window.height
        z: 2

        Behavior on y {
            NumberAnimation { duration: 1500; easing.type: Easing.OutCubic }
        }
    }

    function filenameFromCachePath(cachePath) {
        // Decode %20, %28, etc.
        var decoded = decodeURIComponent(cachePath)

        // Strip file:/// prefix
        if (decoded.startsWith("file:///")) {
            decoded = decoded.substring(8)
        }

        // Return last path segment
        var parts = decoded.split("/")
        return parts[parts.length - 1]
    }

    property bool isVideoPanelVisible: false

    




    Column {
        id: buttonRows

        width: parent.width * 0.75
        anchors.horizontalCenter: parent.horizontalCenter


        //anchors.horizontalCenter: parent.horizontalCenter
        //id: buttonRows
        //anchors.left: parent.left
        //anchors.right: parent.right

        anchors.top: centralMenu.bottom
        anchors.topMargin: 30
        property int sideMargin: 50

        spacing: 20   // space between top and bottom rows
        //property int sideMargin: 50


        // Top row: clickable buttons
        RowButton {
            id: rowButtons
            width: parent.width - (2 * buttonRows.sideMargin)
            //anchors.leftMargin: buttonRows.sideMargin
            //anchors.rightMargin: buttonRows.sideMargin


            //width: parent.width - 40   // stretch row across window
        }
        
    }

    Rectangle {
        id: contentContainer
        anchors.top: buttonRows.bottom   // anchor to the column, not the row

        //anchors.top: rowButtons.bottom   // anchor to the instance

        //anchors.top: buttonRow.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 50

        radius: 25
        color: "transparent"
        border.color: "#2566c2"
   
        border.width: 1

        // Loader for dynamically loading content like the GridView
        // Loader for dynamically loading content like the GridView
        // Loader for dynamically loading content like the GridView
        Loader {
            id: contentLoader
            anchors.fill: parent
            source: "ImageGridView_v2.qml" // Set initial view
            /*onStatusChanged: {
                console.log("📦 Loader status change:",
                            "source =", source.toString(),
                            "status =", status,
                            "item =", item,
                            "error =", errorString())
            }*/

            onLoaded: {
                //console.log("✅ Loader loaded:", source.toString(),
                    //"item type =", item ? item.metaObject.className : "null")

                // --- NEW: Handle the 2x3 Category Grid Connection ---
                if (contentLoader.source.toString().includes("CategoryMenu.qml")) {
                    //console.log("🎬 Category Menu Loaded")
                    
                    // Connect the signal from the card click
                    contentLoader.item.categorySelected.connect(function(categoryKey) {
                        //console.log("📡 Signal Received: Filter by " + categoryKey)
                        
                        // 1. Fetch filtered list from Python
                        let filteredData = collectionLogic.get_collections_by_category(categoryKey)
                        
                        // 2. Load the Gallery, passing the filtered data
                        contentLoader.setSource("CollectionsGallery.qml", { "collectionsModel": filteredData })
                        
                        notificationManager.post_notification("Showing " + categoryKey + " Collections", false)
                    })
                }

                // --- UPDATED: Handle Collections Gallery Data Hand-off ---
                if (contentLoader.source.toString().includes("CollectionsGallery.qml")) {
                    // If collectionsModel wasn't passed in (legacy call from the old button), load everything
                    if (!contentLoader.item.collectionsModel || contentLoader.item.collectionsModel.length === 0) {
                        //console.log("📂 Legacy Call: Loading ALL Collections")
                        //contentLoader.item.collectionsModel = collectionLogic.load_collections_list()
                        contentLoader.item.collectionsModel = collectionLogic.load_all_collections_v2()
                    }
                }
                // --- NEW: Auto-switch Grid/Carousel when a collection is selected ---
                if (contentLoader.source.toString().includes("CollectionsGallery.qml")) {

                    if (contentLoader.item && contentLoader.item.collectionSelected) {

                        contentLoader.item.collectionSelected.connect(function(collectionItems) {

                            window.currentCollectionItems = collectionItems

                            if (collectionItems.length > 14) {
                                window.useCarouselView = false
                                contentLoader.setSource("ImageGridView_v2.qml", {
                                    externalImageList: window.currentCollectionItems
                                })
                            } else {
                                window.useCarouselView = true
                                contentLoader.setSource("CarouselView_v2.qml", {
                                    externalImageList: window.currentCollectionItems,
                                    sortMode: "year",
                                    showLabels: false
                                })
                            }
                        })
                    }
                }

                // --- Existing: Single-click connection ---
                if (contentLoader.item && contentLoader.item.imageClicked) {
                    contentLoader.item.imageClicked.connect(function(cachePath, originalPath) {
                        var decoded = decodeURIComponent(cachePath)
                        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
                        var filename = decoded.split("/").pop()
                        window.selectedImageFile = filename

                        contentLoader.setSource("Detail_View.qml", {
                            imagePath: cachePath,
                            xmlDetails: xmlDetails
                        })
                    })
                }

                // --- NEW: V2 Grid → Detail View connection ---
                if (contentLoader.item && contentLoader.item.v2OpenDetail) {
                    contentLoader.item.v2OpenDetail.connect(function(movie) {

                        console.log("📌 V2 Grid clicked →", movie.display)

                        // 1. Resolve full-size image + XML via Python
                        let resolved = _xmlController.resolve_paths(movie.display)

                        console.log("   → resolved.image =", resolved.image)
                        console.log("   → resolved.xml   =", resolved.xml)

                        // 2. Load the V2 Detail View
                        contentLoader.setSource("Detail_View_v2.qml", {
                            imagePath: resolved.image,
                            xmlPath: resolved.xml
                        })
                    })
                }

                if (contentLoader.item && contentLoader.item.v2PlayMovie) {
                    contentLoader.item.v2PlayMovie.connect(function(videoPath) {

                        console.log("🎬 V2 PlayMovie →", videoPath)

                        // 1. Call Python to launch JRiver / fallback player
                        _xmlController.play_movie(videoPath)
                    })
                }

                // --- Existing: Double‑click connection ---
                if (contentLoader.item && contentLoader.item.v2PlayMovie) {
                    contentLoader.item.v2PlayMovie.connect(function(videoPath) {

                        console.log("🎬 V2 PlayMovie →", videoPath)

                        // Call Python to launch JRiver / fallback player
                        _xmlController.play_movie(videoPath)
                    })
                }
            } // End of onLoaded
        } // End of Loader    
    }//end contentcontainer

    // ... [Existing code: contentContainer, videoPanel, etc.] ...

    // ------------------------------------------------------------
    // 1. UTILITY SIDEBAR INTEGRATION
    // ------------------------------------------------------------
    // This sits at the end of the file to ensure it's on top of all other layers
    UtilitySidebar {
        id: utilitySidebar
        anchors.fill: parent
        // Note: 'fontPathFA' is already available here 
        // because you set it as a Context Property in main.py
    }

    // ------------------------------------------------------------
    // 2. KEYBOARD TESTING SHORTCUT
    // ------------------------------------------------------------
    // Since you are using a keyboard, this is the fastest way to 
    // test the UI without having to "bump" the mouse every time.
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: {
            utilitySidebar.isOpen = !utilitySidebar.isOpen
            console.log("MediaVerse: Sidebar toggled via keyboard. State: " + utilitySidebar.isOpen)
        }
    }

} // <--- This is the final closing brace of your ApplicationWindow