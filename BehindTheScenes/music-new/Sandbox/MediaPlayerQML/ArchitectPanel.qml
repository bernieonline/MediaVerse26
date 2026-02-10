import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot
    
    // --- STABLE PROPERTIES ---
    property int panelIndex: 0
    property int hitCount: 0
    property bool filterEnabled: false 
    property string currentMode: "selection" 
    
    // The "Staging Area" for results before Commit
    property var stagingResults: []

    width: 360
    height: 600

    // --- 1. THE PERFECT GLOW (Visual Gold Standard) ---
    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 18        
        spread: 0.18        
        //color: "#AAFFFFFF"    // White luminosity halo
        color: "#99FFD700"    // Goldenrod with 60% alpha for luminosity
        cornerRadius: 12
        z: 0
    }

    // --- 2. THE MAIN FRAME ---
    Rectangle {
        id: cardFrame
        // Margins allow the glow to shine outside the white border
        anchors.fill: parent
        anchors.margins: 15 
        
        color: "#1A1A1A"
        radius: 12 
        border.color: "#FFFFFF" // Pure White Border
        border.width: 1
        clip: true 
        z: 1

        // --- 3. TOOLBAR (Restored Visuals + New Help Icon) ---
        Rectangle {
            id: toolbar
            width: parent.width - 20; height: 48; color: "#2C2C2C"; radius: 8
            anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
            z: 100
            border.color: "#22FFFFFF"; border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 8
                
                Text {
                    text: "#" + (panelIndex + 1)
                    color: "white"; font.bold: true; opacity: 0.5; font.pixelSize: 12
                }

                // Filter Checkbox (Cyan accents)
                CheckBox {
                    id: filterCheckbox
                    text: "FILTER"
                    visible: currentMode !== "selection" && panelRoot.filterEnabled
                    contentItem: Text {
                        text: filterCheckbox.text
                        font.pixelSize: 10; font.bold: true
                        color: filterCheckbox.checked ? "#00F2FF" : "#88FFFFFF"
                        leftPadding: filterCheckbox.indicator.width + 4
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item { Layout.fillWidth: true } 

                // HELP BUTTON (Future Help Panel Trigger)
                Rectangle {
                    id: helpBtn
                    width: 26; height: 26; radius: 13
                    color: helpMouse.containsMouse ? "#3300F2FF" : "transparent"
                    border.color: "#00F2FF"; border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "H"; color: "white"; font.bold: true; font.pixelSize: 13
                    }

                    MouseArea {
                        id: helpMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: console.log("❓ Help requested for panel: " + panelIndex)
                    }
                    ToolTip.visible: helpMouse.containsMouse
                    ToolTip.text: "View logic documentation"
                    ToolTip.delay: 400
                }

                // GOLD MENU (M)
                Text {
                    text: "M"; font.pixelSize: 22; font.bold: true; color: "gold"
                    opacity: menuMouse.containsMouse ? 1.0 : 0.8
                    MouseArea { 
                        id: menuMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: currentMode = "selection" 
                    }
                }

                // CYAN HIT COUNT
                Text {
                    text: panelRoot.hitCount
                    color: "#00F2FF"; font.pixelSize: 18; font.bold: true
                    Layout.preferredWidth: 35; horizontalAlignment: Text.AlignHCenter
                }

                // RED CLOSE (X)
                Text {
                    text: "×"; font.pixelSize: 26; color: "#FF4444"
                    opacity: closeMouse.containsMouse ? 1.0 : 0.7
                    MouseArea { 
                        id: closeMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (typeof architectRoot !== "undefined") architectRoot.removePanel(panelIndex)
                    }
                }
            }
        }

        // --- 4. CONTENT AREA (Nav Loaders) ---
        Loader {
            id: toolLoader
            anchors.top: toolbar.bottom; anchors.bottom: footerArea.top
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 5
            z: 5
            source: {
                if (currentMode === "folder") return "ArchitectFolderNav.qml";
                if (currentMode === "search") return "ArchitectSearchNav.qml";
                if (currentMode === "category") return "ArchitectCategoryNav.qml";
                return "";
            }
            onLoaded: if (item) {
                item.parentPanel = panelRoot
                // Synchronize results from child to panelRoot
                panelRoot.hitCount = Qt.binding(function() { return item.resultsCount || 0 })
                panelRoot.stagingResults = Qt.binding(function() { return item.movieResults || [] })
            }
        }

        // --- 5. SELECTION MENU ---
        Column {
            visible: currentMode === "selection"
            anchors.centerIn: parent; spacing: 15
            z: 10
            Text { 
                text: "SELECT LOGIC"; color: "white"; font.pixelSize: 18; 
                font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.6 
            }
            Button { text: "🔍 SEARCH"; width: 180; height: 45; onClicked: currentMode = "search" }
            Button { text: "📁 FOLDER"; width: 180; height: 45; onClicked: currentMode = "folder" }
            Button { text: "🏷️ CATEGORY"; width: 180; height: 45; onClicked: currentMode = "category" }
        }

        // --- 6. FOOTER (Commit & Save Actions) ---
        Rectangle {
            id: footerArea
            width: parent.width; height: 75
            color: "#111111"
            anchors.bottom: parent.bottom
            visible: currentMode !== "selection"
            z: 100

            // Decorative separator
            Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 10

                // Commit Button (Sends to Vault)
                Button {
                    id: commitBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 40
                    contentItem: Text { 
                        text: "COMMIT"; color: "white"; font.bold: true; font.pixelSize: 11; 
                        horizontalAlignment: Text.AlignHCenter 
                    }
                    background: Rectangle {
                        color: commitBtn.pressed ? "#000" : "#2C2C2C"
                        radius: 6; border.color: "#444"; border.width: 1
                    }
                    onClicked: {
                        if (typeof architectController !== "undefined") {
                            architectController.commit_to_vault(panelIndex, currentMode, stagingResults, filterCheckbox.checked);
                        }
                    }
                }

                // Save Rules Button (Global Save)
                Button {
                    id: saveRulesBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 40
                    contentItem: Text { 
                        text: "SAVE RULES"; color: "white"; font.bold: true; font.pixelSize: 11; 
                        horizontalAlignment: Text.AlignHCenter 
                    }
                    background: Rectangle {
                        color: saveRulesBtn.pressed ? "#0044AA" : "#0066FF"
                        radius: 6; border.color: "white"; border.width: saveRulesBtn.hovered ? 1 : 0
                    }
                    onClicked: {
                        if (typeof architectController !== "undefined") {
                            architectController.save_collection_rules();
                        }
                    }
                }
            }
        }
    }
}