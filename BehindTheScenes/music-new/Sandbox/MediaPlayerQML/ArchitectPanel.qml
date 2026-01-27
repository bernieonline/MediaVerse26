import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot
    
    // --- PROPERTIES ---
    property int panelIndex: 0
    property int hitCount: 0
    property string currentMode: "selection" 
    property string panelValue: ""
    property string nextGate: "NONE" 

    width: 360
    height: 600

    FontLoader { id: iconFont; source: paths.font_path || "" }

    // --- GLOW (Behind the Frame) ---
    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 18; spread: 0.15; color: "#AAFFFFFF"; cornerRadius: 12; z: 0
    }

    // --- MAIN FRAME ---
    Rectangle {
        id: cardFrame
        anchors.fill: parent
        color: "#1A1A1A"; radius: 12; border.color: "#FFFFFF"; border.width: 1; clip: true; z: 1

        // 1. FLOATING TOOLBAR
        Rectangle {
            id: toolbar
            width: parent.width - 24 
            height: 48 
            color: "#2C2C2C" 
            radius: 8
            anchors {
                top: parent.top
                topMargin: 12
                horizontalCenter: parent.horizontalCenter
            }
            z: 100
            border.color: "#22FFFFFF"; border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15; anchors.rightMargin: 15
                spacing: 15 

                Text {
                    text: "#" + (panelIndex + 1)
                    color: "white"; font.bold: true; font.pixelSize: 12; opacity: 0.5
                }

                Item { Layout.fillWidth: true } 

                // BACK
                Text {
                    text: iconFont.status === FontLoader.Ready ? "\uf060" : "←"
                    font.family: iconFont.name; font.pixelSize: 20; color: "white"
                    opacity: currentMode !== "selection" ? 1.0 : 0.2
                    MouseArea {
                        id: backMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: { currentMode = "selection"; panelValue = ""; nextGate = "NONE" }
                    }
                    ToolTip { visible: backMA.containsMouse; text: "Back"; font.pixelSize: 16 }
                }

                // HOME
                Text {
                    text: iconFont.status === FontLoader.Ready ? "\uf015" : "H"
                    font.family: iconFont.name; font.pixelSize: 20; color: "white"
                    MouseArea {
                        id: homeMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: architectRoot.updateRule(panelIndex, currentMode, "")
                    }
                    ToolTip { visible: homeMA.containsMouse; text: "Reset Mode"; font.pixelSize: 16 }
                }

                // MODE (Gold M)
                Text {
                    text: "M"; font.pixelSize: 22; font.bold: true; color: "gold"
                    MouseArea {
                        id: modeMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: { currentMode = "selection"; architectRoot.updateRule(panelIndex, "selection", "") }
                    }
                    ToolTip { visible: modeMA.containsMouse; text: "Main Menu"; font.pixelSize: 16 }
                }

                // --- HIT COUNT (Fixed Layout Property) ---
                Rectangle {
                    color: "transparent"
                    Layout.preferredWidth: 60 // Buffed to 60 for even more shoulder room
                    Layout.preferredHeight: parent.height // Fixed: changed from 'height'
                    
                    Text {
                        anchors.centerIn: parent
                        text: panelRoot.hitCount
                        color: "#00F2FF"; font.pixelSize: 18; font.bold: true
                    }
                    
                    MouseArea { id: countMA; anchors.fill: parent; hoverEnabled: true }
                    ToolTip { visible: countMA.containsMouse; text: "Matching Items"; font.pixelSize: 16 }
                }

                // CLOSE (Red X)
                Text {
                    text: iconFont.status === FontLoader.Ready ? "\uf00d" : "×"
                    font.family: iconFont.name; font.pixelSize: 24; color: "#FF4444"
                    MouseArea {
                        id: closeMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: architectRoot.removePanel(panelIndex)
                    }
                    ToolTip { visible: closeMA.containsMouse; text: "Close"; font.pixelSize: 16 }
                }
            }
        }

        // 2. CONTENT AREA
        Item {
            id: contentContainer
            anchors.top: toolbar.bottom; anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 10

            Column {
                visible: currentMode === "selection"
                anchors.centerIn: parent 
                width: parent.width; spacing: 15
                
                Text { 
                    text: "Select Logic"; color: "white"; font.pixelSize: 22; 
                    font.bold: true; anchors.horizontalCenter: parent.horizontalCenter 
                }
                
                Item { width: 1; height: 10 }
                
                Button { text: "🔍 Search Mode"; width: parent.width * 0.8; height: 55; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "search" }
                Button { text: "📁 Folder Mode"; width: parent.width * 0.8; height: 55; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "folder" }
                Button { text: "🏷️ Category Mode"; width: parent.width * 0.8; height: 55; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "category" }
            }

            Loader {
                id: toolLoader; anchors.fill: parent; visible: currentMode !== "selection"
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