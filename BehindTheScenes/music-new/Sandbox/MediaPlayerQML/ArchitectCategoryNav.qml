import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: catNavRoot
    anchors.fill: parent

    property string currentSubMode: "main"
    property string activeCategory: "" 

    FontLoader { id: catIconFont; source: paths.font_path }

    // --- RESTORED: THE STACK MODEL ---
    ListModel { id: selectedItemsModel }

    // Function to push the current stack to the master Architect rule
    function syncMasterRule() {
        var items = [];
        for (var i = 0; i < selectedItemsModel.count; i++) {
            items.push(selectedItemsModel.get(i).val);
        }
        var finalValue = items.join(", ");
        // Formats as "Genre = Action, Sci-Fi"
        architectRoot.updateRule(panelRoot.panelIndex, "category", activeCategory + " = " + finalValue);
    }

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
                    id: homeBtn
                    width: 35; height: 30; anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text {
                        text: catIconFont.status === FontLoader.Ready ? "\uf015" : "🏠"
                        font.family: catIconFont.name; font.pixelSize: 16
                        color: homeBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: { 
                        currentSubMode = "main"; activeCategory = ""; 
                        filterField.text = ""; selectedItemsModel.clear(); 
                    }
                }
                Text {
                    text: activeCategory === "" ? "SELECT CATEGORY" : activeCategory.toUpperCase()
                    color: "gold"; font.bold: true; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- RESTORED: THE VISUAL STACK (Tags with Crosses) ---
        Flow {
            width: parent.width; spacing: 5
            visible: selectedItemsModel.count > 0 && currentSubMode !== "main"
            Repeater {
                model: selectedItemsModel
                delegate: Rectangle {
                    height: 26; width: tagRow.width + 12
                    color: "#3300F2FF"; radius: 4; border.color: "#00F2FF"
                    Row {
                        id: tagRow; anchors.centerIn: parent; spacing: 8
                        Text { text: val; color: "white"; font.pixelSize: 11; font.bold: true }
                        Text { 
                            text: "×"; color: "#FF4444"; font.bold: true; font.pixelSize: 14
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    selectedItemsModel.remove(index);
                                    syncMasterRule();
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- VIEW 1: CATEGORY TILES ---
        Grid {
            visible: currentSubMode === "main"
            columns: 2; spacing: 12; anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                delegate: Button {
                    id: tileBtn
                    width: 160; height: 80
                    contentItem: Text {
                        text: modelData; color: tileBtn.hovered ? "#00F2FF" : "white"
                        font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter
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
                width: parent.width; height: 40; placeholderText: "Filter " + activeCategory + "..."
                color: "white"; leftPadding: 40
                background: Rectangle {
                    color: "#15FFFFFF"; radius: 20
                    border.color: filterField.activeFocus ? "gold" : "#444"
                    Text { text: "🔍"; color: "gold"; anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Rectangle {
                width: parent.width; height: 320; color: "transparent"; clip: true
                Flickable {
                    anchors.fill: parent; contentHeight: cloudFlow.height; clip: true
                    Flow {
                        id: cloudFlow; width: parent.width - 10; spacing: 8
                        Repeater {
                            model: (currentSubMode === "search" && typeof collectionLogic !== 'undefined') 
                                   ? collectionLogic.get_filtered_keywords(activeCategory, filterField.text) : []
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
                                    // Check for duplicates
                                    var exists = false;
                                    for(var i=0; i < selectedItemsModel.count; i++) {
                                        if(selectedItemsModel.get(i).val === modelData) exists = true;
                                    }
                                    if(!exists) {
                                        selectedItemsModel.append({"val": modelData});
                                        syncMasterRule();
                                    }
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
                    var range = yearFrom.value + "-" + yearTo.value;
                    selectedItemsModel.clear(); // Usually years are a single range
                    selectedItemsModel.append({"val": range});
                    syncMasterRule();
                }
            }
        }
    }
}