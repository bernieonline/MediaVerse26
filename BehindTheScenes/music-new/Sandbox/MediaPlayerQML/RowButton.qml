import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Column {
    id: buttonColumn
    width: parent.width
    spacing: 12
    z: 9999 

    Row {
        id: buttonRow
        anchors.horizontalCenter: parent.horizontalCenter
        
        // Slightly wider buttons to accommodate the longer "Architect" titles
        property int buttonWidth: 160
        property int buttonHeight: 40 
        spacing: 15 

        // --- 1. FREESTYLE ---
        StyledButton {
            id: freestyleBtn
            text: "Freestyle"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            contentItem: Item {
                anchors.fill: parent
                Text {
                    text: "Freestyle"
                    anchors.centerIn: parent
                    color: "gold"; font.bold: true; font.letterSpacing: 1; z: 2
                }
                Text {
                    text: "🦅"; anchors.centerIn: parent
                    opacity: 0.3; font.pixelSize: 24; z: 1
                }
            }
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                contentLoader.setSource("Freestyle.qml")
            }
        }

        // --- 2. ARCHITECT CREATOR (Renamed) ---
        StyledButton {
            id: builderBtn
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            contentItem: Item {
                anchors.fill: parent
                Text {
                    text: "Architect Creator"
                    anchors.centerIn: parent
                    color: "#00F2FF" // Your High-tech Cyan
                    font.bold: true; font.letterSpacing: 1
                }
            }
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                architectHUD.visible = true 
            }
        }

        // --- 3. ARCHITECT COLLECTIONS (New Button) ---
        StyledButton {
            id: archCollBtn
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            contentItem: Item {
                anchors.fill: parent
                Text {
                    text: "Architect Collections"
                    anchors.centerIn: parent
                    color: "gold" // Setting to Gold to distinguish from the Creator
                    font.bold: true; font.letterSpacing: 1
                }
            }
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                console.log("📚 Opening Saved Architect Collections...")
                // This is where we will trigger the Michael Caine/Top 10 display
            }
        }

        // --- 4. CATEGORIES (Renamed from Collections to avoid confusion) ---
        StyledButton {
            text: "Categories"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                contentLoader.setSource("CategoryMenu.qml")
            }
        }

        // --- 5. CREATE ---
        StyledButton {
            text: "Create"
            fixedWidth: 120; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                utilitySidebar.showCollectionCreator()
            }
        }

        // --- 6. CLOSE ---
        StyledButton {
            text: "Close"
            fixedWidth: 80; fixedHeight: buttonRow.buttonHeight
            onClicked: Qt.quit()
        }
    }

    // --- ROW 2: SEARCH BAR (Untouched) ---
    Rectangle {
        id: searchBarContainer
        width: parent.width * 0.7; height: 45 
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 22.5; color: "#E6000000" 
        border.color: searchInput.activeFocus ? "yellow" : "#44FFFFFF"; border.width: 2

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
            Text { text: "🔍"; font.pixelSize: 20; color: "white" }
            TextField {
                id: searchInput
                Layout.fillWidth: true; placeholderText: "Search W:/Collection..."
                color: "white"; font.pixelSize: 20; verticalAlignment: TextInput.AlignVCenter
                background: null 
                onTextChanged: {
                    if (text.length >= 3) searchController.perform_search(text)
                    else resultsPopup.close()
                }
            }
        }
        // ... [Results Popup logic remains exactly as per your source] ...
    }
}