import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    // Configuration for 10ft UI
    property int sidebarWidth: 450
    property bool isOpen: false
    property int iconSize: 42 

    // --- FONT LOADER ---
    // Uses 'fontPathFA' variable passed from your main.py context
    FontLoader {
        id: faSolid
        source: fontPathFA
        onStatusChanged: {
            if (status === FontLoader.Error) console.log("❌ Error loading FontAwesome from:", source)
            if (status === FontLoader.Ready) console.log("✅ FontAwesome Loaded Successfully")
        }
    }

    // --- 1. THE TRIGGER ZONE (BUMP) ---
    // Invisible area on the far right edge to trigger the slide
    MouseArea {
        id: bumpArea
        width: 20
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        onEntered: {
            root.isOpen = true
            console.log("➡️ Sidebar Triggered via Bump")
        }
        z: 999 
    }

    // --- 2. KEYBOARD TOGGLE (FOR TESTING) ---
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: {
            root.isOpen = !root.isOpen
            console.log("⌨️ Sidebar Toggled via Keyboard. Open:", root.isOpen)
        }
    }

    // --- 3. THE SIDEBAR BODY ---
    Rectangle {
        id: sidebarBody
        width: root.sidebarWidth
        height: parent.height
        x: root.isOpen ? parent.width - width : parent.width
        color: "#F2121212" // 95% Opaque Dark Charcoal
        z: 1000

        // Smooth Slide Animation
        Behavior on x {
            NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
        }

        // --- DEPTH SHADOW ---
        // Visual cue that the panel is "above" the library grid
        Rectangle {
            id: edgeGlow
            width: 30
            height: parent.height
            anchors.right: sidebarBody.left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#CC000000" }
            }
        }

        Column {
            anchors.fill: parent
            anchors.topMargin: 80
            spacing: 45

            Text {
                text: "SYSTEM TOOLS"
                color: "yellow"
                font.pixelSize: 36
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                
                layer.enabled: true
                layer.effect: DropShadow { radius: 8; color: "black"; samples: 16 }
            }

            // TOOL LIST
            Column {
                width: parent.width
                spacing: 20

                ToolButton {
                    iconCode: "\uf0f3" // Bell
                    toolName: "Notifications"
                    toolDesc: "System logs and alerts"
                    onClicked: {
                        console.log("🔔 Notifications clicked")
                        root.isOpen = false 
                    }
                }

                ToolButton {
                    iconCode: "\uf5dc" // Brain
                    toolName: "AI Assistant"
                    toolDesc: "Query ChatGPT about media"
                    onClicked: {
                        console.log("🤖 AI Assistant clicked")
                        // Stay open for AI interaction
                    }
                }

                ToolButton {
                    iconCode: "\uf002" // Search
                    toolName: "Global Search"
                    toolDesc: "Search library & MySQL"
                    onClicked: {
                        console.log("🔍 Search clicked")
                        root.isOpen = false
                    }
                }

                ToolButton {
                    iconCode: "\uf07c" // Folder
                    toolName: "File Explorer"
                    toolDesc: "Browse server filesystem"
                    onClicked: {
                        console.log("📂 File Explorer clicked")
                        root.isOpen = false
                    }
                }
            }
        }

        // --- AUTO-HIDE SENSOR ---
        // Closes the sidebar when the mouse moves back to the library
        MouseArea {
            anchors.fill: parent
            z: -1 // Sits behind the buttons
            hoverEnabled: true
            onExited: {
                // If the mouse moves left (mouseX < 0), close the bar
                if (mouseX < 0) {
                    root.isOpen = false
                    console.log("⬅️ Mouse left sidebar area")
                }
            }
        }
    }

    // --- INTERNAL COMPONENT: ToolButton ---
    component ToolButton: Rectangle {
        id: btnRoot
        property string iconCode: ""
        property string toolName: ""
        property string toolDesc: ""
        signal clicked()

        width: parent.width - 40
        height: 120
        anchors.horizontalCenter: parent.horizontalCenter
        color: btnMouse.containsMouse ? "#22FFFFFF" : "transparent"
        radius: 15
        border.color: btnMouse.containsMouse ? "yellow" : "transparent"
        border.width: 2

        Row {
            anchors.fill: parent
            anchors.leftMargin: 30
            spacing: 30

            // Font Awesome Icon
            Text {
                text: btnRoot.iconCode
                font.family: faSolid.name
                font.pixelSize: root.iconSize
                color: btnMouse.containsMouse ? "yellow" : "white"
                anchors.verticalCenter: parent.verticalCenter
            }

            // Label and Description
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                
                Text {
                    text: btnRoot.toolName
                    color: "white"
                    font.pixelSize: 26
                    font.bold: true
                }
                
                Text {
                    text: btnRoot.toolDesc
                    color: "#AAAAAA"
                    font.pixelSize: 18
                    visible: btnMouse.containsMouse
                    width: btnRoot.width - 120
                    wrapMode: Text.WordWrap
                }
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btnRoot.clicked()
        }
    }
}