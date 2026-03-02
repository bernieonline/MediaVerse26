import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1 
import Qt5Compat.GraphicalEffects 1.1

Rectangle {
    id: finishOverlay
    anchors.fill: parent
    color: "#F2121214"
    visible: false
    z: 10000 

    property var collectionData: null
    property bool isSaved: false 
    property string selectedImagePath: "None"
    
    signal requestFullReset()

    // --- JOB 1: THE HARD RESET ---
    function resetForm() {
        console.log("🧹 Architect Panel: Performing Hard Reset...");
        
        // Force clear the UI components directly
        nameInput.text = "";
        bespokeCategoryInput.text = "";
        descInput.text = "";
        
        // Reset the Logic properties
        categoryPicker.currentIndex = 0;
        selectedImagePath = "None";
        isSaved = false;
        
        // Optional: Force focus away to clear any active highlight
        mainDialog.focus = true;
    }

 

    function prepareDNA(dna) {
        resetForm(); 
        collectionData = dna;
        nameInput.text = dna ? dna.collectionName : "";
        var liveList = architectController.get_architect_categories();
        categoryPicker.model = liveList;
    }

    // --- FILE DIALOG ---
    FileDialog {
        id: imageSelector
        title: "Select Splash Image"
        // Note: PySide6 prefers folder as a URL
        folder: "file:///D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/Assets/Splash"
        nameFilters: ["Images (*.jpg *.png *.jpeg)"]
        onAccepted: {
            //var path = file.toString().replace("file:///", "");
            //selectedImagePath = path.replace(/\//g, "\\");
            // 1. Get the full string
            var fullPath = file.toString().replace("file:///", "");
            
            // 2. Extract just the filename (e.g., "Western.jpg")
            var parts = fullPath.split(/[\/\\]/);
            var filename = parts[parts.length - 1];
            
            // 3. Store ONLY the filename
            selectedImagePath = filename;

        }
    }

    Rectangle {
        id: mainDialog
        anchors.centerIn: parent
        width: 550; height: 700 // Increased height for better spacing
        color: "#1A1A1C"
        border.color: nameInput.text.trim() === "" ? "#55FF0000" : "gold"
        border.width: 2
        radius: 10

        Column {
            id: mainContent
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 15 
            visible: !isSaved
            
            Text {
                text: "COLLECTION RECORDED"
                color: "gold"; font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
            }

            // --- Collection Name ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "COLLECTION NAME *"; color: nameInput.text.trim() === "" ? "red" : "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: nameInput.activeFocus ? "gold" : "#333"
                    TextField { id: nameInput; anchors.fill: parent; anchors.leftMargin: 10; color: "white"; font.pixelSize: 14; placeholderText: "Required..."; background: null }
                }
            }

            // --- IMAGE SECTOR (The "Missing" Row) ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "COLLECTION SPLASH IMAGE"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                
                Row {
                    width: parent.width; height: 50; spacing: 10
                    
                    // The Select Button
                    Rectangle {
                        width: 130; height: 45; color: "#000"; radius: 4; border.color: "gold"; border.width: 1
                        Text { anchors.centerIn: parent; text: "CHOOSE IMAGE"; color: "white"; font.bold: true; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: imageSelector.open()
                            onPressed: parent.color = "#222"
                            onReleased: parent.color = "#000"
                        }
                    }

                    // Preview Box
                    Rectangle {
                        width: 80; height: 45; color: "#000"; radius: 4; border.color: "#333"; clip: true
                        Image {
                            anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                            source: selectedImagePath !== "None" ? "file:///" + selectedImagePath : ""
                            visible: selectedImagePath !== "None"
                        }
                        Text { anchors.centerIn: parent; text: "NONE"; color: "#333"; font.pixelSize: 9; visible: selectedImagePath === "None" }
                    }

                    // Filename Text
                    Text {
                        text: selectedImagePath === "None" ? "No Image Selected" : selectedImagePath.split('\\').pop()
                        color: "gold"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideLeft; width: parent.width - 230
                    }
                }
            }

            // --- Category Picker ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "SELECT EXISTING CATEGORY"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: "#333"
                    ComboBox { id: categoryPicker; anchors.fill: parent; model: ["Actors", "Director", "Genre", "Year", "Top Ten", "Studio"]; background: Rectangle { color: "transparent" } }
                }
            }

            // --- Bespoke Category ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "OR ENTER BESPOKE CATEGORY"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: "#333"
                    TextField { id: bespokeCategoryInput; anchors.fill: parent; anchors.leftMargin: 10; color: "gold"; font.pixelSize: 14; placeholderText: "New category..."; background: null }
                }
            }

            // --- Description ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "DESCRIPTION / NOTES"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 70; color: "#000"; radius: 4; border.color: "#333"
                    ScrollView { anchors.fill: parent; anchors.margins: 5
                        TextArea { id: descInput; color: "white"; font.pixelSize: 13; wrapMode: TextEdit.Wrap; placeholderText: "Details..."; background: null }
                    }
                }
            }

            // --- Actions ---
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 20
                Button {
                    id: saveBtn; text: "SAVE COLLECTION"; width: 200; height: 50
                    onClicked: {
                        if (nameInput.text.trim() === "") return;
                        var record = {
                            "name": nameInput.text.trim(),
                            "description": descInput.text.trim(),
                            "rules": collectionData.rules,
                            "category": bespokeCategoryInput.text.trim() !== "" ? bespokeCategoryInput.text.trim() : categoryPicker.currentText.replace(/\s+/g, ''),
                            "type": "Architect",
                            "created": new Date().toLocaleDateString('en-CA'),
                            "timestamp": new Date().toISOString(),
                            "favorite": false,
                            "imagePath": selectedImagePath
                        };
                        architectController.save_collection(JSON.stringify(record, null, 4));
                        isSaved = true;
                    }
                    contentItem: Text { text: parent.text; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: nameInput.text.trim() === "" ? "#444" : "gold"; radius: 6 }
                }
                Button {
                    id: cancelBtn; text: "CANCEL"; width: 120; height: 50
                    onClicked: { resetForm(); finishOverlay.visible = false; }
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: "transparent"; border.color: "#444"; radius: 6 }
                }
            }
        }

        // --- Success View ---
        Column {
            anchors.centerIn: parent; visible: isSaved; spacing: 20
            Text { text: "Record Saved"; color: "gold"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }
            //Button { text: "EXIT"; width: 100; height: 40; onClicked: { resetForm(); finishOverlay.visible = false; architectRoot.visible = false; } }
            Button {
                text: "EXIT"; width: 100; height: 40; 
                onClicked: { 
                    finishOverlay.visible = false; 
                    finishOverlay.requestFullReset(); // 🔥 Signal the HUD to clean up
                }
            }
        
        
        
        }
    }
}