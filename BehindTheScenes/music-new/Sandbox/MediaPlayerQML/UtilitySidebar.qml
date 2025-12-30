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
    property int unreadCount: 0  
    property bool hasUrgent: false 

    // --- NEW: Helper Function for your main button ---
    function showCollectionCreator() {
        // 1. Close other panels
        notificationPanel.isShown = false
        todoPanel.isShown = false
        
        // 2. Open this panel
        collectionCreatorPanel.isShown = true
        
        // 3. Refresh data from Python
        collectionLogic.refresh_master_cache()
    }

    FontLoader { 
        id: faSolid;
        Component.onCompleted: {
            faSolid.source = fontPathFA 
        }
    }

    // --- SIGNAL BRIDGES ---
    Connections {
        target: notificationManager
        function onNotificationReceived(message, is_urgent) {
            root.unreadCount += 1
            if (is_urgent) root.hasUrgent = true
            notificationPanel.addNewEntry(message, is_urgent)
        }
    }

    Connections {
        target: todoManager
        function onTodoChanged(newContent) {
            todoTextArea.text = newContent
        }
    }

    // --- 1. THE DISMISSAL SHIELD ---
    MouseArea {
        id: dismissalShield
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: {
            root.isOpen = false
            notificationPanel.isShown = false
            todoPanel.isShown = false
            collectionCreatorPanel.isShown = false // Close the new panel too
        }
        z: 997 
    }

    // --- 2. THE TRIGGER ZONE ---
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

    // --- 3. THE NOTIFICATION PANEL ---
    Notifications {
        id: notificationPanel
        x: root.isOpen && notificationPanel.isShown ? 
           (parent.width - sidebarBody.width - width) : parent.width
        z: 998 
    }

    // --- 4. THE TODO PANEL ---
    // (Existing code remains the same inside this rectangle)
    Rectangle {
        id: todoPanel
        property bool isShown: false
        width: 350; height: parent.height
        color: "#1E1E1E"; border.color: "#333"; border.width: 1; z: 998
        x: root.isOpen && isShown ? (parent.width - sidebarBody.width - width) : parent.width
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        
        // ... rest of your Column/TextArea code here ...
        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 15
            Text { text: "SHARED TO-DO LIST"; color: "yellow"; font.pixelSize: 18; font.bold: true }
            Rectangle {
                width: parent.width; height: parent.height - 120; color: "#121212"; radius: 5
                ScrollView {
                    anchors.fill: parent; anchors.margins: 10
                    TextArea {
                        id: todoTextArea; color: "white"; font.pixelSize: 14; wrapMode: TextEdit.Wrap
                        selectByMouse: true; placeholderText: "Type notes here..."
                    }
                }
            }
            Row {
                width: parent.width; spacing: 10
                Button { text: "Save"; width: parent.width * 0.5; onClicked: todoManager.save_todo(todoTextArea.text) }
                Button { text: "Close"; width: parent.width * 0.4; onClicked: todoPanel.isShown = false }
            }
        }
    }

    // --- 5. NEW: THE COLLECTION CREATOR PANEL ---
    CollectionCreator {
        id: collectionCreatorPanel
        property bool isShown: false
        z: 1100 // Set this higher than sidebarBody (which is 1000)
        
        // If isShown is true, it slides to its open position. 
        // If false, it hides off-screen to the right.
        x: isShown ? (parent.width - width) : parent.width
        
        width: 600 // Or whatever width you want for the builder
        
        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    }

    // --- 6. THE SIDEBAR BODY ---
    Rectangle {
        id: sidebarBody
        width: root.sidebarWidth
        height: parent.height
        x: root.isOpen ? parent.width - width : parent.width
        color: "#F2121212" 
        z: 1000

        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.topMargin: 40
            spacing: 25

            Text {
                text: "TOOLS"
                color: "yellow"; font.pixelSize: 20; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                width: parent.width; spacing: 12
                
                ToolButton {
                    iconCode: "\uf0f3"; toolName: "Alerts"
                    unreadBadge: root.unreadCount; isUrgent: root.hasUrgent
                    onClicked: {
                        todoPanel.isShown = false
                        collectionCreatorPanel.isShown = false // Added this
                        notificationPanel.isShown = !notificationPanel.isShown
                    }
                }

                ToolButton { 
                    iconCode: "\uf044"; toolName: "To-Do" 
                    onClicked: {
                        notificationPanel.isShown = false
                        collectionCreatorPanel.isShown = false // Added this
                        todoPanel.isShown = !todoPanel.isShown
                        if (todoPanel.isShown) todoTextArea.text = todoManager.load_todo()
                    }
                }

                // New icon for the Collection Creator within the sidebar
                ToolButton { 
                    iconCode: "\uf00b" 
                    toolName: "Collections" 
                    onClicked: root.showCollectionCreator()
                }

                ToolButton { iconCode: "\uf5dc"; toolName: "AI" }
                ToolButton { iconCode: "\uf002"; toolName: "Search" }
                ToolButton { iconCode: "\uf07c"; toolName: "Files" }
            }
        }
    }

    // --- TOOL BUTTON COMPONENT ---
    // (Existing ToolButton component remains exactly the same)
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
        }
        MouseArea { id: btnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: btnRoot.clicked() }
    }
}