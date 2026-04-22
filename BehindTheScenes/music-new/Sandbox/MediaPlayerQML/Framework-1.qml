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

    // Navigation history for the Quick Collection flow
    // Each entry: { source: string, props: object }
    property var navHistory: []
    property var lastCollectionsModel: []     // restored when going back to CollectionsGallery
    property string workbenchMode: "standard" // shared with WorkbenchView mode toggle

    property alias splashAlias: splash

    Material.theme: Material.Dark
    Material.accent: Material.Yellow

    // --- Background Layer ---
    Rectangle {
        id: background
        anchors.fill: parent
        color: "#030810"
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

    // --- RowButton signals (active only when RowButton.qml is loaded) ---
    Connections {
        target: buttonLoader.source.toString().indexOf("RowButton") !== -1
                ? buttonLoader.item : null

        function onArchitectClicked() {
            console.log("🚀 Switching to Architect Gallery Mode")
            if (splash) splash.deactivate()
            contentLoader.setSource("ArchitectGallery.qml")
        }

        function onQuickCreatorClicked() {
            if (typeof utilitySidebar !== "undefined") utilitySidebar.showCollectionCreator()
        }

        function onTvSeriesClicked() {
            console.log("📺 Switching to TV Series view")
            if (splash) splash.deactivate()
            contentLoader.setSource("TV_view.qml")
        }
    }

    // --- WorkButtons signals (active only when WorkButtons.qml is loaded) ---
    Connections {
        target: buttonLoader.source.toString().indexOf("WorkButtons") !== -1
                ? buttonLoader.item : null

        function onCloseWorkbenchClicked() {
            buttonLoader.source = "RowButton.qml"
        }

        function onTestFileClicked() {
            if (typeof splash !== "undefined") splash.deactivate()
            contentLoader.setSource("WorkbenchView.qml")
            ffmpegBackend.checkFFmpeg()
            ffmpegBackend.testFile(workbenchMode)
        }

        function onCompareFilesClicked() {
            if (typeof splash !== "undefined") splash.deactivate()
            contentLoader.setSource("CompareView.qml")
            ffmpegBackend.checkFFmpeg()
            ffmpegBackend.compareFiles()
        }

        function onRepairFileClicked() {
            if (typeof splash !== "undefined") splash.deactivate()
            contentLoader.setSource("RepairView.qml")
            ffmpegBackend.checkFFmpeg()
        }

        function onTestFolderClicked() {
            if (typeof splash !== "undefined") splash.deactivate()
            contentLoader.setSource("FolderTestView.qml")
            ffmpegBackend.checkFFmpeg()
            ffmpegBackend.testFolder(workbenchMode)
        }

        function onVideoProcClicked() {
            SettingsManager.launch_tool("VideoProc")
        }

        function onFileDetailsClicked() {
            if (typeof splash !== "undefined") splash.deactivate()
            contentLoader.setSource("FileDetailsView.qml")
            ffmpegBackend.checkFFmpeg()
            ffmpegBackend.fileDetails()
        }

        function onQualityAuditsClicked() {
            if (typeof splash !== "undefined") splash.deactivate()
            contentLoader.setSource("QualityAuditView.qml")
        }
    }

    // --- Forward ffmpeg AI requests to aiController ---
    Connections {
        target: ffmpegBackend
        function onFfmpegAskAI(filename, prompt) {
            aiController.ask(filename, prompt)
        }
    }

    // --- Check tool availability when WorkButtons loads ---
    Connections {
        target: buttonLoader
        function onLoaded() {
            if (buttonLoader.source.toString().indexOf("WorkButtons") === -1) return
            var available = SettingsManager.is_tool_available("VideoProc")
            buttonLoader.item.videoProcAvailable = available
            if (!available)
                notificationManager.post_notification("VideoProc is not installed or configured. Set the path in Settings → Tools.", false)
        }
    }

    // --- SlidePanel module switching ---
    Connections {
        target: slidePanel

        function onWorkbenchClicked() {
            console.log("🔧 Switching to Workbench mode")
            buttonLoader.source = "WorkButtons.qml"
        }

        function onMediaverseClicked() {
            console.log("🏠 Returning to MediaVerse main buttons")
            buttonLoader.source = "RowButton.qml"
        }

        function onCollectionManagerClicked() {
            console.log("📦 Switching to Collection Manager")
            if (typeof splash !== "undefined") splash.deactivate()
            buttonLoader.source  = "CollectButtons.qml"
            contentLoader.source = "MediaManagerView.qml"
        }
    }

    // --- CollectButtons signals ---
    Connections {
        target: buttonLoader.source.toString().indexOf("CollectButtons") !== -1
                ? buttonLoader.item : null

        function onCloseCollectClicked() {
            buttonLoader.source  = "RowButton.qml"
            contentLoader.source = ""
        }

        function onDbEditClicked() {
            if (buttonLoader.item) {
                var view = contentLoader.item
                if (view && typeof view.loadPanel === "function")
                    view.loadPanel("MM_DbEdit.qml")
            }
        }

        function onDbSearchClicked() {
            var view = contentLoader.item
            if (view && typeof view.loadPanel === "function")
                view.loadPanel("MM_DbSearch.qml")
        }

        function onScanLocationClicked() {
            var view = contentLoader.item
            if (view && typeof view.loadPanel === "function")
                view.loadPanel("MM_Scan.qml")
        }

        function onScanMasterClicked() {
            var view = contentLoader.item
            if (view && typeof view.loadPanel === "function")
                view.loadPanel("MM_ScanMaster.qml")
        }

        function onReportClicked() {
            var view = contentLoader.item
            if (view && typeof view.loadPanel === "function")
                view.loadPanel("MM_Report.qml")
        }

        function onCompareClicked() {
            var view = contentLoader.item
            if (view && typeof view.loadPanel === "function")
                view.loadPanel("MM_Compare.qml")
        }

        function onManageClicked() {
            var view = contentLoader.item
            if (view && typeof view.loadPanel === "function")
                view.loadPanel("MM_Manage.qml")
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
            source: imagesPath + "/mediaverse2.jpg"
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
        anchors.topMargin: 26
        spacing: 20
        z: 998    // above UtilitySidebar dismissalShield (z:997) so clicks always reach buttons
        Loader {
            id: buttonLoader
            width: parent.width - 100
            source: "RowButton.qml"
        }
    }

    // --- SEARCH BAR — floats midway between button row and display area ---
    Item {
        id: searchGap
        anchors.top: buttonRows.bottom
        anchors.bottom: contentContainer.top
        anchors.left: parent.left
        anchors.right: parent.right

        // ── Snatcher icon button — image + scissors, left of search bar ──────
        Rectangle {
            id: snatcherIconBtn
            width:  50
            height: 50
            anchors.right:          searchBarContainer.left
            anchors.rightMargin:    14
            anchors.verticalCenter: searchBarContainer.verticalCenter
            radius: 8

            // bevel frame
            Rectangle {
                anchors.fill:    snatcherFace
                anchors.margins: -1
                radius:          snatcherFace.radius + 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: snatcherMa.pressed ? "#0e0e0e" : "#585858" }
                    GradientStop { position: 1.0; color: snatcherMa.pressed ? "#505050" : "#0a0a0a" }
                }
            }

            // face
            Rectangle {
                id: snatcherFace
                anchors.fill:    parent
                anchors.margins: 1
                radius: 8
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: snatcherMa.pressed ? "#1e1e1e"
                             : (snatcherMa.containsMouse ? "#424242" : "#373737")
                    }
                    GradientStop { position: 0.50; color: snatcherMa.pressed ? "#232323" : "#272727" }
                    GradientStop { position: 1.0;  color: snatcherMa.pressed ? "#2d2d2d" : "#141414" }
                }

                // gloss
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: snatcherMa.pressed ? Qt.rgba(1,1,1,0.03) : Qt.rgba(1,1,1,0.18) }
                        GradientStop { position: 0.42; color: snatcherMa.pressed ? Qt.rgba(1,1,1,0.0)  : Qt.rgba(1,1,1,0.05) }
                        GradientStop { position: 0.43; color: Qt.rgba(1,1,1,0.0) }
                        GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0) }
                    }
                }

                // accent border
                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "transparent"
                    border.color: "#FF9800"; border.width: 1
                    opacity: snatcherMa.containsMouse ? (snatcherMa.pressed ? 0.30 : 0.75) : 0.20
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // 🖼 main icon
                Text {
                    anchors.centerIn: parent
                    text:            "🖼"
                    font.pixelSize:  22
                    opacity:         snatcherMa.containsMouse ? 1.0 : 0.80
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                // ✂ scissors badge — bottom-right corner
                Text {
                    anchors.right:        parent.right
                    anchors.bottom:       parent.bottom
                    anchors.rightMargin:  4
                    anchors.bottomMargin: 2
                    text:            "✂"
                    font.pixelSize:  13
                    color:           "#FF9800"
                    opacity:         snatcherMa.containsMouse ? 1.0 : 0.65
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
            }

            // drop shadow
            Rectangle {
                x: 3; y: snatcherMa.pressed ? 2 : 4
                width: parent.width - 2; height: parent.height
                radius: parent.radius; color: "#000000"
                opacity: snatcherMa.pressed ? 0.0 : 0.65
                z: -1
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }

            MouseArea {
                id: snatcherMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked:    snatcher2Panel.visible = true
                ToolTip.visible: containsMouse
                ToolTip.text:    "Snatcher — grab & crop an image"
                ToolTip.delay:   600
            }
        }

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
        anchors.topMargin: parent.height * 0.18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        anchors.left: parent.left
        anchors.leftMargin: 50
        anchors.right: parent.right
        anchors.rightMargin: 50
        radius: 0
        color: "transparent"
        border.color: "#2566c2"
        border.width: 2
        clip: true

        // ── Persistent movie wall — always visible behind all content ─────────
        // Shows through whenever contentLoader is empty or loads a view with a
        // transparent root (workbench panels, etc.).  Covered automatically by
        // SplashScreen (z:9999) and any fully-opaque loaded view.
        WorkbenchSplash {
            anchors.fill: parent
            z: 0
        }

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
                    // Fresh entry into collection flow — reset history
                    window.navHistory = []
                    contentLoader.item.categorySelected.connect(function(categoryKey) {
                        // Push CategoryMenu as the back destination
                        window.navHistory.push({ source: "CategoryMenu.qml", props: {} })
                        window.lastCollectionsModel = collectionLogic.get_collections_by_category(categoryKey)
                        contentLoader.setSource("CollectionsGallery.qml", { "collectionsModel": window.lastCollectionsModel })
                    })
                }

                if (contentLoader.source.toString().includes("CollectionsGallery.qml")) {
                    contentLoader.item.collectionSelected.connect(function(collectionItems) {
                        window.currentCollectionItems = collectionItems
                        // Push CollectionsGallery as the back destination
                        window.navHistory.push({ source: "CollectionsGallery.qml", props: { "collectionsModel": window.lastCollectionsModel } })
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
                            var currentSrc = contentLoader.source.toString()
                            if (currentSrc.includes("Detail_View_v2")) {
                                // Detail_View back — return to where we came from
                                var dest = window.previousLoaderSource
                                if (dest === "landing_view.qml") {
                                    contentLoader.setSource("landing_view.qml")
                                } else if (dest !== "") {
                                    contentLoader.source = dest
                                    splash.activate()
                                } else {
                                    splash.activate()
                                }
                            } else if (window.navHistory.length > 0) {
                                // Collection flow back — pop the history stack
                                var entry = window.navHistory.pop()
                                contentLoader.setSource(entry.source, entry.props || {})
                            } else {
                                // Nothing left — go home
                                splash.activate()
                            }
                        })
                    }
                } catch(e) { console.log("Connection warning: " + e) }
            }
        }

    }

    // ── Quick-access slide panel — top-left, aligned with button row ─────────
    SlidePanel {
        id: slidePanel
        anchors.top:        parent.top
        anchors.topMargin:  26          // matches buttonRows.topMargin
        anchors.left:       parent.left
        anchors.leftMargin: 20
        z: 200
        // Wire signals here when modules are ready:
        // onQobuzMusicClicked:        { ... }
        // onMediaEditClicked:         { ... }
        // onCollectionCuratorClicked: { ... }
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

    // --------------------------------------------------------
    // Server Connectivity — Blocking Popup
    // --------------------------------------------------------
    Connections {
        target: manifestUpdater
        function onServerCheckFailed() {
            serverDownPopup.checking = false
            serverDownPopup.open()
        }
        function onServerCheckPassed() {
            serverDownPopup.close()
            // Reload the initial view so it initialises cleanly with fresh data
            if (startupMode === "Tiles") {
                contentLoader.setSource("landing_view.qml")
            } else {
                contentLoader.setSource("ImageGridView_v2.qml")
            }
        }
    }

    Popup {
        id: serverDownPopup
        property bool checking: false

        anchors.centerIn: parent
        width: 560
        height: 300
        modal: true
        closePolicy: Popup.NoAutoClose
        z: 9999

        background: Rectangle {
            color: "#E8101010"
            radius: 16
            border.color: "#2566c2"
            border.width: 2
        }

        Column {
            anchors.centerIn: parent
            spacing: 24
            width: parent.width - 64

            Text {
                width: parent.width
                text: "No Server Connection"
                color: "white"
                font.pixelSize: 28
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: serverDownPopup.checking
                      ? "Checking server\u2026"
                      : "MediaVerse requires the media server (W:) to start.\nCheck your network connection and try again."
                color: "#AAAAAA"
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: serverDownPopup.checking
                running: serverDownPopup.checking
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                visible: !serverDownPopup.checking

                Button {
                    text: "Retry"
                    font.pixelSize: 22
                    onClicked: {
                        serverDownPopup.checking = true
                        manifestUpdater.retry_server_check()
                    }
                }

                Button {
                    text: "Exit"
                    font.pixelSize: 22
                    onClicked: Qt.quit()
                }
            }
        }
    }
}