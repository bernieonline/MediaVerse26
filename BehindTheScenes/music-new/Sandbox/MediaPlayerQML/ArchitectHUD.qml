import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: architectRoot 
    anchors.fill: parent
    color: "#F2050505"
    visible: false
    z: 5000

    // --- DIMENSIONS ---
    readonly property int cardWidth: 360    
    readonly property int cardHeight: 600   
    readonly property int cardGap: 25       
    readonly property int addButtonWidth: 60
    readonly property int stageWidth: (cardWidth * 4) + (cardGap * 3) + addButtonWidth
    
    property int totalMatches: 0
    // Add this near your other properties at the top
    property var filterRules: []

    ListModel {
        id: criteriaModel
        ListElement { panelType: "selection"; panelValue: "" }
    }
    // Add this inside your architectRoot / ArchitectHUD component
    function getRuleValue(pIndex, cat) {
        // Look at the rules we are already sending to Python
        for (var i = 0; i < filterRules.length; i++) {
            if (filterRules[i].panelIndex === pIndex && filterRules[i].category === cat) {
                return filterRules[i].value;
            }
        }
        return "";
    }

    function updateRule(index, type, value) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelValue", value);

            // --- THE CRITICAL SYNC STEP ---
            // We rebuild filterRules so getRuleValue can see the changes
            var tempRules = [];
            for (var i = 0; i < criteriaModel.count; i++) {
                var item = criteriaModel.get(i);
                if (item.panelType !== "selection") {
                    tempRules.push({
                        "panelIndex": i,
                        "category": item.panelType,
                        "value": item.panelValue
                    });
                }
            }
            filterRules = tempRules; // Now getRuleValue will find the data!

            // Send to Python
            architectController.update_live_preview(JSON.stringify(filterRules));
        }
    }

    function updateRuleOld(index, type, value) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelValue", value);
            refreshLiveCount();
        }
    }

    function refreshLiveCount() {
        var fullLogic = [];
        for (var i = 0; i < criteriaModel.count; i++) {
            var item = criteriaModel.get(i);
            if (item.panelValue !== "") {
                fullLogic.push({ 
                    "category": item.panelType, 
                    "value": item.panelValue 
                });
            }
        }
        var jsonString = JSON.stringify(fullLogic);
        if (typeof architectController !== "undefined") {
            architectController.update_live_preview(jsonString);
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

    // --- NEW MASTER FOOTER ---
    Rectangle {
        id: architectFooter
        width: parent.width
        height: 100
        color: "#1A000000"
        anchors.bottom: parent.bottom
        z: 100

        Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

        Row {
            anchors.centerIn: parent
            spacing: 60

            // MATCH COUNTER
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "MATCHING FILES"; color: "#88FFFFFF"; font.pixelSize: 11 }
                Text { text: architectRoot.totalMatches; color: "gold"; font.pixelSize: 32; font.bold: true }
            }

            // RESET BUTTON
            Button {
                id: resetBtn
                width: 150; height: 45
                contentItem: Text { 
                    text: "RESET SCHEME"; color: "white"; font.bold: true;
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                }
                background: Rectangle { color: "transparent"; border.color: "white"; radius: 4; opacity: resetBtn.hovered ? 1.0 : 0.6 }
                onClicked: {
                    criteriaModel.clear();
                    criteriaModel.append({ "panelType": "selection", "panelValue": "" });
                    architectRoot.totalMatches = 0;
                    refreshLiveCount(); // Update Python that we cleared everything
                }
            }

            // EXIT BUTTON (Replaces Construct for now or sits next to it)
            Button {
                id: exitBtn
                width: 150; height: 45
                contentItem: Text { 
                    text: "EXIT ARCHITECT"; color: "white"; font.bold: true;
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                }
                background: Rectangle { color: "#44FF0000"; border.color: "red"; radius: 4; opacity: exitBtn.hovered ? 1.0 : 0.7 }
                onClicked: {
                    criteriaModel.clear();
                    criteriaModel.append({ "panelType": "selection", "panelValue": "" });
                    architectRoot.totalMatches = 0;
                    architectRoot.visible = false;
                }
            }
        }
    }

    Connections {
        target: architectController
        function onResultsCounted(count) { architectRoot.totalMatches = count }
    }
}