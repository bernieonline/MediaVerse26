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

    // ArchitectPanel.qml will pull the selected list on Commit
    signal searchSelected(string query, var panelList)

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

    // --- INTERNAL LOGIC ---
    function syncToPython() {
        var paths = [];
        for(var i=0; i < selectedModel.count; i++) {
            paths.push(selectedModel.get(i).filePath);
        }
        
        var finalValue = paths.join("|");
        var countVal = selectedModel.count;

        if (parentPanel) {
            parentPanel.hitCount = countVal;
        }

        if (typeof architectController !== "undefined") {
            if (countVal === 0) {
                architectController.resultsCounted.emit(panelIndex, 0);
            } else {
                // Sending updated rule to engine
                architectController.update_logic_rule(panelIndex, "search_files", finalValue);
                architectController.recalculate_foundation();
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
                if (typeof architectController !== "undefined") {
                    architectController.search_library(text);
                }
            }
        }

        // 2. SEARCH RESULTS
        ListView {
            id: resultsView
            width: parent.width
            // ⭐ RESTORED: Using 'count' directly instead of 'model.count'
            height: (searchInput.text.length > 0 && count > 0) ? Math.min(contentHeight, 150) : 0
            clip: true
            model: (typeof architectController !== "undefined") ? architectController.searchResultsModel : []
            
            delegate: ItemDelegate {
                width: resultsView.width; height: 32

                contentItem: Text {
                    text: "➕ " + (model.title || model.filePath || "Unknown")
                    color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: hovered ? "#2200F2FF" : "#05FFFFFF"; radius: 4 }
                
                onClicked: {
                    var finalPath = model.filePath
                    var finalTitle = model.title

                    // Notify listeners
                    searchSelected(searchInput.text, [])

                    // Add to multi-select bucket
                    searchNavRoot.addMovieToBucket(finalTitle, finalPath)

                    // Clear search field
                    searchInput.text = ""
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
    }
}