import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: folderNavRoot
    width: parent ? parent.width : 400
    height: parent ? parent.height : 550
    
    // Reference to the ArchitectPanel frame
    property Item parentPanel: null
    property string currentRelativePath: "" 
    property string selectedFolder: ""
    signal folderSelected(string folderName, var panelList)

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
                        if (typeof architectController !== "undefined") {
                            architectController.get_sub_folders("");
                        }

                        // Emit selection for Root
                        //var list = [];   // placeholder until movie list arrives
                        //closefolderSelected("", list);
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
                        if (typeof architectController !== "undefined") {
                            architectController.get_sub_folders(currentRelativePath);
                        }
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
                    color: parent.hovered ? "#3300F2FF" : "#11FFFFFF"
                    radius: 4; border.color: parent.hovered ? "#00F2FF" : "transparent"; border.width: 1
                }
                onClicked: {
                    var newPath = currentRelativePath === "" ? model.modelData : currentRelativePath + "/" + model.modelData;
                    currentRelativePath = newPath;

                    selectedFolder = newPath
                    
                    if (parentPanel) parentPanel.stagingResults = [newPath];
                    
                    if (typeof architectController !== "undefined" && parentPanel) {
                        architectController.load_movies_for_path(currentRelativePath, parentPanel.panelIndex);
                        //architectController.list_folder_content_v2(currentRelativePath)
                    }

                    // Emit selection for this folder
                    var list = [];   // placeholder until movie list arrives
                    folderSelected(newPath, list);
                }
            }
        }
    }

    ListModel { id: folderListModel }

    // --- BRIDGE TO PYTHON ---
    Connections {
        target: fileSystem
        ignoreUnknownSignals: true
        
        function onFoldersChanged() {
            console.log("📁 FileSystem → foldersChanged")

            folderListModel.clear()
            for (let f of fileSystem.folders) {
                folderListModel.append({ "modelData": f.folderName })
            }

            if (parentPanel) parentPanel.stagingResults = [currentRelativePath];
        }

    }

    Component.onCompleted: {
        if (typeof architectController !== "undefined") {
            if (parentPanel) parentPanel.stagingResults = [currentRelativePath];
            architectController.get_sub_folders(currentRelativePath);
        }
    }
    // ------------------------------------------------------------
    // Debugging toggle
    // ------------------------------------------------------------
    property bool debugEnabled: true

    // ------------------------------------------------------------
    // Debug helper
    // ------------------------------------------------------------
    function debugLog(message, object) {
        if (!debugEnabled)
            return

        if (object !== undefined) {
            console.log("[FolderNav] " + message + ":\n" +
                        JSON.stringify(object, null, 2))
        } else {
            console.log("[FolderNav] " + message)
        }
    }
    Connections {
        target: fileSystem
        ignoreUnknownSignals: true

        function onImages_listed(mappedResults) {
            // Update the panel’s staging results
            if (parentPanel) {
                parentPanel.stagingResults = mappedResults
            }

            // Emit the real list to ArchitectPanel
            folderSelected(selectedFolder, mappedResults)
        }
    }
    Connections {
        target: architectController
        ignoreUnknownSignals: true

        function onImages_listed(mappedResults) {
            console.log("📥 FolderNav received movie list:", mappedResults.length)

            // Store results in the panel
            if (parentPanel) parentPanel.stagingResults = mappedResults

            // Emit the selection with the real list
            folderSelected(currentRelativePath, mappedResults)
        }
    }

    // ------------------------------------------------------------
    // Build JSON snippet for Folder mode
    // Called by HUD when user clicks Finish or Commit
    // ------------------------------------------------------------
    function buildRuleSnippet(panelIndex, gate, checked) {

        let snippet = {
            panelIndex: panelIndex,
            mode: "Folder",
            data: {
                folder: selectedFolder
            },
            gate: gate
        }

        // Only panels 1–3 include checked
        if (panelIndex > 0) {
            snippet.checked = checked
        }

        debugLog("Generated Folder JSON snippet", snippet)

        return snippet
    }
}