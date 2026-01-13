import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: freestyleRoot
    anchors.fill: parent
    color: "#121212"

    property string activeMode: "PANELS"
    ListModel { id: pathStack }

    Item {
        anchors.fill: parent

        Flickable {
            id: panelView
            anchors.fill: parent
            contentWidth: unfoldingRow.width
            clip: true
            visible: freestyleRoot.activeMode === "PANELS"
            Behavior on contentX { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            Row {
                id: unfoldingRow
                height: parent.height

                // PANE 0: DRIVE DOCK
                Rectangle {
                    id: driveDock
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

                        Column {
                            width: parent.width; spacing: 10; visible: pathStack.count === 0
                            Text { text: "LOCAL STORAGE"; color: "#EEEEEE"; font.pixelSize: 11; font.bold: true }
                            Flow { 
                                width: parent.width; spacing: 10
                                Repeater { 
                                    model: (driveManager) ? driveManager.get_grouped_drives().local : []
                                    delegate: driveBtnDelegate 
                                }
                            }
                        }
                        
                        Column {
                            width: parent.width; spacing: 10; visible: pathStack.count === 0
                            Text { text: "NETWORK COLLECTIONS"; color: "#EEEEEE"; font.pixelSize: 11; font.bold: true }
                            Flow { 
                                width: parent.width; spacing: 10
                                Repeater { 
                                    model: (driveManager) ? driveManager.get_grouped_drives().network : []
                                    delegate: driveBtnDelegate 
                                }
                            }
                        }
                    }
                }

                // DYNAMIC FOLDER PANELS
                Repeater {
                    model: pathStack
                    delegate: Rectangle {
                        id: pane
                        property int stackLevel: index // Store column level
                        property bool isActive: index === pathStack.count - 1
                        width: isActive ? 400 : 100
                        height: freestyleRoot.height
                        color: isActive ? "#1A1A1A" : "#141414"
                        border.color: "#33D4AF37"; border.width: 1
                        clip: true
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                        MouseArea {
                            anchors.fill: parent; enabled: !pane.isActive
                            onClicked: { 
                                while (pathStack.count > (pane.stackLevel + 1)) { 
                                    pathStack.remove(pathStack.count - 1); 
                                } 
                            }
                        }

                        Column {
                            anchors.fill: parent; anchors.margins: 15; spacing: 12
                            
                            Row {
                                width: parent.width; spacing: 10
                                Text { 
                                    text: "←"; color: "gold"; font.pixelSize: 18; visible: pane.isActive
                                    MouseArea { 
                                        anchors.fill: parent; 
                                        onClicked: pathStack.remove(pathStack.count - 1)
                                    }
                                }
                                Text { 
                                    text: displayName.toUpperCase(); color: "gold"; font.pixelSize: 13; font.bold: true
                                    elide: Text.ElideRight; width: parent.width - 30
                                    rotation: pane.isActive ? 0 : 90
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Flickable {
                                id: scrollArea
                                width: parent.width; height: parent.height - 120; clip: true
                                contentHeight: contentCol.height
                                visible: pane.isActive
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: contentCol
                                    width: parent.width - 12
                                    spacing: 4
                                    property var folderData: (driveManager && targetPath) ? driveManager.get_folder_contents(targetPath) : {"files":[], "folders":[]}

                                    Repeater {
                                        model: contentCol.folderData.files || []
                                        delegate: ItemDelegate {
                                            width: contentCol.width; height: 30
                                            contentItem: Text { 
                                                text: (modelData.isVideo ? "🎬  " : "📄  ") + modelData.name
                                                color: modelData.isVideo ? "gold" : "#DDDDDD" 
                                                font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Rectangle { 
                                        width: parent.width; height: 1; color: "#44FFFFFF"
                                        visible: (contentCol.folderData.files || []).length > 0 && (contentCol.folderData.folders || []).length > 0
                                    }

                                    Repeater {
                                        model: contentCol.folderData.folders || []
                                        delegate: ItemDelegate {
                                            width: contentCol.width; height: 35
                                            background: Rectangle { color: hovered ? "#22FFFFFF" : "transparent"; radius: 4 }
                                            contentItem: Text { 
                                                text: "📁  " + modelData.name; color: "white"
                                                font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight 
                                            }
                                            onClicked: {
                                                // FIX: use stackLevel to avoid jumping
                                                while (pathStack.count > (pane.stackLevel + 1)) { 
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

                            Button {
                                id: displayBtn
                                width: parent.width - 10; height: 40
                                visible: pane.isActive && (contentCol.folderData.files || []).some(f => f.isVideo)
                                anchors.horizontalCenter: parent.horizontalCenter
                                background: Rectangle { 
                                    color: displayBtn.hovered ? "#33D4AF37" : "transparent"
                                    border.color: "gold"; radius: 4 
                                }
                                contentItem: Text { 
                                    text: "DISPLAY MEDIA"; color: "gold"; font.bold: true
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                                }
                                onClicked: { freestyleRoot.activeMode = "CAROUSEL"; }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            id: triageLoader
            anchors.fill: parent
            visible: freestyleRoot.activeMode === "CAROUSEL"
            source: visible ? "FreestyleView.qml" : ""
            onLoaded: {
                if (item && pathStack.count > 0) {
                    item.targetPath = pathStack.get(pathStack.count - 1).targetPath
                }
            }
        }
    }

    Component {
        id: driveBtnDelegate
        Button {
            id: dBtn
            width: 135; height: 50
            background: Rectangle {
                color: modelData.isCollection ? "#44D4AF37" : (dBtn.hovered ? "#22FFFFFF" : "#11FFFFFF")
                border.color: modelData.isCollection ? "gold" : "#44FFFFFF"; radius: 4
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

    Timer { id: scrollTimer; interval: 50; onTriggered: panelView.contentX = Math.max(0, unfoldingRow.width - panelView.width) }
}