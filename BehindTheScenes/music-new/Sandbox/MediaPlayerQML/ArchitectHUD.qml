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


    // --- POPUP INSTANCES ---
    ArchitectMoviePopup { id: moviePopup }

    // SURGICAL FIX: We use a Loader here. This prevents the "Type ArchitectHUD unavailable" 
    // crash by isolating the Finish Dialog from the main startup sequence.
    Loader {
        id: finishPopupLoader
        anchors.fill: parent
        source: "FinishPopup.qml" // Updated to match your renamed file
        asynchronous: false 
        active: true
        z: 15000 // Higher than the HUD's z: 5000 and the footer's z: 1000
        onStatusChanged: {
            if (status === Loader.Error) {
                console.log("‼️ LOADER ERROR: " + errorString());
            } else if (status === Loader.Ready) {
                console.log("✅ LOADER READY: FinishPopup is live.");
            }
        }
    }

    // This alias ensures all your functions below can still use "finishPopup"
    property var finishPopup: finishPopupLoader.item

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
        console.log("HUD: Shelf requested for index " + pIndex + " (Shelf Logic Disabled)");
    }
   
    function handleList(pIdx, list, folderName) {
        var safeList = list || [];
        if (safeList.length === 0) return;
        var safeName = folderName || "Architect Results";
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
                            architectRoot.handleCommit(pIdx) 
                            if (typeof architectController !== "undefined") {
                                let logicGate = (pIdx > 0) ? criteriaModel.get(pIdx - 1).gateValue : "NONE";
                                snippet.gate = logicGate; 
                                snippet.checked = criteriaModel.get(pIdx).isCommitted;
                                architectController.process_commit(pIdx, JSON.stringify(snippet))
                            }
                        }

                        onFinishRequested: function(pIdx) { architectRoot.handleFinish(pIdx) }
                        onShelfRequested: function(pIdx) { architectRoot.handleShelf(pIdx) }
                        
                        onListRequested: function(pIdx, listOrName, maybeList) {
                            var actualList = (typeof listOrName === "string") ? maybeList : listOrName;
                            var actualName = (typeof listOrName === "string") ? listOrName : "Panel " + (pIdx + 1);
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

                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "AND" ? "#00F2FF" : "#222"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 22; font.bold: true }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        criteriaModel.setProperty(index, "gateValue", "AND");
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

                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "NOT" ? "#FF0055" : "#222"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "-"; color: "white"; font.pixelSize: 22; font.bold: true }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        criteriaModel.setProperty(index, "gateValue", "NOT");
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

    // --- FINISH LOGIC ---
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
        console.log("🏁 DNA Finalized: " + JSON.stringify(fullSet));
        
        // Safety: If for some reason the loader isn't active, kick it
        if (finishPopupLoader.status !== Loader.Ready) {
            console.log("🛠️ HUD: Force-loading Dialog...");
            finishPopupLoader.active = true;
        }

        var popup = finishPopupLoader.item;
        
        if (popup) {
            if (typeof popup.prepareDNA === "function") {
                popup.prepareDNA(fullSet);
            }
            popup.visible = true; 
            popup.forceActiveFocus();
        } else {
            // This is the error you are seeing. 
            // It means "ArchtectFinishDialog.qml" is likely missing or has a typo in the filename.
            console.log("⚠️ HUD: Popup item NOT READY. Check filename: " + finishPopupLoader.source);
        }
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