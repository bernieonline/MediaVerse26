import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: folderNavRoot
    width: parent ? parent.width : 400
    height: parent ? parent.height : 550
    
    // Reference to the ArchitectPanel frame
    property Item parentPanel: null
    property string currentRelativePath: "" 

    // FIXED: Protocol-aware FontLoader to handle Windows paths
    // --- ICON LOADER ---
    FontLoader { 
        id: iconFont
        source: {
            var p = "";
            if (typeof paths !== 'undefined' && paths.font_path) {
                p = paths.font_path;
            } else if (typeof _paths !== 'undefined' && _paths.fonts) {
                p = _paths.fonts;
            }
            
            if (p === "") return "";
            
            if (p.indexOf(":") !== -1 && p.indexOf("file:///") === -1) {
                return "file:///" + p.replace(/\\/g, "/");
            }
            return p;
        }
    }

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
                    width: 35; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text {
                        text: iconFont.status === FontLoader.Ready ? "\uf015" : "H"
                        font.family: iconFont.name; font.pixelSize: 16
                        color: homeBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: homeBtn.pressed ? "#44FFFFFF" : "transparent" }
                    onClicked: { 
                        currentRelativePath = ""; 
                        // Update the holding tank to root immediately
                        if (parentPanel) parentPanel.currentResults = [""];
                        architectController.get_sub_folders(""); 
                    }
                }

                // BACK BUTTON
                Button {
                    id: internalBackBtn
                    width: 35; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: currentRelativePath !== "" 
                    opacity: enabled ? 1.0 : 0.3 
                    contentItem: Text {
                        text: iconFont.status === FontLoader.Ready ? "\uf060" : "←"
                        font.family: iconFont.name; font.pixelSize: 16
                        color: internalBackBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: internalBackBtn.pressed ? "#44FFFFFF" : "transparent" }
                    onClicked: {
                        var parts = currentRelativePath.split('/');
                        parts.pop(); 
                        currentRelativePath = parts.join('/');
                        // Update holding tank to parent folder
                        if (parentPanel) parentPanel.currentResults = [currentRelativePath];
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
            height: parent.height - breadcrumbBar.height - 20
            clip: true
            model: folderListModel
            spacing: 4

            ScrollBar.vertical: ScrollBar { active: true; width: 8; policy: ScrollBar.AlwaysOn }
            
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
                    
                    // CRITICAL: Update the holding tank so Python sees the selection
                    if (parentPanel) parentPanel.currentResults = [newPath];
                    
                    architectController.get_sub_folders(currentRelativePath);
                }
            }
        }
    }

    ListModel { id: folderListModel }

    Connections {
        target: architectController
        ignoreUnknownSignals: true
        
        function onFoldersUpdated(folders) {
            folderListModel.clear();
            for (var i = 0; i < folders.length; i++) {
                folderListModel.append({ "modelData": folders[i] });
            }
            // Ensure the holding tank matches our current navigation state
            if (parentPanel) parentPanel.currentResults = [currentRelativePath];
        }

        function onResultsCounted(panelIndex, panelCount) {
            // panelIndex -1 comes from get_sub_folders logic for 'current view'
            if (parentPanel && (panelIndex === parentPanel.panelIndex || panelIndex === -1)) {
                parentPanel.hitCount = panelCount;
            }
        }
    }

    Component.onCompleted: {
        if (typeof architectController !== "undefined") {
            // Initial load
            if (parentPanel) parentPanel.currentResults = [currentRelativePath];
            architectController.get_sub_folders(currentRelativePath);
        }
    }
}