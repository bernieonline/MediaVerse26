import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: navPanel
    width: 300
    height: parent.height
    property bool isShown: false

    Behavior on x { 
        NumberAnimation { duration: 400; easing.type: Easing.OutPower4 } 
    }

    // --- 1. THE SOURCE ---
    ShaderEffectSource {
        id: glassSource
        anchors.fill: parent
        // IMPORTANT: sourceItem must point to the root or the main content container
        sourceItem: root 
        sourceRect: Qt.rect(navPanel.x, navPanel.y, navPanel.width, navPanel.height)
        live: true
        visible: false
    }

    // --- 2. THE FROSTED LAYERS ---
    Rectangle {
        id: background
        anchors.fill: parent
        color: "transparent" // We use the children to provide color
        border.color: "#33FFFFFF"
        border.width: 1

        // The Deep Blur
        FastBlur {
            anchors.fill: parent
            source: glassSource
            radius: 100 // Increased from 80 for maximum frosting
            transparentBorder: true
        }

        // The "Density" Layer 
        // This adds the "thickness" so it's not too transparent
        Rectangle {
            anchors.fill: parent
            // Using a slightly higher opacity (0.75 vs 0.3)
            // #BF = ~75% opacity. This makes it feel solid but still "glassy"
            color: "#BF121212" 
        }
        
        // Optional: Noise/Grain overlay (makes it look like real sandblasted glass)
        Rectangle {
            anchors.fill: parent
            opacity: 0.05
            color: "white"
        }
    }

    // --- 3. THE CONTENT ---
    Column {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        Text {
            text: "NOTIFICATIONS"
            color: "white"
            font.pixelSize: 24 // Larger for 10ft UI
            font.bold: true
            font.letterSpacing: 2
            
            layer.enabled: true
            layer.effect: DropShadow {
                color: "black"
                radius: 8
                samples: 16
            }
        }

        // ... Rest of your Tool List / Content ...
    }
}