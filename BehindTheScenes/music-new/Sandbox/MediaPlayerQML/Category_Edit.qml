import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects 6.0

Popup {
    id: root
    width: 650
    height: 600 
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    
    // Sync on open to catch newly added bespoke items
    onOpened: {
        if (typeof architectController !== "undefined") {
            architectController.refresh_registry();
        }
    }
    
    background: Rectangle {
        color: "#121212" 
        radius: 12
        border.color: "#FFD700" 
        border.width: 1
    }

    // --- SUB-POPUP: Rename Dialog ---
    Popup {
        id: editDialog
        width: 400; height: 180; modal: true; focus: true
        anchors.centerIn: parent
        property string originalName: ""

        background: Rectangle { color: "#1a1a1c"; border.color: "gold"; border.width: 2; radius: 8 }

        Column {
            anchors.centerIn: parent; spacing: 15; width: parent.width - 40
            Text { text: "RENAME CATEGORY"; color: "gold"; font.bold: true; font.pixelSize: 16 }
            
            Rectangle {
                width: parent.width; height: 40; color: "#000"; radius: 4; border.color: "#333"
                TextField {
                    id: renameInput
                    anchors.fill: parent; anchors.leftMargin: 10
                    text: editDialog.originalName
                    color: "white"; verticalAlignment: Text.AlignVCenter
                    placeholderText: "Enter new name..."
                }
            }

            Row {
                spacing: 15; anchors.horizontalCenter: parent.horizontalCenter
                Button { 
                    text: "BACKFLUSH CHANGES"
                    onClicked: {
                        if (renameInput.text.trim() !== "" && renameInput.text !== editDialog.originalName) {
                            architectController.rename_category_global(editDialog.originalName, renameInput.text.trim());
                            backflushNotify.open();
                            editDialog.close();
                        }
                    }
                }
                Button { text: "CANCEL"; onClicked: editDialog.close() }
            }
        }
    }

    // --- SUB-POPUP: Success Notification ---
    Popup {
        id: backflushNotify
        width: 300; height: 130; modal: true; anchors.centerIn: parent
        background: Rectangle { color: "#050505"; border.color: "#00FF00"; border.width: 1; radius: 8 }
        Column {
            anchors.centerIn: parent; spacing: 20; width: parent.width - 40
            Text { 
                text: "All changes have been\nsuccessfully backflushed."; 
                color: "white"; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 14 
            }
            Button { 
                text: "OK"; anchors.horizontalCenter: parent.horizontalCenter
                onClicked: backflushNotify.close() 
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // --- Header ---
        Row {
            width: parent.width; height: 30
            Text {
                text: "CATEGORY REGISTRY"
                color: "#FFD700"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 2
                width: parent.width - 40
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333333" }

        // --- The Registry List ---
        ListView {
            id: categoryListView
            width: parent.width
            height: 400 
            clip: true
            model: architectController.categoryModel 
            spacing: 6 

            delegate: Item {
                width: categoryListView.width
                height: 45 

                Rectangle {
                    anchors.fill: parent
                    color: modelData.locked ? "#1a1a1a" : "#2a2418" 
                    radius: 4
                    border.color: modelData.locked ? "#333333" : "#FFD700"
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        Text { text: modelData.locked ? "🔒" : "👑"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            text: modelData.label
                            color: modelData.locked ? "#aaaaaa" : "#FFD700"
                            font.pixelSize: 14; font.bold: !modelData.locked
                            width: 140; anchors.verticalCenter: parent.verticalCenter; verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: modelData.tooltip
                            color: "#888888"; font.pixelSize: 11; font.italic: true
                            width: 200; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; verticalAlignment: Text.AlignVCenter
                        }

                        // --- Actions ---
                        Row {
                            visible: !modelData.locked
                            spacing: 12
                            anchors.verticalCenter: parent.verticalCenter 

                            // Rename Button
                            Button {
                                width: 32; height: 32; flat: true
                                contentItem: Text { text: "✏️"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: {
                                    editDialog.originalName = modelData.key;
                                    editDialog.open();
                                }
                            }

                            // Delete Button (Backflush to Unassigned)
                            Button {
                                width: 32; height: 32; flat: true
                                contentItem: Text { 
                                    text: "❌"; font.pixelSize: 14
                                    color: parent.hovered ? "#ff0000" : "#ff4444"
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                                }
                                onClicked: {
                                    architectController.delete_category_global(modelData.key);
                                    backflushNotify.open(); // Notify user that items are now unassigned
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333333" }

        Button {
            text: "SAVE & EXIT REGISTRY"
            width: parent.width; height: 40
            background: Rectangle { color: parent.hovered ? "#FFC107" : "#FFD700"; radius: 4 }
            contentItem: Text { text: parent.text; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: root.close()
        }
    }
}