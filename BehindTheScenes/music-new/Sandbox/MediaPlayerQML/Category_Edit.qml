import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Popup {
    id: root
    width: 650
    height: 600 
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    
    background: Rectangle {
        color: "#121212" 
        radius: 12
        border.color: "#FFD700" 
        border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // --- Header ---
        Row {
            width: parent.width
            height: 30
            Text {
                text: "CATEGORY REGISTRY"
                color: "#FFD700"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
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
                        // Row doesn't support verticalAlignment, so children use anchors below

                        Text {
                            text: modelData.locked ? "🔒" : "👑"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.label
                            color: modelData.locked ? "#aaaaaa" : "#FFD700"
                            font.pixelSize: 14
                            font.bold: !modelData.locked
                            width: 140
                            anchors.verticalCenter: parent.verticalCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: modelData.tooltip
                            color: "#888888" 
                            font.pixelSize: 11
                            font.italic: true
                            width: 220
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // --- Centered Action Icons ---
                        Row {
                            visible: !modelData.locked
                            spacing: 8
                            anchors.verticalCenter: parent.verticalCenter 

                            // Rename Button
                            Button {
                                width: 32; height: 32; flat: true
                                contentItem: Text { 
                                    text: "✏️" 
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter 
                                }
                                onClicked: console.log("Rename Category: " + modelData.key)
                            }

                            // Red Cross Delete Button
                            Button {
                                width: 32; height: 32; flat: true
                                contentItem: Text { 
                                    text: "❌" 
                                    font.pixelSize: 14
                                    color: parent.hovered ? "#ff0000" : "#ff4444"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter 
                                }
                                onClicked: console.log("Delete Category: " + modelData.key)
                            }
                        }
                    }
                }
            }
        }

        // --- Bottom Action Section ---
        Rectangle { width: parent.width; height: 1; color: "#333333" }

        Button {
            text: "SAVE & EXIT REGISTRY"
            width: parent.width
            height: 40
            background: Rectangle {
                color: parent.hovered ? "#FFC107" : "#FFD700"
                radius: 4
            }
            contentItem: Text {
                text: parent.text
                color: "black"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                console.log("Saving Category Registry...")
                root.close()
            }
        }
    }
}