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
                    width: pathStack.count > 0 ? 80 : 320
                    height: parent.height; color: "#161616"; border.color: "#33D4AF37"; border.width: 1
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                    // Click to clear stack (Go Home)
                    MouseArea {
                        anchors.fill: parent; enabled: pathStack.count > 0
                        z: 50
                        onClicked: pathStack.clear()
                    }

                    // Vertical "DRIVES" Label when collapsed
                    Text {
                        text: "DRIVES"
                        color: "gold"; font.bold: true; font.pixelSize: 18
                        visible: pathStack.count > 0
                        anchors.centerIn: parent
                        rotation: -90
                    }

                    Column {
                        anchors.fill: parent; anchors.margins: 20; spacing: 30
                        visible: pathStack.count === 0
                        opacity: pathStack.count > 0 ? 0.0 : 1.0

                        Text { 
                            text: "FREESTYLE"; color: "gold"; font.pixelSize: 22; font.bold: true; 
                        }
                        
                        Column {
                            width: parent.width; spacing: 10
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
                            width: parent.width; spacing: 10
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
                        property int stackLevel: index 
                        property bool isActive: index === pathStack.count - 1
                        width: isActive ? 400 : 80 // Contracted panels are thinner for more space
                        height: parent.height
                        color: isActive ? "#1A1A1A" : "#141414"
                        border.color: "#33D4AF37"; border.width: 1
                        clip: true
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                        property var folderData: (driveManager && targetPath) ? driveManager.get_folder_contents(targetPath) : {"files":[], "folders":[]}
                        property bool hasVideos: (folderData.files || []).some(f => f.isVideo)

                        // 1. VERTICAL TITLE (Only visible when NOT active)
                        Text {
                            id: verticalText
                            text: displayName.toUpperCase()
                            color: "gold"; font.pixelSize: 14; font.bold: true
                            visible: !pane.isActive
                            anchors.centerIn: parent
                            rotation: -90
                            width: parent.height
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // 2. ACTIVE PANEL CONTENT (Only visible when ACTIVE)
                        Item {
                            anchors.fill: parent
                            visible: pane.isActive

                            // Header
                            Rectangle {
                                id: paneHeader
                                width: parent.width; height: 50; color: "transparent"
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: 15; spacing: 10
                                    Text { 
                                        text: "←"; color: "gold"; font.pixelSize: 18
                                        anchors.verticalCenter: parent.verticalCenter
                                        MouseArea { anchors.fill: parent; onClicked: pathStack.remove(pathStack.count - 1) }
                                    }
                                    Text { 
                                        text: displayName.toUpperCase(); color: "gold"; font.pixelSize: 13; font.bold: true
                                        elide: Text.ElideRight; width: parent.width - 60
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // List Area
                            Flickable {
                                id: scrollArea
                                anchors.top: paneHeader.bottom; anchors.bottom: displayBtn.visible ? displayBtn.top : parent.bottom
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 15; anchors.rightMargin: 15; anchors.bottomMargin: 10
                                contentHeight: contentCol.height
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: contentCol
                                    width: parent.width - 10
                                    spacing: 4

                                    Repeater {
                                        model: pane.folderData.files || []
                                        delegate: ItemDelegate {
                                            width: contentCol.width; height: 30
                                            contentItem: Text { 
                                                text: (modelData.isVideo ? "🎬  " : "📄  ") + modelData.name
                                                color: modelData.isVideo ? "gold" : "#CCCCCC"; font.pixelSize: 12
                                                verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Rectangle { 
                                        width: parent.width; height: 1; color: "#22FFFFFF"
                                        visible: (pane.folderData.files || []).length > 0 && (pane.folderData.folders || []).length > 0
                                    }

                                    Repeater {
                                        model: pane.folderData.folders || []
                                        delegate: ItemDelegate {
                                            width: contentCol.width; height: 35
                                            background: Rectangle { color: hovered ? "#11FFFFFF" : "transparent"; radius: 4 }
                                            contentItem: Text { 
                                                text: "📁  " + modelData.name; color: "white"; font.pixelSize: 12
                                                verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight 
                                            }
                                            onClicked: {
                                                while (pathStack.count > (pane.stackLevel + 1)) { pathStack.remove(pathStack.count - 1); }
                                                pathStack.append({ "targetPath": String(modelData.path), "displayName": String(modelData.name) });
                                                scrollTimer.restart();
                                            }
                                        }
                                    }
                                }

                                ScrollBar.vertical: ScrollBar {
                                    id: vBar
                                    active: hovered || scrollArea.moving
                                    policy: scrollArea.contentHeight > scrollArea.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                                    contentItem: Rectangle { implicitWidth: 6; radius: 3; color: "gold"; opacity: vBar.active ? 0.8 : 0.3 }
                                }
                            }

                            // Display Button
                            Button {
                                id: displayBtn
                                width: parent.width - 30; height: 40
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 15
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: pane.hasVideos
                                background: Rectangle { color: displayBtn.hovered ? "#33D4AF37" : "transparent"; border.color: "gold"; radius: 4 }
                                contentItem: Text { text: "DISPLAY MEDIA"; color: "gold"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { freestyleRoot.activeMode = "CAROUSEL"; }
                            }
                        }

                        // Click logic for contracted panels (Returns to this level)
                        MouseArea {
                            anchors.fill: parent
                            enabled: !pane.isActive
                            z: 100 
                            onClicked: { 
                                while (pathStack.count > (pane.stackLevel + 1)) { pathStack.remove(pathStack.count - 1); } 
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
                Text { text: modelData.label; color: "white"; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; width: 135; elide: Text.ElideRight }
                Text { text: modelData.letter; color: "gold"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; width: 135 }
            }
            onClicked: {
                pathStack.clear();
                pathStack.append({ "targetPath": String(modelData.path), "displayName": String(modelData.label) });
            }
        }
    }

    Timer { id: scrollTimer; interval: 50; onTriggered: panelView.contentX = Math.max(0, unfoldingRow.width - panelView.width) }
}