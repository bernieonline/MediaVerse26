import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 400
    height: 80
    color: "#CC1a1a1a" // Dark, 80% opaque
    radius: 10
    border.color: "#333333"
    border.width: 1

    // For now, we'll position it at the bottom center
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 50
    anchors.horizontalCenter: parent.horizontalCenter

    Row {
        anchors.centerIn: parent
        spacing: 30

        // --- PREVIOUS ---
        Button {
            text: "⏮"
            onClicked: console.log("Skip Back") 
        }

        // --- PLAY / PAUSE ---
        Button {
            text: "⏯"
            onClicked: {
                // MCC 10000 toggles play/pause
                playbackBridge.stopPlayback() // We can update bridge for this later
            }
        }

        // --- STOP & RETURN ---
        Button {
            id: stopButton
            text: "STOP & EXIT"
            palette.buttonText: "white"
            background: Rectangle {
                color: stopButton.down ? "#990000" : "#cc0000"
                radius: 5
            }
            onClicked: {
                playbackBridge.stopPlayback()
            }
        }

        // --- NEXT ---
        Button {
            text: "⏭"
            onClicked: console.log("Skip Forward")
        }
    }
}