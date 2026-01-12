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
        property int buttonCount: 6  // Updated from 5 to 6
        property real spacingCalc: (width - (buttonCount * buttonWidth)) / (buttonCount - 1)

        spacing: spacingCalc

        // --- NEW FREESTYLE BUTTON ---
        StyledButton {
            id: freestyleBtn
            text: "Freestyle"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            
            // This is where we "advertise" the bird
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
                    text: "🦅" // Placeholder for your stylized gold bird outline icon/image
                    anchors.centerIn: parent
                    opacity: 0.3
                    font.pixelSize: 24
                    z: 1
                }
            }

            onClicked: {
                console.log("🚀 Soaring into Freestyle Mode...")
                // Logic to swap the ContentLoader to your new FreestyleWorkbench.qml
                contentLoader.setSource("Freestyle.qml")
            }
        }

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
    // ... (rest of your search bar code remains unchanged)
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
        // ... (remaining popup and connection code)
    }
}