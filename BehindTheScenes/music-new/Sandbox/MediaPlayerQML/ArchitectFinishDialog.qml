import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: finishOverlay
    anchors.fill: parent
    color: "#F2121214" // Slightly more opaque
    visible: false

    Column {
        anchors.centerIn: parent
        width: 400
        spacing: 20

        Text {
            text: "FINALIZING COLLECTION"
            color: "gold"; font.pixelSize: 22; font.letterSpacing: 3
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // --- NAME INPUT ---
        Column {
            width: parent.width; spacing: 5
            Text { text: "COLLECTION NAME"; color: "#88FFFFFF"; font.pixelSize: 10 }
            TextField {
                id: nameInput
                width: parent.width; height: 45
                placeholderText: "e.g., My 50s War Classics"
                color: "white"
                background: Rectangle { 
                    color: "#1AFFFFFF"; radius: 5
                    border.color: nameInput.text === "" ? "#33FFFFFF" : (nameAvailable ? "cyan" : "red")
                }
                onTextChanged: {
                    // Check availability via Python backend
                    nameAvailable = architectController.check_name_exists(text) === false
                }
            }
            Text { 
                text: nameAvailable ? "Name is available" : "Name already in use!"
                color: nameAvailable ? "cyan" : "red"
                font.pixelSize: 10; visible: nameInput.text !== ""
            }
        }

        // --- DESCRIPTION ---
        Column {
            width: parent.width; spacing: 5
            Text { text: "DESCRIPTION"; color: "#88FFFFFF"; font.pixelSize: 10 }
            TextArea {
                id: descInput
                width: parent.width; height: 100
                placeholderText: "What is this collection about?"
                color: "white"
                wrapMode: Text.WordWrap
                background: Rectangle { color: "#1AFFFFFF"; radius: 5 }
            }
        }

        // --- CATEGORY PICKER ---
        Column {
            width: parent.width; spacing: 5
            Text { text: "ASSIGN TO CATEGORY"; color: "#88FFFFFF"; font.pixelSize: 10 }
            ComboBox {
                id: catPicker
                width: parent.width
                model: ["Westerns", "War", "Noir", "Custom..."] // Dynamically load existing categories
            }
        }

        Button {
            width: parent.width; height: 55
            text: "SAVE TO ASSETS"
            enabled: nameInput.text !== "" && nameAvailable
            onClicked: {
                // Collect all logic from the HUD's panels and send to Python
                var finalLogic = architectRoot.getCompiledLogic();
                architectController.save_collection(
                    nameInput.text, 
                    descInput.text, 
                    catPicker.currentText, 
                    JSON.stringify(finalLogic)
                );
            }
        }
    }

    property bool nameAvailable: true
}