import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: searchModeRoot
    anchors.fill: parent

    // The index from the parent ArchitectPanel
    property int pIdx: (typeof panelRoot !== "undefined") ? panelRoot.panelIndex : 0

    // This model holds the "Bucket" of manually selected movies
    ListModel { id: selectedModel }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // 1. SEARCH INPUT
        TextField {
            id: searchInput
            width: parent.width; height: 45
            placeholderText: "Type to find movies..."
            color: "white"; font.pixelSize: 14; leftPadding: 40
            
            background: Rectangle {
                color: "#15FFFFFF"; radius: 8
                border.color: searchInput.activeFocus ? "#00F2FF" : "#33FFFFFF"
                Text { 
                    text: "🔍"; color: "#00F2FF"; anchors.left: parent.left; 
                    anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter 
                }
            }

            onTextChanged: {
                // Trigger the Python library search
                if (typeof architectController !== "undefined") {
                    architectController.search_library(text)
                }
            }
        }

        // 2. SEARCH RESULTS (Dropdown style)
        // This only appears when you are typing
        ListView {
            id: resultsView
            width: parent.width
            height: searchInput.text.length > 0 ? 120 : 0
            clip: true
            model: (typeof architectController !== "undefined") ? architectController.searchResultsModel : []
            visible: height > 0
            
            delegate: ItemDelegate {
                width: resultsView.width; height: 35
                contentItem: Text {
                    text: "➕ " + (modelData.title || "Unknown")
                    color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: hovered ? "#2200F2FF" : "#11FFFFFF"; radius: 4 }
                onClicked: {
                    // Use your External API function
                    addMovieToBucket(modelData.title, modelData.filename);
                    searchInput.text = ""; // Reset search
                }
            }
        }

        // 3. THE SELECTION BUCKET (Visual Feedback)
        Text {
            text: "SELECTED STACK: " + selectedModel.count
            color: "gold"; font.pixelSize: 11; font.bold: true
            visible: selectedModel.count > 0
        }

        ListView {
            id: bucketView
            width: parent.width
            height: parent.height - (resultsView.height + 180) // Dynamic height
            clip: true
            model: selectedModel
            spacing: 5

            delegate: Rectangle {
                width: bucketView.width; height: 40
                color: "#0AFFFFFF"; radius: 5; border.color: "#1AFFFFFF"
                
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text { text: "🎬"; anchors.verticalCenter: parent.verticalCenter }
                    Text { 
                        text: title; color: "white"; font.pixelSize: 13
                        elide: Text.ElideRight; width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { 
                        text: "✕"; color: "#FF4444"; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                        MouseArea { 
                            anchors.fill: parent; anchors.margins: -10 
                            onClicked: {
                                selectedModel.remove(index);
                                syncToPython(); // Update Python whenever we remove
                            }
                        }
                    }
                }
            }
        }

        // 4. LOCK IN BUTTON (Saves to the Rule)
        Button {
            width: parent.width; height: 50
            enabled: selectedModel.count > 0
            contentItem: Text {
                text: "SYNC STACK TO RULE"
                color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter
            }
            background: Rectangle {
                color: parent.enabled ? "#00F2FF" : "#444"; radius: 8
            }
            onClicked: syncToPython()
        }
    }

    // Internal helper to push the list to your Backend
    function syncToPython() {
        var paths = [];
        for(var i=0; i<selectedModel.count; i++) {
            paths.push(selectedModel.get(i).filePath);
        }
        // updateRule(index, mode, value)
        architectRoot.updateRule(pIdx, "search_files", paths.join("|"));
    }

    // --- EXTERNAL API ---
    function addMovieToBucket(title, path) {
        for(var i=0; i<selectedModel.count; i++) {
            if(selectedModel.get(i).filePath === path) return;
        }
        selectedModel.append({"title": title, "filePath": path});
        syncToPython(); // Auto-sync when adding
    }
}