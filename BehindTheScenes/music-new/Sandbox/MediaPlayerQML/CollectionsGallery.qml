import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

GridView {
    id: collectionsGrid
    anchors.fill: parent
    anchors.margins: 30
    
    // Adjusted for nice spacing between square cards
    cellWidth: 280 
    cellHeight: 300
    clip: true

    // This property is filled by the Loader in main.qml
    property var collectionsModel: []
    model: collectionsModel

    delegate: Item {
        width: 260; height: 280

        // --- 1. SHADOW LAYER ---
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
            width: 240; height: 260
            anchors.centerIn: parent
            color: "#1A1A1A"
            radius: 20 // Rounded corners
            border.color: cardMouse.containsMouse ? "#1E90FF" : "#333333"
            border.width: cardMouse.containsMouse ? 3 : 1

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                // --- SQUARE IMAGE CONTAINER ---
                Rectangle {
                    id: imageContainer
                    width: parent.width
                    height: parent.width // Makes it square
                    color: "#000"
                    radius: 15
                    
                    Image {
                        id: posterPreview
                        anchors.fill: parent
                        // Python function to find the first movie image for this collection
                        source: (modelData.rules) ? collectionLogic.get_collection_images_by_rules(modelData.rules)[0] : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: false // Hidden to be used by the mask
                    }

                    // Rounded Mask for the Image
                    Rectangle {
                        id: maskRect
                        anchors.fill: parent
                        radius: 15
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: posterPreview
                        source: posterPreview
                        maskSource: maskRect
                    }
                    
                    // Inner glow to give the image depth
                    InnerShadow {
                        anchors.fill: parent
                        radius: 10
                        samples: 16
                        color: "#AA000000"
                        source: maskRect
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
                    
                    // 1. Get the list of movies from Python using the card's rules
                    var images = collectionLogic.get_collection_results(modelData.rules)
                    
                    // 2. Switch the Loader back to the GridView, passing the results
                    contentLoader.setSource("ImageGridView.qml", { "externalImageList": images })
                }
            }
        }
    }
    
    // Scrollbar styling
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
}