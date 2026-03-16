import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts 1.15
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

    // StyledMenu removed — navigation consolidated into RowButton bar

    Connections {
        target: searchController
        function onDetailRequested(result) {
            if (result.error || !result.xml) {
                contentLoader.setSource("NoDetails.qml")
            } else {
                window.previousLoaderSource = ""
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

        function onArchitectClicked() {
            console.log("🚀 Switching to Architect Gallery Mode")
            if (splash) splash.deactivate()
            contentLoader.setSource("ArchitectGallery.qml")
        }

        function onSnatcherClicked() {
            snatcher2Panel.visible = true
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
        anchors.top: parent.top
        anchors.topMargin: 18
        spacing: 20
        RowButton { id: rowButtons; width: parent.width - 100 }
    }

    // --- SEARCH BAR — floats midway between button row and display area ---
    Item {
        id: searchGap
        anchors.top: buttonRows.bottom
        anchors.bottom: contentContainer.top
        anchors.left: parent.left
        anchors.right: parent.right

        Rectangle {
            id: searchBarContainer
            width: parent.width * 0.5
            height: 45
            anchors.centerIn: parent
            radius: 22.5
            color: "#E6000000"
            border.color: searchInput.activeFocus ? "yellow" : "#99B8956A"
            border.width: 2

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                Text { text: "🔍"; font.pixelSize: 20; color: "white" }
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search W:/Collection..."
                    color: "white"; font.pixelSize: 20; verticalAlignment: TextInput.AlignVCenter
                    background: null
                    onTextChanged: {
                        if (text.length >= 3) searchController.perform_search(text)
                        else resultsPopup.close()
                    }
                }
            }

            Popup {
                id: resultsPopup
                y: searchBarContainer.height + 4
                x: 0
                width: searchBarContainer.width
                padding: 0
                modal: false
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                background: Rectangle {
                    color: "#EE0d0d0d"; radius: 10
                    border.color: "#2566c2"; border.width: 2
                }

                contentItem: ListView {
                    id: resultsList
                    implicitHeight: Math.min(contentHeight, 400)
                    clip: true
                    model: []

                    delegate: ItemDelegate {
                        width: resultsList.width
                        height: 52

                        background: Rectangle {
                            color: hovered ? "#2566c2" : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        contentItem: Row {
                            spacing: 12
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 16

                            Image {
                                width: 34; height: 34
                                source: modelData.imageFilename || ""
                                fillMode: Image.PreserveAspectCrop
                                visible: modelData.imageFilename !== ""
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name
                                color: "white"; font.pixelSize: 20; font.bold: true
                                elide: Text.ElideRight
                                width: resultsList.width - 80
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onClicked: {
                            if (typeof splash !== "undefined") splash.deactivate()
                            searchController.confirm_selection(modelData.filePath)
                            resultsPopup.close()
                            searchInput.text = ""
                        }
                    }
                }
            }

            Connections {
                target: searchController
                function onResultsUpdated(results) {
                    resultsList.model = results
                    if (results.length > 0) resultsPopup.open()
                    else resultsPopup.close()
                }
            }
        }
    }

    Rectangle {
        id: contentContainer
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        anchors.left: parent.left
        anchors.leftMargin: 50
        anchors.right: parent.right
        anchors.rightMargin: 50
        radius: 25
        color: "transparent"
        border.color: "#2566c2"
        border.width: 2
        clip: true

        SplashScreen {
            id: splash
            anchors.fill: parent
            z: 9999
            visible: (typeof startupMode === "undefined" || startupMode !== "Tiles")
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            source: (typeof startupMode !== "undefined" && startupMode === "Tiles")
                    ? "landing_view.qml"
                    : "ImageGridView_v2.qml"

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
                            var dest = window.previousLoaderSource
                            if (dest === "landing_view.qml") {
                                // Return to landing view paused, fresh 20 s timer
                                contentLoader.setSource("landing_view.qml", { "startPaused": true })
                            } else if (dest !== "") {
                                contentLoader.source = dest
                                splash.activate()
                            } else {
                                splash.activate()
                            }
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
    SettingsPanel {
        id: settingsPanel
    }

    SettingsFlyout {
        id: settingsFlyout
        height: parent.height
        z: 9999
    }

    Connections {
        target: utilitySidebar
        function onSettingsClicked() { settingsFlyout.open() }
    }

    Connections {
        target: settingsFlyout
        function onMenuItemClicked(item) {
            if      (item === "Manage Players...") playerExeBrowser.open()
            else if (item === "Categories")        categoryEditPanel.open()
            else if (item === "Configuration...")  settingsPanel.open()
        }
    }

    Snatcher2 {
        id: snatcher2Panel
        anchors.fill: parent
        visible: false
    }

    // Cinema return fade — fades from black to transparent when returning from JRiver
    Rectangle {
        id: cinemaReturnFade
        anchors.fill: parent
        color: "black"
        opacity: 0.0
        visible: opacity > 0.0
        z: 9998

        NumberAnimation {
            id: fadeFromBlack
            target: cinemaReturnFade
            property: "opacity"
            from: 1.0; to: 0.0
            duration: 1500
            easing.type: Easing.InOutQuad
        }
    }

    Connections {
        target: playbackBridge
        function onPlaybackFinished() {
            // Toggle visibility Windowed→FullScreen to force a compositor
            // repaint — this ensures Qt repaints over any residual JRiver pixels
            window.visibility = Window.Windowed
            window.visibility = Window.FullScreen
            window.raise()
            window.requestActivate()
            // Cinema fade from black
            cinemaReturnFade.opacity = 1.0
            fadeFromBlack.start()
        }
    }
}