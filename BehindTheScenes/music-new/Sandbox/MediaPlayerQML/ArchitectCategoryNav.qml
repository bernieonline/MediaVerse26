import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: catNavRoot
    anchors.fill: parent

    property Item parentPanel: null
    property string currentSubMode: "main"
    property string activeCategory: "" 

    FontLoader { 
        id: catIconFont
        source: {
            var p = _paths.font_path || _paths.fonts || "";
            if (p === "") return "";
            return "file:///" + p.replace(/\\/g, "/");
        }
    }

    ListModel { id: selectedItemsModel }

    function syncMasterRule() {
        var items = [];
        for (var i = 0; i < selectedItemsModel.count; i++) {
            items.push(selectedItemsModel.get(i).val);
        }
        var finalValue = items.join(", ");
        
        if (parentPanel) {
            parentPanel.currentResults = [activeCategory + " = " + finalValue];
        }
        architectController.request_category_matches(activeCategory, finalValue);
    }

    Column {
        id: mainLayout
        width: parent.width
        height: parent.height - 20 
        anchors.top: parent.top
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

        // --- THE VISUAL STACK (Tags) ---
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
                        Text { text: model.val; color: "white"; font.pixelSize: 11; font.bold: true }
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

        // --- VIEW 1: CATEGORY TILES (RESTORED) ---
        Grid {
            id: categoryGrid
            visible: currentSubMode === "main"
            columns: 2; spacing: 12; anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                delegate: Button {
                    id: tileBtn
                    width: 140; height: 70
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

        // --- VIEW 2: SEARCH + CLOUD (RESTORED) ---
        Column {
            visible: currentSubMode === "search"
            width: parent.width; spacing: 10
            TextField {
                id: filterField
                width: parent.width; height: 35; placeholderText: "Filter " + activeCategory + "..."
                color: "white"; leftPadding: 35
                background: Rectangle {
                    color: "#15FFFFFF"; radius: 17
                    border.color: filterField.activeFocus ? "gold" : "#444"
                }
            }
            
            Flickable {
                width: parent.width; height: 300; contentHeight: cloudFlow.height; clip: true
                Flow {
                    id: cloudFlow; width: parent.width; spacing: 6
                    Repeater {
                        // Crucial: Call Python to get keywords based on active category
                        model: (currentSubMode === "search") ? architectController.get_filtered_keywords(activeCategory, filterField.text) : []
                        delegate: Button {
                            id: cloudItem; padding: 8
                            contentItem: Text { text: modelData; color: cloudItem.hovered ? "black" : "gold"; font.bold: true; font.pixelSize: 11 }
                            background: Rectangle {
                                color: cloudItem.hovered ? "gold" : "transparent"
                                border.color: "gold"; radius: 14
                            }
                            onClicked: {
                                selectedItemsModel.append({"val": modelData});
                                syncMasterRule();
                            }
                        }
                    }
                }
                ScrollBar.vertical: ScrollBar { active: true }
            }
        }
    }

    Connections {
        target: architectController
        ignoreUnknownSignals: true
        function onResultsCounted(panelIndex, panelCount) {
            if (parentPanel && (panelIndex === parentPanel.panelIndex || panelIndex === -1)) {
                parentPanel.hitCount = panelCount;
            }
        }
    }
}