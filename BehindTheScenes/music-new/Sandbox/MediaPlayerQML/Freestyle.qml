import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: freestyleRoot
    anchors.fill: parent
    color: "#121212"

    ListModel { id: pathStack }

    Flickable {
        id: mainFlick
        anchors.fill: parent
        contentWidth: unfoldingRow.width
        clip: true
        Behavior on contentX { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            id: unfoldingRow
            height: parent.height

            // --- PANE 0: DRIVE DOCK ---
            Rectangle {
                width: 300; height: parent.height; color: "#161616"; border.color: "#33D4AF37"
                Column {
                    anchors.fill: parent; anchors.margins: 20; spacing: 15
                    Text { text: "FREESTYLE"; color: "gold"; font.pixelSize: 22; font.bold: true; font.letterSpacing: 2 }
                    Flow {
                        width: parent.width; spacing: 8
                        Repeater {
                            model: driveManager.get_available_drives()
                            delegate: Button {
                                text: modelData.label
                                onClicked: {
                                    pathStack.clear();
                                    // Ensure path is treated as a string and has the trailing slash
                                    pathStack.append({
                                        "targetPath": String(modelData.path), 
                                        "displayName": String(modelData.label)
                                    });
                                }
                            }
                        }
                    }
                }
            }

            // --- UNFOLDING FOLDERS ---
            Repeater {
                model: pathStack
                delegate: Rectangle {
                    id: pane
                    width: 320; height: freestyleRoot.height
                    color: "#1A1A1A"; border.color: "#33D4AF37"; border.width: 1

                    Column {
                        anchors.fill: parent; anchors.margins: 15; spacing: 12
                        
                        // Header: Uses the displayName from our append
                        Text {
                            text: displayName.toUpperCase()
                            color: "gold"; font.pixelSize: 12; font.bold: true
                        }

                        ListView {
                            id: folderList
                            width: parent.width; height: parent.height - 80; clip: true
                            // Use targetPath here - this is the key link to Python
                            model: driveManager.get_subfolders(targetPath)
                            
                            delegate: ItemDelegate {
                                width: folderList.width; height: 35
                                contentItem: Text { 
                                    text: "📁  " + modelData.name
                                    color: "white"; verticalAlignment: Text.AlignVCenter 
                                }
                                
                                onClicked: {
                                    // index is the pane index. Clear everything after this pane.
                                    while (pathStack.count > (index + 1)) { 
                                        pathStack.remove(pathStack.count - 1); 
                                    }
                                    
                                    pathStack.append({
                                        "targetPath": String(modelData.path), 
                                        "displayName": String(modelData.name)
                                    });
                                    scrollTimer.restart();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer { 
        id: scrollTimer; interval: 50; 
        onTriggered: mainFlick.contentX = Math.max(0, unfoldingRow.width - mainFlick.width) 
    }
}