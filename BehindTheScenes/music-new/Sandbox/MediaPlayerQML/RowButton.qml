import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Column {
    id: buttonColumn
    width: parent.width
    spacing: 12
    z: 9999 

    // --- ROW 1: NAVIGATION BUTTONS ---
    Row {
        id: buttonRow
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        
        property int buttonWidth: 130
        property int buttonHeight: 40 
        property int buttonCount: 5 
        property real spacingCalc: (width - (buttonCount * buttonWidth)) / (buttonCount - 1)

        spacing: spacingCalc

        StyledButton {
            text: "Menu"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: libraryPanel.x = (libraryPanel.x === 0) ? -libraryPanel.width : 0
        }
        StyledButton {
            text: "Video"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: isVideoPanelVisible = !isVideoPanelVisible
        }
        StyledButton {
            text: "Collections"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: contentLoader.setSource("CategoryMenu.qml")
        }
        StyledButton {
            text: "Create"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: utilitySidebar.showCollectionCreator()
        }
        StyledButton {
            text: "Close"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: Qt.quit()
        }
    }

    // --- ROW 2: SEARCH BAR ---
    Rectangle {
        id: searchBarContainer
        width: parent.width * 0.7 
        height: 45 
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 22.5
        color: "#E6000000" 
        border.color: searchInput.activeFocus ? "yellow" : "#44FFFFFF"
        border.width: 2

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20; anchors.rightMargin: 20

            Text { 
                text: "🔍"
                font.pixelSize: 20
                color: "white" 
            }

            TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: "Search W:/Collection..."
                color: "white"
                font.pixelSize: 20
                verticalAlignment: TextInput.AlignVCenter
                background: null 

                onTextChanged: {
                    if (text.length >= 3) {
                        console.log("📡 QML: Requesting Search for ->", text)
                        searchController.perform_search(text)
                    } else {
                        resultsPopup.visible = false
                    }
                }
            }
        }

        // --- RESULTS POPUP ---
        Rectangle {
            id: resultsPopup
            width: parent.width
            height: Math.min(resultsList.contentHeight + 10, 400) 
            anchors.top: parent.bottom
            anchors.topMargin: 10
            color: "#F21A1A1A"
            border.color: "yellow"
            border.width: 1
            visible: resultsList.count > 0
            radius: 8
            z: 10001 

            ListView {
                id: resultsList
                anchors.fill: parent
                anchors.margins: 5
                model: []
                clip: true

                delegate: ItemDelegate {
                    width: resultsList.width
                    height: 45

                    contentItem: RowLayout {
                        spacing: 10
                        Text { 
                            text: modelData.hasMetadata ? "🎬" : "📄"
                            font.pixelSize: 16 
                        }
                        Text {
                            text: modelData.name || "Unknown Item"
                            color: "white"
                            font.pixelSize: 16
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    // --- THE PURE PRINT TEST ---
                    onClicked: {
                        var moviePath = modelData.filePath
                        var movieName = modelData.name

                        console.log("📡 QML: Sending path to Python: " + moviePath)
                        // CALL THE NEW PYTHON SLOT
                        searchController.confirm_selection(moviePath)



                        console.log("=======================================")
                        console.log("✅ CLICK REGISTERED ON QML SIDE")
                        console.log("🎥 TARGET NAME: " + movieName)
                        console.log("📂 TARGET PATH: " + moviePath)
                        console.log("=======================================")

                        // UI Cleanup
                        resultsPopup.visible = false
                        searchInput.text = ""
                        searchInput.focus = false
                    }

                    background: Rectangle {
                        color: highlighted ? "#44FFFF00" : "transparent"
                        radius: 4
                    }
                }
            }
        }
    }

    // --- BACKEND CONNECTION ---
    Connections {
        target: searchController
        ignoreUnknownSignals: true
        function onResultsUpdated(results) {
            console.log("📥 QML: Received " + results.length + " results")
            resultsList.model = results
            resultsPopup.visible = (results.length > 0)
        }
    }
}