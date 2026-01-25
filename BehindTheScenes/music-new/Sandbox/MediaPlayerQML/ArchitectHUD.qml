import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: architectRoot 
    anchors.fill: parent
    color: "#F2050505"
    visible: false
    z: 5000

    // --- REFINED DIMENSIONS ---
    readonly property int cardWidth: 360    
    readonly property int cardHeight: 600   
    readonly property int cardGap: 25       
    readonly property int addButtonWidth: 60

    // Fixed Stage Width for 4 Slots
    readonly property int stageWidth: (cardWidth * 4) + (cardGap * 3) + addButtonWidth
    property int totalMatches: 0

    ListModel {
        id: criteriaModel
        ListElement { panelType: "selection"; panelValue: "" }
    }

    function updateRule(index, type, value) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelValue", value);
            refreshLiveCount();
        }
    }

    function refreshLiveCount() {
        var fullLogic = [];
        console.log("🛠️ Debug: Building Logic for " + criteriaModel.count + " panels");

        for (var i = 0; i < criteriaModel.count; i++) {
            var item = criteriaModel.get(i);
            
            // Log every item even if empty so we see the state
            console.log("   Panel " + i + ": Type=" + item.panelType + " | Value=" + item.panelValue);

            if (item.panelValue !== "") {
                // CRITICAL FIX: Changed "type" to "category" to stop the Python KeyError
                fullLogic.push({ 
                    "category": item.panelType, 
                    "value": item.panelValue 
                });
            }
        }

        var jsonString = JSON.stringify(fullLogic);
        console.log("📦 Sending to Python: " + jsonString);

        if (typeof architectController !== "undefined") {
            architectController.update_live_preview(jsonString);
        } else {
            console.error("❌ Error: architectController is NOT defined!");
        }
    }

    // THE STAGE
    Item {
        id: stage
        width: architectRoot.stageWidth
        height: architectRoot.cardHeight
        anchors.centerIn: parent 

        Row {
            id: cardRow
            spacing: architectRoot.cardGap
            anchors.centerIn: parent 
            height: parent.height

            Repeater {
                model: criteriaModel
                delegate: ArchitectPanel {
                    width: architectRoot.cardWidth
                    height: architectRoot.cardHeight
                    panelIndex: index
                }
            }

            // CIRCULAR ADD BUTTON
            Button {
                id: addRuleBtn
                width: architectRoot.addButtonWidth; height: 60
                visible: criteriaModel.count < 4
                anchors.verticalCenter: parent.verticalCenter
                
                background: Rectangle {
                    color: addRuleBtn.hovered ? "#33FFFFFF" : "#08FFFFFF"
                    radius: 30; border.color: "#00F2FF"; border.width: 1
                }
                contentItem: Text {
                    text: "+"; color: "#00F2FF"; font.pixelSize: 32;
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                onClicked: criteriaModel.append({ "panelType": "selection", "panelValue": "" })
            }
        }
    }

    // FOOTER
    Rectangle {
        width: parent.width; height: 100; anchors.bottom: parent.bottom; color: "#1A000000"
        Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }
        Row {
            anchors.centerIn: parent; spacing: 60
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "MATCHING FILES"; color: "#88FFFFFF"; font.pixelSize: 11 }
                Text { text: architectRoot.totalMatches; color: "gold"; font.pixelSize: 32; font.bold: true }
            }
            Button {
                id: constructBtn
                width: 260; height: 45
                contentItem: Text { 
                    text: "CONSTRUCT COLLECTION"; color: "black"; font.bold: true;
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                }
                background: Rectangle { color: "#00F2FF"; radius: 4; opacity: constructBtn.hovered ? 0.8 : 1.0 }
            }
        }
    }

    // MASTER CLOSE
    Button {
        id: masterClose
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 30
        width: 44; height: 44
        onClicked: architectRoot.visible = false
        contentItem: Text {
            text: "✕"; color: "white"; font.pixelSize: 20;
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { color: masterClose.hovered ? "#CCFF4444" : "#22FFFFFF"; radius: 22 }
    }

    Connections {
        target: architectController
        function onResultsCounted(count) { architectRoot.totalMatches = count }
    }
}