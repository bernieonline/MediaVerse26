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
   
    // FIXED: Unified function with explicit safety checks
    function handleList(pIdx, list, folderName) {
        var safeList = list || [];

        if (safeList.length === 0) {
            console.log("HUD: Ignoring empty list signal to prevent overwriting results.");
            return; 
        }

        var safeName = folderName || "Architect Results";
        
        console.log("HUD received list for index", pIdx, "count:", safeList.length);
        
        // Open the popup using the correct ID and parameters
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
                        }

                        onFinishRequested: function(pIdx) { architectRoot.handleFinish(pIdx) }
                        onShelfRequested: function(pIdx) { architectRoot.handleShelf(pIdx) }
                        
                        // SURGICAL FIX: Handling parameter swap from Panel signal
                        onListRequested: function(pIdx, listOrName, maybeList) {
                            // If the 2nd arg is a string, it's the folder name (e.g., "Caine")
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

                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "AND" ? "#00F2FF" : "#222"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 22; font.bold: true }

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

                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "NOT" ? "#FF0055" : "#222"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "-"; color: "white"; font.pixelSize: 22; font.bold: true }

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

    // --- FINISH POPUP ---
    Rectangle {
        id: finishPopup
        anchors.centerIn: parent
        width: 420; height: 240
        radius: 18
        visible: false
        color: "#111111EE"
        border.color: "#FFD700"
        border.width: 2
        z: 9999

        RectangularGlow {
            anchors.fill: parent
            glowRadius: 28
            spread: 0.25
            color: "#FFD700AA"
            cornerRadius: 18
        }

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "FINISH LOGIC"
                font.pixelSize: 22
                font.bold: true
                color: "gold"
            }

            Text {
                text: "Apply all committed logic and close Architect."
                color: "white"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "CONFIRM"
                onClicked: {
                    finishPopup.visible = false
                    architectRoot.visible = false
                }
            }

            Button {
                text: "CANCEL"
                onClicked: finishPopup.visible = false
            }
        }
    }

    // --- SHELF POPUP ---
    Rectangle {
        id: shelfPopup
        anchors.centerIn: parent
        width: 420; height: 240
        radius: 18
        visible: false
        color: "#111111EE"
        border.color: "#FFD700"
        border.width: 2
        z: 9999

        RectangularGlow {
            anchors.fill: parent
            glowRadius: 28
            spread: 0.25
            color: "#FFD700AA"
            cornerRadius: 18
        }

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "SHELF RESULTS"
                font.pixelSize: 22
                font.bold: true
                color: "gold"
            }

            Text {
                text: "Save this logic result to your Shelf."
                color: "white"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "SAVE TO SHELF"
                onClicked: {
                    shelfPopup.visible = false
                    if (typeof architectController !== "undefined")
                        architectController.save_to_shelf()
                }
            }

            Button {
                text: "CANCEL"
                onClicked: shelfPopup.visible = false
            }
        }
    }

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
                    var currentGate = criteriaModel.get(i).gateValue;
                    var snippet = tool.buildRuleSnippet(i, currentGate, i > 0);
                    if (snippet) {
                        snippet.checked = true;
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