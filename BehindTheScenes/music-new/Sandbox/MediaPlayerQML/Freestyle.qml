import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: freestyleRoot
    anchors.fill: parent
    color: "#121212" // Deep dark background

    // 1. DATA TRACKER: The "Flight Path"
    ListModel { id: pathStack }

    // 2. STYLIZED WATERMARK: The Gold Bird
    Image {
        id: birdWatermark
        source: "assets/gold_bird_outline.svg" 
        anchors.centerIn: parent
        width: parent.width * 0.5
        fillMode: Image.PreserveAspectFit
        opacity: 0.05 // Very subtle, barely there
        z: 0
    }

    // 3. THE UNFOLDING ENGINE
    Flickable {
        id: mainFlick
        anchors.fill: parent
        contentWidth: unfoldingRow.width
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        // Smoothly slides view to the right when a new pane opens
        Behavior on contentX { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            id: unfoldingRow
            height: parent.height
            spacing: 2

            // --- PANE 0: THE DRIVE DOCK ---
            Rectangle {
                width: 320
                height: freestyleRoot.height
                color: "#D9121212"
                border.color: "#66D4AF37"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 20

                    Text {
                        text: "FREESTYLE"
                        color: "gold"
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 4
                    }

                    Text { text: "SELECT ENTRY POINT"; color: "#888"; font.pixelSize: 10 }

                    Flow {
                        width: parent.width
                        spacing: 12
                        Repeater {
                            model: driveManager.get_available_drives()
                            delegate: Button {
                                text: modelData.label
                                onClicked: {
                                    pathStack.clear();
                                    pathStack.append({"folderPath": modelData.path, "folderName": modelData.label});
                                }
                                // ... (Insert the Gold Pill styling from earlier here)
                            }
                        }
                    }
                }
            }

            // --- DYNAMIC FOLDER PANES ---
            Repeater {
                model: pathStack
                delegate: Rectangle {
                    width: 320
                    height: freestyleRoot.height
                    color: "#F2121212" 
                    border.color: "#33D4AF37"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Text {
                            text: folderName.toUpperCase()
                            color: "gold"
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        ListView {
                            id: folderList
                            width: parent.width
                            height: parent.height - 100
                            clip: true
                            model: driveManager.get_subfolders(folderPath)
                            
                            delegate: ItemDelegate {
                                width: folderList.width
                                height: 40
                                
                                contentItem: Text {
                                    text: "📁  " + modelData.name
                                    color: highlighted ? "gold" : "white"
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    // Remove panes to the right of this one
                                    while (pathStack.count > index + 1) {
                                        pathStack.remove(pathStack.count - 1);
                                    }
                                    // Add new folder
                                    pathStack.append({"folderPath": modelData.path, "folderName": modelData.name});
                                    // Slide view to focus on the new panel
                                    mainFlick.contentX = unfoldingRow.width - mainFlick.width;
                                }
                            }
                        }
                    }
                    // Entrance animation
                    NumberAnimation on width { from: 0; to: 320; duration: 250; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}