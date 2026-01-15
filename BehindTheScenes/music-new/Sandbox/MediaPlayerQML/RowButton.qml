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
        property int buttonCount: 6
        property real spacingCalc: (width - (buttonCount * buttonWidth)) / (buttonCount - 1)

        spacing: spacingCalc

        // --- NEW FREESTYLE BUTTON ---
        StyledButton {
            id: freestyleBtn
            text: "Freestyle"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            
            contentItem: Item {
                anchors.fill: parent
                Text {
                    text: parent.parent.text
                    anchors.centerIn: parent
                    color: "gold"
                    font.bold: true
                    font.letterSpacing: 1
                    z: 2
                }
                Text {
                    text: "🦅"
                    anchors.centerIn: parent
                    opacity: 0.3
                    font.pixelSize: 24
                    z: 1
                }
            }

            onClicked: {
                splash.deactivate()
                console.log("🚀 Soaring into Freestyle Mode...")
                contentLoader.setSource("Freestyle.qml")
            }
        }

        StyledButton {
            text: "Menu"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                splash.deactivate()
                libraryPanel.x = (libraryPanel.x === 0) ? -libraryPanel.width : 0
            }
        }

        StyledButton {
            text: "Video"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                splash.deactivate()
                isVideoPanelVisible = !isVideoPanelVisible
            }
        }

        StyledButton {
            text: "Collections"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                splash.deactivate()
                contentLoader.setSource("CategoryMenu.qml")
            }
        }

        StyledButton {
            text: "Create"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                splash.deactivate()
                utilitySidebar.showCollectionCreator()
            }
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
                        resultsPopup.close()
                    }
                }
            }
        }

        // Connect to Python SearchController signals
        Connections {
            target: searchController
            
            function onResultsUpdated(results) {
                resultsModel.clear()
                for (var i = 0; i < results.length; i++) {
                    resultsModel.append(results[i])
                }
                if (results.length > 0) {
                    resultsPopup.open()
                } else {
                    resultsPopup.close()
                }
            }
        }

        Popup {
            id: resultsPopup
            y: parent.height + 5
            width: parent.width
            height: Math.min(resultsModel.count * 40, 400)
            padding: 0
            background: Rectangle { 
                color: "#F21A1A1A"
                border.color: "gold"
                radius: 10
            }

            ListView {
                id: resultsList
                anchors.fill: parent
                model: ListModel { id: resultsModel }
                clip: true
                delegate: ItemDelegate {
                    width: parent.width
                    height: 40
                    contentItem: Text {
                        text: "🎬  " + model.name 
                        color: hovered ? "gold" : "white"
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 15
                    }
                    background: Rectangle {
                        color: hovered ? "#33D4AF37" : "transparent"
                    }
                    onClicked: {
                        console.log("🎥 Selecting:", model.filePath)
                        searchController.confirm_selection(model.filePath)
                        resultsPopup.close()
                        searchInput.text = ""
                    }
                }
            }
        }
    }
}