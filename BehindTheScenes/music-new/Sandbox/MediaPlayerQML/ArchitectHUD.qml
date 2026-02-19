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
    readonly property int joinGap: 60 
    
    property int totalMatches: 0
    property bool filterEnabled: false

    // --- POPUP INSTANCE ---
    ArchitectMoviePopup {
        id: moviePopup
    }

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
        if (index < 0 || index >= criteriaModel.count) return;
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
        if (typeof architectController !== "undefined") architectController.recalculate_foundation();
    }

    function syncPanelData(index, type, hits) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelHits", hits);
        }
    }

    function handleCommit(pIndex) {
        console.log("HUD: Attempting Commit for Index:", pIndex);
        if (pIndex >= 0 && pIndex < criteriaModel.count) {
            criteriaModel.setProperty(pIndex, "isCommitted", true);
        }
    }

    function handleShelf(pIndex) { 
        shelfPopup.visible = true; 
        shelfPopup.forceActiveFocus(); 
    }
   
    function handleList(pIdx, list, folderName) {
        var safeList = list || [];
        if (safeList.length === 0) {
            console.log("HUD: Ignoring empty list signal to prevent overwriting results.");
            return; 
        }
        var safeName = folderName || "Architect Results";
        console.log("HUD received list for index", pIdx, "count:", safeList.length);
        moviePopup.openWith(safeName, safeList);
    }

    // --- STEP 1: THE PANEL STAGE ---
    Item {
        id: stage
        anchors.fill: parent
        anchors.bottomMargin: 120
        z: 1

        Row {
            id: cardRow
            anchors.centerIn: parent
            spacing: 0 

            Repeater {
                id: cardRepeater
                model: criteriaModel

                delegate: Row {
                    id: delegateRow
                    property alias mainPanelRef: mainPanel
                    height: architectRoot.cardHeight

                    ArchitectPanel {
                        id: mainPanel
                        width: architectRoot.cardWidth
                        height: architectRoot.cardHeight
                        panelIndex: index

                        isCommitted: model.isCommitted
                        hitCount: model.panelHits
                        currentMode: model.panelType
                        filterEnabled: index >= 1

                        onCurrentModeChanged: architectRoot.syncPanelData(index, currentMode, hitCount)

                        onCommitRequested: function(pIdx, snippet) {
                            // First, update the visual commit state in the model
                            architectRoot.handleCommit(pIdx) 

                            if (typeof architectController !== "undefined") {
                                // SURGICAL FIX: A panel must select the gate to its LEFT
                                // Panel 0 (Foundation) is always NONE. 
                                // Panel 1 looks at Gate 0, Panel 2 looks at Gate 1, etc.
                                let logicGate = "NONE";
                                if (pIdx > 0) {
                                    logicGate = criteriaModel.get(pIdx - 1).gateValue;
                                }
                                
                                snippet.gate = logicGate; 
                                snippet.checked = criteriaModel.get(pIdx).isCommitted;

                                console.log("📤 HUD: Stamping Gate [" + logicGate + "] from PREVIOUS panel onto Panel " + pIdx);
                                architectController.process_commit(pIdx, JSON.stringify(snippet))
                            }
                        }

                        onFinishRequested: function(pIdx) { architectRoot.handleFinish(pIdx) }
                        onShelfRequested: function(pIdx) { architectRoot.handleShelf(pIdx) }
                        
                        onListRequested: function(pIdx, listOrName, maybeList) {
                            var actualList = (typeof listOrName === "string") ? maybeList : listOrName;
                            var actualName = (typeof listOrName === "string") ? listOrName : "Panel " + (pIdx + 1);
                            var len = (actualList && typeof actualList.length !== "undefined") ? actualList.length : 0;
                            console.log("HUD Signal Check - Name:", actualName, "Count:", len);
                            architectRoot.handleList(pIdx, actualList, actualName);
                        }
                    }

                    Item {
                        id: gateWrapper
                        width: (model.isCommitted === true) ? architectRoot.joinGap : 0
                        height: architectRoot.cardHeight
                        visible: (model.isCommitted === true)
                        clip: true

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 15

                            // AND GATE (+)
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "AND" ? "#00F2FF" : "#222"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 22; font.bold: true }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        criteriaModel.setProperty(index, "gateValue", "AND");
                                        console.log("🧬 HUD: Bridge " + index + " set to AND (Logic for Panel " + (index + 1) + ")");

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
                                color: model.gateValue === "NOT" ? "#FF0055" : "#222"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "-"; color: "white"; font.pixelSize: 22; font.bold: true }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        criteriaModel.setProperty(index, "gateValue", "NOT");
                                        console.log("🧬 HUD: Bridge " + index + " set to NOT (Logic for Panel " + (index + 1) + ")");

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

    // --- STEP 2: MASTER FOOTER ---
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
                Text { text: architectRoot.totalMatches; color: "#00F2FF"; font.pixelSize: 36; font.bold: true }
            }

            Button {
                text: "RESET SCHEME"
                onClicked: {
                    criteriaModel.clear();
                    criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE", "panelHits": 0, "isFilterMode": false, "isCommitted": false });
                    if (typeof architectController !== "undefined") architectController.reset_logic();
                }
            }

            Button { text: "EXIT"; onClicked: architectRoot.visible = false }
        }
    }

    // --- POPUPS ---
    // (Existing ArchitectMoviePopup, finishPopup, and shelfPopup logic remains in the implementation)

    function buildFullRuleSet() {
        var rules = [];
        for (var i = 0; i < cardRepeater.count; i++) {
            var delegateItem = cardRepeater.itemAt(i);
            if (!delegateItem) continue;
            var panel = delegateItem.mainPanelRef;
            if (!panel) continue;
            if (panel.toolLoader && panel.toolLoader.item) {
                var tool = panel.toolLoader.item;
                if (typeof tool.buildRuleSnippet === "function") {
                    // When building the full set, we apply the same "look left" logic
                    var logicGate = (i === 0) ? "NONE" : criteriaModel.get(i - 1).gateValue;
                    var snippet = tool.buildRuleSnippet(i, logicGate, i > 0);
                    if (snippet) {
                        snippet.checked = criteriaModel.get(i).isCommitted;
                        rules.push(snippet);
                    }
                }
            }
        }
        return { 
            "collectionName": "New Collection",
            "rules": rules,
            "timestamp": new Date().toISOString()
        };
    }

    function handleFinish(pIndex) {
        var fullSet = buildFullRuleSet();
        finishPopup.visible = true;
        finishPopup.forceActiveFocus();
    }

    // --- VAULT CONNECTIONS ---
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        function onCountChanged(total) { architectRoot.totalMatches = total; }
        function onResultsCounted(pIndex, pCount) {
            if (pIndex >= 0 && pIndex < criteriaModel.count) {
                criteriaModel.setProperty(pIndex, "panelHits", pCount);
            }
        }
    }
}