import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: searchNavRoot
    anchors.fill: parent
    color: "transparent"

    // --- BRIDGING TO NEW HUD ---
    property Item parentPanel: null
    property int panelIndex: (parentPanel !== null) ? parentPanel.panelIndex : 0

    // Safe Font Loader for the Search Icon
    FontLoader { 
        id: searchIconFont
        source: {
            var p = (typeof _paths !== 'undefined' && _paths.fonts) ? _paths.fonts.toString() : "";
            if (p === "") return "";
            return (p.indexOf("file:///") === -1) ? "file:///" + p.replace(/\\/g, "/") : p;
        }
    }

    ListModel { id: selectedModel }

    // --- INTERNAL LOGIC (PRESERVED) ---
    function syncToPython() {
        var paths = [];
        for(var i=0; i < selectedModel.count; i++) {
            paths.push(selectedModel.get(i).filePath);
        }
        
        var finalValue = paths.join("|");
        var count = selectedModel.count;

        // 1. Local Frame Update
        if (parentPanel) {
            parentPanel.hitCount = count;
            parentPanel.currentResults = count > 0 ? ["search_files = " + finalValue] : [];
        }

        // 2. Engine Update
        if (typeof architectController !== "undefined") {
            // IF count is 0, we explicitly tell Python there are 0 matches
            if (count === 0) {
                architectController.resultsCounted.emit(panelIndex, 0);
            } else {
                var ruleObj = [{
                    "panelIndex": panelIndex,
                    "category": "search_files",
                    "value": finalValue
                }];
                architectController.update_live_preview(JSON.stringify(ruleObj));
            }
        }
    }

    function addMovieToBucket(title, path) {
        if (!path) return;
        for(var i=0; i<selectedModel.count; i++) {
            if(selectedModel.get(i).filePath === path) return;
        }
        selectedModel.append({"title": title, "filePath": path});
        syncToPython();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Row {
            spacing: 8
            Text { 
                text: searchIconFont.status === FontLoader.Ready ? "\uf002" : "🔍"
                font.family: searchIconFont.name; color: "#00F2FF"; font.pixelSize: 14
            }
            Text { 
                text: "FILE SEARCH MODE"
                color: "#00F2FF"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 1. SEARCH INPUT
        TextField {
            id: searchInput
            width: parent.width; height: 40
            placeholderText: "Type to find movies..."
            color: "white"; font.pixelSize: 13
            background: Rectangle { color: "#1AFFFFFF"; radius: 4; border.color: "#33FFFFFF" }
            
            onTextChanged: {
                // Ensure architectController is globally accessible
                if (typeof architectController !== "undefined") {
                    architectController.search_library(text);
                }
            }
        }

        // 2. SEARCH RESULTS
        ListView {
            id: resultsView
            width: parent.width
            height: (searchInput.text.length > 0 && count > 0) ? Math.min(contentHeight, 150) : 0
            clip: true
            // Binds to your existing Python Property
            model: (typeof architectController !== "undefined") ? architectController.searchResultsModel : []
            
            delegate: ItemDelegate {
                width: resultsView.width; height: 32
                contentItem: Text {
                    text: "➕ " + (modelData.title || modelData.filename || "Unknown")
                    color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: hovered ? "#2200F2FF" : "#05FFFFFF"; radius: 4 }
                
                onClicked: {
                    var finalPath = modelData.filename || modelData.path || modelData.filePath;
                    var finalTitle = modelData.title || (finalPath ? finalPath.split(/[\\/]/).pop() : "Unknown");
                    
                    addMovieToBucket(finalTitle, finalPath);
                    searchInput.text = ""; 
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#33FFFFFF"; visible: selectedModel.count > 0 }

        // 3. SELECTED STACK
        Text { 
            text: "SELECTED STACK: " + selectedModel.count
            color: "gold"; font.pixelSize: 10; font.bold: true; visible: selectedModel.count > 0
        }

        ListView {
            id: bucketView
            width: parent.width
            height: parent.height - (resultsView.height + 140)
            model: selectedModel
            spacing: 5
            clip: true

            delegate: Rectangle {
                width: bucketView.width; height: 36
                color: "#15FFFFFF"; radius: 4; border.color: "#22FFFFFF"

                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text { text: "🎬"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: title
                        color: "white"; font.pixelSize: 11; width: parent.width - 60
                        elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "✕"; color: "#FF4444"; font.bold: true; font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectedModel.remove(index);
                                syncToPython();
                            }
                        }
                    }
                }
            }
        }

        // 4. ACTION BUTTON
        Button {
            id: syncBtn
            width: parent.width; height: 44
            visible: selectedModel.count > 0
            contentItem: Text {
                text: "SYNC TO COLLECTION"; color: "black"; font.bold: true
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: syncBtn.pressed ? "#00C2CC" : "#00F2FF"; radius: 6 }
            onClicked: syncToPython()
        }
    }
}