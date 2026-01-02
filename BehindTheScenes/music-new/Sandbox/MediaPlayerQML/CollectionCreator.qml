import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: creatorRoot
    width: 400 
    height: parent.height
    color: "#D9121212" 
    
    // --- 1. CLICK BLOCKER ---
    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => mouse.accepted = true
    }

    Rectangle {
        width: 3; height: parent.height; color: "gold"; anchors.left: parent.left
    }
    
    property string collectionName: ""
    property var currentCriteria: ({})
    property string activeCategory: "Actors" 
    property int resultsCount: 0
    property bool isFavorite: false
    property string feedbackMessage: ""
    property color feedbackColor: "#00FF7F"

    Timer {
        id: feedbackTimer
        interval: 3000
        onTriggered: feedbackText.opacity = 0
    }

    SequentialAnimation {
        id: nameWarningAnim
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "red"; duration: 200 }
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "gold"; duration: 200 }
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "red"; duration: 200 }
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "#444"; duration: 400 }
    }

    function updateResults() {
        if (typeof collectionLogic !== 'undefined' && collectionLogic !== null) {
            let results = collectionLogic.get_collection_results(currentCriteria)
            resultsCount = results.length
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 25 

        Text {
            text: "QUICK COLLECTION"
            color: "gold"; font.pixelSize: 22; font.bold: true; font.letterSpacing: 2
        }

        // --- NAME INPUT SECTION ---
        Column {
            width: parent.width; spacing: 8 
            Text { text: "COLLECTION NAME"; color: "#AAA"; font.pixelSize: 11; font.bold: true }
            RowLayout {
                width: parent.width; spacing: 15
                TextField {
                    id: nameInput
                    Layout.fillWidth: true
                    placeholderText: "Type name..."
                    color: "white"; font.pixelSize: 16
                    background: Rectangle {
                        id: nameInputBg
                        // --- OPAQUE BACKGROUND ---
                        color: "#252525" 
                        radius: 4
                        border.color: nameInput.activeFocus ? "gold" : "#444"
                        border.width: 2
                    }
                }
                Text {
                    text: creatorRoot.isFavorite ? "★" : "☆"
                    color: "gold"; font.pixelSize: 30
                    MouseArea { anchors.fill: parent; onClicked: creatorRoot.isFavorite = !creatorRoot.isFavorite }
                }
            }
        }
        // --- CATEGORIES ---
        Flow {
            width: parent.width; spacing: 12
            Repeater {
                model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                delegate: Text {
                    text: modelData
                    color: activeCategory === modelData ? "gold" : "#BBB"
                    font.pixelSize: 14; font.bold: activeCategory === modelData
                    MouseArea { 
                        anchors.fill: parent; 
                        onClicked: { 
                            // 1. Switch the tab
                            activeCategory = modelData; 
                            
                            // 2. Clear the search text
                            filterField.text = ""; 
                            
                            // 3. FIX: Clear the old filter criteria (e.g., remove Aaron Eckhart)
                            // so you can search fresh in the new category
                            currentCriteria = {}; 
                            
                            // 4. Update the "Matches" count to reflect the reset
                            updateResults();
                        } 
                    }
                }
            }
        }

        

        // --- SEARCH SECTION ---
        Column {
            width: parent.width; spacing: 8
            Text { text: "SEARCH " + activeCategory.toUpperCase(); color: "#AAA"; font.pixelSize: 11; font.bold: true }
            TextField {
                id: filterField
                width: parent.width
                placeholderText: "Find..."
                color: "white"; leftPadding: 45; font.pixelSize: 14
                background: Rectangle {
                    color: "#15FFFFFF"; radius: 20; border.color: filterField.activeFocus ? "gold" : "#666"; border.width: 2
                    Text { text: "🔍"; anchors.left: parent.left; anchors.leftMargin: 15; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }

        // --- DISCOVERY CLOUD ---
        // --- DISCOVERY CLOUD ---
        Rectangle {
            width: parent.width; height: 400; color: "transparent"; clip: true
            Flickable {
                anchors.fill: parent; contentHeight: keywordFlow.height; clip: true
                ScrollBar.vertical: ScrollBar { width: 4; policy: ScrollBar.AsNeeded }
                Flow {
                    id: keywordFlow; width: parent.width - 10; spacing: 8
                    
                    Repeater {
                        // FIX: We use a block to force QML to re-evaluate when 
                        // activeCategory or filterField.text changes
                        model: {
                            var cat = activeCategory
                            var text = filterField.text
                            if (typeof collectionLogic !== 'undefined' && collectionLogic !== null) {
                                return collectionLogic.get_filtered_keywords(cat, text)
                            }
                            return []
                        }
                        
                        delegate: Button {
                            background: Rectangle {
                                implicitWidth: lbl.implicitWidth + 24; implicitHeight: 34
                                color: currentCriteria[activeCategory] === modelData ? "gold" : "transparent"
                                border.color: "gold"; border.width: 1; radius: 17
                            }
                            contentItem: Text {
                                id: lbl; text: modelData
                                color: currentCriteria[activeCategory] === modelData ? "black" : "gold"
                                font.pixelSize: 12; font.bold: true
                            }
                            onClicked: {
                                // 1. Set the collection name to the keyword automatically
                                nameInput.text = modelData;

                                // 2. THE FIX: Create a brand new, empty object
                                // This ensures any previous category (like Actor) is wiped out
                                let freshCriteria = {};
                                
                                // 3. Add ONLY the current selection to the fresh object
                                freshCriteria[activeCategory] = modelData;
                                
                                // 4. Overwrite currentCriteria with our clean, single-parameter object
                                currentCriteria = freshCriteria;

                                // 5. Update the count (Matches: X Movies)
                                updateResults();
                            }
                        }
                    }
                }
            }
        }//discovery cloud

        // --- FOOTER AREA ---
        Item {
            width: parent.width; height: 100

            Text {
                id: feedbackText; anchors.top: parent.top; anchors.right: parent.right
                text: creatorRoot.feedbackMessage; color: creatorRoot.feedbackColor
                font.pixelSize: 13; font.bold: true; opacity: 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            Column {
                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                Text { text: "MATCHES"; color: "gold"; font.pixelSize: 10; font.bold: true }
                Text { text: resultsCount + " Movies"; color: "white"; font.pixelSize: 22; font.bold: true }
            }

            Row {
                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; spacing: 20

                // --- CLOSE BUTTON ---
                Column {
                    spacing: 4
                    Text { text: "CLOSE"; color: "gold"; font.pixelSize: 10; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Button {
                        id: closeBtn
                        width: 60; height: 60
                        background: Rectangle { 
                            color: closeBtn.pressed ? "#B8860B" : "gold"
                            radius: 30 
                        }
                        contentItem: Text { 
                            text: "✕"; font.pixelSize: 26; font.bold: true; 
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                        }
                        onClicked: {
                            creatorRoot.isShown = false 
                        }
                    }
                }

                // --- SAVE BUTTON ---
                Column {
                    spacing: 4
                    Text { text: "SAVE"; color: "gold"; font.pixelSize: 10; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Button {
                        id: saveBtn
                        width: 60; height: 60
                        background: Rectangle { color: saveBtn.pressed ? "#B8860B" : "gold"; radius: 30 }
                        contentItem: Text { text: "💾"; font.pixelSize: 26; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                            let name = nameInput.text.trim();
                            if (name === "") {
                                creatorRoot.feedbackMessage = "⚠ Name Required!";
                                creatorRoot.feedbackColor = "#FF4444";
                                feedbackText.opacity = 1;
                                nameWarningAnim.start();
                                feedbackTimer.restart();
                            } else {
                                collectionLogic.save_collection_v2(name, currentCriteria, activeCategory, creatorRoot.isFavorite);
                                creatorRoot.feedbackMessage = "✓ Saved: " + name;
                                creatorRoot.feedbackColor = "#00FF7F";
                                feedbackText.opacity = 1;
                                feedbackTimer.restart();
                                
                                currentCriteria = {}; 
                                nameInput.text = ""; 
                                filterField.text = ""; 
                                creatorRoot.isFavorite = false;
                                updateResults();
                            }
                        }
                    }
                }
            }
        }
    }
}