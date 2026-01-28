import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: catNavRoot
    anchors.fill: parent

    property string currentSubMode: "main"
    property string activeCategory: "" 

    // --- ICON LOADER ---
    FontLoader { id: catIconFont; source: paths.font_path }

    // --- THE STACK MODEL ---
    ListModel { id: selectedItemsModel }

    // Function to push the current stack to the master Architect rule
    function syncMasterRule() {
        var items = [];
        for (var i = 0; i < selectedItemsModel.count; i++) {
            items.push(selectedItemsModel.get(i).val);
        }
        var finalValue = items.join(", ");
        
        // Passes path, category string, and the filter checkbox state
        architectRoot.updateRule(
            panelRoot.panelIndex, 
            "category", 
            activeCategory + " = " + finalValue,
            filterToggle.checked
        );
    }

    // --- MAIN CONTENT AREA (Everything except the Footer) ---
    Column {
        id: mainLayout
        width: parent.width
        height: parent.height - footerBar.height - 20
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

        // --- THE VISUAL STACK (Tags with Crosses) ---
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
                    width: 150; height: 70
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
            width: parent.width; spacing: 10
            TextField {
                id: filterField
                width: parent.width; height: 35; placeholderText: "Filter " + activeCategory + "..."
                color: "white"; leftPadding: 35
                background: Rectangle {
                    color: "#15FFFFFF"; radius: 17
                    border.color: filterField.activeFocus ? "gold" : "#444"
                    Text { text: "🔍"; color: "gold"; anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Rectangle {
                width: parent.width; height: 260; color: "transparent"; clip: true
                Flickable {
                    anchors.fill: parent; contentHeight: cloudFlow.height; clip: true
                    Flow {
                        id: cloudFlow; width: parent.width - 10; spacing: 6
                        Repeater {
                            model: (currentSubMode === "search" && typeof collectionLogic !== 'undefined') 
                                   ? collectionLogic.get_filtered_keywords(activeCategory, filterField.text) : []
                            delegate: Button {
                                id: cloudItem
                                padding: 8
                                contentItem: Text {
                                    text: modelData; color: cloudItem.hovered ? "black" : "gold"
                                    font.bold: true; font.pixelSize: 11
                                }
                                background: Rectangle {
                                    color: cloudItem.hovered ? "gold" : "transparent"
                                    border.color: "gold"; border.width: 1; radius: 14
                                }
                                onClicked: {
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
        }
    }

    // --- FIXED LOGIC BAR (Bottom Anchored) ---
    Row {
        id: footerBar
        width: parent.width - 20
        height: 45
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 10
        spacing: 8
        visible: currentSubMode !== "main"

        CheckBox {
            id: filterToggle
            width: 85; height: parent.height
            enabled: panelRoot.panelIndex > 0
            opacity: enabled ? 1.0 : 0.4
            
            indicator: Rectangle {
                implicitWidth: 18; implicitHeight: 18
                y: parent.height/2 - 9; radius: 3
                border.color: filterToggle.enabled ? "#00F2FF" : "gray"
                color: "transparent"
                Rectangle { 
                    width: 10; height: 10; x: 4; y: 4; radius: 2; 
                    color: "#00F2FF"; visible: filterToggle.checked 
                }
            }

            contentItem: Text {
                text: "Filter"; font.pixelSize: 12; color: filterToggle.enabled ? "white" : "gray"
                leftPadding: 24; verticalAlignment: Text.AlignVCenter
            }
            
            ToolTip.visible: hovered
            ToolTip.delay: 400
            ToolTip.text: enabled ? "Narrow down results from previous panels" : "First panel defines the source"

            onClicked: syncMasterRule()
        }

        Button {
            id: actionBtn
            width: parent.width - filterToggle.width - parent.spacing; height: parent.height
            contentItem: Text { 
                text: currentSubMode === "year" ? "SET YEAR RANGE" : "USE SELECTION"
                color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
            }
            background: Rectangle { color: "#00F2FF"; radius: 6 }
            onClicked: {
                if (currentSubMode === "year") {
                    var range = yearFrom.value + "-" + yearTo.value;
                    selectedItemsModel.clear();
                    selectedItemsModel.append({"val": range});
                }
                syncMasterRule();
            }
        }
    }
}