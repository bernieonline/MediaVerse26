import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

GridView {
    id: collectionsGrid
    anchors.fill: parent
    anchors.margins: 30
    cellWidth: 280
    cellHeight: 320
    clip: true
    // High Z-index ensures the grid isn't buried under background layers
    z: 100 

    property var collectionsModel: []
    model: collectionsModel

    // Safety bridge to Python logic
    property var logic: (typeof collectionLogic !== "undefined") ? collectionLogic : null

    delegate: Item {
        width: 260
        height: 300
        z: 101

        // Fan images logic
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
            // Glow border on hover
            border.color: (topMouse.containsMouse || actionRow.anyHover) ? "#1E90FF" : "#333333"
            border.width: (topMouse.containsMouse || actionRow.anyHover) ? 3 : 1

            // --- 1. TOP CLICKABLE AREA (Main Card Body) ---
            MouseArea {
                id: topMouse
                width: parent.width
                height: parent.height - 70 // Stops above the icon row
                anchors.top: parent.top
                hoverEnabled: true
                onClicked: {
                    console.log("QML DEBUG: Main Card Clicked -> " + modelData.name)
                    if (collectionsGrid.logic) {
                        var filteredMovies = collectionsGrid.logic.get_collection_results(modelData.rules)
                        contentLoader.setSource("ImageGridView.qml", { "externalImageList": filteredMovies })
                    }
                }
            }

            // --- 2. VISUAL CONTENT ---
            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                // The Fan Stack
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

                // Collection Title
                Text {
                    text: modelData.name || "Unnamed Collection"
                    width: parent.width
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            // --- 3. BOTTOM ACTION ROW (Icons) ---
            Row {
                id: actionRow
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 25
                z: 110 // Ensure buttons are physically on top of everything

                property bool anyHover: favM.containsMouse || renM.containsMouse || delM.containsMouse
                
                opacity: (topMouse.containsMouse || anyHover) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // FAVORITE BUTTON
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

                // EDIT BUTTON
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
                            console.log("QML DEBUG: EDIT Button Clicked")
                            // Future: Add Rename Dialog call here
                        }
                    }
                }

                // DELETE BUTTON
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
                            console.log("QML DEBUG: DEL Button Clicked")
                            if (typeof notificationManager !== "undefined")
                                notificationManager.post_notification("Delete " + modelData.name + "?", true)
                        }
                    }
                }
            }
        }

        // --- 4. DECORATION ---
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