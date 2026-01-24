import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: architectRoot 
    anchors.fill: parent
    color: "#F2050505"
    visible: false 
    z: 5000

    // --- 1. ENFORCED DIMENSIONS (The "Source of Truth") ---
    readonly property int cardWidth: 420
    readonly property int cardHeight: 640
    readonly property int cardGap: 30
    property int totalMatches: 0

    // Center Calculation: This tells the UI exactly how much space the cards need
    property int totalContentWidth: (criteriaModel.count * cardWidth) + ((criteriaModel.count - 1) * cardGap)

    // --- 2. DATA MODEL ---
    ListModel {
        id: criteriaModel
        ListElement { panelType: "selection"; panelValue: "" }
    }

    // --- 3. LOGIC ---
    function refreshLiveCount() {
        var fullLogic = [];
        for (var i = 0; i < criteriaModel.count; i++) {
            var item = criteriaModel.get(i);
            if (item.panelValue !== "") {
                fullLogic.push({ "type": item.panelType, "value": item.panelValue });
            }
        }
        if (typeof architectController !== "undefined") {
            architectController.update_live_preview(JSON.stringify(fullLogic));
        }
    }

    function updateRule(index, type, value) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelValue", value);
            refreshLiveCount();
        }
    }

    // --- 4. UI LAYOUT ---

    // THE STAGE (Ensures vertical centering)
    Item {
        id: stage
        width: parent.width
        height: architectRoot.cardHeight
        anchors.centerIn: parent

        // THE CARDS ROW (Ensures horizontal centering)
        Row {
            id: cardRow
            spacing: architectRoot.cardGap
            // We force the row to be exactly the width of its content
            width: childrenRect.width 
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: criteriaModel
                delegate: ArchitectPanel {
                    width: architectRoot.cardWidth
                    height: architectRoot.cardHeight
                    panelIndex: index
                    // Explicitly pass properties to the panel
                }
            }

            // ADD BUTTON (Fixed: Removed dashPattern to prevent crash)
            Button {
                id: addRuleBtn
                width: 80
                height: architectRoot.cardHeight
                visible: criteriaModel.count < 3
                
                background: Rectangle {
                    color: addRuleBtn.hovered ? "#22FFFFFF" : "#08FFFFFF"
                    radius: 15
                    border.color: "#00F2FF"
                    border.width: 1 // Simplified border
                }
                contentItem: Text {
                    text: "+"
                    color: "#00F2FF"
                    font.pixelSize: 40
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: criteriaModel.append({ "panelType": "selection", "panelValue": "" })
            }
        }
    }

    // FOOTER PANEL
    Rectangle {
        width: parent.width; height: 100
        anchors.bottom: parent.bottom
        color: "#1A000000"
        
        Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

        Row {
            anchors.centerIn: parent
            spacing: 60
            
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "MATCHING FILES"; color: "#88FFFFFF"; font.pixelSize: 12; font.letterSpacing: 1 }
                Text { 
                    text: architectRoot.totalMatches
                    color: architectRoot.totalMatches > 0 ? "gold" : "white"
                    font.pixelSize: 36; font.bold: true 
                }
            }

            Button {
                id: constructBtn
                width: 280; height: 50
                anchors.verticalCenter: parent.verticalCenter
                contentItem: Text {
                    text: "CONSTRUCT COLLECTION"
                    color: "black"; font.bold: true; font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { 
                    color: constructBtn.hovered ? "#55F2FF" : "#00F2FF"
                    radius: 4 
                }
            }
        }
    }

    // Master Close
    Button {
        id: masterClose
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 30
        width: 50; height: 50
        background: Rectangle { color: masterClose.hovered ? "#FF4444" : "transparent"; radius: 25 }
        contentItem: Text { text: "✕"; color: "white"; font.pixelSize: 22; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        onClicked: architectRoot.visible = false
    }

    Connections {
        target: architectController
        function onResultsCounted(count) { architectRoot.totalMatches = count }
    }
}