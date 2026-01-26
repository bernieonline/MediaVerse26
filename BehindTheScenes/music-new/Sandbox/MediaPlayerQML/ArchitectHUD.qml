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
    readonly property int joinGap: 40 // Space between panels for the gate to sit
    
    property int totalMatches: 0
    property var filterRules: []

    ListModel {
        id: criteriaModel
        ListElement { panelType: "selection"; panelValue: ""; gateValue: "NONE" }
    }

    // --- LOGIC FUNCTIONS ---
    function updateRule(index, type, value) {
        if (index >= 0 && index < criteriaModel.count) {
            criteriaModel.setProperty(index, "panelType", type);
            criteriaModel.setProperty(index, "panelValue", value);
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
            spacing: 0 // We use the Gate's width to create the gap

            Repeater {
                model: criteriaModel
                delegate: Row {
                    // 1. THE PANEL
                    ArchitectPanel {
                        id: mainPanel
                        width: architectRoot.cardWidth
                        height: architectRoot.cardHeight
                        panelIndex: index
                        
                        // Syncing with model
                        nextGate: model.gateValue
                        onNextGateChanged: model.gateValue = nextGate
                    }

                    // 2. THE GATE (Sitting outside the bottom join)
                    Item {
                        width: architectRoot.joinGap
                        height: architectRoot.cardHeight
                        visible: index < 3 && mainPanel.currentMode !== "selection"

                        Column {
                            width: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom 
                            anchors.topMargin: -40 // Pulls it up so it straddles the bottom edge
                            spacing: 8

                            // AND BUTTON
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "AND" ? "#00F2FF" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "AND"; color: "white"; font.pixelSize: 10; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.gateValue === "NONE") {
                                            criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE" })
                                        }
                                        model.gateValue = "AND"
                                    }
                                }
                            }

                            // NOT BUTTON
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                color: model.gateValue === "NOT" ? "#FF0055" : "#1A1A1A"
                                border.color: "white"; border.width: 1
                                Text { anchors.centerIn: parent; text: "NOT"; color: "white"; font.pixelSize: 10; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (model.gateValue === "NONE") {
                                            criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE" })
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
                    criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE" });
                }
            }

            Button {
                id: exitBtn
                width: 150; height: 45
                text: "EXIT ARCHITECT"
                onClicked: {
                    criteriaModel.clear();
                    criteriaModel.append({ "panelType": "selection", "panelValue": "", "gateValue": "NONE" });
                    architectRoot.visible = false;
                }
            }
        }
    }
}