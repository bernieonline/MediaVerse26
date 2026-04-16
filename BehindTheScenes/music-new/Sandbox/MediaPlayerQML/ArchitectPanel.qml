import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot

    // --- PUBLIC INTERFACE ---
    property alias toolLoader: toolLoader 

    // --- SIGNALS ---
    signal finishRequested(int panelIndex)
    signal shelfRequested(int panelIndex)
    signal listRequested(int panelIndex, string folderName, var list)
    signal commitRequested(int pIndex, var snippet)

    // --- PROPERTIES ---
    property int panelIndex: 0
    property int hitCount: 0
    property bool filterEnabled: false 
    property string currentMode: "selection" 
    property string currentGate: "NONE"
    property bool isCommitted: false

    // --- DATA PERSISTENCE & STATE MEMORY ---
    property string selectedFolder: "Results"
    property var stagingResults: []
    
    // NEW: Memory slots to store Category intent for the "This List" Join
    property string selectedCategory: ""
    property string selectedKeyword: ""

    // Scales all selection-overlay elements proportionally to panel width (reference: 288px)
    readonly property real scaleFactor:      panelRoot.width / 288.0
    readonly property real selectBtnWidth:   Math.floor(Math.min(180 * scaleFactor, panelRoot.width - 40))
    readonly property real selectBtnHeight:  Math.floor(45 * scaleFactor)
    readonly property int  selectHeadingPx:  Math.round(18 * scaleFactor)
    readonly property int  selectBtnFontPx:  Math.round(13 * scaleFactor)

    // --- DEBUG ---
    function debugSignal(name, payload) {
        console.log("📡 PANEL " + panelIndex + " RECEIVED SIGNAL:", name, "Items:", (payload.list ? payload.list.length : 0))
    }
    
    width: 360
    height: 600

    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 18         
        spread: 0.18        
        color: "#99FFD700"
        cornerRadius: 12
        z: 0
    }

    Rectangle {
        id: cardFrame
        anchors.fill: parent
        anchors.margins: 15 
        
        color: "#1A1A1A"
        radius: 12 
        border.color: isCommitted ? "#00F2FF" : "#FFFFFF"
        border.width: isCommitted ? 2 : 1
        clip: true 
        z: 1

        // --- TOOLBAR ---
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

                // HELP BUTTON WITH TOOLTIP
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
                        //onClicked: console.log("❓ Help requested for panel: " + panelIndex)
                        onClicked: {
                            console.log("❓ Help requested for panel: " + panelIndex);
                            
                            // Use the sectionKey logic we built
                            // Panel 0 gets 'modes', Panels 1-3 get 'logic'
                            let section = (panelIndex === 0) ? "modes" : "logic";
                            
                            // We try to find the helpSlideout starting from the root of the app
                            // This 'root' should be the ID of your main container in Framework-1.qml
                            //helpSidebar.helpSlideout.openToSection(section);
                            helpSlideout.openToSection(section);
                        }
                    
                    }
                    
                    ToolTip.visible: helpMouse.containsMouse
                    ToolTip.text: "View logic documentation"
                    ToolTip.delay: 400
                }

                // MENU RESET (M)
                Text {
                    text: "M"; font.pixelSize: 22; font.bold: true; color: "gold"
                    opacity: menuMouse.containsMouse ? 1.0 : 0.8
                    MouseArea { 
                        id: menuMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            currentMode = "selection"
                            isCommitted = false
                            stagingResults = []
                            hitCount = 0
                            selectedCategory = ""
                            selectedKeyword = ""
                        }
                    }
                }

                // HIT COUNTER
                Text {
                    text: panelRoot.hitCount
                    color: "#00F2FF"; font.pixelSize: 18; font.bold: true
                    Layout.preferredWidth: 35; horizontalAlignment: Text.AlignHCenter
                }

                // CLOSE BUTTON
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

        // --- DYNAMIC CONTENT LOADER ---
        Loader {
            id: toolLoader 
            asynchronous: false
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
                
                let syncData = function(label, list) {
                    if (list && list.length > 0) {
                        console.log("✅ Panel " + panelIndex + " synchronized " + list.length + " items.");
                        panelRoot.selectedFolder = label;
                        panelRoot.stagingResults = list;
                    }
                }

                if (item.folderSelected) {
                    item.folderSelected.connect(function(p, l) { syncData(p, l) });
                }
                if (item.categorySelected) {
                    item.categorySelected.connect(function(c, l) { syncData(c, l) });
                }
            }
        }

        // --- SELECTION OVERLAY (The Master Mode Switches) ---
        Column {
            visible: currentMode === "selection"
            anchors.centerIn: parent
            spacing: Math.floor(15 * panelRoot.scaleFactor)
            z: 10

            Text {
                text: "SELECT LOGIC"
                color: "white"
                font.pixelSize: panelRoot.selectHeadingPx
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.6
            }
            Button {
                text: "🔍 SEARCH"
                width: panelRoot.selectBtnWidth; height: panelRoot.selectBtnHeight
                font.pixelSize: panelRoot.selectBtnFontPx
                onClicked: { currentMode = "search" }
            }
            Button {
                text: "📁 FOLDER"
                width: panelRoot.selectBtnWidth; height: panelRoot.selectBtnHeight
                font.pixelSize: panelRoot.selectBtnFontPx
                onClicked: { currentMode = "folder" }
            }
            Button {
                text: "🏷️ CATEGORY"
                width: panelRoot.selectBtnWidth; height: panelRoot.selectBtnHeight
                font.pixelSize: panelRoot.selectBtnFontPx
                onClicked: { currentMode = "category" }
            }
        }

        // --- FOOTER AREA ---
        Rectangle {
            id: footerArea
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 1
            height: 85
            color: "#111111"
            visible: currentMode !== "selection"
            z: 100
            radius: 12

            Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

            GridLayout {
                anchors.fill: parent; anchors.margins: 8; columns: 2; rowSpacing: 6; columnSpacing: 6

                // ⭐ COMMIT
                Button {
                    id: commitBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    enabled: hitCount > 0 && !panelRoot.isCommitted
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: commitBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: commitBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: panelRoot.isCommitted ? "COMMITTED" : "COMMIT"
                        color: panelRoot.isCommitted ? "#00F2FF" : "gold"
                        font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        let tool = toolLoader.item
                        if (tool && typeof tool.buildRuleSnippet === "function") {
                            // USE THE CHECKBOX STATE: filterCheckbox.checked
                            let snippet = tool.buildRuleSnippet(panelIndex, currentGate, filterCheckbox.checked)
                            
                            // Ensure the snippet carries the value explicitly
                            snippet.checked = filterCheckbox.checked 
                            
                            commitRequested(panelIndex, snippet)
                        }
                    }
                }

                // ⭐ FINISH
                Button {
                    id: finishBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    enabled: panelRoot.isCommitted
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: finishBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: finishBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "FINISH"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: panelRoot.finishRequested(panelRoot.panelIndex)
                }

                // ⭐ SHELF
                Button {
                    id: shelfBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    enabled: panelRoot.isCommitted
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: shelfBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: shelfBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "SHELF"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: panelRoot.shelfRequested(panelRoot.panelIndex)
                }

                // ⭐ THIS LIST (The Decision Engine)
                Button {
                    id: listBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    enabled: hitCount > 0
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: listBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: listBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "THIS LIST"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    // SURGICAL FIX: The Smart Router
                    // SURGICAL FIX: The Smart Router
                    onClicked: {
                        if (panelRoot.currentMode === "category") {
                            console.log("🎯 Category Join: Launching list from staged results...")
                            
                            // STOP calling Python here. Use the data we already saved!
                            panelRoot.listRequested(
                                panelRoot.panelIndex, 
                                panelRoot.selectedFolder, // This has the "Actors: John Wayne" label
                                panelRoot.stagingResults  // This has the 31 movies
                            )
                        } else {
                            console.log("📁 Standard Mode: Using staging results.")
                            panelRoot.listRequested(
                                panelRoot.panelIndex, 
                                panelRoot.selectedFolder, 
                                panelRoot.stagingResults
                            )
                        }
                    }
                }
            }
        }
    }

    // --- EXTERNAL CONTROLLER SYNC ---
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        function onResultsCounted(pIndex, pCount) {
            if (panelRoot.panelIndex === pIndex) {
                panelRoot.hitCount = pCount
            }
        }
    }
    // This ensures that when Python finishes the "Strip and Send", 
    // the Panel actually opens the HUD.
    // --- EXTERNAL CONTROLLER SYNC (REVISED) ---
    // This handles both Folder results and Category results
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true

        function onOnMovieListReady(pIdx, list, label) {
            if (panelRoot.panelIndex === pIdx) {
                console.log("📥 Panel " + pIdx + " syncing data for: " + label)
                
                // 1. ALWAYS store the results so the "THIS LIST" button can use them
                panelRoot.stagingResults = list
                panelRoot.selectedFolder = label 

                // 2. THE SMART ROUTER
                if (panelRoot.currentMode === "folder") {
                    // FOLDERS: Keep the instant-pop behavior you like
                    console.log("📁 Folder Mode: Auto-launching popup.")
                    panelRoot.listRequested(pIdx, label, list)
                } else {
                    // CATEGORIES: Stay silent! Just wait for the button click.
                    console.log("🛡️ Category Mode: Data cached. Suppression active.")
                }
            }
        }
    }
    
}