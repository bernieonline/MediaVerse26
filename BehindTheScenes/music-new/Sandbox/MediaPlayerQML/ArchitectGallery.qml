import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: galleryRoot
    anchors.fill: parent

    // ── Signals — same signature as ImageGridView so parent connections work ──
    signal v2OpenDetail(var movie)
    signal v2PlayMovie(var movie)

    // true once a collection has been selected and its movies resolved
    property bool showingCollection: false
    property string currentCollectionName: ""

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
            property bool hovered: false

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: categoryList.currentIndex === index
                    ? Qt.rgba(0.15, 0.40, 0.76, 0.92)
                    : categoryTile.hovered
                        ? Qt.rgba(0.12, 0.12, 0.12, 0.88)
                        : Qt.rgba(0.04, 0.04, 0.04, 0.78)
                Behavior on color { ColorAnimation { duration: 120 } }
                border.color: categoryList.currentIndex === index ? "#2566c2" : Qt.rgba(1,1,1,0.14)
                border.width: categoryList.currentIndex === index ? 2 : 1

                Text {
                    anchors.centerIn:   parent
                    text:               modelData.label.toUpperCase()
                    color:              "white"
                    font.pixelSize:     20
                    font.bold:          true
                    font.letterSpacing: 2.0
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
            property bool hovered: false

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: collectionList.currentIndex === index
                    ? Qt.rgba(0.15, 0.40, 0.76, 0.92)
                    : collectionTile.hovered
                        ? Qt.rgba(0.12, 0.12, 0.12, 0.88)
                        : Qt.rgba(0.04, 0.04, 0.04, 0.78)
                Behavior on color { ColorAnimation { duration: 120 } }
                border.color: collectionList.currentIndex === index ? "#2566c2" : Qt.rgba(1,1,1,0.14)
                border.width: collectionList.currentIndex === index ? 2 : 1

                Text {
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin:     8
                    anchors.rightMargin:    8
                    text:               model.name
                    color:              "white"
                    font.pixelSize:     15
                    font.bold:          true
                    font.letterSpacing: 1.0
                    wrapMode:           Text.WordWrap
                    maximumLineCount:   2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
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
                    radius: 48
                }
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.04, 0.04, 0.07, 0.50)
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
                                color:  "#111"
                                clip:   true

                                // Layer + drop shadow: card floats above the glass surface
                                layer.enabled: true
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

                                // Top-lit sheen — plain QML gradient, no effect chaining
                                Rectangle {
                                    anchors.fill: parent
                                    radius:       parent.radius
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

                                // Hover tint
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius
                                    color: Qt.rgba(1,1,1, cellMouse.containsMouse ? 0.09 : 0)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                // Blue bottom accent on hover
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 3
                                    color: "#2566c2"
                                    opacity: cellMouse.containsMouse ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                // ── Click handler (same pattern as ImageGridView) ──
                                MouseArea {
                                    id: cellMouse
                                    anchors.fill:   parent
                                    hoverEnabled:   true
                                    acceptedButtons: Qt.LeftButton
                                    property bool dblActive: false
                                    property var  singleTimer: null

                                    onClicked: {
                                        if (!cellItem.hasData) return
                                        if (singleTimer) singleTimer.stop()
                                        singleTimer = Qt.createQmlObject(
                                            'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                                            galleryRoot
                                        )
                                        singleTimer.triggered.connect(function() {
                                            if (!dblActive) {
                                                galleryRoot.v2OpenDetail({
                                                    display:  cellItem.movieData.imageUri,
                                                    filePath: cellItem.movieData.imageUri,
                                                    title:    cellItem.movieData.title,
                                                    year:     cellItem.movieData.year
                                                })
                                            }
                                            dblActive = false
                                        })
                                        singleTimer.start()
                                    }

                                    onDoubleClicked: {
                                        if (!cellItem.hasData) return
                                        dblActive = true
                                        if (singleTimer) singleTimer.stop()
                                        let resolved = _xmlController.resolve_paths(cellItem.movieData.display)
                                        if (resolved && resolved.video) {
                                            let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                                            playbackBridge.playVideo(cleanPath)
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

        // ── Bottom-right: ARCHITECT label + collection name ───────────────────
        Column {
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
            Text {
                anchors.right:      parent.right
                text:               galleryRoot.currentCollectionName
                color:              "#FFD700"
                font.pixelSize:     28
                font.bold:          true
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignRight
                elide:              Text.ElideLeft
                width:              480
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
                galleryRoot.showingCollection = false
                movieGridModel.clear()
                collectionHero.imageSource = ""
                galleryRoot.currentCollectionName = ""
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
