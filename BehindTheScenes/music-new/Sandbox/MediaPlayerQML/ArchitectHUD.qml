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

                                // REMOVE OR COMMENT OUT THE snippet.checked OVERRIDE
                                // It is now already set correctly by the Panel's toolLoader
                                
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

        // NEW: THE BOOKSHELF ROW
        Row {
            id: spineRow
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            
            Repeater {
                id: shelfRepeater  // This is the NEW ID for the spines
                model: (typeof architectController !== "undefined") ? architectController.get_bookshelf_list() : []
                
                delegate: Rectangle {
                    width: 8   // Thin like a book spine
                    height: 60 // Shorter than the footer
                    color: modelData.spineColor
                    radius: 1
                    
                    ToolTip.visible: shelfMouse.containsMouse
                    ToolTip.text: modelData.title

                    MouseArea {
                        id: shelfMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }


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

    // --- UPDATED HUD LOGIC ---
    function handleShelf(pIndex) { 
        console.log("🚀 HUD: Requesting shelf build for panel " + pIndex);
        
        // Check if the controller exists, then call the Python Slot
        if (typeof architectController !== "undefined") {
            architectController.handle_shelf_request(pIndex);
        } else {
            console.log("❌ HUD Error: architectController is not available.");
        }
    }

    
    function handleFinish(pIndex) {
        console.log("🏁 HUD: Finalizing collection with Metadata...");
        
        // 1. Get the base rules
        var finalPayload = buildFullRuleSet();
        
        // 2. Append the additional Key/Value pairs (The "Tweak")
        finalPayload.type = "Architect";
        finalPayload.imagePath = "None"; // Placeholder
        finalPayload.reviews = [];       // Array for future text snippets
        finalPayload.description = "";   // Will be filled by the Popup
        
        console.log("🧬 ENRICHED DNA STRAND:\n" + JSON.stringify(finalPayload, null, 2));

        if (finishPopup) {
            // Hand the enriched object to the popup
            finishPopup.collectionData = finalPayload; 
            finishPopup.visible = true;
            finishPopup.forceActiveFocus();
        }
    }

    // --- VAULT CONNECTIONS ---
    // --- VAULT CONNECTIONS ---
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true

        // Use the signal name directly as a property (no 'function' keyword)
        onCountChanged: (total) => { 
            console.log("🎯 [QML HUD] Signal Received! Value: " + total);
            architectRoot.totalMatches = total; 
        }

        // Fixes the "Duplicate method name" crash
        onBookshelfListChanged: {
            console.log("📖 HUD: Refreshing bookshelf spines...");
            shelfRepeater.model = architectController.get_bookshelf_list();
        }

        onResultsCounted: (pIndex, pCount) => {
            if (pIndex >= 0 && pIndex < criteriaModel.count) {
                criteriaModel.setProperty(pIndex, "panelHits", pCount);
            }
        }
    }
}