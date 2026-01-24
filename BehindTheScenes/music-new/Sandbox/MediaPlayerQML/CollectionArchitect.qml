import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Item {
    id: architectRoot
    anchors.fill: parent
    visible: opacity > 0
    opacity: 0

    // 1. DIM BACKGROUND
    Rectangle {
        anchors.fill: parent
        color: "#E6000000" // 90% Noir Black
        MouseArea { anchors.fill: parent; onClicked: architectRoot.close() }
    }

    // 2. MAIN FLOATING HUD
    Rectangle {
        id: floatingHUD
        width: parent.width * 0.95
        height: 750
        anchors.centerIn: parent
        color: "#1A1A1D"
        radius: 15
        border.color: "#00F2FF" // Glowing Cyan
        border.width: 1
        clip: true

        // BACKGROUND GLOW EFFECT
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2200F2FF" }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        // 3. TOP NAVIGATION / TITLE
        Row {
            id: headerRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 80
            anchors.margins: 20
            spacing: 20

            Text {
                text: "COLLECTION ARCHITECT"
                font.pixelSize: 24
                font.letterSpacing: 4
                color: "#00F2FF"
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            // Results Counter (Updates live)
            Rectangle {
                width: 120; height: 40; radius: 20
                color: "#3300F2FF"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "ITEMS: 542" // Placeholder
                    color: "white"
                }
            }
        }

        // 4. THE PANEL CHAIN (Up to 4)
        Flickable {
            id: panelFlicker
            anchors.top: headerRow.bottom
            anchors.bottom: footerRow.top
            anchors.left: parent.left
            anchors.right: parent.right
            contentWidth: panelRow.width
            interactive: contentWidth > width

            Row {
                id: panelRow
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                padding: 40
                spacing: 30

                // INITIAL PANEL (Injected manually for speed)
                PanelBlock { 
                    panelTitle: "ROOT SOURCE"
                    isFirst: true 
                }
            }
        }

        // 5. FOOTER CONTROLS
        Row {
            id: footerRow
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            height: 100
            spacing: 40

            Button {
                text: "+ ADD MORE"
                onClicked: addAnotherPanel()
                // Custom high-tech styling here
            }

            Button {
                text: "SCAN / TEST"
                palette.button: "gold"
                // Logic to trigger the "Virtual Shelf"
            }

            Button {
                text: "COMPLETE"
                onClicked: finalizeCollection()
            }
        }
    }

    // --- LOGIC FUNCTIONS ---
    function launch() {
        architectRoot.opacity = 1
    }

    function close() {
        architectRoot.opacity = 0
    }

    function addAnotherPanel() {
        // Logic to create a new PanelBlock.qml and append to panelRow
        // Also inserts the AND/NOT connector bridge
    }
}