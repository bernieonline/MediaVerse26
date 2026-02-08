import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot
    
    // --- PROPERTIES ---
    property int panelIndex: 0
    property int hitCount: 0
    property string currentMode: "selection" 
    property string panelValue: ""
    property string nextGate: "NONE" 
    
    // THE HOLDING TANK: Stores results from Nav tools before 'COMMIT' is clicked
    property var currentResults: []
    property bool isNotMode: false 

    // Logic Flags
    property bool filterEnabled: false 
    readonly property bool isFilterActive: filterCheckbox.checked

    // Signal for the HUD to listen to
    signal filterChanged()

    width: 360
    height: 600

    // --- ICON LOADER ---
    FontLoader { 
        id: iconFont
        source: {
            var p = "";
            if (typeof paths !== 'undefined' && paths.font_path) {
                p = paths.font_path;
            } else if (typeof _paths !== 'undefined' && _paths.fonts) {
                p = _paths.fonts;
            }
            if (p === "") return "";
            if (p.indexOf(":") !== -1 && p.indexOf("file:///") === -1) {
                return "file:///" + p.replace(/\\/g, "/");
            }
            return p;
        }
    }

    // --- GLOW (Behind the Frame) ---
    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 18; spread: 0.15; color: "#AAFFFFFF"; cornerRadius: 12; z: 0
    }

    // --- MAIN FRAME ---
    Rectangle {
        id: cardFrame
        anchors.fill: parent
        color: "#1A1A1A"; radius: 12; border.color: "#FFFFFF"; border.width: 1; clip: true; z: 1

        // 1. PERSISTENT TOOLBAR (Top)
        Rectangle {
            id: toolbar
            width: parent.width - 24 
            height: 48 
            color: "#2C2C2C" 
            radius: 8
            anchors {
                top: parent.top
                topMargin: 12
                horizontalCenter: parent.horizontalCenter
            }
            z: 100
            border.color: "#22FFFFFF"; border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 10 

                Text {
                    // Re-displays the live hitCount in the header
                    text: "#" + (panelIndex + 1) + " (" + panelRoot.hitCount + ")"
                    color: "white"; font.bold: true; font.pixelSize: 12; opacity: 0.5
                }

                CheckBox {
                    id: filterCheckbox
                    text: "FILTER"
                    visible: panelRoot.filterEnabled 
                    Layout.alignment: Qt.AlignVCenter
                    
                    contentItem: Text {
                        text: filterCheckbox.text
                        font.pixelSize: 10; font.bold: true
                        color: filterCheckbox.checked ? "#00F2FF" : "#88FFFFFF"
                        leftPadding: filterCheckbox.indicator.width + 4
                        verticalAlignment: Text.AlignVCenter
                    }
                    onCheckedChanged: panelRoot.filterChanged()
                }

                Item { Layout.fillWidth: true } 

                Text {
                    text: "H"
                    font.pixelSize: 20; font.bold: true; 
                    color: helpMA.containsMouse ? "#3498db" : "white"
                    MouseArea {
                        id: helpMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: console.log("❓ [UI] Opening Help Overlay...")
                    }
                    ToolTip { visible: helpMA.containsMouse; text: "How this system works"; font.pixelSize: 14 }
                }

                Text {
                    text: "M"; font.pixelSize: 22; font.bold: true; color: "gold"
                    MouseArea {
                        id: modeMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: { 
                            currentMode = "selection"; 
                            panelRoot.hitCount = 0;
                            panelRoot.currentResults = [];
                        }
                    }
                }

                Text {
                    text: iconFont.status === FontLoader.Ready ? "\uf00d" : "×"
                    font.family: iconFont.name; font.pixelSize: 20; color: "#FF4444"
                    MouseArea {
                        id: closeMA; anchors.fill: parent; hoverEnabled: true
                        onClicked: architectRoot.removePanel(panelIndex)
                    }
                }
            }
        }

        // 2. CONTENT AREA (Middle)
        Item {
            id: contentContainer
            anchors.top: toolbar.bottom
            anchors.bottom: footerArea.top 
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 10

            Column {
                visible: currentMode === "selection"
                anchors.centerIn: parent 
                width: parent.width; spacing: 15
                
                Text { 
                    text: "Select Logic"; color: "white"; font.pixelSize: 22; 
                    font.bold: true; anchors.horizontalCenter: parent.horizontalCenter 
                }
                
                Button { text: "🔍 Search Mode"; width: parent.width * 0.8; height: 55; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "search" }
                Button { text: "📁 Folder Mode"; width: parent.width * 0.8; height: 55; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "folder" }
                Button { text: "🏷️ Category Mode"; width: parent.width * 0.8; height: 55; anchors.horizontalCenter: parent.horizontalCenter; onClicked: currentMode = "category" }
            }

            Loader {
                id: toolLoader
                anchors.fill: parent
                visible: currentMode !== "selection"
                source: {
                    if (currentMode === "folder") return "ArchitectFolderNav.qml";
                    if (currentMode === "search") return "ArchitectSearchNav.qml";
                    if (currentMode === "category") return "ArchitectCategoryNav.qml";
                    return "";
                }
                onLoaded: {
                    if (item) {
                        item.parentPanel = panelRoot
                        // Binds the live results from Nav tools to the panel
                        panelRoot.hitCount = Qt.binding(function() { return item.resultsCount || 0 })
                        panelRoot.currentResults = Qt.binding(function() { return item.movieResults || [] })
                    }
                }
            }
        }

        // 3. PERSISTENT FOOTER
        Rectangle {
            id: footerArea
            width: parent.width; height: 70; color: "#252525"
            anchors.bottom: parent.bottom
            visible: currentMode !== "selection"
            z: 200

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 12

                Button {
                    id: saveBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 40
                    contentItem: Text { text: "SAVE"; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { color: saveBtn.pressed ? "#1b4f72" : "#2980b9"; radius: 4; border.color: "white" }
                    onClicked: console.log("💾 [UI] Save Dialog Triggered")
                }

                Button {
                    id: commitBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 40
                    contentItem: Text { text: "COMMIT"; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { color: commitBtn.pressed ? "#444" : "#111"; radius: 4; border.color: "#00F2FF" }

                    onClicked: {
                        console.log("🚀 [UI] Committing Panel " + panelRoot.panelIndex);
                        
                        if (typeof architectController !== "undefined") {
                            // FIXED: Passing all 5 arguments to Python
                            architectController.commit_panel_logic(
                                panelRoot.panelIndex,
                                panelRoot.currentMode,
                                panelRoot.currentResults,
                                "ADD", 
                                filterCheckbox.checked
                            );
                        }

                        if (typeof architectRoot !== "undefined") {
                            architectRoot.updateRule(
                                panelRoot.panelIndex, 
                                panelRoot.currentMode, 
                                panelRoot.currentResults, 
                                filterCheckbox.checked
                            );
                        }
                    }
                }
            }
        }
    }
}