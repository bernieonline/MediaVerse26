import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick
import QtQuick.Controls
//import "CinemaButton.qml" as Custom
//import QtQuick.Controls 2.15


//version 1.0.1 border edge added to left panel
//1.o.2 sliding video panel added
//1.0.3 centre button moved to toolbar
//1.0.4 final adjustments made before applying styling to panels
//1.0.5 Glow effects added to main window

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"
    //property var xmlDetails  // will be set by Python as a dynamic property
    property var xmlDetails: xmlDetails   // bind the context property into the window’s property

    // 🔑 Add these two here from signals emitted on clicking a folder
    property string selectedFolderPath: ""
    property string selectedImageFile: ""




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
                contentLoader.setSource("ImageGridView.qml", { xmlDetails: xmlDetails })
            } else {
                contentLoader.source = "CarouselView.qml"
            }
        }






        /*
        onViewRequested: {
            if (viewType === "grid")
                contentLoader.setSource("ImageGridView.qml", { xmlDetails: xmlDetails })
            else
                contentLoader.source = "CarouselView.qml"
        }
        */
    }


    GlowStyling {
        //target: videoPanel
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

    Rectangle {
        id: contentContainer
        anchors.top: buttonRow.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 100

        radius: 25
        color: "transparent"
        border.color: "#2566c2"
   
        border.width: 1

        // Loader for dynamically loading content like the GridView
        Loader {
            id: contentLoader
            anchors.fill: parent
            source: "ImageGridView.qml" // Set initial view

            onLoaded: {
                if (contentLoader.item && contentLoader.item.imageClicked) {
                    // Log that the signal is connected
                    console.log("✅ Connected imageClicked from ImageGridView")

                    contentLoader.item.imageClicked.connect(function(cachePath, originalPath) {
                        // Derive filename from cachePath
                        var decoded = decodeURIComponent(cachePath)
                        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
                        var filename = decoded.split("/").pop()

                        // Store filename for Video button
                    window.selectedImageFile = filename
                    console.log("🖼️ Stored filename for Video button:", filename)

                    // Optional: also store folder path from cachePath (redundant if SlidingPanel already sets it)
                    // window.selectedFolderPath = decoded.split("/").slice(0, -1).join("/")





                        //contentLoader.setSource("Detail_View.qml", { imagePath: path })

                        contentLoader.setSource("Detail_View.qml", {
                            imagePath: cachePath,
                            xmlDetails: xmlDetails
                        })

                    })
                }

                // Double‑click connection (new)
                if (contentLoader.item && contentLoader.item.launchVideoRequested) {
                    console.log("✅ Connected launchVideoRequested from ImageGridView")

                    contentLoader.item.launchVideoRequested.connect(function(cachePath) {
                        console.log("🎯 Double‑click received cachePath:", cachePath)

                        // Derive filename from cachePath
                        var filename = window.filenameFromCachePath(cachePath)
                        window.selectedImageFile = filename


                        // ✅ Use the existing Python slot

                        var videoPath = fileSystemManager.findVideoInFolder(window.selectedFolderPath, filename)

                        console.log("🎬 Resolved Video Path:", videoPath)

                        // Launch PlayerPanel
                        videoPanel.videoPath = videoPath
                        videoPanel.isPlaying = true
                        isVideoPanelVisible = true
                    })
                }

            }

        }
    }
}