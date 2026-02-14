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
            criteriaModel.setProperty(0, "panelType", "selection");
            criteriaModel.setProperty(0, "panelHits", 0);
            if (typeof architectController !== "undefined") architectController.reset_logic();
            return;
        }
        criteriaModel.remove(index);
        
        if (criteriaModel.count > 0) {
            criteriaModel.setProperty(criteriaModel.count - 1, "gateValue", "NONE");
        }
        
        if (typeof architectController !== "undefined") {
            architectController.recalculate_foundation();
        }
    }

    function syncPanelData(index, type, hits) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelHits", hits);
        }
    }

    // --- STEP 2: NEW HUD HANDLER FUNCTIONS ---
    function handleCommit(index)  { console.log("HUD: Commit", index) }
    function handleFinish(index)  { console.log("HUD: Finish", index) }
    function handleShelf(index)   { console.log("HUD: Shelf", index) }
    function handleList(index)    { console.log("HUD: List", index) }

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
                        
                        hitCount: model.panelHits
                        currentMode: model.panelType
                        filterEnabled: index >= 1
                        
                        onCurrentModeChanged: architectRoot.syncPanelData(index, currentMode, hitCount)

                        // --- STEP 2: NEW SIGNAL HANDLERS ---
                        onCommitRequested: architectRoot.handleCommit(panelIndex)
                        onFinishRequested: architectRoot.handleFinish(panelIndex)
                        onShelfRequested: architectRoot.handleShelf(panelIndex)
                        onListRequested: architectRoot.handleList(panelIndex)
                    }

                    // --- THE GATE (The Joiner) ---
                    Item {
                        width: architectRoot.joinGap
                        height: architectRoot.cardHeight
                        visible: index < 3 && mainPanel.currentMode !== "selection"

                        Column {
                            width: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 40
                            spacing: 12

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
                                    }
                                }
                            }

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
                }
            }
        }
    }

    // --- VAULT CONNECTION ---
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        
        function onCountChanged(total) {
            architectRoot.totalMatches = total;
        }

        function onResultsCounted(panelIndex, panelCount) { 
            if (panelIndex >= 0 && panelIndex < criteriaModel.count) {
                criteriaModel.setProperty(panelIndex, "panelHits", panelCount);
            }
        }
    }
}