import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: galleryRoot
    anchors.fill: parent

    // true once a collection image has been confirmed and displayed
    property bool showingCollection: false

    // ── Data model for the collections column ─────────────────────────────────
    ListModel { id: collectionsModel }

    Connections {
        target: architectController

        function onCollectionsForCategoryReady(data) {
            collectionsModel.clear()
            for (var i = 0; i < data.length; i++) {
                collectionsModel.append(data[i])
            }
            collectionList.currentIndex = -1
        }

        function onCollectionImageReady(uri) {
            if (uri === "") return   // no splash image yet — deferred
            collectionHero.imageSource = uri
            galleryRoot.showingCollection = true
        }
    }

    // ── Background: scattered photo display ───────────────────────────────────
    Loader {
        id: splashLoader
        anchors.fill: parent
        source: "splash_screen.qml"
        opacity: galleryRoot.showingCollection ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    }

    // ── ARCHITECT header — top left ───────────────────────────────────────────
    Column {
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.margins: 36
        spacing: 8
        z: 100

        Text {
            text: "ARCHITECT"
            color: "white"
            font.pixelSize:    46
            font.bold:         true
            font.letterSpacing: 7
        }
        Rectangle {
            width: 64; height: 3
            color: "#2566c2"
        }
    }

    // ── Category navigation — right edge ─────────────────────────────────────
    ListView {
        id: categoryList
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
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
            width:  190
            height: 62
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

                border.color: categoryList.currentIndex === index
                    ? "#2566c2"
                    : Qt.rgba(1, 1, 1, 0.14)
                border.width: categoryList.currentIndex === index ? 2 : 1

                Text {
                    anchors.centerIn:  parent
                    text:              modelData.label.toUpperCase()
                    color:             "white"
                    font.pixelSize:    20
                    font.bold:         true
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

    // ── Collections column — appears left of category column on click ─────────
    ListView {
        id: collectionList
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  categoryList.left
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
            width:  190
            height: 62
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

                border.color: collectionList.currentIndex === index
                    ? "#2566c2"
                    : Qt.rgba(1, 1, 1, 0.14)
                border.width: collectionList.currentIndex === index ? 2 : 1

                Text {
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin:     8
                    anchors.rightMargin:    8
                    text:                   model.name
                    color:                  "white"
                    font.pixelSize:         15
                    font.bold:              true
                    font.letterSpacing:     1.0
                    wrapMode:               Text.WordWrap
                    maximumLineCount:       2
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: collectionTile.hovered = true
                onExited:  collectionTile.hovered = false
                onClicked: {
                    collectionList.currentIndex = index
                    architectController.getCollectionImage(model.name)
                    architectController.resolve_collection_for_display(model.name)
                }
            }
        }
    }

    // ── Collection hero view — cinematic single image ─────────────────────────
    Item {
        id: collectionHero
        anchors.fill: parent
        opacity:      galleryRoot.showingCollection ? 1.0 : 0.0
        visible:      opacity > 0

        property string imageSource: ""

        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }

        // Dark stage behind the image
        Rectangle {
            anchors.fill: parent
            color: "#0d0d0d"
        }

        // Clipped container so the zoom doesn't spill outside the frame
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

                onSourceChanged: {
                    scale = 1.0
                    zoomAnim.restart()
                }

                NumberAnimation {
                    id:       zoomAnim
                    target:   heroImg
                    property: "scale"
                    from:     1.0
                    to:       1.10
                    duration: 20000
                    easing.type: Easing.Linear
                }
            }
        }

        // Vignette — radial gradient overlay, dark at edges, clear at centre
        RadialGradient {
            anchors.fill: parent
            z: 1
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.50; color: "transparent" }
                GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.82) }
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
