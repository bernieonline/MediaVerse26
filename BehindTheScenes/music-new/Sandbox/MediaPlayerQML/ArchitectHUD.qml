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
        source: "FinishPopup.qml" 
        active: true
        z: 15000 
        
        onLoaded: {
            item.requestFullReset.connect(function() {
                console.log("♻️ HUD: Collection Saved. Re-priming for next creation...");
                
                // 1. Reset Python Logic immediately
                if (typeof architectController !== "undefined") {
                    architectController.reset_logic(); 
                }

                // 2. Clear the UI and restore the "Starter" panel
                criteriaModel.clear();
                criteriaModel.append({ 
                    "panelType": "selection", 
                    "panelValue": "", 
                    "gateValue": "NONE", 
                    "panelHits": 0, 
                    "isFilterMode": false, 
                    "isCommitted": false 
                });

                // 3. Clear the Shelf and Counters
                architectRoot.totalMatches = 0;
                shelfRepeater.model = []; 

                // 4. IMPORTANT: Close only the Popup, NOT the HUD
                if (finishPopupLoader.item) {
                    finishPopupLoader.item.visible = false;
                }
                
                // The Architect HUD stays visible, and the user is back at square one.
            });
        }
        //end onloaded
    }
    //end Loader

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
                                // Persist the filter checkbox state so buildFullRuleSet can read it later
                                criteriaModel.setProperty(pIdx, "isFilterMode", snippet.checked === true);
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
                    console.log("♻️ HUD: Resetting Scheme and Logic...");

                    // 1. Reset the UI Model to exactly one "Starter" panel
                    criteriaModel.clear();
                    criteriaModel.append({ 
                        "panelType": "selection", 
                        "panelValue": "", 
                        "gateValue": "NONE", 
                        "panelHits": 0, 
                        "isFilterMode": false, 
                        "isCommitted": false 
                    });

                    // 2. Clear the Python Logic (Zeroes out the backend lists)
                    if (typeof architectController !== "undefined") {
                        architectController.reset_logic();
                    }

                    // 3. Force the UI counters and bookshelf spines to clear
                    architectRoot.totalMatches = 0;
                    shelfRepeater.model = []; 
                    
                    // 4. Ensure the finish popup is hidden if it was open
                    if (finishPopupLoader.item) {
                        finishPopupLoader.item.visible = false;
                    }
                }
            }
            //end button

            //Button { text: "EXIT"; onClicked: architectRoot.visible = false }

            Button { 
                text: "EXIT"
                onClicked: {
                    console.log("🎬 [HUD]: Closing and re-priming Architect...");

                    // 1. Tell Python to wipe the current session data
                    if (typeof architectController !== "undefined") {
                        architectController.reset_logic();
                    }

                    // 2. Reset the UI Model to its "Factory" state
                    criteriaModel.clear();
                    criteriaModel.append({ 
                        "panelType": "selection", 
                        "panelValue": "", 
                        "gateValue": "NONE", 
                        "panelHits": 0, 
                        "isFilterMode": false, 
                        "isCommitted": false 
                    });

                    // 3. Zero out the HUD's visual properties
                    architectRoot.totalMatches = 0;
                    
                    // 4. Hide the HUD
                    architectRoot.visible = false;
                    
                    // Note: Because the criteriaModel now has 1 item, 
                    // the Repeater will naturally build 1 panel the moment it becomes visible again.
                }
            }


            //end button
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
                    var snippet = tool.buildRuleSnippet(i, logicGate, criteriaModel.get(i).isFilterMode);
                    if (snippet) {
                        snippet.checked = criteriaModel.get(i).isFilterMode;
                        rules.push(snippet);
                    }
                }
            }
        }
        return { 
            "collectionName": "New Collection",
            "rules": rules,
            // Capture the actual results from the controller
            "movies": (typeof architectController !== "undefined") ? architectController.get_current_results() : [],
            "timestamp": new Date().toISOString(),
            "type": "Architect",
            "imagePath": "None",
            "reviews": [],
            "description": ""
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
        var finalPayload = buildFullRuleSet();
        
        // --- LOG SUPPRESSION ---
        // console.log("🧬 ENRICHED DNA STRAND:\n" + JSON.stringify(finalPayload, null, 2)); 
        // -----------------------

        if (finishPopupLoader.item) {
            if (typeof finishPopupLoader.item.prepareDNA === "function") {
                finishPopupLoader.item.prepareDNA(finalPayload);
            } else {
                finishPopupLoader.item.collectionData = finalPayload;
            }
            finishPopupLoader.item.visible = true;
            finishPopupLoader.item.forceActiveFocus();
            
            // A clean, single-line confirmation instead of a wall of text
            console.log("🏁 [HUD]: Handoff complete. " + finalPayload.movies.length + " movies ready to save.");
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
    HelpSlideout {
        id: helpSlideout
        // We set z to 100 so it stays on top of everything else
        z: 100
        
        // Ensure it spans the full height of the main container
        height: parent.height 
    }
}