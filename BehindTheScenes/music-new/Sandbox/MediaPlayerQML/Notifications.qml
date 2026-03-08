import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: navPanel
    width: 300
    height: parent.height
    property bool isShown: false

    // Slide Animation
    Behavior on x { 
        NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
    }

    // --- 1. THE DATA MODEL ---
    // This stores the notifications sent from Python
    ListModel {
        id: notifModel
    }

    // --- 2. THE BRIDGE FUNCTION ---
    // Called by UtilitySidebar's Connections block
    function addNewEntry(msg, urgent) {
        // Insert at index 0 so newest notifications appear at the top
        notifModel.insert(0, { 
            "messageText": msg, 
            "isUrgent": urgent,
            "timestamp": new Date().toLocaleTimeString(Qt.locale(), "hh:mm")
        })
    }

    // --- 3. THE FROSTED GLASS BACKGROUND ---
    ShaderEffectSource {
        id: glassSource
        anchors.fill: parent
        sourceItem: root // Points to the main background defined in UtilitySidebar
        sourceRect: Qt.rect(navPanel.x, navPanel.y, navPanel.width, navPanel.height)
        live: true
        visible: false
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "transparent"
        border.color: "#33FFFFFF"
        border.width: 1

        FastBlur {
            anchors.fill: parent
            source: glassSource
            radius: 100 
            transparentBorder: true
        }

        // The "Density" Layer (75% opacity dark tint)
        Rectangle {
            anchors.fill: parent
            color: "#BF121212" 
        }
    }

    // --- 4. THE CONTENT LAYOUT ---
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "NOTIFICATIONS"
            color: "white"
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 2
            
            layer.enabled: true
            layer.effect: DropShadow {
                color: "black"
                radius: 8
                samples: 16
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#44FFFFFF"
        }

        // THE SCROLLABLE LIST
        ListView {
            id: notifListView
            width: parent.width
            height: parent.height - 100
            model: notifModel
            spacing: 10
            clip: true

            // Behavior for adding new items (they will slide in)
            add: Transition {
                NumberAnimation { properties: "x"; from: -100; duration: 300; easing.type: Easing.OutBack }
                NumberAnimation { properties: "opacity"; from: 0; duration: 300 }
            }

            delegate: Rectangle {
                width: notifListView.width
                height: 70
                color: model.isUrgent ? "#44FF0000" : "#22FFFFFF"
                radius: 8
                border.color: model.isUrgent ? "red" : "#33FFFFFF"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Row {
                        width: parent.width
                        Text {
                            text: model.isUrgent ? "⚠ URGENT" : "SYSTEM"
                            color: model.isUrgent ? "#FF4444" : "yellow"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        Item { width: 10; height: 1 } // Spacer
                        Text {
                            text: model.timestamp
                            color: "#88FFFFFF"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: model.messageText
                        color: "white"
                        font.pixelSize: 13
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}