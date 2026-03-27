import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: collectionsCarousel
    anchors.fill: parent
    anchors.margins: 40

    // --- Layout parameters ---
    property int cardWidth: 300
    property int cardHeight: 420
    property int cardSpacing: 40
    property int visibleCount: 4

    property var collectionsModel: []
    property var logic: (typeof collectionLogic !== "undefined") ? collectionLogic : null

    signal collectionSelected(var items)
    signal backRequested

    // Back button — top-left corner
    Rectangle {
        id: backBtn
        width: 46; height: 46
        anchors.top: parent.top
        anchors.left: parent.left
        z: 200
        color: backMa.containsMouse ? "#2a2a2a" : "transparent"
        radius: 8
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "❮"
            font.pixelSize: 26
            color: backMa.containsMouse ? "white" : "#888888"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: backMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: collectionsCarousel.backRequested()
        }
    }

    // Max starting index so we never show a partial row at the end
    property int maxIndex: Math.max(0, (collectionsModel.length || 0) - visibleCount)

    function updatePosition() {
        carousel.contentX = carousel.currentIndex * (cardWidth + cardSpacing)
    }

    // --- LEFT NAV BUTTON ---
    Rectangle {
        id: leftBtn
        width: 60
        height: 200
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: "❮"
            font.pixelSize: 70
            color: leftBtnMouse.containsMouse ? "#FFFFFF" : "#666666"
        }

        MouseArea {
            id: leftBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                console.log(">>>> CAROUSEL CLICK TRIGGERED 1 <<<<")

                carousel.currentIndex = Math.max(0, carousel.currentIndex - 1)
                collectionsCarousel.updatePosition()
            }
        }
    }

    // --- RIGHT NAV BUTTON ---
    Rectangle {
        id: rightBtn
        width: 60
        height: 200
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: "❯"
            font.pixelSize: 70
            color: rightBtnMouse.containsMouse ? "#FFFFFF" : "#666666"
        }

        MouseArea {
            id: rightBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                console.log(">>>> CAROUSEL CLICK TRIGGERED 2 <<<<")

                carousel.currentIndex = Math.min(collectionsCarousel.maxIndex, carousel.currentIndex + 1)
                collectionsCarousel.updatePosition()
            }
        }
    }

    // --- SINGLE‑ROW, 4‑CARD WINDOW, CENTRED ---
    ListView {
        id: carousel

        width: collectionsCarousel.cardWidth * collectionsCarousel.visibleCount
               + collectionsCarousel.cardSpacing * (collectionsCarousel.visibleCount - 1)
        height: collectionsCarousel.cardHeight

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        orientation: ListView.Horizontal
        spacing: collectionsCarousel.cardSpacing
        clip: true

        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.NoSnap

        model: collectionsModel

        onModelChanged: {
            carousel.currentIndex = 0
            collectionsCarousel.updatePosition()
        }

        delegate: Item {
            width: collectionsCarousel.cardWidth
            height: collectionsCarousel.cardHeight
            z: 101

            property var fanImages: {
                try {
                    if (modelData && modelData.rules && collectionsCarousel.logic) {
                        return collectionsCarousel.logic.get_collection_images_by_rules(modelData.rules)
                    }
                } catch(e) { return [] }
                return []
            }

            Rectangle {
                id: cardRect
                width: 260
                height: 380
                anchors.centerIn: parent
                color: "#1A1A1A"
                radius: 20

                border.color: (cardHover.hovered || actionRow.anyHover) ? "#2566c2" : "#333333"
                border.width: (cardHover.hovered || actionRow.anyHover) ? 3 : 1

                HoverHandler {
                    id: cardHover
                }

                TapHandler {
                    onTapped: {
                        console.log(">>>> CAROUSEL CLICK TRIGGERED 3 <<<<")
                        console.log("Target Collection:", modelData.name)
                        console.log("Rules Object:", JSON.stringify(modelData.rules))

                        if (!collectionsCarousel.logic)
                            return

                        const rules = modelData.rules
                        const tempResults = collectionsCarousel.logic.get_collection_results_v2(rules, "thumb")
                        const count = tempResults.length
                        const resolution = (count <= 14) ? "display" : "thumb"

                        var filteredMovies = collectionsCarousel.logic.get_collection_results_v2(
                            rules,
                            resolution
                        )

                        collectionsCarousel.collectionSelected(filteredMovies)
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    // FAN IMAGE CONTAINER
                    Item {
                        id: fanContainer
                        width: parent.width
                        height: 260

                        Repeater {
                            model: fanImages.length
                            delegate: Item {
                                width: 150
                                height: 220
                                anchors.centerIn: parent
                                rotation: index === 0 ? -25 : (index === 1 ? 0 : 25)
                                x: index === 0 ? -50 : (index === 1 ? 0 : 50)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#000"
                                    border.color: "white"
                                    border.width: 2
                                    clip: true

                                    Image {
                                        id: collectionImg
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: fanImages[index] || ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: false
                                    }

                                    Rectangle {
                                        id: maskRect
                                        anchors.fill: parent
                                        radius: 6
                                        visible: false
                                    }

                                    OpacityMask {
                                        anchors.fill: parent
                                        source: collectionImg
                                        maskSource: maskRect
                                    }
                                }
                            }
                        }
                    }

                    // RENAME BLOCK
                    Item {
                        id: renameBlock
                        width: parent.width
                        height: nameLabel.implicitHeight
                        property bool editing: false

                        Text {
                            id: nameLabel
                            visible: !renameBlock.editing
                            text: modelData.name || "Unnamed Collection"
                            width: parent.width
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        TextField {
                            id: nameEditor
                            visible: renameBlock.editing
                            text: modelData.name
                            width: parent.width
                            font.pixelSize: 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            focus: renameBlock.editing

                            color: "white"
                            selectionColor: "#2566c2"
                            selectedTextColor: "white"

                            background: Rectangle {
                                color: "#000000"
                                radius: 6
                                border.color: "#2566c2"
                                border.width: 2
                            }

                            onAccepted: renameBlock.finishRename()
                            onFocusChanged: {
                                if (!focus && renameBlock.editing)
                                    renameBlock.finishRename()
                            }
                        }

                        function finishRename() {
                            renameBlock.editing = false
                            let newName = nameEditor.text.trim()

                            if (newName.length === 0 || newName === modelData.name) return

                            let oldName = modelData.name

                            if (collectionsCarousel.logic) {
                                collectionsCarousel.logic.rename_collection(oldName, newName)
                            }

                            modelData.name = newName
                            collectionsCarousel.modelChanged()
                        }
                    }
                }

                // ACTION ROW
                Row {
                    id: actionRow
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 25
                    z: 110

                    property bool anyHover: favM.containsMouse || renM.containsMouse || delM.containsMouse

                    opacity: (cardHover.hovered || anyHover) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    // FAV
                    Item {
                        width: 60; height: 30
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Icon {
                                name: "heart"
                                iconColor: modelData.favorite ? "#FFD700" : (favM.containsMouse ? "#FFFFFF" : "#888888")
                            }
                            Text {
                                text: "FAV"; font.pixelSize: 14; font.bold: true
                                color: favM.containsMouse ? "#FFD700" : "#888888"
                            }
                        }
                        MouseArea {
                            id: favM; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                console.log(">>>> CAROUSEL CLICK TRIGGERED 4 <<<<")

                                if (collectionsCarousel.logic) {
                                    modelData.favorite = !modelData.favorite
                                    collectionsCarousel.logic.toggle_favorite(modelData.name)
                                }
                            }
                        }
                    }

                    // EDIT
                    Item {
                        width: 60; height: 30
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Icon {
                                name: "pen-to-square"
                                iconColor: renM.containsMouse ? "#2566c2" : "#888888"
                            }
                            Text {
                                text: "EDIT"; font.pixelSize: 14; font.bold: true
                                color: renM.containsMouse ? "#2566c2" : "#888888"
                            }
                        }
                        MouseArea {
                            id: renM; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                console.log(">>>> CAROUSEL CLICK TRIGGERED 5 <<<<")

                                renameBlock.editing = true
                                nameEditor.forceActiveFocus()
                                nameEditor.selectAll()
                            }
                        }
                    }

                    // DELETE
                    Item {
                        width: 60; height: 30
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Icon {
                                name: "trash"
                                iconColor: delM.containsMouse ? "#FF4444" : "#888888"
                            }
                            Text {
                                text: "DEL"; font.pixelSize: 14; font.bold: true
                                color: delM.containsMouse ? "#FF4444" : "#888888"
                            }
                        }
                        MouseArea {
                            id: delM; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                console.log(">>>> CAROUSEL CLICK TRIGGERED 6 <<<<")

                                if (collectionsCarousel.logic) {
                                    collectionsCarousel.logic.delete_collection(modelData.name)
                                }

                                collectionsCarousel.collectionsModel.splice(index, 1)
                                collectionsCarousel.model = collectionsCarousel.collectionsModel
                            }
                        }
                    }
                }
            }

            DropShadow {
                anchors.fill: cardRect
                radius: 15
                samples: 20
                color: (cardHover.hovered || actionRow.anyHover) ? "#802566c2" : "#99000000"
                source: cardRect
            }
        }
    }

    Component.onCompleted: {
        collectionsCarousel.updatePosition()
    }
}