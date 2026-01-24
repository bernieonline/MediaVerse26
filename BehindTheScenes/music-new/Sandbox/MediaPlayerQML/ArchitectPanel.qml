import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot
    property int panelIndex: 0
    property string currentMode: "selection" // selection, folder, search, category, year

    // --- THE GLOWING WHITE SHADOW ---
    // This sits behind the cardFrame to create that floating aura
    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 18
        spread: 0.15
        color: "#AAFFFFFF" // Soft White Glow
        cornerRadius: cardFrame.radius + glowRadius
    }

    Rectangle {
        id: cardFrame
        anchors.fill: parent
        color: "#1A1A1A"
        radius: 15
        border.color: "#FFFFFF"
        border.width: 1
        clip: true // Prevents child components from breaking the glowing box

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // --- CARD HEADER ---
            Row {
                width: parent.width
                height: 30
                
                Text {
                    text: "CRITERIA #" + (panelIndex + 1)
                    color: "white"
                    font.bold: true
                    font.pixelSize: 12
                    opacity: 0.6
                    width: parent.width - 30
                }

                // Small Reset/Close Button to go back to selection
                Button {
                    width: 24; height: 24
                    visible: currentMode !== "selection"
                    contentItem: Text { text: "↺"; color: "white"; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { color: "transparent" }
                    onClicked: {
                        currentMode = "selection";
                        architectRoot.updateRule(panelIndex, "selection", "");
                    }
                }
            }

            // --- VIEW PORT ---
            Item {
                id: viewPort
                width: parent.width
                height: parent.height - 70

                // MODE A: SELECTION MENU
                Column {
                    id: selectionMenu
                    visible: currentMode === "selection"
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 12

                    Text {
                        text: "Select Logic"
                        color: "white"
                        font.pixelSize: 20
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Item { width: 1; height: 10 } // Spacer

                    // --- BUTTONS ---
                    Button {
                        text: "🔍 Search Mode"
                        width: parent.width * 0.8; height: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: currentMode = "search"
                    }

                    Button {
                        text: "📁 Folder Mode"
                        width: parent.width * 0.8; height: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: currentMode = "folder"
                    }

                    Button {
                        text: "🏷️ Category Mode"
                        width: parent.width * 0.8; height: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: currentMode = "category"
                    }

                    Button {
                        text: "📅 Year Mode"
                        width: parent.width * 0.8; height: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: currentMode = "year"
                    }
                }

                // MODE B: THE DYNAMIC TOOL LOADER
                Loader {
                    id: toolLoader
                    anchors.fill: parent
                    visible: currentMode !== "selection"
                    
                    // Maps the mode to the actual file
                    source: {
                        if (currentMode === "folder") return "ArchitectFolderNav.qml";
                        if (currentMode === "search") return "ArchitectSearchNav.qml";
                        // Future proofing for category/year
                        if (currentMode === "category") return "ArchitectCategoryNav.qml"; 
                        return "";
                    }

                    onStatusChanged: {
                        if (status === Loader.Ready) {
                            console.log("✅ Card " + panelIndex + " loaded: " + source)
                        }
                    }
                }
            }
        }
    }
}