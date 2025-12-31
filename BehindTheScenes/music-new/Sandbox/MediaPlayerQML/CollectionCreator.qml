import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: creatorRoot
    width: 350
    height: parent.height
    color: "#D9121212" 
    border.color: "#66D4AF37" 
    border.width: 1
    
    property string collectionName: ""
    property var currentCriteria: ({})
    property string activeCategory: "Actors" 
    property var resultsCount: 0

    // Guarded function to prevent "null" errors during startup
    function updateResults() {
        if (typeof collectionLogic !== 'undefined' && collectionLogic !== null) {
            let results = collectionLogic.get_collection_results(currentCriteria)
            resultsCount = results.length
        }
    }

    // Refresh when the panel is opened
    onVisibleChanged: {
        if (visible) {
            updateResults()
        }
    }

    // Listen for the background scan to finish
    Connections {
        target: collectionLogic
        function onCacheRebuilt() {
            updateResults()
            // Force a refresh of the Repeater
            let temp = activeCategory
            activeCategory = ""
            activeCategory = temp
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        Text {
            text: "QUICK COLLECTION"
            color: "gold"
            font.pixelSize: 20
            font.bold: true
            font.letterSpacing: 2
        }

        TextField {
            id: nameInput
            width: parent.width
            placeholderText: "Name your collection..."
            color: "white"
            font.pixelSize: 14
            background: Rectangle {
                color: "#1AFFFFFF"
                radius: 4
                border.color: nameInput.activeFocus ? "gold" : "#333"
            }
            onTextChanged: creatorRoot.collectionName = text
        }

        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                delegate: Text {
                    text: modelData
                    color: activeCategory === modelData ? "gold" : "#888"
                    font.pixelSize: 12
                    font.bold: activeCategory === modelData
                    font.underline: activeCategory === modelData
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            activeCategory = modelData;
                            currentCriteria = {}; // Fixed the spelling and added semicolon
                            updateResults();      
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - 380
            color: "transparent"
            clip: true

            Column {
                width: parent.width
                spacing: 15

                Text {
                    text: "TOP 10 " + activeCategory.toUpperCase()
                    color: "#AAA"
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }

                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        // Guarded model to prevent startup crash
                        model: (typeof collectionLogic !== 'undefined' && collectionLogic !== null) 
                            ? collectionLogic.get_filter_options(activeCategory) 
                            : []
                        delegate: Button {
                            id: goldBtn
                            flat: true
                            contentItem: Text {
                                text: modelData
                                color: currentCriteria[activeCategory] === modelData ? "black" : "gold"
                                font.bold: true
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: 32
                                color: currentCriteria[activeCategory] === modelData ? "gold" : "transparent"
                                border.color: "gold"
                                border.width: 1
                                radius: 16
                            }
                            onClicked: {
                                if (currentCriteria[activeCategory] === modelData) {
                                    delete currentCriteria[activeCategory]
                                } else {
                                    currentCriteria[activeCategory] = modelData
                                }
                                currentCriteria = Object.assign({}, currentCriteria)
                                updateResults()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 140
            radius: 12
            color: "#22D4AF37"
            border.color: "#44D4AF37"

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                Text {
                    text: "COLLECTION SUMMARY"
                    color: "gold"
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    text: "Items: " + resultsCount
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    text: "Rules: " + (Object.keys(currentCriteria).length > 0 ? JSON.stringify(currentCriteria) : "None selected")
                    color: "#888"
                    font.pixelSize: 10
                    width: parent.width
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
            }

            Button {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                width: 50
                height: 50
                
                background: Rectangle {
                    color: "gold"
                    radius: 25
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        color: "#80000000"
                        radius: 8
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "💾" 
                    font.pixelSize: 20
                }
                //onclicked
                onClicked: {
                    // 1. Get the current text and trim whitespace
                    let finalName = nameInput.text.trim();
                    
                    // 2. TRAP: If name is empty, try to generate one
                    if (finalName === "") {
                        let keys = Object.keys(currentCriteria);
                        if (keys.length > 0) {
                            // Take the values of the rules (e.g., "1960s") and add " Collection"
                            let autoParts = keys.map(k => currentCriteria[k]);
                            finalName = autoParts.join(" & ") + " Collection";
                            
                            // Show the user what we named it in the UI
                            nameInput.text = finalName;
                        }
                    }

                    // 3. FINAL VALIDATION: If it's STILL empty (no name AND no rules selected)
                    if (finalName === "") {
                        notificationManager.post_notification("Please select a filter or enter a name!", true);
                    } else {
                        // 4. Send to Python
                        collectionLogic.save_collection_template(finalName, currentCriteria);
                        notificationManager.post_notification("Saved: " + finalName, false);

                        // 5. Reset the Form
                        currentCriteria = {};
                        nameInput.text = "";
                        updateResults();

                        // Close the panel
                        if (creatorRoot.parent.hasOwnProperty("isShown")) {
                            creatorRoot.parent.isShown = false;
                        }
                    }
                }
            }
        }
    }
}