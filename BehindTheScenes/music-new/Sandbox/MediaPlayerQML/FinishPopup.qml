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
        console.log("✅ DIALOG: DNA Captured successfully!");
    }

    Rectangle {
        anchors.centerIn: parent
        width: 550; height: 550 // Increased height slightly for the new category row
        color: "#1A1A1C"
        border.color: "gold"; border.width: 2
        radius: 10

        // --- SUCCESS VIEW ---
        Column {
            anchors.centerIn: parent
            visible: isSaved
            spacing: 30
            width: parent.width - 60

            Text {
                text: "Architect Collection Record Saved"
                color: "gold"
                font.pixelSize: 24; font.bold: true
                horizontalAlignment: Text.AlignHCenter; width: parent.width; wrapMode: Text.WordWrap
            }

            Text {
                text: "The collection logic and metadata have been committed to the master manifest."
                color: "#88FFFFFF"
                font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter
                width: parent.width; wrapMode: Text.WordWrap
            }

            Button {
                id: exitBtn
                text: "EXIT ARCHITECT"
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200; height: 50
                contentItem: Text {
                    text: parent.text; color: "black"; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { color: "gold"; radius: 6 }
                onClicked: {
                    finishOverlay.visible = false;
                    if (typeof architectRoot !== 'undefined') architectRoot.visible = false;
                }
            }
        }

        // --- INPUT VIEW (Hidden once saved) ---
        Column {
            id: mainContent
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 18
            visible: !isSaved
            
            Text {
                text: "COLLECTION RECORDED"
                color: "gold"; font.pixelSize: 22; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // --- Row 1: Name & Image ---
            Row {
                width: parent.width; spacing: 15
                Column {
                    width: parent.width - 135; spacing: 5
                    Text { text: "COLLECTION NAME"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                    Rectangle {
                        width: parent.width; height: 45; color: "#000"; radius: 4; border.color: "#333"
                        TextField {
                            id: nameInput
                            anchors.fill: parent; anchors.leftMargin: 10
                            color: "white"; font.pixelSize: 16
                            text: collectionData ? collectionData.collectionName : "New Collection"
                            background: null
                        }
                    }
                }

                Column {
                    width: 120; spacing: 5
                    Text { text: "COVER ART"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                    Button {
                        id: setImageBtn
                        width: parent.width; height: 45
                        contentItem: Text {
                            text: "SET IMAGE"; color: "gold"; font.pixelSize: 12; font.bold: true
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: setImageBtn.hovered ? "#33FFFFFF" : "#11FFFFFF"
                            border.color: "gold"; border.width: 1; radius: 4
                        }
                        onClicked: console.log("🖼️ Set Image clicked")
                    }
                }
            }

            // --- Row 2: Category Assignment (NEW) ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "ASSIGN CATEGORY PILLAR"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 45; color: "#000"; radius: 4; border.color: "#333"
                    ComboBox {
                        id: categoryPicker
                        anchors.fill: parent
                        model: architectController.categories // Loaded from PySide6 Signal
                        textRole: "label"
                        
                        contentItem: Text {
                            text: categoryPicker.displayText
                            color: "gold"; font.pixelSize: 16; verticalAlignment: Text.AlignVCenter; leftPadding: 10
                        }
                        background: Rectangle { color: "transparent" }

                        // Tooltip [2026-02-05]
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        ToolTip.text: "Select which registry pillar this collection belongs to."
                    }
                }
            }

            // --- Row 3: Description ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "DESCRIPTION / NOTES"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 100; color: "#000"; radius: 4; border.color: "#333"
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

            Text {
                text: "DNA sequence captured. Ready for MediaVerse V2."
                color: "#44FFFFFF"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter
            }

            // --- Actions ---
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Button {
                    id: saveBtn
                    text: "SAVE COLLECTION"
                    width: 200; height: 50
                    contentItem: Text {
                        text: parent.text; color: "black"; font.bold: true
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "gold"; radius: 6 }

                    onClicked: {
                        if (collectionData) {
                            // 1. Create a fresh, local record so QML doesn't block the edits
                            var record = {};

                            // 2. Map the UI data directly (The simple way)
                            record.name = nameInput.text;
                            record.description = descInput.text;
                            record.rules = collectionData.rules; // Keep the existing movie list
                            
                            // 3. Add your category key:value pair
                            if (categoryPicker.currentIndex !== -1) {
                                record.category = categoryPicker.model[categoryPicker.currentIndex].key;
                            } else {
                                record.category = categoryPicker.editText.toLowerCase().trim();
                            }

                            // 4. Standard Metadata
                            record.type = "Architect";
                            record.created = new Date().toLocaleDateString('en-CA');
                            record.timestamp = new Date().toISOString();
                            record.favorite = false;
                            record.imagePath = "None";

                            // 5. Stringify and Send
                            var finalPayload = JSON.stringify(record, null, 4);
                            
                            console.log("✅ [SAVE] Data mapped: " + record.name + " | Cat: " + record.category);
                            architectController.save_collection(finalPayload);
                            isSaved = true;
                        }
                    }
                }

                Button {
                    id: cancelBtn
                    text: "CANCEL"
                    width: 120; height: 50
                    contentItem: Text {
                        text: parent.text; color: "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent"; border.color: "#444"; radius: 6 }
                    onClicked: finishOverlay.visible = false
                }
            }
        }
    }
}