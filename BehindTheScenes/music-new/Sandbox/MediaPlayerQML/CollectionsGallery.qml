import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

GridView {
    id: collectionsGrid
    signal collectionSelected(var items)
    anchors.fill: parent
    anchors.margins: 30
    cellWidth: 280
    cellHeight: 320
    clip: true
    z: 100

    property var collectionsModel: []
    model: collectionsModel

    property var logic: (typeof collectionLogic !== "undefined") ? collectionLogic : null

    delegate: Item {
        width: 260
        height: 300
        z: 101

        property var fanImages: {
            try {
                if (modelData && modelData.rules && collectionsGrid.logic) {
                    return collectionsGrid.logic.get_collection_images_by_rules(modelData.rules)
                }
            } catch(e) { return [] }
            return []
        }

        Rectangle {
            id: cardRect
            width: 240
            height: 280
            anchors.centerIn: parent
            color: "#1A1A1A"
            radius: 20

            border.color: (topMouse.containsMouse || actionRow.anyHover) ? "#1E90FF" : "#333333"
            border.width: (topMouse.containsMouse || actionRow.anyHover) ? 3 : 1

            MouseArea {
                id: topMouse
                width: parent.width
                height: parent.height - 70
                anchors.top: parent.top
                hoverEnabled: true
                onClicked: {
                    if (collectionsGrid.logic) {
                        var filteredMovies = collectionsGrid.logic.get_collection_results(modelData.rules)

                        // ⭐ NEW: Emit the signal so Loader can auto-switch views
                        collectionsGrid.collectionSelected(filteredMovies)

                        // ⭐ Existing behavior (kept exactly as-is)
                        //contentLoader.setSource("ImageGridView_v2.qml", { "externalImageList": filteredMovies })
                    }

                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                Item {
                    id: fanContainer
                    width: parent.width
                    height: 180

                    Repeater {
                        model: fanImages.length
                        delegate: Item {
                            width: 110
                            height: 165
                            anchors.centerIn: parent
                            rotation: index === 0 ? -20 : (index === 1 ? 0 : 30)
                            x: index === 0 ? -30 : (index === 1 ? 0 : 35)

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: "#000"
                                border.color: "white"
                                border.width: 2
                                clip: true

                                Image {
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
                                    source: parent.children[0]
                                    maskSource: maskRect
                                }
                            }
                        }
                    }
                }

                // --- INLINE RENAME BLOCK ---
                Item {
                    id: renameBlock
                    width: parent.width
                    height: nameLabel.implicitHeight
                    property bool editing: false

                    // VIEW MODE
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

                    
                    // EDIT MODE
                    // EDIT MODE
                    // EDIT MODE
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
                        
                        // --- TEXT CONTRAST FIXES ---
                        color: "white"
                        selectionColor: "#1E90FF"      // Bright blue selection
                        selectedTextColor: "white"
                        leftPadding: 10
                        rightPadding: 10
                        
                        // --- HIGH CONTRAST BACKGROUND ---
                        background: Rectangle {
                            color: "#000000"           // Pure black for maximum contrast
                            radius: 6
                            border.color: "#1E90FF"    // Action Blue border
                            border.width: 2            // Thicker border while editing
                            
                            // Add a slight glow effect to the input box
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                color: "#401E90FF"
                                radius: 8
                                samples: 16
                            }
                        }

                        onAccepted: renameBlock.finishRename()

                        onFocusChanged: {
                            if (!focus && renameBlock.editing)
                                renameBlock.finishRename()
                        }
                    }
                    //finishRename
                    function finishRename() {
                        renameBlock.editing = false
                        let newName = nameEditor.text.trim()
                        
                        // 1. If it's the same or empty, do nothing
                        if (newName.length === 0 || newName === modelData.name) return

                        // 2. Capture the REAL old name before changing
                        let oldName = modelData.name 

                        // 3. Call Python to update the JSON
                        if (collectionsGrid.logic) {
                            collectionsGrid.logic.rename_collection(oldName, newName)
                        }

                        // 4. Update the local data
                        modelData.name = newName
                        
                        // 5. REFRESH FIX: 
                        // Instead of setting to [], just notify the grid the model has updated
                        collectionsGrid.modelChanged() 
                    }
                }
            }

            Row {
                id: actionRow
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 25
                z: 110

                property bool anyHover: favM.containsMouse || renM.containsMouse || delM.containsMouse

                opacity: (topMouse.containsMouse || anyHover) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }

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
                            console.log("QML DEBUG: FAV Button Clicked")
                            if (collectionsGrid.logic) {
                                modelData.favorite = !modelData.favorite
                                collectionsGrid.logic.toggle_favorite(modelData.name)
                            }
                        }
                    }
                }

                Item {
                    width: 60; height: 30
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Icon {
                            name: "pen-to-square"
                            iconColor: renM.containsMouse ? "#1E90FF" : "#888888"
                        }
                        Text {
                            text: "EDIT"; font.pixelSize: 14; font.bold: true
                            color: renM.containsMouse ? "#1E90FF" : "#888888"
                        }
                    }
                    MouseArea {
                        id: renM; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            //console.log("QML DEBUG: EDIT Button Clicked -> " + modelData.name)
                            renameBlock.editing = true
                            nameEditor.forceActiveFocus()
                            nameEditor.selectAll()
                        }
                    }
                }

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
                            console.log("QML DEBUG: DEL Button Clicked -> " + modelData.name)

                            if (collectionsGrid.logic) {
                                collectionsGrid.logic.delete_collection(modelData.name)
                            }

                            collectionsGrid.collectionsModel.splice(index, 1)
                            collectionsGrid.model = collectionsGrid.collectionsModel
                        }
                    }
                }
            }
        }

        DropShadow {
            anchors.fill: cardRect
            radius: 15
            samples: 20
            color: (topMouse.containsMouse || actionRow.anyHover) ? "#801E90FF" : "#99000000"
            source: cardRect
        }
    }

    Component.onCompleted: console.log("QML DEBUG: Collections Gallery Loaded Successfully")
}