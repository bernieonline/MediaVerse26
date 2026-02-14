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
            isFilterMode: false;
            isCommitted: false 
        }
    }

    // --- VAULT MESSENGER FUNCTIONS ---
    function removePanel(index) {
        if (criteriaModel.count <= 1) {
            criteriaModel.setProperty(0, "panelType", "selection");
            criteriaModel.setProperty(0, "panelHits", 0);
            criteriaModel.setProperty(0, "isCommitted", false);
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

    function handleCommit(pIndex) {
        console.log("HUD: Commit Received for Panel", pIndex)
        criteriaModel.setProperty(pIndex, "isCommitted", true)
    }

    function handleFinish(pIndex)  { finishPopup.visible = true; finishPopup.forceActiveFocus(); }
    function handleShelf(pIndex)   { shelfPopup.visible = true; shelfPopup.forceActiveFocus(); }
    function handleList(pIndex)    { listPopup.visible = true; listPopup.forceActiveFocus(); }

    // --- STEP 1: THE PANEL STAGE (Z: 1) ---
    Item {
        id: stage
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: architectFooter.top
        z: 1

        Row {
            id: cardRow
            anchors.centerIn: parent
            spacing: 0 

            Repeater {
                model: criteriaModel
                delegate: Row {
                    z: 1
                    ArchitectPanel {
                        id: mainPanel
                        width: architectRoot.cardWidth
                        height: architectRoot.cardHeight
                        panelIndex: index
                        
                        hitCount: model.panelHits
                        currentMode: model.panelType
                        filterEnabled: index >= 1
                        
                        onCurrentModeChanged: architectRoot.syncPanelData(index, currentMode, hitCount)

                        // ⭐ SURGICAL FIX: Using formal function parameters to stop deprecation logs
                        onCommitRequested: function(pIndex) { architectRoot.handleCommit(pIndex) }
                        onFinishRequested: function(pIndex) { architectRoot.handleFinish(pIndex) }
                        onShelfRequested: function(pIndex) { architectRoot.handleShelf(pIndex) }
                        onListRequested: function(pIndex) { architectRoot.handleList(pIndex) }
                    }

                    // --- THE GATE ---
                    Item {
                        width: architectRoot.joinGap
                        height: architectRoot.cardHeight
                        visible: model.isCommitted 

                        Column {
                            width: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 40
                            spacing: 12

                            // AND GATE (+)
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
                                            criteriaModel.append({ 
                                                "panelType": "selection", "panelValue": "", 
                                                "gateValue": "NONE", "panelHits": 0, 
                                                "isFilterMode": false, "isCommitted": false 
                                            });
                                        }
                                    }
                                }
                            }

                            // NOT GATE (-)
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "NOT" ? "#FF0055" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "-"; color: "white"; font.pixelSize: 20; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        model.gateValue = "NOT"
                                        if (criteriaModel.count <= index + 1) {
                                            criteriaModel.append({ 
                                                "panelType": "selection", "panelValue": "", 
                                                "gateValue": "NONE", "panelHits": 0, 
                                                "isFilterMode": false, "isCommitted": false 
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- STEP 2: MASTER FOOTER (Z: 1000) ---
    Rectangle {
        id: architectFooter
        width: parent.width; height: 120; color: "#050505"
        anchors.bottom: parent.bottom; z: 1000

        Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

        // ⭐ NEW: Mode Label on the left
        Item {
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width; height: childrenRect.height
            
            Text {
                text: "ARCHITECT MODE"
                color: "gold"
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 2
                opacity: 0.9
            }
        }

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
                    criteriaModel.append({ 
                        "panelType": "selection", "panelValue": "", 
                        "gateValue": "NONE", "panelHits": 0, 
                        "isFilterMode": false, "isCommitted": false 
                    });
                    if (typeof architectController !== "undefined") architectController.reset_logic(); 
                }
            }

            Button {
                id: exitBtn
                width: 150; height: 45; text: "EXIT ARCHITECT"
                onClicked: { architectRoot.visible = false }
            }
        }
    }

    // --- STEP 3: DIMMER & POPUPS (Z: 9000 - 10000) ---
    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: "#AA000000"
        visible: finishPopup.visible || shelfPopup.visible || listPopup.visible
        z: 9000
        
        // This eats all mouse events so you can't click panels while a popup is open
        MouseArea {
            anchors.fill: parent
            enabled: parent.visible
            onClicked: {} 
        }
    }

    // --- FINISH POPUP ---
    Rectangle {
        id: finishPopup
        width: 400; height: 280; radius: 12; color: "#1A1A1A"
        border.color: "#FFD700"; border.width: 2
        anchors.centerIn: parent; visible: false; z: 10000

        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 15
            Text { text: "Save Collection"; color: "white"; font.pixelSize: 20; font.bold: true }
            TextField {
                id: collectionNameField
                width: parent.width
                placeholderText: "Enter name..."
                background: Rectangle { color: "#333"; radius: 4 }
                color: "white"
            }
            Button { 
                text: "SAVE"; width: parent.width; height: 40
                onClicked: { finishPopup.visible = false; /* logic to save here */ }
            }
            Button { 
                text: "CANCEL"; width: parent.width; height: 40
                onClicked: finishPopup.visible = false 
            }
        }
    }

    // --- SHELF POPUP ---
    Rectangle {
        id: shelfPopup
        width: 600; height: 450; radius: 12; color: "#1A1A1A"
        border.color: "#FFD700"; border.width: 2
        anchors.centerIn: parent; visible: false; z: 10000
        
        Text { anchors.centerIn: parent; text: "Shelf View Content"; color: "white" }
        Button { 
            text: "CLOSE"; anchors.bottom: parent.bottom; anchors.margins: 20; anchors.horizontalCenter: parent.horizontalCenter
            onClicked: shelfPopup.visible = false 
        }
    }

    // --- LIST POPUP ---
    Rectangle {
        id: listPopup
        width: 600; height: 450; radius: 12; color: "#1A1A1A"
        border.color: "#FFD700"; border.width: 2
        anchors.centerIn: parent; visible: false; z: 10000
        
        Text { anchors.centerIn: parent; text: "Panel Results List"; color: "white" }
        Button { 
            text: "CLOSE"; anchors.bottom: parent.bottom; anchors.margins: 20; anchors.horizontalCenter: parent.horizontalCenter
            onClicked: listPopup.visible = false 
        }
    }

    // --- VAULT CONNECTION ---
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        
        function onCountChanged(total) {
            architectRoot.totalMatches = total;
        }

        function onResultsCounted(pIndex, pCount) { 
            if (pIndex >= 0 && pIndex < criteriaModel.count) {
                criteriaModel.setProperty(pIndex, "panelHits", pCount);
            }
        }
    }
}