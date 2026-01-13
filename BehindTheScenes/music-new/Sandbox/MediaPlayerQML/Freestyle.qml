import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: freestyleRoot
    anchors.fill: parent
    color: "#121212"

    ListModel { id: pathStack }

    // --- HEADER TOOLS ---
    Row {
        id: toolBar
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 15
        z: 10
        spacing: 10

        Button {
            text: "RESET ALL"
            flat: true
            contentItem: Text { text: parent.text; color: "gold"; font.pixelSize: 10; font.bold: true }
            background: Rectangle { color: parent.hovered ? "#22FFFFFF" : "transparent"; border.color: "gold"; radius: 4 }
            onClicked: pathStack.clear()
        }
    }

    Flickable {
        id: mainFlick
        anchors.fill: parent
        contentWidth: unfoldingRow.width
        clip: true
        Behavior on contentX { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            id: unfoldingRow
            height: parent.height

            // --- PANE 0: THE DRIVE DOCK ---
            Rectangle {
                // Collapse Drive Dock if something is selected
                width: pathStack.count > 0 ? 100 : 320
                height: parent.height; color: "#161616"; border.color: "#33D4AF37"; border.width: 1
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                // Click to return to Drive Selection
                MouseArea {
                    anchors.fill: parent
                    enabled: pathStack.count > 0
                    onClicked: pathStack.clear()
                }

                Column {
                    anchors.fill: parent; anchors.margins: 20; spacing: 30
                    opacity: pathStack.count > 0 ? 0.3 : 1.0 // Fade out when collapsed
                    
                    Text { text: "FREESTYLE"; color: "gold"; font.pixelSize: 22; font.bold: true; visible: pathStack.count == 0 }
                    
                    // Show vertical text when collapsed
                    Text { 
                        text: "DRIVES"; color: "gold"; font.bold: true; 
                        visible: pathStack.count > 0; anchors.horizontalCenter: parent.horizontalCenter
                        rotation: 90; font.pixelSize: 18
                    }

                    Column {
                        width: parent.width; spacing: 10; visible: pathStack.count == 0
                        Text { text: "LOCAL"; color: "#BBBBBB"; font.pixelSize: 10; font.bold: true }
                        Flow { width: parent.width; spacing: 10
                            Repeater { model: driveManager.get_grouped_drives().local; delegate: driveBtnDelegate }
                        }
                    }
                    
                    Column {
                        width: parent.width; spacing: 10; visible: pathStack.count == 0
                        Text { text: "NETWORK"; color: "#BBBBBB"; font.pixelSize: 10; font.bold: true }
                        Flow { width: parent.width; spacing: 10
                            Repeater { model: driveManager.get_grouped_drives().network; delegate: driveBtnDelegate }
                        }
                    }
                }
            }

            // --- UNFOLDING FOLDER PANELS ---
            Repeater {
                model: pathStack
                delegate: Rectangle {
                    id: pane
                    // Current active pane is 400px, previous ones are 100px
                    property bool isActive: index === pathStack.count - 1
                    width: isActive ? 400 : 100
                    height: freestyleRoot.height
                    color: isActive ? "#1A1A1A" : "#141414"
                    border.color: "#33D4AF37"; border.width: 1
                    clip: true

                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                    // Click collapsed panel to navigate back to this level
                    MouseArea {
                        anchors.fill: parent
                        enabled: !pane.isActive
                        onClicked: {
                            while (pathStack.count > (index + 1)) { pathStack.remove(pathStack.count - 1); }
                        }
                    }

                    Column {
                        anchors.fill: parent; anchors.margins: 15; spacing: 12
                        
                        Row {
                            width: parent.width; spacing: 10
                            // Subtle Back Arrow
                            Text { 
                                text: "←"
                                color: "gold"; font.pixelSize: 16; visible: pane.isActive
                                MouseArea { anchors.fill: parent; onClicked: pathStack.remove(pathStack.count - 1) }
                            }
                            Text { 
                                text: displayName.toUpperCase()
                                color: "gold"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; 
                                width: parent.width - 30
                                rotation: pane.isActive ? 0 : 90 // Rotate text if collapsed
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        ListView {
                            id: folderList
                            width: parent.width; height: parent.height - 80; clip: true
                            model: driveManager.get_subfolders(targetPath)
                            visible: pane.isActive // Hide list when collapsed to save resources
                            
                            ScrollBar.vertical: ScrollBar { 
                                id: listSB
                                policy: ScrollBar.AsNeeded; active: true
                                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#555555"; opacity: listSB.hovered ? 0.6 : 0.25 }
                            }

                            delegate: ItemDelegate {
                                width: folderList.width; height: 35
                                background: Rectangle { color: hovered ? "#1AFFFFFF" : "transparent"; radius: 4 }
                                contentItem: Text { text: "📁  " + modelData.name; color: "white"; verticalAlignment: Text.AlignVCenter }
                                onClicked: {
                                    while (pathStack.count > (index + 1)) { pathStack.remove(pathStack.count - 1); }
                                    pathStack.append({ "targetPath": String(modelData.path), "displayName": String(modelData.name) });
                                    scrollTimer.restart();
                                }
                            }
                            
                            // EMPTY STATE: If no subfolders found, show the Analyze button
                            Text {
                                anchors.centerIn: parent
                                text: "NO SUBFOLDERS FOUND"
                                color: "#444"
                                visible: folderList.count === 0
                            }
                        }
                    }
                }
            }
        }
    }

    // Shared Delegate for Drive Buttons (Simplified for readability)
    Component {
        id: driveBtnDelegate
        Button {
            width: 135; height: 50
            background: Rectangle { color: modelData.isCollection ? "#44D4AF37" : "#11FFFFFF"; border.color: "gold"; radius: 4 }
            contentItem: Text { text: modelData.label; color: "white"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: {
                pathStack.clear();
                pathStack.append({ "targetPath": String(modelData.path), "displayName": String(modelData.label) });
            }
        }
    }

    Timer { id: scrollTimer; interval: 50; onTriggered: mainFlick.contentX = Math.max(0, unfoldingRow.width - mainFlick.width) }
}