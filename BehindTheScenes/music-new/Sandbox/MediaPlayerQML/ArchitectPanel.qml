import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot

    // --- PUBLIC INTERFACE ---
    // This alias is the "bridge" that allows ArchitectHUD to see the tools
    property alias toolLoader: toolLoader 

    // --- SIGNALS ---
    signal finishRequested(int panelIndex)
    signal shelfRequested(int panelIndex)
    
    signal listRequested(int panelIndex, var list)


    signal commitRequested(int pIndex, var snippet)

    property int panelIndex: 0
    property int hitCount: 0
    property bool filterEnabled: false 
    property string currentMode: "selection" 
    property var stagingResults: []
    property string currentGate: "NONE"

    // Track whether this panel has been committed
    property bool isCommitted: false

    // --- DEBUG: Monitor incoming signals from MODE files ---
    function debugSignal(name, payload) {
        console.log("📡 PANEL " + panelIndex + " RECEIVED SIGNAL:", name, JSON.stringify(payload))
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
                        onClicked: console.log("❓ Help requested for panel: " + panelIndex)
                    }
                    ToolTip.visible: helpMouse.containsMouse
                    ToolTip.text: "View logic documentation"
                    ToolTip.delay: 400
                }

                Text {
                    text: "M"; font.pixelSize: 22; font.bold: true; color: "gold"
                    opacity: menuMouse.containsMouse ? 1.0 : 0.8
                    MouseArea { 
                        id: menuMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            currentMode = "selection"
                            isCommitted = false
                        }
                    }
                }

                Text {
                    text: panelRoot.hitCount
                    color: "#00F2FF"; font.pixelSize: 18; font.bold: true
                    Layout.preferredWidth: 35; horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: "×"; font.pixelSize: 26; color: "#FF4444"
                    opacity: closeMouse.containsMouse ? 1.0 : 0.7
                    MouseArea { 
                        id: closeMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (typeof architectRoot !== "undefined") architectRoot.removePanel(panelIndex)
                    }
                }
            }
        } // End of Toolbar

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
                console.log("🛠️ Tool Loaded: " + currentMode + " linked to Panel " + panelIndex)

                // --- CONNECT MODE SIGNALS TO DEBUG LOGGER ---
                if (item.folderSelected) {
                    item.folderSelected.connect(function(folderPath, list) {
                        debugSignal("folderSelected", { folderPath: folderPath, list: list })
                    })
                }
                if (item.categorySelected) {
                    item.categorySelected.connect(function(categoryName, list) {
                        debugSignal("categorySelected", { categoryName: categoryName, list: list })
                    })
                }
                if (item.searchSelected) {
                    item.searchSelected.connect(function(query, list) {
                        debugSignal("searchSelected", { query: query, list: list })
                    })
                }
            }
        }

        Column {
            visible: currentMode === "selection"
            anchors.centerIn: parent; spacing: 15
            z: 10
            Text { 
                text: "SELECT LOGIC"; color: "white"; font.pixelSize: 18; 
                font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.6 
            }
            Button { text: "🔍 SEARCH"; width: 180; height: 45; onClicked: currentMode = "search" }
            Button { text: "📁 FOLDER"; width: 180; height: 45; onClicked: currentMode = "folder" }
            Button { text: "🏷️ CATEGORY"; width: 180; height: 45; onClicked: currentMode = "category" }
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
                anchors.fill: parent
                anchors.margins: 8
                columns: 2
                rowSpacing: 6
                columnSpacing: 6

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
                        console.log("📤 COMMIT REQUESTED from panel", panelRoot.panelIndex)
                        let tool = toolLoader.item
                        if (tool && typeof tool.buildRuleSnippet === "function") {
                            let snippet = tool.buildRuleSnippet(panelIndex, currentGate, true)
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

                // ⭐ THIS LIST
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
                    onClicked: panelRoot.listRequested(panelRoot.panelIndex, panelRoot.stagingResults)
                }
            }
        }
    }

    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        
        function onResultsCounted(pIndex, pCount) {
            if (panelRoot.panelIndex === pIndex) {
                panelRoot.hitCount = pCount
            }
        }
    }
}