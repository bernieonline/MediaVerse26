import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: finishOverlay
    anchors.fill: parent
    color: "#F2121214"
    visible: false
    z: 10000 

    property var collectionData: null
    property bool isSaved: false 

    function prepareDNA(dna) {
        collectionData = dna;
        isSaved = false; 
        nameInput.text = dna ? dna.collectionName : "";
        bespokeCategoryInput.text = ""; 
        categoryPicker.currentIndex = 0; 
    }

    Rectangle {
        anchors.centerIn: parent
        width: 550; height: 620 
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
                color: "gold"; font.pixelSize: 22; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // --- Collection Name ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "COLLECTION NAME *"; color: nameInput.text.trim() === "" ? "red" : "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: nameInput.activeFocus ? "gold" : "#333"
                    TextField {
                        id: nameInput
                        anchors.fill: parent; anchors.leftMargin: 10
                        color: "white"; font.pixelSize: 16
                        placeholderText: "Required..."
                        background: null
                    }
                }
            }

            // --- Fixed Category List (Bypasses Python Model) ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "SELECT EXISTING CATEGORY"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: "#333"
                    ComboBox {
                        id: categoryPicker
                        anchors.fill: parent
                        // WE HARDCODE THIS TO AVOID THE 'KEYWORDS' LEAK
                        model: ["Actors", "Director", "Genre", "Year", "Top Ten", "Studio"]
                        currentIndex: 0 
                        background: Rectangle { color: "transparent" }
                    }
                }
            }

            // --- Bespoke Category ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "OR ENTER BESPOKE CATEGORY (OVERRIDES LIST)"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: "#333"
                    TextField {
                        id: bespokeCategoryInput
                        anchors.fill: parent; anchors.leftMargin: 10
                        color: "gold"; font.pixelSize: 16
                        placeholderText: "Type a new category..."
                        background: null
                    }
                }
            }

            // --- Description ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "DESCRIPTION / NOTES"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 80; color: "#000"; radius: 4; border.color: "#333"
                    ScrollView {
                        anchors.fill: parent; anchors.margins: 5
                        TextArea {
                            id: descInput
                            color: "white"; font.pixelSize: 14; wrapMode: TextEdit.Wrap
                            placeholderText: "Enter collection details here..."
                        }
                    }
                }
            }

            // --- Actions ---
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Button {
                    id: saveBtn
                    text: "SAVE COLLECTION"
                    width: 200; height: 50
                    // Correct onClicked placement
                    onClicked: {
                        if (nameInput.text.trim() === "") return;
                        if (collectionData) {
                            var record = {};
                            record.name = nameInput.text.trim();
                            record.description = descInput.text.trim();
                            record.rules = collectionData.rules;
                            
                            var bespoke = bespokeCategoryInput.text.trim();
                            if (bespoke !== "") {
                                record.category = bespoke;
                            } else {
                                // Strip space (e.g. "Top Ten" -> "TopTen")
                                record.category = categoryPicker.currentText.replace(/\s+/g, '');
                            }

                            record.type = "Architect";
                            record.created = new Date().toLocaleDateString('en-CA');
                            record.timestamp = new Date().toISOString();
                            record.favorite = false;
                            record.imagePath = "None";

                            architectController.save_collection(JSON.stringify(record, null, 4));
                            isSaved = true;
                        }
                    }
                    contentItem: Text { text: parent.text; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: nameInput.text.trim() === "" ? "#444" : "gold"; radius: 6 }
                }

                Button {
                    id: cancelBtn
                    text: "CANCEL"
                    width: 120; height: 50
                    onClicked: finishOverlay.visible = false
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: "transparent"; border.color: "#444"; radius: 6 }
                }
            }
        }

        // --- Success View ---
        Column {
            anchors.centerIn: parent
            visible: isSaved
            spacing: 20
            Text { text: "Record Saved"; color: "gold"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }
            Button {
                text: "EXIT"; width: 100; height: 40; 
                onClicked: { finishOverlay.visible = false; architectRoot.visible = false; }
            }
        }
    }
}