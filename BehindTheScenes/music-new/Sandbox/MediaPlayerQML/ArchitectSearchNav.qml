import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: searchNavRoot
    anchors.fill: parent
    color: "transparent"

    // Index from parent panel
    property int panelIndex: (typeof panelRoot !== "undefined") ? panelRoot.panelIndex : 0

    // This model holds the "Bucket" of manually selected movies
    ListModel { id: selectedModel }

    // --- INTERNAL LOGIC ---
    function syncToPython() {
        var paths = [];
        for(var i=0; i<selectedModel.count; i++) {
            paths.push(selectedModel.get(i).filePath);
        }
        if (typeof architectRoot !== "undefined") {
            architectRoot.updateRule(panelIndex, "search_files", paths.join("|"));
        }
    }

    function addMovieToBucket(title, path) {
        if (!path) return;
        // Prevent duplicates
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

        Text { 
            text: "FILE SEARCH MODE"
            color: "#00F2FF"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 
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

        // 2. SEARCH RESULTS (Appears when typing)
        ListView {
            id: resultsView
            width: parent.width
            height: (searchInput.text.length > 0 && count > 0) ? Math.min(contentHeight, 150) : 0
            clip: true
            model: (typeof architectController !== "undefined") ? architectController.searchResultsModel : []
            
            delegate: ItemDelegate {
                width: resultsView.width; height: 32
                contentItem: Text {
                    // Tries to find a title, then a filename, then fallback
                    text: "➕ " + (modelData.title || modelData.filename || "Unknown")
                    color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: hovered ? "#2200F2FF" : "#05FFFFFF"; radius: 4 }
                
                onClicked: {
                    // Determine which property holds the path
                    var finalPath = modelData.filename || modelData.path || modelData.filePath;
                    var finalTitle = modelData.title || (finalPath ? finalPath.split(/[\\/]/).pop() : "Unknown");
                    
                    addMovieToBucket(finalTitle, finalPath);
                    searchInput.text = ""; // Reset search after selection
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#33FFFFFF"; visible: selectedModel.count > 0 }

        // 3. SELECTED STACK (The Bucket)
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
                        color: "white"; font.pixelSize: 11
                        width: parent.width - 50
                        elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter
                    }

                    // REMOVE BUTTON (Red X)
                    Text {
                        text: "✕"; color: "#FF4444"; font.bold: true; font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -5
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
            width: parent.width; height: 44
            visible: selectedModel.count > 0
            contentItem: Text {
                text: "SYNC TO COLLECTION"; color: "black"; font.bold: true
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: "#00F2FF"; radius: 6 }
            onClicked: syncToPython()
        }
    }
}