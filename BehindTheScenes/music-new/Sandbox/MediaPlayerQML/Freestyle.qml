import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: freestyleRoot
    anchors.fill: parent
    color: "#121212"

    ListModel { id: pathStack }

    // --- GLOBAL RESET BUTTON ---
    Button {
        id: resetBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        z: 100
        visible: pathStack.count > 0
        text: "RESET TO DRIVES"
        
        background: Rectangle { 
            color: resetBtn.hovered ? "#33D4AF37" : "transparent"
            border.color: "gold"
            radius: 4 
        }
        contentItem: Text { 
            text: parent.text; color: "gold"; font.bold: true; font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        onClicked: pathStack.clear()
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
                width: pathStack.count > 0 ? 100 : 320
                height: parent.height; color: "#161616"; border.color: "#33D4AF37"; border.width: 1
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                MouseArea {
                    anchors.fill: parent; enabled: pathStack.count > 0
                    onClicked: pathStack.clear()
                }

                Column {
                    anchors.fill: parent; anchors.margins: 20; spacing: 30
                    opacity: pathStack.count > 0 ? 0.4 : 1.0

                    Text { 
                        text: "FREESTYLE"; color: "gold"; font.pixelSize: 22; font.bold: true; 
                        visible: pathStack.count === 0 
                    }
                    
                    Text { 
                        text: "DRIVES"; color: "gold"; font.bold: true; font.pixelSize: 18
                        visible: pathStack.count > 0; anchors.horizontalCenter: parent.horizontalCenter
                        rotation: 90
                    }

                    // Local/Network Groupings
                    Column {
                        width: parent.width; spacing: 10; visible: pathStack.count === 0
                        Text { text: "LOCAL STORAGE"; color: "#BBBBBB"; font.pixelSize: 11; font.bold: true }
                        Flow { width: parent.width; spacing: 10
                            Repeater { model: driveManager.get_grouped_drives().local; delegate: driveBtnDelegate }
                        }
                    }
                    
                    Column {
                        width: parent.width; spacing: 10; visible: pathStack.count === 0
                        Text { text: "NETWORK COLLECTIONS"; color: "#BBBBBB"; font.pixelSize: 11; font.bold: true }
                        Flow { width: parent.width; spacing: 10
                            Repeater { model: driveManager.get_grouped_drives().network; delegate: driveBtnDelegate }
                        }
                    }
                }
            }

            // --- DYNAMIC UNFOLDING FOLDERS ---
            Repeater {
                model: pathStack
                delegate: Rectangle {
                    id: pane
                    property bool isActive: index === pathStack.count - 1
                    width: isActive ? 400 : 100
                    height: freestyleRoot.height
                    color: isActive ? "#1A1A1A" : "#141414"
                    border.color: "#33D4AF37"; border.width: 1
                    clip: true
                    
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                    // Navigation Back-click
                    MouseArea {
                        anchors.fill: parent; enabled: !pane.isActive
                        onClicked: { while (pathStack.count > (index + 1)) { pathStack.remove(pathStack.count - 1); } }
                    }

                    Column {
                        anchors.fill: parent; anchors.margins: 15; spacing: 12
                        
                        // Header
                        Row {
                            width: parent.width; spacing: 10
                            Text { 
                                text: "←"; color: "gold"; font.pixelSize: 18; visible: pane.isActive
                                MouseArea { anchors.fill: parent; onClicked: pathStack.remove(pathStack.count - 1) }
                            }
                            Text { 
                                text: displayName.toUpperCase(); color: "gold"; font.pixelSize: 13; font.bold: true
                                elide: Text.ElideRight; width: parent.width - 30
                                rotation: pane.isActive ? 0 : 90
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Content List
                        Flickable {
                            id: scrollArea
                            width: parent.width; height: parent.height - 120; clip: true
                            contentHeight: contentCol.height
                            visible: pane.isActive

                            ScrollBar.vertical: ScrollBar { 
                                id: listSB
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#555555"; opacity: listSB.hovered ? 0.6 : 0.25 }
                            }

                            Column {
                                id: contentCol
                                width: parent.width; spacing: 4
                                
                                // Fetch data for this specific panel
                                property var folderData: driveManager.get_folder_contents(targetPath)

                                // 1. FILES (Top)
                                Repeater {
                                    model: contentCol.folderData.files
                                    delegate: ItemDelegate {
                                        width: contentCol.width; height: 30
                                        contentItem: Text { 
                                            text: (modelData.isVideo ? "🎬  " : "📄  ") + modelData.name
                                            color: modelData.isVideo ? "gold" : "#888"
                                            font.pixelSize: 11; verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                        onDoubleClicked: console.log("Future action: Open " + modelData.path)
                                    }
                                }

                                // Separator
                                Rectangle { 
                                    width: parent.width; height: 1; color: "#22FFFFFF"
                                    visible: contentCol.folderData.files.length > 0 && contentCol.folderData.folders.length > 0
                                }

                                // 2. FOLDERS (Bottom)
                                Repeater {
                                    model: contentCol.folderData.folders
                                    delegate: ItemDelegate {
                                        width: contentCol.width; height: 35
                                        background: Rectangle { color: hovered ? "#11FFFFFF" : "transparent"; radius: 4 }
                                        contentItem: Text { 
                                            text: "📁  " + modelData.name; color: "white"
                                            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight 
                                        }
                                        onClicked: {
                                            while (pathStack.count > (index + 1)) { pathStack.remove(pathStack.count - 1); }
                                            pathStack.append({ "targetPath": String(modelData.path), "displayName": String(modelData.name) });
                                            scrollTimer.restart();
                                        }
                                    }
                                }
                            }
                        }

                        // --- DISPLAY MEDIA BUTTON ---
                        Button {
                            id: displayBtn
                            width: parent.width - 10; height: 40
                            visible: pane.isActive && contentCol.folderData.files.some(f => f.isVideo)
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            background: Rectangle { 
                                color: displayBtn.hovered ? "#22D4AF37" : "transparent"
                                border.color: "gold"; radius: 4 
                            }
                            contentItem: Text { 
                                text: "DISPLAY MEDIA"; color: "gold"; font.bold: true
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                            }
                            onClicked: console.log("Tomorrow: Run Matching Logic for " + targetPath)
                        }
                    }
                }
            }
        }
    }

    // Shared Delegate for Drive Buttons
    Component {
        id: driveBtnDelegate
        Button {
            id: dBtn
            width: 135; height: 50
            background: Rectangle {
                color: modelData.isCollection ? "#44D4AF37" : (dBtn.hovered ? "#22FFFFFF" : "#11FFFFFF")
                border.color: modelData.isCollection ? "gold" : "#33FFFFFF"; radius: 4
            }
            contentItem: Column {
                anchors.centerIn: parent
                Text { text: modelData.label; color: "white"; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; width: 125; elide: Text.ElideRight }
                Text { text: modelData.letter; color: "gold"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; width: 125 }
            }
            onClicked: {
                pathStack.clear();
                pathStack.append({ "targetPath": String(modelData.path), "displayName": String(modelData.label) });
            }
        }
    }

    Timer { id: scrollTimer; interval: 50; onTriggered: mainFlick.contentX = Math.max(0, unfoldingRow.width - mainFlick.width) }
}