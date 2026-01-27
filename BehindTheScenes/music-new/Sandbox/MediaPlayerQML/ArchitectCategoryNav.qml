import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: catNavRoot
    anchors.fill: parent

    // UI States: "main" (the tiles), "search" (search box + cloud), "year"
    property string currentSubMode: "main"
    property string activeCategory: "" 

    // FIXED: Use the global paths dictionary for the font
    FontLoader { id: catIconFont; source: paths.font_path }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // --- NAVIGATION HEADER (Synced Style) ---
        Rectangle {
            id: breadcrumbBar
            width: parent.width; height: 40; color: "#22FFFFFF"; radius: 6
            
            Row {
                anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                
                // HOME BUTTON
                Button { 
                    id: homeBtn
                    width: 35; height: 30; anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text {
                        text: catIconFont.status === FontLoader.Ready ? "\uf015" : "🏠"
                        font.family: catIconFont.name; font.pixelSize: 16
                        color: homeBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: { currentSubMode = "main"; activeCategory = ""; filterField.text = ""; }
                }

                // BACK BUTTON (Iconized)
                Button {
                    id: internalBackBtn
                    visible: currentSubMode !== "main"
                    width: 35; height: 30; anchors.verticalCenter: parent.verticalCenter
                    
                    contentItem: Text {
                        text: catIconFont.status === FontLoader.Ready ? "\uf060" : "←"
                        font.family: catIconFont.name; font.pixelSize: 16
                        color: internalBackBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: {
                        currentSubMode = "main";
                        activeCategory = "";
                        filterField.text = "";
                    }
                }

                Text {
                    text: activeCategory === "" ? "SELECT CATEGORY" : activeCategory.toUpperCase()
                    color: "gold"; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- VIEW 1: CATEGORY TILES (Synchronized Styling) ---
        Grid {
            visible: currentSubMode === "main"
            columns: 2; spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                delegate: Button {
                    id: tileBtn
                    width: 160; height: 80
                    
                    contentItem: Text {
                        text: modelData
                        color: tileBtn.hovered ? "#00F2FF" : "white"
                        font.pixelSize: 14; font.bold: true
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: tileBtn.hovered ? "#3300F2FF" : "#11FFFFFF"
                        radius: 8; border.color: tileBtn.hovered ? "#00F2FF" : "#33FFFFFF"
                    }
                    
                    onClicked: {
                        activeCategory = modelData;
                        currentSubMode = (modelData === "Decade") ? "year" : "search";
                    }
                }
            }
        }

        // --- VIEW 2: SEARCH BOX + DISCOVERY CLOUD ---
        Column {
            visible: currentSubMode === "search"
            width: parent.width; spacing: 15

            TextField {
                id: filterField
                width: parent.width; height: 40
                placeholderText: "Filter " + activeCategory + "..."
                color: "white"; leftPadding: 40
                background: Rectangle {
                    color: "#15FFFFFF"; radius: 20
                    border.color: filterField.activeFocus ? "gold" : "#444"
                    Text { 
                        text: "🔍"; color: "gold"; font.pixelSize: 14
                        anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter 
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 350; color: "transparent"; clip: true
                Flickable {
                    anchors.fill: parent; contentHeight: cloudFlow.height; clip: true
                    
                    Flow {
                        id: cloudFlow; width: parent.width - 10; spacing: 8
                        Repeater {
                            model: {
                                if (currentSubMode !== "search") return [];
                                // Use collectionLogic as per your original file
                                return (typeof collectionLogic !== 'undefined' && collectionLogic !== null) 
                                    ? collectionLogic.get_filtered_keywords(activeCategory, filterField.text) : []
                            }
                            
                            delegate: Button {
                                id: cloudItem
                                padding: 10
                                contentItem: Text {
                                    text: modelData; color: cloudItem.hovered ? "black" : "gold"
                                    font.bold: true; font.pixelSize: 12
                                }
                                background: Rectangle {
                                    color: cloudItem.hovered ? "gold" : "transparent"
                                    border.color: "gold"; border.width: 1; radius: 17
                                }
                                onClicked: {
                                    architectRoot.updateRule(panelRoot.panelIndex, "category", activeCategory + " = " + modelData);
                                }
                            }
                        }
                    }
                    ScrollBar.vertical: ScrollBar { active: true }
                }
            }
        }

        // --- VIEW 3: YEAR RANGE ---
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
                id: yearBtn
                width: parent.width; height: 45
                contentItem: Text { text: "SET YEAR RANGE"; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { color: "#00F2FF"; radius: 6 }
                onClicked: {
                    var range = "Year = " + yearFrom.value + " - " + yearTo.value;
                    architectRoot.updateRule(panelRoot.panelIndex, "category", range);
                }
            }
        }
    }
}