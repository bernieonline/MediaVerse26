import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: navPanel
    width: 350
    height: parent.height
    x: parent.width // Start hidden behind sidebar

    property bool isShown: false

    // Slide Animation
    Behavior on x { 
        NumberAnimation { duration: 400; easing.type: Easing.OutPower4 } 
    }

    // --- FROSTED GLASS EFFECT ---
    // This captures the content behind the panel and blurs it
    ShaderEffectSource {
        id: glassSource
        anchors.fill: parent
        sourceItem: root // Points back to the main window content
        sourceRect: Qt.rect(parent.x, parent.y, parent.width, parent.height)
        live: true
        recursive: true
        visible: false
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#AA121212" // Semi-transparent dark base
        border.color: "#33FFFFFF"
        border.width: 1

        FastBlur {
            anchors.fill: parent
            source: glassSource
            radius: 64
            transparentBorder: true
        }
        
        // Dark tint overlay to ensure text readability
        Rectangle {
            anchors.fill: parent
            color: "#44000000"
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "NOTIFICATIONS"
            color: "white"
            font.pixelSize: 18
            font.bold: true
        }

        // Placeholder for the list
        Rectangle {
            width: parent.width
            height: 80
            color: "#22FFFFFF"
            radius: 5
            Text {
                text: "No new messages"
                anchors.centerIn: parent
                color: "#88FFFFFF"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: navPanel.isShown = false
            }
        }
    }
}