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

    property var collectionsModel: []
    model: collectionsModel

    // Safety bridge to Python logic
    property var logic: (typeof collectionLogic !== "undefined") ? collectionLogic : null

    delegate: Item {
        width: 260
        height: 300

        // Fan images from Python rules
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
            border.color: cardMouse.containsMouse ? "#1E90FF" : "#333333"
            border.width: cardMouse.containsMouse ? 3 : 1

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                // --- FAN IMAGE STACK ---
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
                                    id: m
                                    anchors.fill: parent
                                    radius: 6
                                    visible: false
                                }

                                OpacityMask {
                                    anchors.fill: parent
                                    source: parent.children[0]
                                    maskSource: m
                                }
                            }
                        }
                    }
                }

                // --- COLLECTION NAME ---
                Text {
                    text: modelData.name || ""
                    width: parent.width
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            // --- ACTION ROW (FAV / EDIT / DELETE) ---
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 25
                opacity: cardMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // FAVORITE
                Item {
                    width: 60
                    height: 24

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "heart"
                            //iconColor: modelData.is_favorite ? "#FFD700" : "#888888"
                            iconColor: modelData.favorite ? "#FFD700" : "#888888"
                        }

                        Text {
                            text: "FAV"
                            font.pixelSize: 14
                            font.bold: true
                            color: favM.containsMouse ? "#FFD700" : "#888888"
                        }
                    }

                    MouseArea {
                        id: favM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (collectionsGrid.logic)
                            collectionsGrid.logic.toggle_favorite(modelData.name)
                    }
                }

                // EDIT
                Item {
                    width: 60
                    height: 24

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "pen-to-square"
                            iconColor: renM.containsMouse ? "#1E90FF" : "#888888"
                        }

                        Text {
                            text: "EDIT"
                            font.pixelSize: 14
                            font.bold: true
                            color: renM.containsMouse ? "#1E90FF" : "#888888"
                        }
                    }

                    MouseArea {
                        id: renM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: console.log("Rename: " + modelData.name)
                    }
                }

                // DELETE
                Item {
                    width: 60
                    height: 24

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "trash"
                            iconColor: delM.containsMouse ? "#FF4444" : "#888888"
                        }

                        Text {
                            text: "DEL"
                            font.pixelSize: 14
                            font.bold: true
                            color: delM.containsMouse ? "#FF4444" : "#888888"
                        }
                    }

                    MouseArea {
                        id: delM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (typeof notificationManager !== "undefined")
                            notificationManager.post_notification("Delete?", true)
                    }
                }
            }

            // --- CLICK TO OPEN COLLECTION ---
            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (collectionsGrid.logic) {
                        var filteredMovies =
                            collectionsGrid.logic.get_collection_results(modelData.rules)
                        contentLoader.setSource("ImageGridView.qml",
                            { "externalImageList": filteredMovies })
                    }
                }
            }
        }

        // --- DROP SHADOW ---
        DropShadow {
            anchors.fill: cardRect
            radius: 15
            samples: 20
            color: cardMouse.containsMouse ? "#801E90FF" : "#99000000"
            source: cardRect
        }
    }
}