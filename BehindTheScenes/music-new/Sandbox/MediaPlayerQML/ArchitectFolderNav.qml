import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: folderNavRoot
    width: parent ? parent.width : 400
    height: parent ? parent.height : 550
    
    // Reference to the ArchitectPanel frame
    property Item parentPanel: null
    property string currentRelativePath: "" 


    //property alias folderNameField: currentRelativePath
    property string folderNameField: currentRelativePath // ✅ Just keep them in sync


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
            width: parent.width; height: 40; color: "#22FFFFFF"; radius: 6
            Row {
                anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                
                Button { 
                    id: homeBtn; width: 35; height: 30; anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text {
                        text: iconFont.status === FontLoader.Ready ? "\uf015" : "H"
                        font.family: iconFont.name; font.pixelSize: 16
                        color: homeBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: homeBtn.pressed ? "#44FFFFFF" : "transparent" }
                    onClicked: { 
                        currentRelativePath = ""; 
                        if (parentPanel) parentPanel.stagingResults = [""];
                        architectController.get_sub_folders(""); 
                    }
                }

                Button {
                    id: internalBackBtn; width: 35; height: 30; anchors.verticalCenter: parent.verticalCenter
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
                        if (parentPanel) parentPanel.stagingResults = [currentRelativePath];
                        architectController.get_sub_folders(currentRelativePath);
                    }
                }

                Text {
                    text: currentRelativePath === "" ? "Root" : currentRelativePath
                    color: "gold"; font.pixelSize: 12; font.bold: true; elide: Text.ElideMiddle 
                    width: parent.width - 110; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- FOLDER LIST ---
        ListView {
            id: folderListView
            width: parent.width; height: parent.height - breadcrumbBar.height - 20
            clip: true; model: folderListModel; spacing: 4
            ScrollBar.vertical: ScrollBar { active: true; width: 8; policy: ScrollBar.AlwaysOn }
            
            delegate: ItemDelegate {
                width: folderListView.width - 12; height: 38
                contentItem: Text {
                    text: "📁 " + model.modelData
                    color: "white"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    // Visual feedback: Subtle cyan border when hovering
                    color: parent.hovered ? "#3300F2FF" : "#11FFFFFF"
                    radius: 4; border.color: parent.hovered ? "#00F2FF" : "transparent"; border.width: 1
                }
                onClicked: {
                    var newPath = currentRelativePath === "" ? model.modelData : currentRelativePath + "/" + model.modelData;
                    currentRelativePath = newPath;
                    
                    // Push choice to ArchitectPanel immediately
                    if (parentPanel) parentPanel.stagingResults = [newPath];
                    
                    //architectController.get_sub_folders(currentRelativePath);
                    architectController.load_movies_for_path(currentRelativePath)

                }
            }
        }
    }

    ListModel { id: folderListModel }

    // --- BRIDGE TO PYTHON ---
    Connections {
        target: fileSystem          // ✅ CHANGED from architectController
        ignoreUnknownSignals: true
        
        function onFoldersChanged() {
        // ✅ CHANGED from onFoldersUpdated
            console.log("📁 FileSystem → foldersChanged")
            //console.log("📁 Folders:", fileSystem.folders)

            folderListModel.clear()
            for (let f of fileSystem.folders) {
                folderListModel.append({ "modelData": f.folderName })
            }

            if (parentPanel) parentPanel.stagingResults = [currentRelativePath];
        }

        function onResultsCounted(panelIndex, panelCount) {
            // Signal check: -1 is global, otherwise match this panel's index
            if (parentPanel && (panelIndex === parentPanel.panelIndex || panelIndex === -1)) {
                
                // 1. UPDATE GOLDEN HEADER (Step 3 Verified)
                parentPanel.hitCount = panelCount;

                // 2. CONSOLE EVIDENCE
                console.log("-----------------------------------------");
                console.log("📁 FOLDER NAV SYNC | Panel: " + panelRoot.parentPanel.panelIndex);
                console.log("Target Path: " + (currentRelativePath === "" ? "Root" : currentRelativePath));
                console.log("Hit Count: " + panelCount);
                console.log("-----------------------------------------");
            }
        }
    }

    Component.onCompleted: {
        if (typeof architectController !== "undefined") {
            // Initial path registration
            if (parentPanel) parentPanel.stagingResults = [currentRelativePath];
            architectController.get_sub_folders(currentRelativePath);
        }
    }
}