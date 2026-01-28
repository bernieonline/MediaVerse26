import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: folderNavRoot
    width: parent ? parent.width : 400
    height: parent ? parent.height : 550
    
    property string currentRelativePath: "" 

    // --- ICON LOADER ---
    FontLoader { id: folderIconFont; source: paths.font_path || "" }

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
                
                // 1. HOME BUTTON
                Button { 
                    id: homeBtn
                    width: 35; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    
                    contentItem: Text {
                        text: folderIconFont.status === FontLoader.Ready ? "\uf015" : "H"
                        font.family: folderIconFont.name
                        font.pixelSize: 16
                        color: homeBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: homeBtn.pressed ? "#44FFFFFF" : "transparent" }
                    onClicked: { currentRelativePath = ""; architectController.get_sub_folders(""); }
                }

                // 2. BACK BUTTON (Iconized)
                Button {
                    id: internalBackBtn
                    width: 35; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: currentRelativePath !== "" 
                    opacity: enabled ? 1.0 : 0.3 
                    
                    contentItem: Text {
                        text: folderIconFont.status === FontLoader.Ready ? "\uf060" : "←"
                        font.family: folderIconFont.name
                        font.pixelSize: 16
                        color: internalBackBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: internalBackBtn.pressed ? "#44FFFFFF" : "transparent" }
                    
                    onClicked: {
                        var parts = currentRelativePath.split('/');
                        parts.pop(); 
                        var newPath = parts.join('/');
                        currentRelativePath = newPath;
                        architectController.get_sub_folders(currentRelativePath);
                    }
                }

                Text {
                    text: currentRelativePath === "" ? "Root" : currentRelativePath
                    color: "gold"; font.pixelSize: 12; font.bold: true; elide: Text.ElideMiddle 
                    width: parent.width - 110 
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- FOLDER LIST ---
        ListView {
            id: folderListView
            width: parent.width
            // Adjusted height to account for the new footerBar Row
            height: parent.height - breadcrumbBar.height - footerBar.height - 30
            clip: true
            model: folderListModel
            spacing: 4

            ScrollBar.vertical: ScrollBar {
                id: vbar; active: true; width: 8; policy: ScrollBar.AlwaysOn
            }
            
            delegate: ItemDelegate {
                width: folderListView.width - 12
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

        // --- SELECTION & LOGIC TOOLBAR ---
        Row {
            id: footerBar
            width: parent.width
            height: 45
            spacing: 8

            // 1. FILTER TOGGLE
            CheckBox {
                id: filterToggle
                width: 85
                height: parent.height
                
                // Logic: Disable if it's the first panel
                enabled: panelRoot.panelIndex > 0 
                opacity: enabled ? 1.0 : 0.4
                
                indicator: Rectangle {
                    implicitWidth: 18
                    implicitHeight: 18
                    x: filterToggle.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 3
                    border.color: filterToggle.enabled ? "#00F2FF" : "gray"
                    color: "transparent"
                    Rectangle {
                        width: 10; height: 10
                        x: 4; y: 4
                        radius: 2
                        color: "#00F2FF"
                        visible: filterToggle.checked
                    }
                }

                contentItem: Text {
                    text: "Filter"
                    font.pixelSize: 12
                    color: filterToggle.enabled ? "white" : "gray"
                    leftPadding: filterToggle.indicator.width + 6
                    verticalAlignment: Text.AlignVCenter
                }

                checked: false // Defaults to unchecked (OR logic)

                ToolTip.visible: hovered
                ToolTip.delay: 400
                ToolTip.text: enabled ? "Narrow down results from previous panels" : "First panel sets the source"
            }

            // 2. ACCEPT BUTTON
            Button {
                id: selectBtn
                width: parent.width - filterToggle.width - parent.spacing
                height: parent.height
                
                contentItem: Text {
                    text: "USE: " + (currentRelativePath === "" ? "Root" : currentRelativePath.split('/').pop())
                    color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { 
                    color: "#00F2FF"; radius: 6 
                    border.color: selectBtn.hovered ? "white" : "transparent"
                }

                onClicked: {
                    console.log("✅ Selecting Folder: " + currentRelativePath + " | Filter: " + filterToggle.checked)
                    // Passing the folder path and the filter state
                    architectRoot.updateRule(panelRoot.panelIndex, "folder", currentRelativePath, filterToggle.checked);
                }
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