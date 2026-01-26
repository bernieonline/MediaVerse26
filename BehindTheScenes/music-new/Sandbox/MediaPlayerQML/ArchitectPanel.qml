import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot
    property int panelIndex: 0
    property string currentMode: "selection" 
    property string nextGate: "NONE" // HUD reads this but we don't draw it here

    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 15; spread: 0.15; color: "#AAFFFFFF"; cornerRadius: 20
    }

    Rectangle {
        id: cardFrame
        anchors.fill: parent
        color: "#1A1A1A"; radius: 12; border.color: "#FFFFFF"; border.width: 1; clip: true 

        Column {
            anchors.fill: parent
            anchors.margins: 12 
            spacing: 12

            // HEADER
            Row {
                width: parent.width; height: 25
                Text {
                    text: "CRITERIA #" + (panelIndex + 1)
                    color: "white"; font.bold: true; font.pixelSize: 11; opacity: 0.5
                    width: parent.width - 25
                }
                
                Button {
                    width: 20; height: 20; visible: currentMode !== "selection"
                    contentItem: Text { text: "↺"; color: "white"; horizontalAlignment: Text.AlignHCenter }
                    background: Item {}
                    onClicked: { 
                        currentMode = "selection"; 
                        nextGate = "NONE";
                        architectRoot.updateRule(panelIndex, "selection", ""); 
                    }
                }
            }

            // VIEWPORT (The Main Content Area)
            Item {
                width: parent.width
                height: parent.height - 40 

                Column {
                    visible: currentMode === "selection"
                    anchors.centerIn: parent; width: parent.width; spacing: 10
                    Text { 
                        text: "Select Logic"; color: "white"; font.pixelSize: 18; 
                        font.bold: true; anchors.horizontalCenter: parent.horizontalCenter 
                    }
                    Item { width: 1; height: 8 }
                    Button { text: "🔍 Search Mode"; width: parent.width * 0.9; height: 45; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "search" }
                    Button { text: "📁 Folder Mode"; width: parent.width * 0.9; height: 45; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "folder" }
                    Button { text: "🏷️ Category Mode"; width: parent.width * 0.9; height: 45; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "category" }
                }

                Loader {
                    id: toolLoader
                    anchors.fill: parent
                    visible: currentMode !== "selection"
                    source: {
                        if (currentMode === "folder") return "ArchitectFolderNav.qml";
                        if (currentMode === "search") return "ArchitectSearchNav.qml";
                        if (currentMode === "category") return "ArchitectCategoryNav.qml";
                        return "";
                    }
                }
            }
        }
    }
}