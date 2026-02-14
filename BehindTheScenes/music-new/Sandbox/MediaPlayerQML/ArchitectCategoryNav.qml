import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: catNavRoot
    anchors.fill: parent

    property Item parentPanel: null
    property string currentSubMode: "main"
    property string activeCategory: ""
    signal categorySelected(string key, string value, var panelList)

    FontLoader {
        id: catIconFont
        source: {
            var p = _paths.font_path || _paths.fonts || "";
            if (p === "") return "";
            return "file:///" + p.replace(/\\/g, "/");
        }
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
            width: parent.width
            height: 40
            color: "#22FFFFFF"
            radius: 6

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 8

                Button {
                    id: homeBtn
                    width: 35
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter

                    contentItem: Text {
                        text: catIconFont.status === FontLoader.Ready ? "\uf015" : "🏠"
                        font.family: catIconFont.name
                        font.pixelSize: 16
                        color: homeBtn.hovered ? "gold" : "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle { color: "transparent" }

                    onClicked: {
                        currentSubMode = "main"
                        activeCategory = ""
                    }
                }

                Text {
                    text: activeCategory === "" ? "SELECT CATEGORY" : activeCategory.toUpperCase()
                    color: "gold"
                    font.bold: true
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- VIEW 1: CATEGORY GRID ---
        Grid {
            visible: currentSubMode === "main"
            columns: 2
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]

                delegate: Button {
                    id: tileBtn
                    width: 140
                    height: 70

                    contentItem: Text {
                        text: modelData
                        color: tileBtn.hovered ? "#00F2FF" : "white"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    background: Rectangle {
                        color: tileBtn.hovered ? "#3300F2FF" : "#11FFFFFF"
                        radius: 8
                        border.color: tileBtn.hovered ? "#00F2FF" : "#33FFFFFF"
                    }

                    onClicked: {
                        activeCategory = modelData
                        currentSubMode = (modelData === "Decade") ? "year" : "search"
                    }
                }
            }
        }

        // --- VIEW 2: SEARCH / CLOUD ---
        Column {
            visible: currentSubMode === "search"
            width: parent.width
            spacing: 10

            TextField {
                id: filterField
                width: parent.width
                height: 35
                placeholderText: "Filter " + activeCategory + "..."
                color: "white"
                background: Rectangle {
                    color: "#15FFFFFF"
                    radius: 17
                    border.color: filterField.activeFocus ? "gold" : "#444"
                }
            }

            Flickable {
                width: parent.width
                height: 300
                contentHeight: cloudFlow.height
                clip: true

                Flow {
                    id: cloudFlow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: (currentSubMode === "search"
                                && typeof architectController !== "undefined")
                               ? architectController.get_filtered_keywords(
                                     activeCategory,
                                     filterField.text
                                 )
                               : []

                        delegate: Button {
                            id: cloudItem
                            padding: 8

                            contentItem: Text {
                                text: modelData
                                color: cloudItem.hovered ? "black" : "gold"
                                font.bold: true
                                font.pixelSize: 11
                            }

                            background: Rectangle {
                                color: cloudItem.hovered ? "gold" : "transparent"
                                border.color: "gold"
                                radius: 14
                                border.width: 1
                            }

                            onClicked: {
                                var key = activeCategory
                                var value = modelData
                                var list = []   // placeholder

                                // Emit the signal upward
                                categorySelected(key, value, list)

                                if (typeof architectController !== "undefined" && parentPanel) {
                                    architectController.category_mode_select(
                                        parentPanel.panelIndex,
                                        key,
                                        value
                                    )
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar { active: true }
            }
        }

        // --- VIEW 3: DECADE BUTTONS ---
        Flow {
            visible: currentSubMode === "year"
            width: parent.width
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: [1930, 1940, 1950, 1960, 1970, 1980, 1990, 2000, 2010, 2020]

                delegate: Button {
                    id: dBtn
                    width: (parent.width / 3) - 10
                    height: 50
                    text: modelData + "s"

                    background: Rectangle {
                        color: dBtn.hovered ? "#3300F2FF" : "#11FFFFFF"
                        radius: 6
                        border.color: "#00F2FF"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: dBtn.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        var key = "Decade"
                        var value = dBtn.text
                        var list = []   // placeholder

                        // Emit the signal upward
                        categorySelected(key, value, list)

                        if (typeof architectController !== "undefined" && parentPanel) {
                            architectController.category_mode_select(
                                parentPanel.panelIndex,
                                key,
                                value
                            )
                        }
                    }
                }
            }
        }
    }

    // --- CONNECTIONS ---
    Connections {
        target: architectController
        ignoreUnknownSignals: true

        function onResultsCounted(panelIndex, panelCount) {
            if (parentPanel && panelIndex === parentPanel.panelIndex) {
                parentPanel.hitCount = panelCount
            }
        }
    }
}