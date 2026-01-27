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
    readonly property int joinGap: 40 
    
    property int totalMatches: 0
    property var filterRules: []

    ListModel {
        id: criteriaModel
        ListElement { panelType: "selection"; panelValue: ""; gateValue: "NONE"; panelHits: 0 }
    }

    // --- THE REMOVAL FUNCTION ---
    function removePanel(index) {
        if (criteriaModel.count <= 1) {
            updateRule(0, "selection", "");
            return;
        }

        criteriaModel.remove(index);

        if (criteriaModel.count > 0) {
            var lastIdx = criteriaModel.count - 1;
            criteriaModel.setProperty(lastIdx, "gateValue", "NONE");
        }

        updateRule(-1, "refresh", ""); 
    }

    // --- HELPER FUNCTIONS ---
    function updateRule(index, type, value) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelValue", value);
        }

        var tempRules = [];
        for (var i = 0; i < criteriaModel.count; i++) {
            var item = criteriaModel.get(i);
            if (item.panelType !== "selection" && item.panelType !== "refresh") {
                tempRules.push({
                    "panelIndex": i,
                    "category": item.panelType,
                    "value": item.panelValue,
                    "logic": item.gateValue
                });
            }
        }
        filterRules = tempRules;
        
        if (typeof architectController !== "undefined") {
            architectController.update_live_preview(JSON.stringify(filterRules));
        }
    }

    // --- THE STAGE ---
    Item {
        id: stage
        width: parent.width
        anchors.top: parent.top
        anchors.bottom: architectFooter.top

        Row {
            id: cardRow
            anchors.centerIn: parent
            spacing: 0 

            Repeater {
                model: criteriaModel
                delegate: Row {
                    // 1. THE PANEL
                    ArchitectPanel {
                        id: mainPanel
                        width: architectRoot.cardWidth
                        height: architectRoot.cardHeight
                        panelIndex: index
                        hitCount: model.panelHits || 0
                        nextGate: model.gateValue
                        
                        onNextGateChanged: {
                            if (model.gateValue !== nextGate) {
                                model.gateValue = nextGate
                                architectRoot.updateRule(index, mainPanel.currentMode, mainPanel.panelValue || "")
                            }
                        }
                    }

                    // 2. THE GATE
                    Item {
                        width: architectRoot.joinGap
                        height: architectRoot.cardHeight
                        visible: index < 3 && mainPanel.currentMode !== "selection"

                        Column {
                            width: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom 
                            anchors.topMargin: -40 
                            spacing: 8

                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "AND" ? "#00F2FF" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "AND"; color: "white"; font.pixelSize: 10; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.gateValue === "NONE") {
                                            criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE", "panelHits": 0 })
                                        }
                                        model.gateValue = "AND"
                                    }
                                }
                            }

                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "NOT" ? "#FF0055" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "NOT"; color: "white"; font.pixelSize: 10; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.gateValue === "NONE") {
                                            criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE", "panelHits": 0 })
                                        }
                                        model.gateValue = "NOT"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- MASTER FOOTER ---
    Rectangle {
        id: architectFooter
        width: parent.width; height: 120
        color: "#050505"
        anchors.bottom: parent.bottom
        z: 1000

        Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

        Row {
            anchors.centerIn: parent
            spacing: 60

            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "MATCHING FILES"; color: "#88FFFFFF"; font.pixelSize: 11 }
                Text { text: architectRoot.totalMatches; color: "gold"; font.pixelSize: 32; font.bold: true }
            }

            Button {
                id: resetBtn
                width: 150; height: 45
                text: "RESET SCHEME"
                onClicked: {
                    criteriaModel.clear();
                    criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE", "panelHits": 0 });
                    architectRoot.totalMatches = 0;
                }
            }

            Button {
                id: exitBtn
                width: 150; height: 45
                text: "EXIT ARCHITECT"
                onClicked: architectRoot.visible = false
            }
        }
    }

    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true
        function onResultsCounted(count) { 
            architectRoot.totalMatches = count 
        }
    }
}