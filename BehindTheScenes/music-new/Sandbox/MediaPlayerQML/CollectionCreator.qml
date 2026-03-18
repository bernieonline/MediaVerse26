import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

// Root fills its parent (UtilitySidebar sets anchors.fill: parent + opacity)
Item {
    id: creatorRoot

    // ── Properties ──────────────────────────────────────────────────────
    property string collectionName: ""
    property var currentCriteria: ({})
    property string activeCategory: "Actors"
    property int resultsCount: 0
    property bool isFavorite: false
    property string feedbackMessage: ""
    property color feedbackColor: "#50E890"

    // ── Animations ──────────────────────────────────────────────────────
    SequentialAnimation {
        id: nameWarningAnim
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "#FF5050"; duration: 180 }
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "#3A5E78"; duration: 180 }
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "#FF5050"; duration: 180 }
        PropertyAnimation { target: nameInputBg; property: "border.color"; to: "#3A5E78"; duration: 360 }
    }

    Timer {
        id: feedbackTimer
        interval: 3000
        onTriggered: feedbackText.opacity = 0
    }

    // ── Logic ────────────────────────────────────────────────────────────
    function updateResults() {
        if (typeof collectionLogic !== 'undefined' && collectionLogic !== null) {
            let results = collectionLogic.get_collection_results(currentCriteria)
            resultsCount = results.length
        }
    }

    onVisibleChanged: {
        if (visible) updateResults()
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

    // ── 1. Dim overlay — click outside to dismiss ─────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#90080E1A"

        MouseArea {
            anchors.fill: parent
            onClicked: creatorRoot.isShown = false
        }
    }

    // ── 2. Floating glass panel ──────────────────────────────────────────
    Rectangle {
        id: panelBox
        width: 620
        height: 740
        anchors.centerIn: parent
        radius: 16
        color: "#F2090F1E"       // dark navy, ~95% opaque
        clip: true

        border.color: "#3D6E94"
        border.width: 2

        // Glass top-edge highlight
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 10
            height: 1
            color: "#558ABACC"
            radius: 1
        }

        // Drop shadow
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 44
            samples: 44
            color: "#C8020610"
        }

        // Block click-through to dim overlay
        MouseArea { anchors.fill: parent; onClicked: {} }

        // ── Header ───────────────────────────────────────────────────────
        Item {
            id: headerBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            // Subtle frosted tint on header (clip handled by panelBox)
            Rectangle {
                anchors.fill: parent
                color: "#1890BBDD"
            }

            // Bottom divider
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#2A4E6A"
            }

            Text {
                anchors.centerIn: parent
                text: "Quick Collection Builder"
                color: "#D8EAF4"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 0.4
            }

            // ✕ Close — top-right
            Rectangle {
                id: closeCircle
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                radius: 17
                color: closeMouse.containsMouse ? "#28607888" : "transparent"
                border.color: closeMouse.containsMouse ? "#507A96" : "#2A4A62"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? "#FFFFFF" : "#B0C8DC"
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: creatorRoot.isShown = false
                }
            }
        }

        // ── Content column ───────────────────────────────────────────────
        Column {
            id: contentCol
            anchors.top: headerBar.bottom
            anchors.bottom: footerBar.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            anchors.topMargin: 20
            anchors.bottomMargin: 12
            spacing: 16

            // ── Collection Name ──────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "Collection Name  (Optional)"
                    color: "#C0DCF2"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 0.8
                }

                RowLayout {
                    width: parent.width
                    spacing: 12

                    TextField {
                        id: nameInput
                        Layout.fillWidth: true
                        height: 46
                        placeholderText: "Give your collection a name..."
                        color: "#D8EAF4"
                        font.pixelSize: 15
                        leftPadding: 14
                        background: Rectangle {
                            id: nameInputBg
                            color: "#0E1F30"
                            radius: 8
                            border.color: nameInput.activeFocus ? "#4A9AC8" : "#2E5A7A"
                            border.width: 2
                        }
                        onTextChanged: creatorRoot.collectionName = text
                    }

                    // Favourite star — only gold when active
                    Text {
                        text: creatorRoot.isFavorite ? "★" : "☆"
                        color: creatorRoot.isFavorite ? "#D4A820" : "#7AACC4"
                        font.pixelSize: 28
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: creatorRoot.isFavorite = !creatorRoot.isFavorite
                        }
                    }
                }
            }

            // ── Category pills ───────────────────────────────────────────
            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: ["Actors", "Decade", "Director", "Genre", "Keywords", "Series"]
                    delegate: Rectangle {
                        id: catPill
                        height: 30
                        width: catLabel.implicitWidth + 22
                        radius: 15
                        color: activeCategory === modelData ? "#2566C2" : "#0D1E2E"
                        border.color: activeCategory === modelData
                                      ? "#4080D4"
                                      : (catHover.containsMouse ? "#4A7A9B" : "#2A4E68")
                        border.width: 1

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: activeCategory === modelData ? "#FFFFFF" : "#C0DCF0"
                            font.pixelSize: 13
                            font.bold: activeCategory === modelData
                        }

                        MouseArea {
                            id: catHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                activeCategory = modelData
                                filterField.text = ""
                                currentCriteria = {}
                                updateResults()
                            }
                        }
                    }
                }
            }

            // ── Search field ─────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "Search " + activeCategory
                    color: "#C0DCF2"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 0.8
                }

                TextField {
                    id: filterField
                    width: parent.width
                    height: 46
                    placeholderText: "Filter " + activeCategory.toLowerCase() + "..."
                    color: "#D8EAF4"
                    font.pixelSize: 15
                    leftPadding: 44
                    background: Rectangle {
                        color: "#0E1F30"
                        radius: 8
                        border.color: filterField.activeFocus ? "#4A9AC8" : "#2E5A7A"
                        border.width: 2

                        Text {
                            text: "🔍"
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 15
                        }
                    }
                }
            }

            // ── Discovery cloud ──────────────────────────────────────────
            Rectangle {
                width: parent.width
                // Fill remaining height between header content and footer
                height: contentCol.height
                       - 46   // name input
                       - 18   // name label+spacing
                       - 30   // cat pills
                       - 46   // search input
                       - 18   // search label+spacing
                       - 16*4 // 4× spacing
                color: "#0A1820"
                radius: 8
                border.color: "#1E3A52"
                border.width: 1
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: keywordFlow.height
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        policy: ScrollBar.AsNeeded
                    }

                    Flow {
                        id: keywordFlow
                        width: parent.width - 8
                        spacing: 8

                        Repeater {
                            model: {
                                var cat  = activeCategory
                                var txt  = filterField.text
                                if (typeof collectionLogic !== 'undefined' && collectionLogic !== null)
                                    return collectionLogic.get_filtered_keywords(cat, txt)
                                return []
                            }

                            delegate: Rectangle {
                                id: chip
                                height: 30
                                width: chipLabel.implicitWidth + 20
                                radius: 15
                                color: currentCriteria[activeCategory] === modelData
                                       ? "#2566C2" : "transparent"
                                border.color: currentCriteria[activeCategory] === modelData
                                              ? "#4080D4"
                                              : (chipHover.containsMouse ? "#4A7A9B" : "#2A4E68")
                                border.width: 1

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: currentCriteria[activeCategory] === modelData
                                           ? "#FFFFFF" : "#C0DCF0"
                                    font.pixelSize: 12
                                    font.bold: currentCriteria[activeCategory] === modelData
                                }

                                MouseArea {
                                    id: chipHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        nameInput.text = modelData
                                        let fresh = {}
                                        fresh[activeCategory] = modelData
                                        currentCriteria = fresh
                                        updateResults()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }// content column

        // ── Footer bar ───────────────────────────────────────────────────
        Item {
            id: footerBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            height: 52

            // Divider
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#1E3A52"
            }

            // Matches count — bottom left
            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "MATCHES"
                    color: "#90BEDD"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.2
                }
                Text {
                    text: resultsCount + " Movies"
                    color: "#E8F4FF"
                    font.pixelSize: 20
                    font.bold: true
                }
            }

            // Feedback message — centre
            Text {
                id: feedbackText
                anchors.centerIn: parent
                text: creatorRoot.feedbackMessage
                color: creatorRoot.feedbackColor
                font.pixelSize: 13
                font.bold: true
                opacity: 0
                Behavior on opacity { NumberAnimation { duration: 280 } }
            }

            // Buttons — bottom right
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Cancel
                Rectangle {
                    width: 96
                    height: 38
                    radius: 8
                    color: cancelHov.containsMouse ? "#18506070" : "transparent"
                    border.color: cancelHov.containsMouse ? "#507080" : "#2A4458"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: cancelHov.containsMouse ? "#FFFFFF" : "#B0C8DC"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: creatorRoot.isShown = false
                    }
                }

                // Save Collection
                Rectangle {
                    width: 168
                    height: 38
                    radius: 8
                    color: saveHov.containsMouse ? "#3076D2" : "#2566C2"
                    border.color: saveHov.containsMouse ? "#5090E0" : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Save Collection"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        id: saveHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let name = nameInput.text.trim()

                            // Auto-name from criteria if blank
                            if (name === "") {
                                let keys = Object.keys(currentCriteria)
                                if (keys.length > 0) {
                                    name = keys.map(k => currentCriteria[k]).join(" & ") + " Collection"
                                    nameInput.text = name
                                }
                            }

                            if (name === "") {
                                creatorRoot.feedbackMessage = "⚠  Select a filter or enter a name"
                                creatorRoot.feedbackColor   = "#FF5555"
                                feedbackText.opacity = 1
                                nameWarningAnim.start()
                                feedbackTimer.restart()
                            } else {
                                collectionLogic.save_collection_v2(
                                    name, currentCriteria, activeCategory, creatorRoot.isFavorite)
                                creatorRoot.feedbackMessage = "✓  Saved: " + name
                                creatorRoot.feedbackColor   = "#50E890"
                                feedbackText.opacity = 1
                                feedbackTimer.restart()
                                currentCriteria = {}
                                nameInput.text  = ""
                                filterField.text = ""
                                creatorRoot.isFavorite = false
                                updateResults()
                            }
                        }
                    }
                }
            }
        }
    }// panelBox
}
