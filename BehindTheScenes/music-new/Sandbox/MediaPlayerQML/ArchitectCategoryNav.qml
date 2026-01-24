import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: catNavRoot
    anchors.fill: parent

    // UI States: "main" (the tiles), "search" (search box + cloud), "year"
    property string currentSubMode: "main"
    property string activeCategory: "" 

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // --- NAVIGATION HEADER ---
        Rectangle {
            id: breadcrumbBar
            width: parent.width; height: 40; color: "#22FFFFFF"; radius: 6
            Row {
                anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                Button { 
                    text: "🏠"; width: 35; height: 30; anchors.verticalCenter: parent.verticalCenter
                    onClicked: { currentSubMode = "main"; activeCategory = ""; filterField.text = ""; }
                }
                Text {
                    text: activeCategory === "" ? "SELECT CATEGORY" : activeCategory.toUpperCase()
                    color: "gold"; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- VIEW 1: CATEGORY BUTTONS (Initial State) ---
        Grid {
            visible: currentSubMode === "main"
            columns: 2; spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                delegate: Button {
                    width: 165; height: 80
                    text: modelData
                    onClicked: {
                        activeCategory = modelData;
                        // Decade follows a different logic (Year Range), others use the Cloud
                        currentSubMode = (modelData === "Decade") ? "year" : "search";
                    }
                }
            }
        }

        // --- VIEW 2: SEARCH BOX + DISCOVERY CLOUD ---
        Column {
            visible: currentSubMode === "search"
            width: parent.width; spacing: 15

            // Search Input
            TextField {
                id: filterField
                width: parent.width
                placeholderText: "Type to filter " + activeCategory + "..."
                color: "white"; leftPadding: 40
                background: Rectangle {
                    color: "#15FFFFFF"; radius: 20
                    border.color: filterField.activeFocus ? "gold" : "#444"
                    Text { text: "🔍"; anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // The Cloud (Flickable for scrolling)
            Rectangle {
                width: parent.width; height: 320; color: "transparent"; clip: true
                Flickable {
                    anchors.fill: parent; contentHeight: cloudFlow.height; clip: true
                    
                    Flow {
                        id: cloudFlow; width: parent.width - 10; spacing: 8
                        
                        Repeater {
                            // This block triggers every time filterField.text or activeCategory changes
                            model: {
                                if (currentSubMode !== "search") return [];
                                if (typeof collectionLogic !== 'undefined' && collectionLogic !== null) {
                                    return collectionLogic.get_filtered_keywords(activeCategory, filterField.text)
                                }
                                return []
                            }
                            
                            delegate: Button {
                                padding: 10
                                background: Rectangle {
                                    // Highlight if it matches the current rule (optional visual flair)
                                    color: "transparent"
                                    border.color: "gold"; border.width: 1; radius: 17
                                }
                                contentItem: Text {
                                    text: modelData; color: "gold"; font.bold: true; font.pixelSize: 12
                                }
                                onClicked: {
                                    // This is the moment "Actor = John Wayne" is locked in
                                    console.log("✅ Category Selected: " + activeCategory + " -> " + modelData)
                                    architectRoot.updateRule(panelRoot.panelIndex, "category", activeCategory + " = " + modelData);
                                }
                            }
                        }
                    }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }
        }

        // --- VIEW 3: YEAR RANGE (Decade replacement) ---
        Column {
            visible: currentSubMode === "year"
            width: parent.width; spacing: 20
            
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 15
                SpinBox { id: yearFrom; from: 1900; to: 2026; value: 1950; editable: true }
                Text { text: "to"; color: "gold"; anchors.verticalCenter: parent.verticalCenter }
                SpinBox { id: yearTo; from: 1900; to: 2026; value: 1960; editable: true }
            }

            Button {
                width: parent.width; height: 45; text: "SET YEAR RANGE"
                onClicked: {
                    var range = "Year: " + yearFrom.value + " - " + yearTo.value;
                    architectRoot.updateRule(panelRoot.panelIndex, "category", range);
                }
            }
        }
    }
}