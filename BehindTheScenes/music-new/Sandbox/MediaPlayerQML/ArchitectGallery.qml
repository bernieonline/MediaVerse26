import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

Item {
    id: galleryRoot
    anchors.fill: parent

    // ── Signals — same signature as ImageGridView so parent connections work ──
    signal v2OpenDetail(var movie)
    signal v2PlayMovie(var movie)

    // true once a collection has been selected and its movies resolved
    property bool   showingCollection:      false
    property string currentCollectionName:  ""
    property bool   currentFavorite:        false
    property bool   renamingActive:         false
    property string pendingNewName:         ""
    property bool   filmStripVisible:       false
    property string currentImagePath:       "None"

    // ── Data models ───────────────────────────────────────────────────────────
    ListModel { id: collectionsModel }
    ListModel { id: movieGridModel  }

    Connections {
        target: architectController

        function onCollectionsForCategoryReady(data) {
            collectionsModel.clear()
            for (var i = 0; i < data.length; i++)
                collectionsModel.append(data[i])
            collectionList.currentIndex = -1
        }

        function onCollectionImageReady(uri) {
            if (uri !== "")
                collectionHero.imageSource = uri
        }

        function onCollectionMoviesReady(data) {
            movieGridModel.clear()
            gridPane.currentPage = 0
            for (var i = 0; i < data.length; i++)
                movieGridModel.append(data[i])
            if (data.length > 0)
                galleryRoot.showingCollection = true
        }

        function onCollectionFavoriteState(isFav) {
            galleryRoot.currentFavorite = isFav
        }

        function onCollectionImagePathReady(imgPath) {
            galleryRoot.currentImagePath = imgPath
        }
    }

    // ── Background: scattered photo splash ────────────────────────────────────
    Loader {
        id: splashLoader
        anchors.fill: parent
        source: "splash_screen.qml"
        opacity: galleryRoot.showingCollection ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    }

    // ── ARCHITECT header — top left (hidden when collection is displayed) ───────
    Column {
        anchors.top:     parent.top
        anchors.left:    parent.left
        anchors.margins: 36
        spacing: 8
        z: 100
        opacity: galleryRoot.showingCollection ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

        Text {
            text: "ARCHITECT"
            color: "white"
            font.pixelSize:     46
            font.bold:          true
            font.letterSpacing: 7
        }
        Text {
            text: "COLLECTION"
            color: "white"
            font.pixelSize:     46
            font.bold:          true
            font.letterSpacing: 7
        }
        Rectangle { width: 64; height: 3; color: "#2566c2" }
    }

    // ── Category column — right edge ──────────────────────────────────────────
    ListView {
        id: categoryList
        anchors.top:          parent.top
        anchors.bottom:       parent.bottom
        anchors.right:        parent.right
        anchors.topMargin:    20
        anchors.bottomMargin: 20
        anchors.rightMargin:  20
        width:        190
        clip:         true
        spacing:      8
        currentIndex: -1
        opacity:      galleryRoot.showingCollection ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

        model: architectController.galleryCategoryModel

        delegate: Item {
            id: categoryTile
            width: 190; height: 62
            property bool hovered:   false
            property bool isActive:  categoryList.currentIndex === index

            // Glass body
            Rectangle {
                anchors.fill: parent
                radius: 7
                gradient: Gradient {
                    GradientStop { position: 0.0; color: categoryTile.isActive
                        ? Qt.rgba(0.10, 0.28, 0.60, 0.96)
                        : categoryTile.hovered ? Qt.rgba(0.10, 0.10, 0.14, 0.90)
                                               : Qt.rgba(0.05, 0.05, 0.08, 0.82) }
                    GradientStop { position: 1.0; color: categoryTile.isActive
                        ? Qt.rgba(0.08, 0.20, 0.50, 0.96)
                        : categoryTile.hovered ? Qt.rgba(0.07, 0.07, 0.11, 0.90)
                                               : Qt.rgba(0.03, 0.03, 0.06, 0.82) }
                }
                Behavior on gradient { }   // keeps ColorAnimation from firing on gradient change
                border.color: categoryTile.isActive ? "#2566c2" : Qt.rgba(1,1,1, categoryTile.hovered ? 0.22 : 0.10)
                border.width: 1

                // Left accent bar
                Rectangle {
                    anchors.left:   parent.left
                    anchors.top:    parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    width:  categoryTile.isActive ? 4 : (categoryTile.hovered ? 3 : 2)
                    radius: 3
                    color:  categoryTile.isActive ? "#2566c2" : Qt.rgba(0.37, 0.50, 0.76, categoryTile.hovered ? 0.70 : 0.30)
                    Behavior on width { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Label
                Text {
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin:     16
                    anchors.rightMargin:    28
                    text:               modelData.label.toUpperCase()
                    color:              "white"
                    font.pixelSize:     18
                    font.bold:          true
                    font.letterSpacing: 1.5
                    elide:              Text.ElideRight
                }

                // Chevron — only on selected
                Text {
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin:    10
                    text:    "›"
                    color:   "#2566c2"
                    font.pixelSize: 22
                    font.bold: true
                    visible: categoryTile.isActive
                    opacity: categoryTile.isActive ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: categoryTile.hovered = true
                onExited:  categoryTile.hovered = false
                onClicked: {
                    categoryList.currentIndex = index
                    architectController.getCollectionsForCategory(modelData.key)
                }
            }
        }
    }

    // ── Collections column — left of category column ──────────────────────────
    ListView {
        id: collectionList
        anchors.top:          parent.top
        anchors.bottom:       parent.bottom
        anchors.right:        categoryList.left
        anchors.topMargin:    20
        anchors.bottomMargin: 20
        anchors.rightMargin:  10
        width:        190
        clip:         true
        spacing:      8
        currentIndex: -1
        visible:      categoryList.currentIndex >= 0
        opacity:      galleryRoot.showingCollection ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

        model: collectionsModel

        delegate: Item {
            id: collectionTile
            width: 190; height: 62
            property bool hovered:  false
            property bool isActive: collectionList.currentIndex === index

            // Slide in from right when column first appears
            x: collectionList.visible ? 0 : 30
            opacity: collectionList.visible ? 1.0 : 0.0
            Behavior on x       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Rectangle {
                anchors.fill: parent
                radius: 7
                gradient: Gradient {
                    GradientStop { position: 0.0; color: collectionTile.isActive
                        ? Qt.rgba(0.10, 0.28, 0.60, 0.96)
                        : collectionTile.hovered ? Qt.rgba(0.10, 0.10, 0.14, 0.90)
                                                 : Qt.rgba(0.05, 0.05, 0.08, 0.82) }
                    GradientStop { position: 1.0; color: collectionTile.isActive
                        ? Qt.rgba(0.08, 0.20, 0.50, 0.96)
                        : collectionTile.hovered ? Qt.rgba(0.07, 0.07, 0.11, 0.90)
                                                 : Qt.rgba(0.03, 0.03, 0.06, 0.82) }
                }
                border.color: collectionTile.isActive ? "#2566c2" : Qt.rgba(1,1,1, collectionTile.hovered ? 0.22 : 0.10)
                border.width: 1

                // Left accent bar
                Rectangle {
                    anchors.left:   parent.left
                    anchors.top:    parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    width:  collectionTile.isActive ? 4 : (collectionTile.hovered ? 3 : 2)
                    radius: 3
                    color:  collectionTile.isActive ? "#2566c2" : Qt.rgba(0.37, 0.50, 0.76, collectionTile.hovered ? 0.70 : 0.30)
                    Behavior on width { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin:     16
                    anchors.rightMargin:    10
                    text:               model.name
                    color:              "white"
                    font.pixelSize:     15
                    font.bold:          true
                    font.letterSpacing: 0.8
                    wrapMode:           Text.WordWrap
                    maximumLineCount:   2
                    verticalAlignment:  Text.AlignVCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: collectionTile.hovered = true
                onExited:  collectionTile.hovered = false
                onClicked: {
                    collectionList.currentIndex = index
                    galleryRoot.currentCollectionName = model.name
                    galleryRoot.renamingActive  = false
                    galleryRoot.pendingNewName  = ""
                    galleryRoot.currentFavorite = false
                    collectionHero.imageSource = ""
                    architectController.getCollectionImage(model.name)
                    architectController.resolve_collection_for_grid(model.name)
                }
            }
        }
    }

    // ── Collection hero view ──────────────────────────────────────────────────
    Item {
        id: collectionHero
        anchors.fill: parent
        opacity: galleryRoot.showingCollection ? 1.0 : 0.0
        visible: opacity > 0
        property string imageSource: ""
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }

        // Dismiss hover-preview when clicking blank background areas
        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: {
                gridPane.hoveredMovie         = null
                theFilmStrip.selectedMovie    = null
                galleryRoot.filmStripVisible  = false
            }
        }

        // Dark stage
        Rectangle { anchors.fill: parent; color: "#0d0d0d" }

        // Zooming hero image
        Item {
            anchors.fill: parent
            clip: true
            Image {
                id: heroImg
                anchors.fill:    parent
                source:          collectionHero.imageSource
                fillMode:        Image.PreserveAspectCrop
                smooth:          true
                asynchronous:    true
                transformOrigin: Item.Center
                layer.enabled:   true
                onSourceChanged: { scale = 1.0; zoomAnim.restart() }
                NumberAnimation {
                    id: zoomAnim; target: heroImg; property: "scale"
                    from: 1.0; to: 1.10; duration: 20000; easing.type: Easing.Linear
                }
            }
        }

        // Vignette
        RadialGradient {
            anchors.fill: parent
            z: 1
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.50; color: "transparent" }
                GradientStop { position: 1.0;  color: Qt.rgba(0,0,0,0.82) }
            }
        }

        // ── Movie grid — top-left anchored, 4 × 2 portrait posters ─────────────
        Item {
            id: gridPane
            anchors.fill: parent
            z: 2
            visible: movieGridModel.count > 0

            property int currentPage: 0
            readonly property int totalPages: Math.max(1, Math.ceil(movieGridModel.count / 8))

            // edgeMargin = half-inch border from screen to glass panel
            // imgGap     = spacing between images inside the grid
            readonly property real edgeMargin: 24
            readonly property real imgGap:     12
            readonly property real posterH: (parent.height - edgeMargin * 2 - imgGap * 3) / 2 - 36
            readonly property real posterW: posterH * 2 / 3

            // ── Hover-preview state ─────────────────────────────────────────────
            property var hoveredMovie: null

            Timer {
                id: showTimer
                interval: 380
                repeat:   false
                property var pendingMovie: null
                onTriggered: if (pendingMovie) gridPane.hoveredMovie = pendingMovie
            }
            Timer {
                id: hideTimer
                interval: 180
                repeat:   false
                onTriggered: gridPane.hoveredMovie = null
            }

            // ── Smoky glass panel — wraps grid with equal imgGap border ─────────
            // Three-item OpacityMask pattern: content (layer) + mask (layer) → clean rounded clip

            Item {
                id: glassContent
                x:      gridPane.edgeMargin
                y:      gridPane.edgeMargin
                width:  gridContainer.width  + gridPane.imgGap * 2
                height: gridContainer.height + gridPane.imgGap * 2
                visible: false
                layer.enabled: true

                FastBlur {
                    x:      -gridPane.edgeMargin
                    y:      -gridPane.edgeMargin
                    width:  galleryRoot.width
                    height: galleryRoot.height
                    source: heroImg
                    radius: 32
                }
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.04, 0.04, 0.07, 0.22)
                }
            }

            Rectangle {
                id: glassMask
                x:      glassContent.x
                y:      glassContent.y
                width:  glassContent.width
                height: glassContent.height
                radius: 14
                visible: false
                layer.enabled: true
            }

            OpacityMask {
                x:          glassContent.x
                y:          glassContent.y
                width:      glassContent.width
                height:     glassContent.height
                source:     glassContent
                maskSource: glassMask
                z: 0
            }

            // Grid + nav wrapped in a Column, inset one imgGap from glass edge
            Column {
                id: gridStack
                x: gridPane.edgeMargin + gridPane.imgGap
                y: gridPane.edgeMargin + gridPane.imgGap
                spacing: 16

                // Page-flip container
                Item {
                    id: gridContainer
                    width:  4 * gridPane.posterW + 3 * gridPane.imgGap
                    height: 2 * (gridPane.posterH + 36) + gridPane.imgGap
                    layer.enabled: true
                    transform: Rotation {
                        id: pageRotation
                        origin.x: gridContainer.width  / 2
                        origin.y: gridContainer.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: 0
                    }

                    Grid {
                        id: movieGrid
                        columns:       4
                        rowSpacing:    gridPane.imgGap
                        columnSpacing: gridPane.imgGap

                    Repeater {
                        model: 8
                        delegate: Item {
                            id: cellItem
                            width:  gridPane.posterW
                            height: gridPane.posterH + 36

                            property int  absIdx:    gridPane.currentPage * 8 + index
                            property bool hasData:   absIdx < movieGridModel.count
                            property var  movieData: hasData
                                ? movieGridModel.get(absIdx)
                                : ({ title: "", year: "", imageUri: "", display: "" })

                            // Poster — portrait 2:3
                            Rectangle {
                                id: posterRect
                                width:  gridPane.posterW
                                height: gridPane.posterH
                                radius: 6
                                // Empty cells are fully transparent — the blurred hero shows through
                                color:  cellItem.hasData ? "#111" : "transparent"
                                clip:   true

                                // Ghost border for empty cells — maintains grid rhythm without weight
                                border.color: cellItem.hasData ? "transparent" : Qt.rgba(1, 1, 1, 0.06)
                                border.width: cellItem.hasData ? 0 : 1

                                // Layer + drop shadow: only on populated cards
                                layer.enabled: cellItem.hasData
                                layer.effect: DropShadow {
                                    horizontalOffset: 0
                                    verticalOffset:   10
                                    radius:           16
                                    samples:          33
                                    color:            Qt.rgba(0, 0, 0, 0.72)
                                    spread:           0
                                }

                                Image {
                                    anchors.fill: parent
                                    source:       cellItem.movieData.imageUri || ""
                                    fillMode:     Image.PreserveAspectCrop
                                    smooth:       true
                                    asynchronous: true
                                }

                                // Top-lit sheen — only on populated cards
                                Rectangle {
                                    anchors.fill: parent
                                    radius:       parent.radius
                                    visible:      cellItem.hasData
                                    gradient: Gradient {
                                        GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, 0.09) }
                                        GradientStop { position: 0.42; color: "transparent" }
                                    }
                                }

                                // Year badge — top right
                                Rectangle {
                                    visible: cellItem.hasData && cellItem.movieData.year !== ""
                                    anchors.top:    parent.top
                                    anchors.right:  parent.right
                                    anchors.margins: 6
                                    width:  yrTxt.implicitWidth + 12
                                    height: 22; radius: 4
                                    color:  Qt.rgba(0,0,0,0.72)
                                    Text {
                                        id: yrTxt
                                        anchors.centerIn: parent
                                        text:  cellItem.movieData.year || ""
                                        color: "#e0e0e0"
                                        font.pixelSize: 13; font.bold: true
                                    }
                                }

                                // Hover tint — only on populated cards
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius
                                    visible: cellItem.hasData
                                    color: Qt.rgba(1,1,1, cellMouse.containsMouse ? 0.09 : 0)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                // Blue bottom accent on hover — only on populated cards
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 3
                                    color: "#2566c2"
                                    visible: cellItem.hasData
                                    opacity: cellMouse.containsMouse ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                // ── Click handler (same pattern as ImageGridView) ──
                                Timer {
                                    id: cellClickTimer
                                    interval: 250; repeat: false
                                    property bool dblGuard: false
                                    onTriggered: {
                                        if (!dblGuard && cellItem.hasData)
                                            galleryRoot.v2OpenDetail({
                                                display:  cellItem.movieData.imageUri,
                                                filePath: cellItem.movieData.imageUri,
                                                title:    cellItem.movieData.title,
                                                year:     cellItem.movieData.year
                                            })
                                        dblGuard = false
                                    }
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill:   parent
                                    hoverEnabled:   true
                                    acceptedButtons: Qt.LeftButton

                                    onEntered: {
                                        hideTimer.stop()
                                        if (cellItem.hasData) {
                                            showTimer.pendingMovie = cellItem.movieData
                                            showTimer.restart()
                                        }
                                    }
                                    onExited: {
                                        showTimer.stop()
                                        showTimer.pendingMovie = null
                                        hideTimer.restart()
                                    }

                                    onClicked: {
                                        if (!cellItem.hasData) return
                                        cellClickTimer.dblGuard = false
                                        cellClickTimer.restart()
                                    }

                                    onDoubleClicked: {
                                        if (!cellItem.hasData) return
                                        cellClickTimer.dblGuard = true
                                        cellClickTimer.stop()
                                        let resolved = _xmlController.resolve_paths(cellItem.movieData.display)
                                        if (resolved && resolved.video) {
                                            let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                                            playbackRouter.playVideo(cleanPath, false)
                                            galleryRoot.v2PlayMovie(cleanPath)
                                        } else {
                                            console.log("❌ No video path for: " + cellItem.movieData.title)
                                        }
                                    }
                                }
                            }

                            // Title
                            Text {
                                anchors.top:              posterRect.bottom
                                anchors.topMargin:        6
                                anchors.horizontalCenter: parent.horizontalCenter
                                width:               gridPane.posterW
                                text:                cellItem.movieData.title || ""
                                color:               "white"
                                font.pixelSize:      14
                                horizontalAlignment: Text.AlignHCenter
                                elide:               Text.ElideRight
                                maximumLineCount:    1
                            }
                        }
                    }
                }
            }  // end gridContainer

            }  // end Column (gridStack)

            // ── Navigation — vertical column to the right of grid, screen-centred ──
            Column {
                id: navButtons
                x: gridStack.x + gridStack.width + gridPane.imgGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20
                z: 3

                // Prev page
                Item {
                    width: 70; height: 70
                    opacity: gridPane.currentPage > 0 ? 1.0 : 0.28
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Rectangle {
                        anchors.fill: parent; radius: 35
                        color: prevHov.containsMouse ? Qt.rgba(0.15,0.40,0.76,0.88) : Qt.rgba(0.08,0.08,0.08,0.82)
                        border.color: "#2566c2"; border.width: 2
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "‹"; color: "white"; font.pixelSize: 42; font.bold: true }
                    MouseArea {
                        id: prevHov; anchors.fill: parent; hoverEnabled: true
                        enabled: gridPane.currentPage > 0
                        onClicked: gridPane.flipPage(gridPane.currentPage - 1, false)
                    }
                }

                // Page indicator
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:  (gridPane.currentPage + 1) + " / " + gridPane.totalPages
                    color: Qt.rgba(1,1,1,0.55); font.pixelSize: 15
                }

                // Next page
                Item {
                    width: 70; height: 70
                    opacity: gridPane.currentPage < gridPane.totalPages - 1 ? 1.0 : 0.28
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Rectangle {
                        anchors.fill: parent; radius: 35
                        color: nextHov.containsMouse ? Qt.rgba(0.15,0.40,0.76,0.88) : Qt.rgba(0.08,0.08,0.08,0.82)
                        border.color: "#2566c2"; border.width: 2
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "›"; color: "white"; font.pixelSize: 42; font.bold: true }
                    MouseArea {
                        id: nextHov; anchors.fill: parent; hoverEnabled: true
                        enabled: gridPane.currentPage < gridPane.totalPages - 1
                        onClicked: gridPane.flipPage(gridPane.currentPage + 1, true)
                    }
                }
            }

            // ── Hover-preview — large portrait right of nav buttons ─────────────
            Item {
                id: hoverPreview
                z: 9
                x: navButtons.x + navButtons.width + 20
                anchors.verticalCenter: parent.verticalCenter
                // Half of the remaining screen width after navButtons
                width:  Math.floor((galleryRoot.width - navButtons.x - navButtons.width) / 2 - 32)
                height: width * 1.5   // portrait 2:3 ratio

                opacity: gridPane.hoveredMovie !== null ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

                Rectangle {
                    id: previewRect
                    anchors.fill: parent
                    radius: 10
                    color:  "#111"
                    clip:   true

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset:   20
                        radius:           30
                        samples:          33
                        color:            Qt.rgba(0, 0, 0, 0.90)
                    }

                    Image {
                        anchors.fill: parent
                        source:       gridPane.hoveredMovie ? gridPane.hoveredMovie.imageUri : ""
                        fillMode:     Image.PreserveAspectCrop
                        smooth:       true
                        asynchronous: true
                    }

                    // Top-lit sheen
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, 0.07) }
                            GradientStop { position: 0.38; color: "transparent" }
                        }
                    }

                    // Year badge — top right
                    Rectangle {
                        visible: gridPane.hoveredMovie !== null && gridPane.hoveredMovie.year !== ""
                        anchors.top:     parent.top
                        anchors.right:   parent.right
                        anchors.margins: 10
                        width:  previewYrTxt.implicitWidth + 16
                        height: 26; radius: 5
                        color:  Qt.rgba(0, 0, 0, 0.75)
                        Text {
                            id: previewYrTxt
                            anchors.centerIn: parent
                            text:  gridPane.hoveredMovie ? gridPane.hoveredMovie.year : ""
                            color: "#e0e0e0"
                            font.pixelSize: 15; font.bold: true
                        }
                    }

                    // Title bar — bottom
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height: 56
                        color:  Qt.rgba(0, 0, 0, 0.76)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.leftMargin:  14
                            anchors.rightMargin: 14
                            text:                gridPane.hoveredMovie ? gridPane.hoveredMovie.title : ""
                            color:               "white"
                            font.pixelSize:      20
                            font.bold:           true
                            horizontalAlignment: Text.AlignHCenter
                            elide:               Text.ElideRight
                            maximumLineCount:    1
                        }
                    }

                    // Blue bottom accent
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 3
                        color: "#2566c2"
                    }
                }

                // ── Click / double-click (mirrors grid cell behaviour) ───────────
                Timer {
                    id: previewClickTimer
                    interval: 250; repeat: false
                    property bool dblGuard: false
                    onTriggered: {
                        if (!dblGuard && gridPane.hoveredMovie)
                            galleryRoot.v2OpenDetail({
                                display:  gridPane.hoveredMovie.imageUri,
                                filePath: gridPane.hoveredMovie.imageUri,
                                title:    gridPane.hoveredMovie.title,
                                year:     gridPane.hoveredMovie.year
                            })
                        dblGuard = false
                    }
                }

                MouseArea {
                    id: previewMouse
                    anchors.fill:    hoverPreview
                    hoverEnabled:    true
                    acceptedButtons: Qt.LeftButton

                    onEntered: hideTimer.stop()
                    onExited:  hideTimer.restart()

                    onClicked: {
                        if (!gridPane.hoveredMovie) return
                        previewClickTimer.dblGuard = false
                        previewClickTimer.restart()
                    }

                    onDoubleClicked: {
                        if (!gridPane.hoveredMovie) return
                        previewClickTimer.dblGuard = true
                        previewClickTimer.stop()
                        var md = gridPane.hoveredMovie
                        let resolved = _xmlController.resolve_paths(md.display)
                        if (resolved && resolved.video) {
                            let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                            playbackRouter.playVideo(cleanPath, false)
                            galleryRoot.v2PlayMovie(cleanPath)
                        } else {
                            console.log("❌ No video path for: " + md.title)
                        }
                    }
                }
            }

            // ── Film strip dim — darkens glass+grid, sits above glass (z:0) but
            //    below nav/toggle (z:3) so those remain fully interactive ────────
            Rectangle {
                anchors.fill: parent
                z:       1
                color:   "black"
                opacity: galleryRoot.filmStripVisible ? 0.62 : 0.0
                visible: opacity > 0
                // enabled: true (default) — intentionally blocks grid interaction
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
            }

            // ── Film strip toggle button — below nav buttons ───────────────────
            Item {
                id: filmToggle
                z: 3
                x: navButtons.x
                y: navButtons.y + navButtons.height + 22
                width: 70; height: 58
                property bool hovered: false

                ToolTip.visible: hovered
                ToolTip.text:    "Fast Browse"
                ToolTip.delay:   500

                Rectangle {
                    anchors.fill: parent; radius: 10
                    color: galleryRoot.filmStripVisible
                        ? Qt.rgba(0.15, 0.40, 0.76, 0.92)
                        : (filmToggle.hovered
                            ? Qt.rgba(0.15, 0.40, 0.76, 0.55)
                            : Qt.rgba(0.08, 0.08, 0.08, 0.82))
                    border.color: "#2566c2"; border.width: 2
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Mini drawn film strip icon — 4 frames with sprocket holes
                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: 4
                        Item {
                            width: 8; height: 22
                            // Frame body
                            Rectangle {
                                x: 0; y: 4; width: 8; height: 14
                                color: Qt.rgba(1, 1, 1, galleryRoot.filmStripVisible ? 0.95 : 0.70)
                                radius: 1
                            }
                            // Top hole
                            Rectangle {
                                x: 1; y: 0; width: 6; height: 3; radius: 1
                                color: Qt.rgba(1, 1, 1, galleryRoot.filmStripVisible ? 0.40 : 0.28)
                            }
                            // Bottom hole
                            Rectangle {
                                x: 1; y: 19; width: 6; height: 3; radius: 1
                                color: Qt.rgba(1, 1, 1, galleryRoot.filmStripVisible ? 0.40 : 0.28)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: filmToggle.hovered = true
                    onExited:  filmToggle.hovered = false
                    onClicked: {
                        galleryRoot.filmStripVisible = !galleryRoot.filmStripVisible
                        // Clear any lingering grid hover preview
                        if (galleryRoot.filmStripVisible) gridPane.hoveredMovie = null
                    }
                }
            }

            // ── Page-flip animation ───────────────────────────────────────────
            function flipPage(target, forward) {
                flipAnim.nextTarget = target
                flipAnim.goForward  = forward
                flipAnim.restart()
            }

            SequentialAnimation {
                id: flipAnim
                property int  nextTarget: 0
                property bool goForward:  true

                NumberAnimation {
                    target: pageRotation; property: "angle"
                    to: flipAnim.goForward ? -90 : 90
                    duration: 320; easing.type: Easing.InCubic
                }
                ScriptAction { script: gridPane.currentPage = flipAnim.nextTarget }
                NumberAnimation {
                    target: pageRotation; property: "angle"
                    from: flipAnim.goForward ? 90 : -90; to: 0
                    duration: 320; easing.type: Easing.OutCubic
                }
            }
        }

        // ── Film strip — floats low, overlays dimmed grid ────────────────────
        FilmStrip {
            id: theFilmStrip
            z: 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     50
            width:  parent.width - 40
            height: parent.height * 0.40

            movieModel: movieGridModel

            opacity: galleryRoot.filmStripVisible ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

            onPlayMovie: function(movie) {
                var resolved = _xmlController.resolve_paths(movie.display)
                if (resolved && resolved.video) {
                    var cleanPath = resolved.video.toString().replace(/\\/g, "/")
                    playbackRouter.playVideo(cleanPath, false)
                    galleryRoot.v2PlayMovie(cleanPath)
                } else {
                    console.log("❌ [FilmStrip] No video path for: " + movie.title)
                }
            }
        }

        // ── Bottom-right: ARCHITECT label + collection name ───────────────────
        Column {
            id: collectionLabelColumn
            anchors.bottom:       parent.bottom
            anchors.right:        parent.right
            anchors.bottomMargin: 36
            anchors.rightMargin:  40
            spacing: 4
            z: 3

            Text {
                anchors.right:      parent.right
                text:               "ARCHITECT"
                color:              Qt.rgba(1,1,1,0.55)
                font.pixelSize:     14
                font.bold:          true
                font.letterSpacing: 6
            }

            // Rename-aware name block
            Item {
                width: 480; height: 42

                // Normal view
                Text {
                    id: collectionNameLabel
                    anchors.right:       parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible:             !galleryRoot.renamingActive
                    text:                galleryRoot.currentCollectionName
                    color:               "#FFD700"
                    font.pixelSize:      28
                    font.bold:           true
                    font.letterSpacing:  1
                    horizontalAlignment: Text.AlignRight
                    elide:               Text.ElideLeft
                    width:               480
                }

                // Rename mode
                TextField {
                    id: renameField
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible:                galleryRoot.renamingActive
                    width:                  480
                    height:                 42
                    text:                   galleryRoot.currentCollectionName
                    color:                  "#FFD700"
                    font.pixelSize:         24
                    font.bold:              true
                    horizontalAlignment:    Text.AlignRight
                    selectByMouse:          true
                    selectionColor:         Qt.rgba(0.55, 0.55, 0.55, 0.80)
                    selectedTextColor:      "white"
                    focus:                  galleryRoot.renamingActive
                    background: Rectangle {
                        color:        "transparent"
                        border.color: "#FFD700"
                        border.width: 1
                        radius:       4
                    }
                    onAccepted: {
                        var trimmed = renameField.text.trim()
                        if (trimmed.length === 0 || trimmed === galleryRoot.currentCollectionName) {
                            galleryRoot.renamingActive = false
                            return
                        }
                        galleryRoot.pendingNewName = trimmed
                        renameConfirmPopup.visible = true
                    }
                    Keys.onEscapePressed: {
                        galleryRoot.renamingActive = false
                        renameField.text = galleryRoot.currentCollectionName
                    }
                }
            }
        }

        // ── Collection action bar — smoky glass, above the name label ──────────
        Item {
            id: actionBar
            anchors.bottom:       collectionLabelColumn.top
            anchors.right:        parent.right
            anchors.bottomMargin: 10
            anchors.rightMargin:  40
            width:  284   // 4 × 60px icons + 3 × 14px gaps + 2 × 11px padding
            height: 72
            z: 4
            opacity: galleryRoot.showingCollection ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

            // 80% transparent background (was 50%)
            Rectangle {
                anchors.fill:  parent
                radius:        12
                color:         Qt.rgba(0.04, 0.04, 0.07, 0.20)
                border.color:  Qt.rgba(1, 1, 1, 0.28)
                border.width:  1
            }

            // ── File dialog — same folder as FinishPopup ──────────────────────
            FileDialog {
                id: splashImagePicker
                title:       "Select Splash Image"
                folder:      "file:///D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/Assets/Splash"
                nameFilters: ["Images (*.jpg *.png *.jpeg)"]
                onAccepted: {
                    var fullPath = file.toString().replace("file:///", "")
                    var parts    = fullPath.split(/[\/\\]/)
                    var filename = parts[parts.length - 1]
                    architectController.update_collection_image(galleryRoot.currentCollectionName, filename)
                }
            }

            Row {
                anchors.centerIn: parent
                spacing:          14

                // ── Favourite ──────────────────────────────────────────────────
                Item {
                    id: favBtn
                    width: 60; height: 60
                    property bool hovered: false

                    ToolTip.visible: hovered
                    ToolTip.text:    galleryRoot.currentFavorite ? "Remove from Favourites" : "Add to Favourites"
                    ToolTip.delay:   500

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: favBtn.hovered ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text:           "♥"
                        font.pixelSize: 33
                        color: galleryRoot.currentFavorite
                            ? "#FFD700"
                            : (favBtn.hovered ? "white" : Qt.rgba(1,1,1,0.55))
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: favBtn.hovered = true
                        onExited:  favBtn.hovered = false
                        onClicked: {
                            galleryRoot.currentFavorite = !galleryRoot.currentFavorite
                            architectController.toggle_favorite_architect(galleryRoot.currentCollectionName)
                        }
                    }
                }

                // ── Set image ──────────────────────────────────────────────────
                Item {
                    id: imgBtn
                    width: 60; height: 60
                    property bool hovered: false

                    ToolTip.visible: hovered
                    ToolTip.text:    galleryRoot.currentImagePath !== "None"
                                         ? "Change Collection Image"
                                         : "Set Collection Image"
                    ToolTip.delay:   500

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: imgBtn.hovered ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Tiny thumbnail if image is set, otherwise a placeholder icon
                    Rectangle {
                        anchors.centerIn: parent
                        width: 38; height: 28; radius: 4
                        color:        "#1a1a2a"
                        border.color: imgBtn.hovered ? "#2566c2" : Qt.rgba(1,1,1,0.40)
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: galleryRoot.currentImagePath !== "None"
                                ? "file:///D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/Assets/Splash/"
                                  + galleryRoot.currentImagePath
                                : ""
                            fillMode: Image.PreserveAspectCrop
                            smooth:   true
                            visible:  galleryRoot.currentImagePath !== "None"
                        }
                        // Placeholder mountain/landscape glyph when no image
                        Text {
                            anchors.centerIn: parent
                            text:    "🖼"
                            font.pixelSize: 16
                            visible: galleryRoot.currentImagePath === "None"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: imgBtn.hovered = true
                        onExited:  imgBtn.hovered = false
                        onClicked: splashImagePicker.open()
                    }
                }

                // ── Rename ─────────────────────────────────────────────────────
                Item {
                    id: renBtn
                    width: 60; height: 60
                    property bool hovered: false

                    ToolTip.visible: hovered
                    ToolTip.text:    "Rename Collection"
                    ToolTip.delay:   500

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: renBtn.hovered ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text:           "✏"
                        font.pixelSize: 30
                        color: renBtn.hovered || galleryRoot.renamingActive
                            ? "#5599ff"
                            : "#2566c2"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: renBtn.hovered = true
                        onExited:  renBtn.hovered = false
                        onClicked: {
                            if (!galleryRoot.renamingActive) {
                                galleryRoot.renamingActive = true
                                renameField.text = galleryRoot.currentCollectionName
                                renameField.forceActiveFocus()
                                renameField.selectAll()
                            } else {
                                galleryRoot.renamingActive = false
                            }
                        }
                    }
                }

                // ── Delete ─────────────────────────────────────────────────────
                Item {
                    id: delBtn
                    width: 60; height: 60
                    property bool hovered: false

                    ToolTip.visible: hovered
                    ToolTip.text:    "Delete Collection"
                    ToolTip.delay:   500

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: delBtn.hovered ? Qt.rgba(0.40, 0.04, 0.04, 0.55) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text:           "✕"
                        font.pixelSize: 30
                        font.bold:      true
                        color: delBtn.hovered ? "#FF6666" : "#CC2222"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: delBtn.hovered = true
                        onExited:  delBtn.hovered = false
                        onClicked: deleteConfirmPopup.visible = true
                    }
                }
            }
        }
    }

    // ── FilmStrip dwell preview — galleryRoot level, z:150, not bound by any container ──
    // Reads hover state from theFilmStrip; positioned using theFilmStrip's coordinate space
    // which maps 1:1 to galleryRoot (collectionHero + gridPane are both anchors.fill at 0,0).
    Item {
        id: stripDwellPreview
        z: 150

        // 25% bigger than the old in-strip popup (was height * 0.88)
        readonly property real pvW: Math.round(theFilmStrip.height * 1.10)
        readonly property real pvH: Math.round(pvW * 1.50)

        width:  pvW
        height: pvH

        // Positioned above the selected frame; x tracks selectedCenterX.
        x: Math.max(4, Math.min(galleryRoot.width - pvW - 4,
               theFilmStrip.x + theFilmStrip.selectedCenterX - pvW / 2))
        y: Math.max(10, theFilmStrip.y - pvH - 16)

        // Driven purely by click — no hover timers.
        // enabled flips off immediately when selection clears so the strip below
        // is never blocked by the fading card.
        enabled: theFilmStrip.selectedMovie !== null

        opacity: (galleryRoot.showingCollection && galleryRoot.filmStripVisible
                  && theFilmStrip.selectedMovie !== null) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

        // Single-click → open detail view (no disambiguation timer needed: click is the intent)
        // Double-click → play movie

        Rectangle {
            id: sdpCard
            anchors.fill: parent
            radius: 10; color: "#111"; clip: true

            layer.enabled: true
            layer.effect: DropShadow {
                verticalOffset: 0; horizontalOffset: 0
                radius: 30; samples: 33
                color: Qt.rgba(0, 0, 0, 0.94)
            }

            Image {
                anchors.fill: parent
                source:       theFilmStrip.selectedMovie ? theFilmStrip.selectedMovie.imageUri : ""
                fillMode:     Image.PreserveAspectCrop
                smooth: true; asynchronous: true
            }

            // Top sheen
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, 0.08) }
                    GradientStop { position: 0.35; color: "transparent"           }
                }
            }

            // Year badge — top right
            Rectangle {
                visible: theFilmStrip.selectedMovie !== null && theFilmStrip.selectedMovie.year !== ""
                anchors.top:     parent.top
                anchors.right:   parent.right
                anchors.margins: 10
                width: sdpYrTxt.implicitWidth + 16; height: 26; radius: 5
                color: Qt.rgba(0, 0, 0, 0.76)
                Text {
                    id: sdpYrTxt; anchors.centerIn: parent
                    text:  theFilmStrip.selectedMovie ? theFilmStrip.selectedMovie.year : ""
                    color: "#e0e0e0"; font.pixelSize: 14; font.bold: true
                }
            }

            // "Open detail" hint — small label at top-left
            Rectangle {
                anchors.top:    parent.top
                anchors.left:   parent.left
                anchors.margins: 10
                width: hintTxt.implicitWidth + 16; height: 24; radius: 4
                color: Qt.rgba(0.15, 0.40, 0.76, 0.80)
                Text {
                    id: hintTxt; anchors.centerIn: parent
                    text: "tap for details"
                    color: "white"; font.pixelSize: 11; font.bold: false
                }
            }

            // Title bar — bottom
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: 54; color: Qt.rgba(0, 0, 0, 0.80)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    anchors.margins: 12
                    text:  theFilmStrip.selectedMovie ? theFilmStrip.selectedMovie.title : ""
                    color: "white"; font.pixelSize: 17; font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight; maximumLineCount: 1
                }
            }

            // Blue accent line
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 3; color: "#2566c2"
            }
        }

        // Single click on the popup → open detail view and dismiss popup
        // Double-click → play movie
        MouseArea {
            anchors.fill:    sdpCard
            acceptedButtons: Qt.LeftButton

            onClicked: {
                var mv = theFilmStrip.selectedMovie
                if (!mv) return
                theFilmStrip.selectedMovie = null
                galleryRoot.v2OpenDetail({
                    display:  mv.imageUri,
                    filePath: mv.imageUri,
                    title:    mv.title,
                    year:     mv.year
                })
            }

            onDoubleClicked: {
                var mv = theFilmStrip.selectedMovie
                if (!mv) return
                theFilmStrip.selectedMovie = null
                var resolved = _xmlController.resolve_paths(mv.display)
                if (resolved && resolved.video) {
                    var cleanPath = resolved.video.toString().replace(/\\/g, "/")
                    playbackRouter.playVideo(cleanPath, false)
                    galleryRoot.v2PlayMovie(cleanPath)
                }
            }
        }
    }

    // ── Close button — top right, visible when viewing a collection ───────────
    Item {
        anchors.top:         parent.top
        anchors.right:       parent.right
        anchors.topMargin:   24
        anchors.rightMargin: 24
        width: 44; height: 44
        z: 200
        opacity: galleryRoot.showingCollection ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Rectangle {
            anchors.fill: parent; radius: 22
            color: closeBtnHov.containsMouse ? Qt.rgba(0.15,0.40,0.76,0.88) : Qt.rgba(0.08,0.08,0.08,0.82)
            border.color: "#2566c2"; border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 18 }
        MouseArea {
            id: closeBtnHov; anchors.fill: parent; hoverEnabled: true
            onClicked: {
                galleryRoot.showingCollection     = false
                galleryRoot.renamingActive        = false
                galleryRoot.pendingNewName        = ""
                galleryRoot.currentFavorite       = false
                galleryRoot.currentCollectionName = ""
                galleryRoot.currentImagePath      = "None"
                galleryRoot.filmStripVisible      = false
                movieGridModel.clear()
                collectionHero.imageSource = ""
            }
        }
    }

    // ── Delete confirm popup ──────────────────────────────────────────────────
    Rectangle {
        id: deleteConfirmPopup
        anchors.centerIn: parent
        width: 440; height: 188
        radius: 12
        visible: false
        z: 500
        color:        Qt.rgba(0.07, 0.07, 0.10, 0.97)
        border.color: "#FF4444"
        border.width: 2

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:            "Delete this collection?"
                color:           "white"
                font.pixelSize:  20
                font.bold:       true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:            "\u201c" + galleryRoot.currentCollectionName + "\u201d"
                color:           "#FFD700"
                font.pixelSize:  16
                elide:           Text.ElideMiddle
                width:           380
                horizontalAlignment: Text.AlignHCenter
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Item {
                    width: 130; height: 40
                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: yesDelHov.containsMouse ? "#CC2222" : "#882222"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "YES, DELETE"; color: "white"; font.pixelSize: 14; font.bold: true }
                    MouseArea {
                        id: yesDelHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            deleteConfirmPopup.visible = false
                            architectController.delete_architect_collection(galleryRoot.currentCollectionName)
                            galleryRoot.showingCollection     = false
                            galleryRoot.renamingActive        = false
                            galleryRoot.pendingNewName        = ""
                            galleryRoot.currentFavorite       = false
                            galleryRoot.currentCollectionName = ""
                            galleryRoot.filmStripVisible      = false
                            movieGridModel.clear()
                            collectionHero.imageSource = ""
                            categoryList.currentIndex  = -1
                        }
                    }
                }

                Item {
                    width: 90; height: 40
                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: noDelHov.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.06)
                        border.color: Qt.rgba(1,1,1,0.30); border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "CANCEL"; color: "white"; font.pixelSize: 14 }
                    MouseArea { id: noDelHov; anchors.fill: parent; hoverEnabled: true; onClicked: deleteConfirmPopup.visible = false }
                }
            }
        }
    }

    // ── Rename confirm popup ──────────────────────────────────────────────────
    Rectangle {
        id: renameConfirmPopup
        anchors.centerIn: parent
        width: 460; height: 210
        radius: 12
        visible: false
        z: 500
        color:        Qt.rgba(0.07, 0.07, 0.10, 0.97)
        border.color: "#2566c2"
        border.width: 2

        Column {
            anchors.centerIn: parent
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "Rename this collection?"
                color:          "white"
                font.pixelSize: 20
                font.bold:      true
            }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:  "\u201c" + galleryRoot.currentCollectionName + "\u201d"
                    color: Qt.rgba(1,1,1,0.50); font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↓"; color: Qt.rgba(1,1,1,0.35); font.pixelSize: 13
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:  "\u201c" + galleryRoot.pendingNewName + "\u201d"
                    color: "#FFD700"; font.pixelSize: 16; font.bold: true
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Item {
                    width: 130; height: 40
                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: yesRenHov.containsMouse ? "#1a56b0" : "#0d3a7a"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "YES, RENAME"; color: "white"; font.pixelSize: 14; font.bold: true }
                    MouseArea {
                        id: yesRenHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            renameConfirmPopup.visible = false
                            var oldName = galleryRoot.currentCollectionName
                            architectController.rename_architect_collection(oldName, galleryRoot.pendingNewName)
                            galleryRoot.currentCollectionName = galleryRoot.pendingNewName
                            galleryRoot.pendingNewName        = ""
                            galleryRoot.renamingActive        = false
                            // Patch the tile in the collection list model
                            for (var i = 0; i < collectionsModel.count; i++) {
                                if (collectionsModel.get(i).name === oldName) {
                                    collectionsModel.setProperty(i, "name", galleryRoot.currentCollectionName)
                                    break
                                }
                            }
                        }
                    }
                }

                Item {
                    width: 90; height: 40
                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: noRenHov.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.06)
                        border.color: Qt.rgba(1,1,1,0.30); border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "CANCEL"; color: "white"; font.pixelSize: 14 }
                    MouseArea {
                        id: noRenHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            renameConfirmPopup.visible = false
                            galleryRoot.renamingActive = false
                            galleryRoot.pendingNewName = ""
                            renameField.text = galleryRoot.currentCollectionName
                        }
                    }
                }
            }
        }
    }

    // ── Blue rounded border overlay ───────────────────────────────────────────
    Rectangle {
        anchors.fill:  parent
        color:         "transparent"
        radius:        20
        border.color:  "#2566c2"
        border.width:  2
        antialiasing:  true
        z:             10000
        enabled:       false
    }
}
