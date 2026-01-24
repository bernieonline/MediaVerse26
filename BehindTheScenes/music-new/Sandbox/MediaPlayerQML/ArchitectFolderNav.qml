import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: folderNavRoot
    width: parent ? parent.width : 400
    height: parent ? parent.height : 550
    
    property string currentRelativePath: "" 

    Column {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 10

        // --- BREADCRUMB STRIP ---
        Rectangle {
            id: breadcrumbBar
            width: parent.width
            height: 40
            color: "#22FFFFFF" 
            radius: 6
            
            Row {
                anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                
                // HOME BUTTON
                Button { 
                    id: homeBtn
                    text: "🏠"; width: 35; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: { currentRelativePath = ""; architectController.get_sub_folders(""); }
                }

                // BACK BUTTON (The New Addition)
                Button {
                    id: backBtn
                    text: "⬅"; width: 35; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    // Only show if we aren't at Root
                    visible: currentRelativePath !== "" 
                    
                    onClicked: {
                        var parts = currentRelativePath.split('/');
                        parts.pop(); // Remove the last folder in the path
                        var newPath = parts.join('/');
                        currentRelativePath = newPath;
                        architectController.get_sub_folders(currentRelativePath);
                    }
                }

                Text {
                    text: currentRelativePath === "" ? "Root" : currentRelativePath
                    color: "gold"; font.pixelSize: 12; font.bold: true; elide: Text.ElideMiddle 
                    // Dynamic width adjustment based on buttons
                    width: parent.width - (backBtn.visible ? 100 : 60)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- FOLDER LIST ---
        ListView {
            id: folderListView
            width: parent.width
            height: parent.height - breadcrumbBar.height - selectBtn.height - 30
            clip: true
            model: folderListModel
            spacing: 4
            
            // RESTORED SCROLLBAR
            ScrollBar.vertical: ScrollBar {
                id: vbar
                active: true
                width: 8
                policy: ScrollBar.AlwaysOn
                anchors.right: parent.right
            }

            delegate: ItemDelegate {
                width: folderListView.width - 12 // Account for scrollbar space
                height: 38
                contentItem: Text {
                    text: "📁 " + model.modelData
                    color: "white"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? "#3300F2FF" : "#11FFFFFF"
                    radius: 4
                }
                onClicked: {
                    var newPath = currentRelativePath === "" ? model.modelData : currentRelativePath + "/" + model.modelData;
                    currentRelativePath = newPath;
                    architectController.get_sub_folders(currentRelativePath);
                }
            }
        }

        // --- ACCEPT BUTTON ---
        Button {
            id: selectBtn
            width: parent.width
            height: 45
            contentItem: Text {
                text: "USE: " + (currentRelativePath === "" ? "Root" : currentRelativePath.split('/').pop())
                color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { 
                color: "#00F2FF"; radius: 6 
                border.color: selectBtn.hovered ? "white" : "transparent"
            }

            onClicked: {
                console.log("✅ Selecting Folder: " + currentRelativePath)
                architectRoot.updateRule(panelRoot.panelIndex, "folder", currentRelativePath);
            }
        }
    }

    ListModel { id: folderListModel }

    Connections {
        target: architectController
        function onFoldersUpdated(folders) {
            folderListModel.clear();
            for (var i = 0; i < folders.length; i++) {
                folderListModel.append({ "modelData": folders[i] });
            }
        }
    }

    Component.onCompleted: {
        if (architectController) architectController.get_sub_folders(currentRelativePath);
    }
}