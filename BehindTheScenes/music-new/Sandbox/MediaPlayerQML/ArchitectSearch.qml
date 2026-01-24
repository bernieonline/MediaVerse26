import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: searchModeRoot
    anchors.fill: parent

    // This model holds the "Bucket" of manually selected movies
    ListModel { id: selectedModel }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // 1. SEARCH INPUT
        TextField {
            id: searchInput
            width: parent.width
            height: 45
            placeholderText: "Search and click to add..."
            color: "white"
            font.pixelSize: 14
            leftPadding: 10
            
            background: Rectangle {
                color: "#15FFFFFF"
                radius: 8
                border.color: searchInput.activeFocus ? "#00F2FF" : "#33FFFFFF"
            }

            onTextChanged: {
                // HOOK: Trigger your existing library search logic here
                // e.g., mainController.searchLibrary(text)
            }
        }

        // 2. THE SELECTION BUCKET (Visual Feedback)
        Text {
            text: "SELECTED MOVIES: " + selectedModel.count
            color: "gold"
            font.pixelSize: 11
            font.bold: true
            visible: selectedModel.count > 0
        }

        ListView {
            id: bucketView
            width: parent.width
            height: 340
            clip: true
            model: selectedModel
            spacing: 5

            delegate: ItemDelegate {
                width: bucketView.width
                height: 40
                
                contentItem: Row {
                    spacing: 10
                    Text { text: "🎬"; verticalAlignment: Text.AlignVCenter }
                    Text { 
                        text: model.title
                        color: "white"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: 240
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text { 
                        text: "✕" 
                        color: "#FF4444"
                        font.bold: true
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        
                        MouseArea { 
                            anchors.fill: parent 
                            onClicked: selectedModel.remove(index) 
                        }
                    }
                }

                background: Rectangle {
                    color: "#0AFFFFFF"
                    radius: 5
                    border.color: "#1AFFFFFF"
                }
            }
        }

        // 3. CONFIRMATION
        Button {
            width: parent.width
            height: 50
            enabled: selectedModel.count > 0
            
            contentItem: Text {
                text: "LOCK IN " + selectedModel.count + " MOVIES"
                color: "black"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.enabled ? "#00F2FF" : "#444"
                radius: 8
            }

            onClicked: {
                // THE HANDSHAKE
                // We pass a summary string for the panel display
                var summary = selectedModel.count + " Specific Movies";
                
                // Note: In the final Save, we will loop through this selectedModel 
                // to get the actual file paths.
                panelRoot.updateRule("freestyle", summary);
            }
        }
    }

    // --- EXTERNAL API ---
    // Call this function from your main search results list 
    // when a movie is clicked.
    function addMovieToBucket(title, path) {
        // Prevent duplicates
        for(var i=0; i<selectedModel.count; i++) {
            if(selectedModel.get(i).filePath === path) return;
        }
        selectedModel.append({"title": title, "filePath": path});
    }
}