import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: searchNavRoot
    anchors.fill: parent
    color: "transparent"
    
    // REMOVED local titleStack - we will use the one from the master logic
    property int panelIndex: 0 

    // Helper to get the current list from the master controller
    // This ensures Section B always sees what Section A added
    function getCurrentStack() {
        if (typeof architectRoot !== "undefined") {
            // We pull the current rule value for this panel
            var rule = architectRoot.getRuleValue(panelIndex, "search_files");
            return rule ? rule.split("|") : [];
        }
        return [];
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text { 
            text: "FILE SEARCH MODE"
            color: "#00F2FF"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1 
        }

        TextField {
            id: searchInput
            width: parent.width; height: 38
            placeholderText: "Type to find movies..."
            color: "white"
            font.pixelSize: 13
            background: Rectangle { color: "#1AFFFFFF"; radius: 4; border.color: "#33FFFFFF" }
            onTextChanged: architectController.search_library(text)
        }

        // Section A: Results
        ListView {
            id: resultsView
            width: parent.width
            height: searchInput.text.length > 0 ? 120 : 0
            clip: true
            model: architectController.searchResultsModel
            
            delegate: ItemDelegate {
                width: resultsView.width; height: 32
                contentItem: Text {
                    text: "➕ " + (modelData.title || "Unknown")
                    color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    var current = getCurrentStack();
                    if (current.indexOf(modelData.filename) === -1) {
                        current.push(modelData.filename);
                        // Update master logic
                        architectRoot.updateRule(panelIndex, "search_files", current.join("|"));
                        searchInput.text = ""; // Force refresh
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#33FFFFFF" }

        // Section B: The Stack
        Text { 
            text: "SELECTED STACK"
            color: "gold"; font.pixelSize: 10; font.bold: true 
        }

        ListView {
            id: stackView
            width: parent.width
            height: parent.height - 200 // Fixed height for testing
            // We bind directly to the master rule to ensure it updates
            model: getCurrentStack()
            spacing: 5
            clip: true

            delegate: Rectangle {
                width: stackView.width; height: 34
                color: "#22FFFFFF"; radius: 4

                Row {
                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                    Text {
                        text: modelData.split('\\').pop()
                        color: "white"; font.pixelSize: 11
                        width: parent.width - 40
                        elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter
                    }
                    Button {
                        width: 20; height: 20; flat: true
                        contentItem: Text { text: "✕"; color: "#FF4444"; font.bold: true }
                        onClicked: {
                            var current = getCurrentStack();
                            current.splice(index, 1);
                            architectRoot.updateRule(panelIndex, "search_files", current.join("|"));
                        }
                    }
                }
            }
        }
    }
}