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
    
    // The "Staging Area" - purely for the UI to show what's happening
    property var stagingResults: []
    property bool isFilterMode: filterCheckbox.checked

    width: 360
    height: 600

    // --- MAIN FRAME ---
    Rectangle {
        id: cardFrame
        anchors.fill: parent
        color: "#1A1A1A"; radius: 12; border.color: "#FFFFFF"; border.width: 1; clip: true; z: 1

        // 1. TOOLBAR
        Rectangle {
            id: toolbar
            width: parent.width - 24; height: 48; color: "#2C2C2C"; radius: 8
            anchors { top: parent.top; topMargin: 12; horizontalCenter: parent.horizontalCenter }
            z: 100

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                
                Text {
                    text: "PANEL " + (panelIndex + 1) + " [" + panelRoot.hitCount + "]"
                    color: "white"; font.bold: true; opacity: 0.6
                }

                CheckBox {
                    id: filterCheckbox
                    text: "FILTER"
                    visible: currentMode !== "selection"
                    onCheckedChanged: {
                        // Immediately update the vault's filter state for this index
                        if (typeof architectController !== "undefined") {
                            architectController.update_vault_filter(panelIndex, checked)
                        }
                    }
                }

                Item { Layout.fillWidth: true } 

                // Reset Mode Button
                Button {
                    text: "↺"
                    onClicked: currentMode = "selection"
                }
            }
        }

        // 2. NAV LOADERS (The Input Devices)
        Loader {
            id: toolLoader
            anchors.top: toolbar.bottom; anchors.bottom: footerArea.top
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 10
            source: {
                if (currentMode === "folder") return "ArchitectFolderNav.qml";
                if (currentMode === "search") return "ArchitectSearchNav.qml";
                if (currentMode === "category") return "ArchitectCategoryNav.qml";
                return "";
            }
            onLoaded: {
                if (item) {
                    item.parentPanel = panelRoot
                    // Update our staging count as the user interacts
                    panelRoot.hitCount = Qt.binding(function() { return item.resultsCount || 0 })
                    panelRoot.stagingResults = Qt.binding(function() { return item.movieResults || [] })
                }
            }
        }

        // 3. SELECTION MENU (Visible only when no tool is loaded)
        Column {
            visible: currentMode === "selection"
            anchors.centerIn: parent; spacing: 10
            Button { text: "🔍 SEARCH"; width: 200; onClicked: currentMode = "search" }
            Button { text: "📁 FOLDER"; width: 200; onClicked: currentMode = "folder" }
            Button { text: "🏷️ CATEGORY"; width: 200; onClicked: currentMode = "category" }
        }

        // 4. FOOTER (The Postman)
        Rectangle {
            id: footerArea
            width: parent.width; height: 70; color: "#222"
            anchors.bottom: parent.bottom
            visible: currentMode !== "selection"

            Button {
                anchors.centerIn: parent
                width: parent.width - 40; height: 40
                text: "COMMIT TO VAULT"
                
                onClicked: {
                    console.log("📨 [UI] Sending Panel " + panelIndex + " to Vault...");
                    
                    // Flatten nested arrays if they exist
                    var cleanList = [];
                    if (Array.isArray(panelRoot.stagingResults)) {
                        cleanList = (panelRoot.stagingResults.length === 1 && Array.isArray(panelRoot.stagingResults[0])) 
                                    ? panelRoot.stagingResults[0] 
                                    : panelRoot.stagingResults;
                    }

                    if (typeof architectController !== "undefined") {
                        // DEPOSIT INTO THE PYTHON VAULT
                        architectController.commit_to_vault(
                            panelIndex, 
                            currentMode, 
                            cleanList, 
                            filterCheckbox.checked
                        );
                    }
                }
            }
        }
    }
}