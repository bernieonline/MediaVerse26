import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15



Column {
    id: buttonColumn
    width: parent.width
    spacing: 12
    z: 9999 
    signal architectClicked()
    signal snatcherClicked()


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
                console.log("📚 Launching Architect Gallery...")

                buttonColumn.architectClicked()
                
                // 1. Swap the main view to our new Gallery
                contentLoader.setSource("ArchitectGallery.qml")
                
                // 2. Ensure sidebar/HUD are tucked away for the "cinematic" look
                if (typeof utilitySidebar !== "undefined") utilitySidebar.isOpen = false
                if (typeof architectHUD !== "undefined") architectHUD.visible = false

                //end click
            }
        }

        // --- 4. QUICK GALLERY ---
        StyledButton {
            text: "Quick Gallery"
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                contentLoader.setSource("CategoryMenu.qml")
            }
        }

        // --- 5. SNATCHER ---
        StyledButton {
            fixedWidth: buttonRow.buttonWidth; fixedHeight: buttonRow.buttonHeight
            contentItem: Item {
                anchors.fill: parent
                Text {
                    text: "Snatcher"
                    anchors.centerIn: parent
                    color: "#FF9800"; font.bold: true; font.letterSpacing: 1; z: 2
                }
                Text {
                    text: "📷"; anchors.centerIn: parent
                    opacity: 0.3; font.pixelSize: 22; z: 1
                }
            }
            onClicked: buttonColumn.snatcherClicked()
        }

        // --- 7. CREATE ---
        StyledButton {
            text: "Create"
            fixedWidth: 120; fixedHeight: buttonRow.buttonHeight
            onClicked: {
                if (typeof splash !== "undefined") splash.deactivate()
                utilitySidebar.showCollectionCreator()
            }
        }

        // --- 8. CLOSE ---
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
        // --- Results Popup ---
        Popup {
            id: resultsPopup
            y: searchBarContainer.height + 4
            x: 0
            width: searchBarContainer.width
            padding: 0
            modal: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

            background: Rectangle {
                color: "#EE0d0d0d"
                radius: 10
                border.color: "#2566c2"
                border.width: 2
            }

            contentItem: ListView {
                id: resultsList
                implicitHeight: Math.min(contentHeight, 400)
                clip: true
                model: []

                delegate: ItemDelegate {
                    width: resultsList.width
                    height: 52

                    background: Rectangle {
                        color: hovered ? "#2566c2" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    contentItem: Row {
                        spacing: 12
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 16

                        Image {
                            width: 34; height: 34
                            source: modelData.imageFilename || ""
                            fillMode: Image.PreserveAspectCrop
                            visible: modelData.imageFilename !== ""
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                            elide: Text.ElideRight
                            width: resultsList.width - 80
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    onClicked: {
                        if (typeof splash !== "undefined") splash.deactivate()
                        searchController.confirm_selection(modelData.filePath)
                        resultsPopup.close()
                        searchInput.text = ""
                    }
                }
            }
        }

        Connections {
            target: searchController
            function onResultsUpdated(results) {
                resultsList.model = results
                if (results.length > 0) resultsPopup.open()
                else resultsPopup.close()
            }
        }
    }
}