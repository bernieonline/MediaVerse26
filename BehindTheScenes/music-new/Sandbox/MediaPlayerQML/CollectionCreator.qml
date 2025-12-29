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
    property string statusMessage: "" // New status tracking

    // Clear status when clicking anywhere in the panel
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onPressed: (mouse) => {
            creatorRoot.statusMessage = ""
            mouse.accepted = false // Allows buttons and fields to still work
        }
    }

    function updateResults() {
        if (typeof collectionLogic !== 'undefined' && collectionLogic !== null) {
            let results = collectionLogic.get_collection_results(currentCriteria)
            resultsCount = results.length
        }
    }

    onVisibleChanged: {
        if (visible) {
            updateResults()
            creatorRoot.statusMessage = ""
        }
    }

    Connections {
        target: collectionLogic
        function onCacheRebuilt() {
            updateResults()
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

        // Category Selector
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
                            currentCriteria = {}; 
                            creatorRoot.statusMessage = "";
                            updateResults();      
                        }
                    }
                }
            }
        }

        // Filter Options List
        Rectangle {
            width: parent.width
            height: parent.height - 420 // Adjusted to make room for status message
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
                                creatorRoot.statusMessage = ""
                                updateResults()
                            }
                        }
                    }
                }
            }
        }

        // Inline Status Notification
        Text {
            id: statusLabel
            width: parent.width
            text: creatorRoot.statusMessage
            color: "gold"
            font.pixelSize: 12
            font.italic: true
            horizontalAlignment: Text.AlignRight
            opacity: creatorRoot.statusMessage !== "" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Summary and Save Section
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
                id: saveButton
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

                onClicked: {
                    let finalName = nameInput.text.trim();
                    
                    // Smart Trap: Auto-generate name if empty
                    if (finalName === "") {
                        let keys = Object.keys(currentCriteria);
                        if (keys.length > 0) {
                            let autoParts = keys.map(k => currentCriteria[k]);
                            finalName = autoParts.join(" & ") + " Collection";
                            nameInput.text = finalName;
                        }
                    }

                    if (finalName === "") {
                        notificationManager.post_notification("Please select a filter or enter a name!", true);
                    } else {
                        // 1. Python Save
                        collectionLogic.save_collection_template(finalName, currentCriteria);
                        
                        // 2. Local Inline Feedback
                        creatorRoot.statusMessage = "✓ " + finalName + " Created";

                        // 3. Reset for next use
                        currentCriteria = {};
                        nameInput.text = "";
                        updateResults();
                        
                        // We do NOT close the panel here, allowing for "On-The-Fly" creation
                    }
                }
            }
        }
    }
}