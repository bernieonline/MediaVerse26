import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    property int sidebarWidth: 225
    property bool isOpen: false
    property int iconSize: 21
    property color brandColor: "#1E90FF" 
    property int unreadCount: 3
    property bool hasUrgent: true 

    FontLoader { id: faSolid; source: fontPathFA }

    // --- 1. THE DISMISSAL SHIELD ---
    // This covers the entire screen EXCEPT the sidebar when it's open.
    // Clicking anywhere else on the screen will close the sidebar.
    MouseArea {
        id: dismissalShield
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: {
            root.isOpen = false
            notificationPanel.isShown = false
            console.log("🖱️ Sidebar closed via background click")
        }
        z: 997 // Sits below the sidebar but above the library
    }

    // --- 2. THE TRIGGER ZONE (BUMP) ---
    MouseArea {
        id: bumpArea
        width: 15
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        onEntered: root.isOpen = true
        z: 999 

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

    // --- 3. THE NOTIFICATION PANEL ---
    Notifications {
        id: notificationPanel
        x: root.isOpen && notificationPanel.isShown ? (parent.width - sidebarBody.width - width) : parent.width
        z: 998 
    }

    // --- 4. THE SIDEBAR BODY ---
    Rectangle {
        id: sidebarBody
        width: root.sidebarWidth
        height: parent.height
        x: root.isOpen ? parent.width - width : parent.width
        color: "#F2121212" 
        z: 1000

        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

        // --- EMPTY SPACE CLICKER ---
        // This MouseArea fills the sidebar. Because ToolButtons have their own MouseAreas,
        // those will catch clicks first. Clicking anywhere else (empty space) closes the bar.
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.isOpen = false
                notificationPanel.isShown = false
                console.log("🖱️ Sidebar closed via empty space click")
            }
        }

        Column {
            anchors.fill: parent
            anchors.topMargin: 40
            spacing: 25

            Text {
                text: "TOOLS"
                color: "yellow"
                font.pixelSize: 20
                font.bold: true
                font.letterSpacing: 1.5
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                width: parent.width
                spacing: 12

                ToolButton {
                    iconCode: "\uf0f3"; toolName: "Alerts"
                    unreadBadge: root.unreadCount; isUrgent: root.hasUrgent
                    onClicked: notificationPanel.isShown = !notificationPanel.isShown
                }
                
                ToolButton { iconCode: "\uf5dc"; toolName: "AI"; onClicked: console.log("AI Clicked") }
                ToolButton { iconCode: "\uf002"; toolName: "Search"; onClicked: console.log("Search Clicked") }
                ToolButton { iconCode: "\uf07c"; toolName: "Files"; onClicked: console.log("Files Clicked") }
            }
        }

        // Branding Logo
        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Text {
                text: "MediaVerse"; color: root.brandColor; font.pixelSize: 22; font.bold: true
                font.letterSpacing: 1.5; anchors.horizontalCenter: parent.horizontalCenter
                layer.enabled: true
                layer.effect: DropShadow { color: root.brandColor; radius: 4; samples: 8 }
            }
            Text { text: "v1.0"; color: "#66FFFFFF"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    // --- TOOL BUTTON COMPONENT ---
    component ToolButton: Rectangle {
        id: btnRoot
        property string iconCode; property string toolName
        property int unreadBadge: 0; property bool isUrgent: false
        signal clicked()

        width: parent.width - 20; height: 60; anchors.horizontalCenter: parent.horizontalCenter
        color: btnMouse.containsMouse ? "#22FFFFFF" : "transparent"
        radius: 8; border.color: btnMouse.containsMouse ? "yellow" : "transparent"; border.width: 1

        Row {
            anchors.fill: parent; anchors.leftMargin: 15; spacing: 15
            Text {
                text: btnRoot.iconCode; font.family: faSolid.name; font.pixelSize: root.iconSize
                color: btnRoot.isUrgent ? "red" : (btnMouse.containsMouse ? "yellow" : "white")
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: btnRoot.toolName; color: "white"; font.pixelSize: 14; font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 20; height: 20; radius: 10
                color: btnRoot.isUrgent ? "#D32F2F" : "#FBC02D"
                visible: btnRoot.unreadBadge > 0
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: btnRoot.unreadBadge; color: "white" 
                    font.pixelSize: 11; font.bold: true; anchors.centerIn: parent
                }
            }
        }
        MouseArea { 
            id: btnMouse; anchors.fill: parent; hoverEnabled: true; 
            onClicked: btnRoot.clicked() // This "swallows" the click so it doesn't close the sidebar
        }
    }
}