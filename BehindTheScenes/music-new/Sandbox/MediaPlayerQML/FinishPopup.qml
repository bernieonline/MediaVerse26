import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: finishOverlay
    anchors.fill: parent
    color: "#F2121214"
    visible: false
    z: 10000 

    property var collectionData: null

    function prepareDNA(dna) {
        collectionData = dna;
        console.log("✅ DIALOG: DNA Captured successfully!");
    }

    Rectangle {
        anchors.centerIn: parent
        width: 550; height: 500 
        color: "#1A1A1C"
        border.color: "gold"; border.width: 2
        radius: 10

        Column {
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 18
            
            Text {
                text: "COLLECTION RECORDED"
                color: "gold"; font.pixelSize: 22; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // --- NAME & IMAGE ROW ---
            Row {
                width: parent.width
                spacing: 15

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
                            text: "SET IMAGE"
                            color: "gold"; font.pixelSize: 12; font.bold: true
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: setImageBtn.hovered ? "#33FFFFFF" : "#11FFFFFF"
                            border.color: "gold"; border.width: 1; radius: 4
                        }
                        onClicked: console.log("🖼️ Set Image clicked - functionality pending...")
                    }
                }
            }

            // --- DESCRIPTION INPUT ---
            Column {
                width: parent.width; spacing: 5
                Text { text: "DESCRIPTION / NOTES"; color: "#88FFFFFF"; font.pixelSize: 10; font.bold: true }
                Rectangle {
                    width: parent.width; height: 120; color: "#000"; radius: 4; border.color: "#333"
                    ScrollView {
                        anchors.fill: parent; anchors.margins: 5
                        TextArea {
                            id: descInput
                            color: "white"; font.pixelSize: 14; wrapMode: TextEdit.Wrap
                            placeholderText: "Enter collection details or review snippets here..."
                        }
                    }
                }
            }

            Text {
                text: "DNA sequence captured. Ready for MediaVerse V2."
                color: "#44FFFFFF"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // --- ACTION BUTTONS ---
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Button {
                    id: saveBtn
                    text: "SAVE COLLECTION"
                    width: 200; height: 50
                    contentItem: Text {
                        text: parent.text; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "gold"; radius: 6 }
                    onClicked: {
                        if (collectionData) {
                            // 1. Inject the final Metadata from the input fields
                            collectionData.collectionName = nameInput.text;
                            collectionData.description = descInput.text;
                            
                            // 2. Set Architectural defaults
                            collectionData.type = "Architect";
                            collectionData.imagePath = "None"; // Placeholder for the 'Set Image' feature
                            collectionData.reviews = []; 
                            
                            // 3. Add a timestamp for the record
                            collectionData.dateCreated = new Date().toLocaleString();

                            // 4. Generate the payload (indented for clear log inspection)
                            var finalPayload = JSON.stringify(collectionData, null, 4);

                            // 5. The Handover to Python
                            if (typeof architectController !== "undefined") {
                                console.log("💾 [SYSTEM]: Sending Final Architect Record to Controller...");
                                architectController.save_collection(finalPayload);
                            } else {
                                // Fallback print if the Python controller isn't connected yet
                                console.log("⚠️ [DEBUG]: Controller not found. Record Content:\n" + finalPayload);
                            }

                            // 6. UI Cleanup
                            finishOverlay.visible = false;
                            if (typeof architectRoot !== 'undefined') {
                                architectRoot.visible = false;
                            }
                            
                            // Optional: Reset inputs for next use
                            nameInput.text = "";
                            descInput.text = "";
                        }
                    }
                }

                Button {
                    id: cancelBtn
                    text: "CANCEL"
                    width: 120; height: 50
                    contentItem: Text {
                        text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent"; border.color: "#444"; radius: 6 }
                    onClicked: finishOverlay.visible = false
                }
            }
        }
    }
}