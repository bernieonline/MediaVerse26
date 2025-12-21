import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    // --- SLIM 10ft Configuration (Reduced by 50%) ---
    property int sidebarWidth: 225 // Was 450
    property bool isOpen: false
    property int iconSize: 21      // Was 42
    
    // --- FONT LOADER ---
    FontLoader {
        id: faSolid
        source: fontPathFA
        onStatusChanged: {
            if (status === FontLoader.Error) console.log("❌ Error loading FontAwesome from:", source)
        }
    }

    // --- TRIGGER ZONE ---
    MouseArea {
        id: bumpArea
        width: 15
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        onEntered: root.isOpen = true
        z: 999 
    }

    // --- SIDEBAR BODY ---
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

        // --- SLIM DEPTH SHADOW ---
        Rectangle {
            id: edgeGlow
            width: 15 // Reduced shadow width
            height: parent.height
            anchors.right: sidebarBody.left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#AA000000" }
            }
        }

        Column {
            anchors.fill: parent
            anchors.topMargin: 40 // Reduced margin
            spacing: 25           // Reduced spacing

            Text {
                text: "TOOLS" // Shortened for slim width
                color: "yellow"
                font.pixelSize: 18 // Was 36
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // TOOL LIST
            Column {
                width: parent.width
                spacing: 12 // Tighter vertical spacing

                ToolButton {
                    iconCode: "\uf0f3"
                    toolName: "Alerts"
                    onClicked: root.isOpen = false 
                }

                ToolButton {
                    iconCode: "\uf5dc"
                    toolName: "AI"
                    onClicked: console.log("AI Assistant active")
                }

                ToolButton {
                    iconCode: "\uf002"
                    toolName: "Search"
                    onClicked: root.isOpen = false
                }

                ToolButton {
                    iconCode: "\uf07c"
                    toolName: "Files"
                    onClicked: root.isOpen = false
                }
            }
        }

        // --- AUTO-HIDE SENSOR ---
        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            onExited: {
                if (mouseX < 0) root.isOpen = false
            }
        }
    }

    // --- COMPONENT: ToolButton ---
    component ToolButton: Rectangle {
        id: btnRoot
        property string iconCode: ""
        property string toolName: ""
        signal clicked()

        width: parent.width - 20 // Scaled down margin
        height: 60               // Was 120
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
                color: btnMouse.containsMouse ? "yellow" : "white"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: btnRoot.toolName
                color: "white"
                font.pixelSize: 13 // Was 26
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
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