import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: architectRoot 
    anchors.fill: parent
    color: "#F2050505"
    visible: false
    z: 5000
    clip: true

    // --- DIMENSIONS ---
    readonly property int cardWidth: 360    
    readonly property int cardHeight: 600   
    readonly property int joinGap: 40 
    
    property int totalMatches: 0
    property bool filterEnabled: false

    // --- LOGIC MODEL ---
    ListModel {
        id: criteriaModel
        ListElement { 
            panelType: "selection"; 
            panelValue: ""; 
            gateValue: "NONE"; 
            panelHits: 0; 
            isFilterMode: false 
        }
    }

    // --- VAULT MESSENGER FUNCTIONS ---
    
    function removePanel(index) {
        if (criteriaModel.count <= 1) {
            // Reset the only panel instead of deleting it
            criteriaModel.setProperty(0, "panelType", "selection");
            criteriaModel.setProperty(0, "panelHits", 0);
            if (typeof architectController !== "undefined") architectController.reset_logic();
            return;
        }
        criteriaModel.remove(index);
        
        // Ensure the new last panel has no trailing gate
        if (criteriaModel.count > 0) {
            criteriaModel.setProperty(criteriaModel.count - 1, "gateValue", "NONE");
        }
        
        // Tell Python to re-evaluate the vault based on the remaining slots
        if (typeof architectController !== "undefined") {
            architectController.recalculate_foundation();
        }
    }

    // This function now primarily updates the UI Model; 
    // The "ArchitectPanel.qml" itself handles the direct Python Vault commit.
    function syncPanelData(index, type, hits) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelHits", hits);
        }
    }

    Item {
        id: stage
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: architectFooter.top

        Row {
            id: cardRow
            anchors.centerIn: parent
            spacing: 0 

            Repeater {
                model: criteriaModel
                delegate: Row {
                    ArchitectPanel {
                        id: mainPanel
                        width: architectRoot.cardWidth
                        height: architectRoot.cardHeight
                        panelIndex: index
                        
                        // Syncing properties from the vault-fed model
                        hitCount: model.panelHits
                        currentMode: model.panelType
                        
                        // Panel 0 is always the Foundation (No Filter Toggle)
                        filterEnabled: index >= 1
                        
                        // When the Panel commits to the Vault, update our local UI model
                        onCurrentModeChanged: architectRoot.syncPanelData(index, currentMode, hitCount)
                    }

                    // --- THE GATE (The Joiner) ---
                    Item {
                        width: architectRoot.joinGap
                        height: architectRoot.cardHeight
                        // Only show gates between panels, max 4 panels total
                        visible: index < 3 && mainPanel.currentMode !== "selection"

                        Column {
                            width: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 40
                            spacing: 12

                            // ADD GATE (Union)
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "AND" ? "#00F2FF" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 20; font.bold: true }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        model.gateValue = "AND";
                                        if (criteriaModel.count <= index + 1) {
                                            criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE", "panelHits": 0, "isFilterMode": false });
                                        }
                                        // Update Python if needed (Handled by Panel Commit usually)
                                    }
                                }
                            }

                            // SUBTRACT GATE (Not yet implemented in vault, but UI ready)
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "NOT" ? "#FF0055" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "-"; color: "white"; font.pixelSize: 20; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: model.gateValue = "NOT"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- MASTER FOOTER ---
    Rectangle {
        id: architectFooter
        width: parent.width; height: 120; color: "#050505"
        anchors.bottom: parent.bottom; z: 1000

        Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

        Row {
            anchors.centerIn: parent; spacing: 60

            Column {
                spacing: 2
                Text { text: "CUMULATIVE MATCHES"; color: "#88FFFFFF"; font.pixelSize: 11; font.letterSpacing: 1 }
                Text { 
                    text: architectRoot.totalMatches
                    color: "#00F2FF"; font.pixelSize: 36; font.bold: true 
                }
            }

            Button {
                id: resetBtn
                width: 150; height: 45; text: "RESET SCHEME"
                onClicked: {
                    criteriaModel.clear();
                    criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE", "panelHits": 0, "isFilterMode": false });
                    if (typeof architectController !== "undefined") architectController.reset_logic(); 
                }
            }

            Button {
                id: exitBtn
                width: 150; height: 45; text: "EXIT ARCHITECT"
                onClicked: {
                    architectRoot.visible = false
                    // We don't necessarily reset on exit now, allowing "Longevity"
                }
            }
        }
    }

    // --- VAULT CONNECTION ---
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        
        // Listen for the Vault's recalculated total
        function onCountChanged(total) {
            architectRoot.totalMatches = total;
        }

        // Listen for individual panel updates if Python pushes them back
        function onResultsCounted(panelIndex, panelCount) { 
            if (panelIndex >= 0 && panelIndex < criteriaModel.count) {
                criteriaModel.setProperty(panelIndex, "panelHits", panelCount);
            }
        }
    }
}