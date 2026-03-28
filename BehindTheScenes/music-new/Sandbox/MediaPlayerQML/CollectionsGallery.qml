import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: collectionsCarousel
    anchors.fill: parent

    property var collectionsModel: []
    property var logic: (typeof collectionLogic !== "undefined") ? collectionLogic : null

    signal collectionSelected(var items)
    signal backRequested

    // ── Paging ────────────────────────────────────────────────────────────────
    property int pageSize:    10
    property int currentPage: 0
    property int totalPages:  Math.max(1, Math.ceil((collectionsModel.length || 0) / pageSize))

    property var pageItems: {
        var start = currentPage * pageSize
        return collectionsModel.slice(start, start + pageSize)
    }

    onCollectionsModelChanged: {
        currentPage = 0
    }

    // ── Background: dvds.jpg + dark veil (CategoryMenu style) ────────────────
    Image {
        anchors.fill: parent
        source: "file:///" + _paths["splash"] + "/dvds.jpg"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    // ── Back button — top-left ────────────────────────────────────────────────
    Rectangle {
        id: backBtn
        width: 46; height: 46
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
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

    // ── Card grid — 5 cols × 2 rows, centred ─────────────────────────────────
    Item {
        id: cardArea

        property int cols:   5
        property int rows:   2
        property int gap:    64
        // Leave room for back button (top) and page indicator (bottom)
        property int availH: collectionsCarousel.height - 120
        property int cardH:  Math.max(1, Math.floor((availH - gap) / rows))
        property int cardW:  Math.max(1, Math.floor(cardH * 300 / 380))

        width:  cols * (cardW + gap) - gap
        height: rows * (cardH + gap) - gap

        anchors.centerIn: parent

        Repeater {
            model: collectionsCarousel.pageItems

            delegate: Item {
                id: cardDelegate
                property int ci: index
                width:  cardArea.cardW
                height: cardArea.cardH
                x: (ci % cardArea.cols) * (cardArea.cardW + cardArea.gap)
                y: Math.floor(ci / cardArea.cols) * (cardArea.cardH + cardArea.gap)

                property var fanImages: {
                    try {
                        if (modelData && modelData.rules && collectionsCarousel.logic) {
                            return collectionsCarousel.logic.get_collection_images_by_rules(modelData.rules)
                        }
                    } catch(e) { return [] }
                    return []
                }

                // ── DropShadow — gold glow on hover (declared before source) ──
                DropShadow {
                    anchors.fill: cardRect
                    radius: 18
                    samples: 24
                    color: (cardHover.hovered || actionRow.anyHover) ? "#CCFFD700" : "#55000000"
                    source: cardRect
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // ── Card panel ────────────────────────────────────────────────
                Rectangle {
                    id: cardRect
                    anchors.fill: parent
                    color: "#1A1A1A"
                    radius: 20

                    border.color: (cardHover.hovered || actionRow.anyHover) ? "#FFD700" : "#7A5C00"
                    border.width: (cardHover.hovered || actionRow.anyHover) ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    HoverHandler { id: cardHover }

                    TapHandler {
                        onTapped: {
                            if (!collectionsCarousel.logic) return

                            const rules = modelData.rules
                            const tempResults = collectionsCarousel.logic.get_collection_results_v2(rules, "thumb")
                            const count = tempResults.length
                            const resolution = (count <= 14) ? "display" : "thumb"

                            var filteredMovies = collectionsCarousel.logic.get_collection_results_v2(rules, resolution)
                            collectionsCarousel.collectionSelected(filteredMovies)
                        }
                    }

                    // ── Fan image area ────────────────────────────────────────
                    Item {
                        id: fanContainer
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 15
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        height: Math.floor(parent.height * 0.68)
                        clip: true

                        Repeater {
                            model: Math.min(fanImages.length, 4)
                            delegate: Item {
                                property int fi: index
                                property int pw: Math.floor(cardArea.cardW * 0.52)
                                property int ph: Math.floor(pw * 1.48)
                                width: pw; height: ph
                                anchors.centerIn: parent
                                rotation: fi === 0 ? -30 : (fi === 1 ? -10 : (fi === 2 ? 10 : 30))
                                x: fi === 0 ? -Math.floor(pw * 0.46)
                                   : (fi === 1 ? -Math.floor(pw * 0.15)
                                   : (fi === 2 ?  Math.floor(pw * 0.15)
                                   :              Math.floor(pw * 0.46)))
                                z: (fi === 1 || fi === 2) ? 2 : 1
                                opacity: (fi === 0 || fi === 3) ? 0.85 : 1.0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#000"
                                    border.color: "white"
                                    border.width: 2
                                    clip: true

                                    Image {
                                        id: fanImg
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: fanImages[fi] || ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: false
                                    }

                                    Rectangle {
                                        id: fanMask
                                        anchors.fill: parent
                                        radius: 6
                                        visible: false
                                    }

                                    OpacityMask {
                                        anchors.fill: parent
                                        source: fanImg
                                        maskSource: fanMask
                                    }
                                }
                            }
                        }
                    }

                    // ── Collection name ───────────────────────────────────────
                    Item {
                        id: renameBlock
                        anchors.bottom: actionRow.top
                        anchors.bottomMargin: 6
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
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

                    // ── Action row — FAV / EDIT / DEL ─────────────────────────
                    Row {
                        id: actionRow
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        z: 110

                        property bool anyHover: favM.containsMouse || renM.containsMouse || delM.containsMouse

                        opacity: (cardHover.hovered || anyHover) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }

                        // FAV
                        Item {
                            width: 48; height: 26
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Icon {
                                    name: "heart"
                                    iconColor: modelData.favorite ? "#FFE040" : (favM.containsMouse ? "#FFE040" : "#BBBBBB")
                                }
                                Text {
                                    text: "FAV"; font.pixelSize: 12; font.bold: true
                                    color: favM.containsMouse ? "#FFE040" : "#BBBBBB"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                            MouseArea {
                                id: favM; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (collectionsCarousel.logic) {
                                        modelData.favorite = !modelData.favorite
                                        collectionsCarousel.logic.toggle_favorite(modelData.name)
                                    }
                                }
                            }
                        }

                        // EDIT
                        Item {
                            width: 52; height: 26
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Icon {
                                    name: "pen-to-square"
                                    iconColor: renM.containsMouse ? "#66AAFF" : "#BBBBBB"
                                }
                                Text {
                                    text: "EDIT"; font.pixelSize: 12; font.bold: true
                                    color: renM.containsMouse ? "#66AAFF" : "#BBBBBB"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                            MouseArea {
                                id: renM; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    renameBlock.editing = true
                                    nameEditor.forceActiveFocus()
                                    nameEditor.selectAll()
                                }
                            }
                        }

                        // DELETE
                        Item {
                            width: 46; height: 26
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Icon {
                                    name: "trash"
                                    iconColor: delM.containsMouse ? "#FF6060" : "#BBBBBB"
                                }
                                Text {
                                    text: "DEL"; font.pixelSize: 12; font.bold: true
                                    color: delM.containsMouse ? "#FF6060" : "#BBBBBB"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                            MouseArea {
                                id: delM; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (collectionsCarousel.logic) {
                                        collectionsCarousel.logic.delete_collection(modelData.name)
                                    }
                                    collectionsCarousel.collectionsModel.splice(
                                        collectionsCarousel.currentPage * collectionsCarousel.pageSize + index, 1)
                                    collectionsCarousel.collectionsModelChanged()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Left page button ──────────────────────────────────────────────────────
    Rectangle {
        id: leftBtn
        width: 60; height: 200
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        visible: collectionsCarousel.currentPage > 0

        Text {
            anchors.centerIn: parent
            text: "❮"
            font.pixelSize: 70
            color: leftMa.containsMouse ? "#FFFFFF" : "#666666"
        }
        MouseArea {
            id: leftMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: collectionsCarousel.currentPage = Math.max(0, collectionsCarousel.currentPage - 1)
        }
    }

    // ── Right page button ─────────────────────────────────────────────────────
    Rectangle {
        id: rightBtn
        width: 60; height: 200
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        visible: collectionsCarousel.currentPage < collectionsCarousel.totalPages - 1

        Text {
            anchors.centerIn: parent
            text: "❯"
            font.pixelSize: 70
            color: rightMa.containsMouse ? "#FFFFFF" : "#666666"
        }
        MouseArea {
            id: rightMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: collectionsCarousel.currentPage = Math.min(
                collectionsCarousel.totalPages - 1, collectionsCarousel.currentPage + 1)
        }
    }

    // ── Page indicator ────────────────────────────────────────────────────────
    Text {
        visible: collectionsCarousel.totalPages > 1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        text: (collectionsCarousel.currentPage + 1) + " / " + collectionsCarousel.totalPages
        color: "#888888"
        font.pixelSize: 18
    }
}
