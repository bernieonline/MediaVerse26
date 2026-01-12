// SlidingPanel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    property int panelWidth: 300
    property color panelColor: "#1e1e1e"
    property color borderColor: "yellow"
    property int animationDuration: 300

    // Exposed models for parent to set
    property var libraryModel
    property var folderModel

    // Exposed signals
    signal folderSelected(string folderPath)
    signal viewRequested(string viewType)

    // Helper function for toggling
    function toggle() {
        x = (x === 0) ? -width : 0
        if (x === 0 && categoryCombo.currentIndex !== -1) {
            categoryCombo.activated(categoryCombo.currentIndex)
        }
    }

    width: panelWidth
    height: 600   // safe default; parent can override
    x: -width

    y: (parent.height - height) / 2  //sets it centrally on the left

    z: 10   // overlays other views
    color: "transparent"
    radius: 25
    border.color: borderColor
    border.width: 1

    Behavior on x {
        NumberAnimation { duration: animationDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        color: panelColor
        radius: 20

        Label {
            id: chooseLocationLabel
            text: "Choose a Location"
            color: "white"
            font.pixelSize: 20
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
        }

        ComboBox {
            id: categoryCombo
            anchors.top: chooseLocationLabel.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 20
            width: parent.width

            model: libraryModel
            textRole: "name"

            onActivated: function(index) {
                if (model[index]) {
                    // Triggers the update_folders thread in Python
                    folderSelected(model[index].path)
                }
            }

            background: Rectangle {
                color: "transparent"
                border.color: "yellow"
                border.width: 1
                radius: 5
            }

            contentItem: Text {
                text: parent.displayText
                color: "white"
                font: parent.font
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                elide: Text.ElideRight
            }

            indicator: Text {
                text: "▼"
                color: "yellow"
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
            }
        }

        ListView {
            id: fileView
            anchors.top: categoryCombo.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 20
            anchors.bottomMargin: 80
            clip: true

            model: folderModel ? folderModel : []
            property int currentIndex: -1

            delegate: Item {
                width: fileView.width
                height: 40

                Rectangle {
                    anchors.fill: parent
                    color: fileView.currentIndex === index ? "#555555" : "transparent"
                    radius: 5
                }

                Image {
                    source: "../../images/icons/icons8-movie-liquid-glass-color/icons8-movie-32.png"
                    width: 24; height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: modelData.folderName
                    color: "white"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 40
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        fileView.currentIndex = index
                        
                        // --- V2 LOGIC START ---
                        console.log("QML: Triggering V2 Scan for: " + modelData.folderPath)
                        
                        // Check for the Python bridge name from main.py
                        if (typeof fileSystemManager !== "undefined") {
                            // Call the specific V2 method we created
                            fileSystemManager.list_folder_content_v2(modelData.folderPath)
                        } else {
                            console.log("QML ERROR: fileSystemManager bridge not found!")
                        }

                        // Close panel and request the grid display
                        root.x = -root.width
                        viewRequested("grid") 
                        // --- V2 LOGIC END ---
                    }
                }
            }
        }

        // Scroll controls
        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 15
            spacing: 10

            Loader {
                sourceComponent: scrollButtonComponent
                onLoaded: {
                    item.text = "▲"
                    item.scrollAmount = -10
                }
            }
            Loader {
                sourceComponent: scrollButtonComponent
                onLoaded: {
                    item.text = "▼"
                    item.scrollAmount = 10
                }
            }
        }

        Timer {
            id: scrollTimer
            interval: 50
            repeat: true
            property int scrollStep: 0
            onTriggered: fileView.contentY += scrollStep
        }

        Component {
            id: scrollButtonComponent
            Rectangle {
                property string text
                property int scrollAmount

                width: 80
                height: 50
                color: "#333"
                radius: 8
                border.color: "yellow"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: parent.text
                    color: "white"
                    font.pixelSize: 24
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        scrollTimer.scrollStep = scrollAmount
                        scrollTimer.start()
                    }
                    onExited: scrollTimer.stop()
                }
            }
        }
    }
}