import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

GridView {
    id: collectionsGrid
    anchors.fill: parent
    anchors.margins: 30
    
    // Spacing adjusted for the "fan" width
    cellWidth: 280 
    cellHeight: 320
    clip: true

    // This property is filled by the Loader in main.qml
    property var collectionsModel: []
    model: collectionsModel

    delegate: Item {
        width: 260; height: 300

        // Fetch the 3 images from Python. 
        // We do this once per delegate to keep it efficient.
        //property var fanImages: (modelData.rules) ? collectionLogic.get_collection_images_by_rules(modelData.rules) : []
        //property var fanImages: (modelData && modelData.rules && (typeof collectionLogic !== "undefined") && collectionLogic !== null) 
              //           ? collectionLogic.get_collection_images_by_rules(modelData.rules) 
                        // : []
        property var fanImages: (modelData.rules) ? collectionLogic.get_collection_images_by_rules(modelData.rules) : []

        
        
        
        // --- 1. OUTER GLOW/SHADOW ---
        DropShadow {
            anchors.fill: cardRect
            horizontalOffset: 0
            verticalOffset: 8
            radius: 15
            samples: 20
            color: cardMouse.containsMouse ? "#801E90FF" : "#99000000"
            source: cardRect
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // --- 2. MAIN CARD BODY ---
        Rectangle {
            id: cardRect
            width: 240; height: 280
            anchors.centerIn: parent
            color: "#1A1A1A"
            radius: 20 
            border.color: cardMouse.containsMouse ? "#1E90FF" : "#333333"
            border.width: cardMouse.containsMouse ? 3 : 1

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                // --- THE FAN CONTAINER ---
                Item {
                    id: fanContainer
                    width: parent.width
                    height: 180 // Box for the cards to sit in
                    
                    Repeater {
                        model: fanImages.length

                        delegate: Item {
                            width: 110; height: 165
                            anchors.centerIn: parent
                            
                            // Transform logic for the "Playing Card" fan
                            // index 0: Left (-20°), index 1: Center (0°), index 2: Right (+30°)
                            rotation: index === 0 ? -20 : (index === 1 ? 0 : 30)
                            x: index === 0 ? -30 : (index === 1 ? 0 : 35)
                            z: index // Top card sits on top

                            Rectangle {
                                id: cardBase
                                anchors.fill: parent
                                radius: 8
                                color: "#000"
                                border.color: "white"
                                border.width: 2
                                clip: true

                                Image {
                                    id: posterImg
                                    anchors.fill: parent
                                    anchors.margins: 2 // Margin shows the white border
                                    source: fanImages[index]
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false // Used by mask
                                }

                                Rectangle {
                                    id: maskRct
                                    anchors.fill: parent
                                    radius: 6
                                    visible: false
                                }

                                OpacityMask {
                                    anchors.fill: parent
                                    source: posterImg
                                    maskSource: maskRct
                                }
                            }

                            // Subtle shadow for each card in the fan to separate them
                            DropShadow {
                                anchors.fill: cardBase
                                radius: 4
                                samples: 8
                                color: "#AA000000"
                                source: cardBase
                            }
                        }
                    }
                }

                // --- COLLECTION NAME ---
                Text {
                    text: modelData.name
                    width: parent.width
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // --- INTERACTION ---
            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    console.log("🚀 Opening Collection:", modelData.name)
                    var filteredMovies = collectionLogic.get_collection_results(modelData.rules)
    
                    if (typeof contentLoader !== "undefined") {
                        contentLoader.setSource("ImageGridView.qml", { "externalImageList": filteredMovies })
                    } else {
                        // Fallback root search
                        var rootObj = collectionsGrid.parent
                        while (rootObj.parent) { rootObj = rootObj.parent }
                        if (rootObj.findChildLoader) {
                            rootObj.findChildLoader("contentLoader").setSource("ImageGridView.qml", { "externalImageList": filteredMovies })
                        }
                    }
                }
            }
        }
    }
    
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
}