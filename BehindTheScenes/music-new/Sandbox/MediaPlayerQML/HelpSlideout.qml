import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: helpSidebar
    width: 380
    // Ties height to the HUD/Parent
    height: parent ? parent.height : 800
    
    // 🔥 SURGICAL FIX: Park it far to the right. 
    // It only becomes 'visible' when it actually starts sliding in.
    x: parent ? parent.width : 5000 
    visible: x < (parent ? parent.width : 5000)
    
    color: "#0F0F0F"
    border.color: "#333333"
    border.width: 1
    z: 9999 // Global priority

    // Persistent state property to remember the last clicked context
    property string lastSectionKey: ""

    // Smooth sliding animation
    Behavior on x { 
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic } 
    }

    // --- Control Functions ---
    
    function openToSection(targetKey) {
        // Slide into view
        helpSidebar.x = parent.width - width; 
        
        // MEMORY LOGIC: 
        // We only force-expand a section if it's different from the last one.
        // Otherwise, we leave the user's manual expansions exactly as they were.
        if (targetKey !== lastSectionKey) {
            lastSectionKey = targetKey;
            for (var i = 0; i < helpModel.count; i++) {
                if (helpModel.get(i).sectionKey === targetKey) {
                    helpModel.setProperty(i, "expanded", true);
                    helpList.positionViewAtIndex(i, ListView.Beginning);
                }
                // Note: We don't force-collapse other sections here 
                // so the "memory" of other open topics is preserved.
            }
        }
    }

    function close() { 
        helpSidebar.x = parent.width; 
    }

    function toggleAll(shouldExpand) {
        for(var i=0; i < helpModel.count; i++) {
            helpModel.setProperty(i, "expanded", shouldExpand);
        }
    }

    // --- UI Layout ---
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header
        Row {
            width: parent.width
            height: 40
            Text {
                text: "ARCHITECT GUIDE"
                color: "#FFD700"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 1
                width: parent.width - 40
            }
            Text {
                text: "✕"
                color: "#888888"
                font.pixelSize: 24
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                
                MouseArea { 
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: helpSidebar.close() 
                }
            }
        }

        // Toolbar
        Row {
            spacing: 12
            width: parent.width
            
            Button {
                text: "Expand All"
                flat: true
                onClicked: toggleAll(true)
                contentItem: Text { text: parent.text; color: "#aaa"; font.pixelSize: 11; font.bold: true }
            }
            Button {
                text: "Collapse All"
                flat: true
                onClicked: toggleAll(false)
                contentItem: Text { text: parent.text; color: "#aaa"; font.pixelSize: 11; font.bold: true }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#222222" }

        // The Help List
        ListView {
            id: helpList
            width: parent.width
            height: parent.height - 160
            spacing: 10
            clip: true
            model: helpModel
            delegate: helpDelegate
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: true }
        }
    }

    // --- Content Model ---
    ListModel {
        id: helpModel
        ListElement { sectionKey: "intro"; title: "1. WHAT IS ARCHITECT?"; expanded: false; content: "The Architect is a multi-stage filter. Instead of searching for one thing, you layer rules to find specific results (e.g., 'Westerns' AND 'Clint Eastwood' but NOT '1990s')." }
        ListElement { sectionKey: "modes"; title: "2. UNDERSTANDING MODES"; expanded: false; content: "• FOLDER: Lists movies from specific server directories.\n• SEARCH: Accumulate a custom list by selecting specific titles.\n• CATEGORY: Uses metadata (Actor, Director, Genre, Decade) sourced from JRiver XML sidecars." }
        ListElement { sectionKey: "shelf"; title: "3. THE BOOKSHELF & COMMIT"; expanded: false; content: "Clicking 'Commit' stores your current selection as a 'Bookshelf'. This bookshelf acts as the input for the next panel's logic joins. Click 'Shelf' to preview titles at any time." }
        ListElement { sectionKey: "logic"; title: "4. LOGIC JOINS (AND/NOT)"; expanded: false; content: "• AND (Unchecked): Adds new results to your current list.\n• AND (Checked): Filters your current list by the new rule (Intersection).\n• NOT: Removes the new rule's results from your current list." }
        ListElement { sectionKey: "backflush"; title: "5. SAVING & BACKFLUSHING"; expanded: false; content: "Assign a Name and Category on Finish. If you rename a category in Settings later, the 'Backflush' feature automatically updates every affected record in your library." }
        ListElement { sectionKey: "editing"; title: "6. CATEGORY EDITING"; expanded: false; content: "Mistakes happen! Use the Category Registry in Settings to Rename or Delete. Deleting a category safely moves affected collections to the 'Unassigned' group." }
    }

    // --- Accordion Delegate ---
    Component {
        id: helpDelegate
        Column {
            width: helpList.width
            Rectangle {
                width: parent.width
                height: 45
                color: model.expanded ? "#221E14" : "#1A1A1A"
                radius: 4
                border.color: model.expanded ? "#FFD700" : "#333333"
                border.width: 1
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    spacing: 10
                    Text { text: model.expanded ? "▼" : "▶"; color: model.expanded ? "#FFD700" : "#666666"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: model.title; color: model.expanded ? "#FFD700" : "white"; font.bold: model.expanded; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: helpModel.setProperty(index, "expanded", !model.expanded) }
            }
            Rectangle {
                id: revealContainer
                width: parent.width
                height: model.expanded ? contentText.height + 30 : 0
                color: "#080808"
                clip: true
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                Text {
                    id: contentText
                    width: parent.width - 30
                    anchors.centerIn: parent
                    text: model.content
                    color: "#BBBBBB"
                    wrapMode: Text.WordWrap
                    font.pixelSize: 13
                    lineHeight: 1.4
                }
            }
        }
    }
}