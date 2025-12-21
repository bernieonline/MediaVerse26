import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    // --- CONFIGURATION ---
    property int sidebarWidth: 225
    property bool isOpen: false
    property int iconSize: 21
    property color brandColor: "#1E90FF" // ContentWindow Blue

    // --- NOTIFICATION DATA (Mechanisms) ---
    property int unreadCount: 3
    property bool hasUrgent: true 

    // --- FONT LOADER ---
    FontLoader {
        id: faSolid
        source: fontPathFA
    }

    // --- 1. THE TRIGGER ZONE (BUMP) + PULSING URGENT SIGNAL ---
    MouseArea {
        id: bumpArea
        width: 15
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        onEntered: root.isOpen = true
        z: 999 

        // Subtle Red Pulse (Only visible when sidebar is closed)
        Rectangle {
            anchors.fill: parent
            color: "red"
            visible: root.hasUrgent && !root.isOpen
            opacity: 0.5
            
            SequentialAnimation on opacity {
                running: root.hasUrgent && !root.isOpen
                loops: Animation.Infinite
                NumberAnimation { from: 0.1; to: 0.7; duration: 1200; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.7; to: 0.1; duration: 1200; easing.type: Easing.InOutQuad }
            }
        }
    }

    // --- 2. THE NOTIFICATION PANEL (SUB-COMPONENT) ---
    // This is the component defined in Notifications.qml
    Notifications {
        id: notificationPanel
        // Slide out to the left of the sidebar when active
        x: root.isOpen && notificationPanel.isShown ? 
           (parent.width - sidebarBody.width - width) : parent.width
        z: 998 
    }

    // --- 3. THE SIDEBAR BODY ---
    Rectangle {
        id: sidebarBody
        width: root.sidebarWidth
        height: parent.height
        x: root.isOpen ? parent.width - width : parent.width
        color: "#F2121212" 
        z: 1000

        Behavior on x {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }

        // Slim Depth Shadow
        Rectangle {
            id: edgeGlow
            width: 15
            height: parent.height
            anchors.right: sidebarBody.left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#AA000000" }
            }
        }

        // Main Tools Layout
        Column {
            anchors.fill: parent
            anchors.topMargin: 40
            spacing: 25

            Text {
                text: "TOOLS"
                color: "yellow"
                font.pixelSize: 18
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                width: parent.width
                spacing: 12

                ToolButton {
                    iconCode: "\uf0f3"
                    toolName: "Alerts"
                    unreadBadge: root.unreadCount
                    isUrgent: root.hasUrgent
                    onClicked: notificationPanel.isShown = !notificationPanel.isShown
                }

                ToolButton {
                    iconCode: "\uf5dc"
                    toolName: "AI"
                    onClicked: console.log("AI Assistant Toggle")
                }

                ToolButton {
                    iconCode: "\uf002"
                    toolName: "Search"
                    onClicked: {
                        notificationPanel.isShown = false
                        root.isOpen = false
                    }
                }

                ToolButton {
                    iconCode: "\uf07c"
                    toolName: "Files"
                    onClicked: {
                        notificationPanel.isShown = false
                        root.isOpen = false
                    }
                }
            }
        }

        // Branding Logo
        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            Text {
                text: "MediaVerse"
                color: root.brandColor
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 1.5
                anchors.horizontalCenter: parent.horizontalCenter
                
                layer.enabled: true
                layer.effect: DropShadow {
                    color: root.brandColor
                    radius: 4
                    samples: 8
                }
            }

            Text {
                text: "v1.0"
                color: "#66FFFFFF"
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Auto-Hide Sensor
        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            onExited: {
                // If we move left, close everything. 
                // If we move to notification panel, stay open.
                if (mouseX < 0 && !notificationPanel.isShown) {
                    root.isOpen = false
                }
            }
        }
    }

    // --- INTERNAL COMPONENT: ToolButton ---
    component ToolButton: Rectangle {
        id: btnRoot
        property string iconCode: ""
        property string toolName: ""
        property int unreadBadge: 0
        property bool isUrgent: false
        signal clicked()

        width: parent.width - 20
        height: 60
        anchors.horizontalCenter: parent.horizontalCenter
        color: btnMouse.containsMouse ? "#22FFFFFF" : "transparent"
        radius: 8
        border.color: btnMouse.containsMouse ? "yellow" : "transparent"
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin: 15
            spacing: 15

            Text {
                text: btnRoot.iconCode
                font.family: faSolid.name
                font.pixelSize: root.iconSize
                color: btnRoot.isUrgent ? "red" : (btnMouse.containsMouse ? "yellow" : "white")
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: btnRoot.toolName
                color: "white"
                font.pixelSize: 13
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            // Unread Badge Rectangle
            Rectangle {
                width: 18; height: 18; radius: 9
                color: btnRoot.isUrgent ? "red" : "yellow"
                visible: btnRoot.unreadBadge > 0
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: btnRoot.unreadBadge
                    color: "black"; font.pixelSize: 10; font.bold: true
                    anchors.centerIn: parent
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