import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: searchNavRoot
    anchors.fill: parent
    color: "transparent"
    
    property var titleStack: []
    property int panelIndex: 0 

    function addToStack(filename) {
        var temp = titleStack;
        if (temp.indexOf(filename) === -1) {
            temp.push(filename);
            titleStack = temp;
            if (typeof architectRoot !== "undefined") {
                architectRoot.updateRule(panelIndex, "search_files", titleStack.join("|"));
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // 1. HEADER (Fixed the font.letterSpacing syntax)
        Text { 
            text: "FILE SEARCH MODE"
            color: "#00F2FF"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1 
        }

        // 2. SEARCH INPUT
        TextField {
            id: searchInput
            width: parent.width; height: 38
            placeholderText: "Type to find movies..."
            color: "white"
            font.pixelSize: 13
            
            background: Rectangle { 
                color: "#1AFFFFFF"; radius: 4
                border.color: searchInput.activeFocus ? "#00F2FF" : "#33FFFFFF" 
            }
            
            onTextChanged: architectController.search_library(text)
        }

        // 3. RESULTS LIST (Conditional height)
        ListView {
            id: resultsView
            width: parent.width
            height: searchInput.text.length > 0 ? 120 : 0
            clip: true
            visible: height > 0
            model: architectController.searchResultsModel
            
            delegate: ItemDelegate {
                width: resultsView.width; height: 32
                background: Rectangle { color: hovered ? "#33FFFFFF" : "#11FFFFFF"; radius: 2 }
                contentItem: Text {
                    text: "➕ " + (modelData.title || "Unknown")
                    color: "white"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    searchNavRoot.addToStack(modelData.filename);
                    searchInput.text = ""; 
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#33FFFFFF" }

        // 4. STACK SECTION
        Text { 
            text: "SELECTED STACK (" + titleStack.length + ")"
            color: "gold"; font.pixelSize: 10; font.bold: true 
        }

        // We use anchors here to make sure it fills the rest of the column's space
        ListView {
            id: stackView
            width: parent.width
            height: parent.height - (resultsView.visible ? 250 : 130)
            model: titleStack
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
                        anchors.verticalCenter: parent.verticalCenter
                        contentItem: Text { text: "✕"; color: "#FF4444"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        onClicked: {
                            var temp = titleStack;
                            temp.splice(index, 1);
                            titleStack = temp;
                            architectRoot.updateRule(panelIndex, "search_files", titleStack.join("|"));
                        }
                    }
                }
            }
        }
    }
}