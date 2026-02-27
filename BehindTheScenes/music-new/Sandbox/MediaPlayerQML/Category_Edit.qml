import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Popup {
    id: root
    width: 600
    height: 500
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#121212"
        opacity: 0.95
        radius: 15
        border.color: "#2566c2" // MediaVerse Blue
        border.width: 1

        // Subtle Glow for the Architect look
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#000000"
            samples: 20
            radius: 10
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header Row
        Item {
            width: parent.width
            height: 40

            Text {
                text: "CATEGORY REGISTRY"
                color: "white"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 1
                anchors.left: parent.left
            }

            // Close Button
            Button {
                anchors.right: parent.right
                width: 30
                height: 30
                flat: true
                onClicked: root.close()
                
                contentItem: Text {
                    text: "✕"
                    color: parent.hovered ? "#ff4444" : "#888888"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#333333"
        }

        // Placeholder for the "Friendly Interface"
        Text {
            text: "Registry Data Loading..."
            color: "#2566c2"
            font.italic: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}