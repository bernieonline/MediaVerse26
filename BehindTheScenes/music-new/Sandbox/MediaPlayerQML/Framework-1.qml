import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick
import QtQuick.Controls
//version 1.0.1 border edge added to left panel
//1.o.2 sliding video panel added
//1.0.3 centre button moved to toolbar
//1.0.4 final adjustments made before applying styling to panels
//1.0.5 Glow effects added to main window

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"

    Material.theme: Material.Dark
    Material.accent: Material.Yellow

    // The colors used in this file are standard hex color codes.
    // If your editor is highlighting them as invalid, it might be a linter configuration issue.

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1e1e1e"
    }

    GlowStyling {
        target: border
    }

    Rectangle {
        id: border
        anchors.fill: parent
        anchors.margins: 10
        radius: 25
        color: "transparent"
        border.color: "yellow"
        border.width: 1
        z: 2
    }

    GlowStyling {
        target: sidePanel
    }

    Rectangle {
        id: sidePanel
        width: 300
        height: parent.height * 2 / 3
        anchors.verticalCenter: parent.verticalCenter
        x: -width
        z: 2
        color: "transparent"
        radius: 25
        border.color: "yellow"
        border.width: 1

        Behavior on x {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Rectangle {
            // This is the background
            anchors.fill: parent
            anchors.margins: 5
            color: "#1e1e1e"
            radius: 20
            border.width: 0

            Label {
                id: chooseLocationLabel
                text: "Choose a Location"
                color: white
                font.pixelSize: 20
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10
                padding: 10
                background: Rectangle {
                    color: "white"
                    border.color: "yellow"
                    border.width: 1
                    radius: 5
                }

            ComboBox {
                id: categoryCombo
                anchors.top: chooseLocationLabel.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 20
                
                width: parent.width -40
                model: ["All Files", "Images", "Videos", "Documents"]
                    currentIndex: 0
                }  

            }

            ListView {
                id: fileView
                anchors.fill: parent
                anchors.topMargin: 100
                anchors.bottomMargin: 80
                clip: true
                model: 50
                delegate: Item {
                    width: fileView.width
                    height: 40
                    //populates side panel with demo
                    Text {
                        text: "Folder or File " + (index + 1)
                        color: "white"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                    }
                }
            }

            Timer {
                id: scrollTimer
                interval: 50
                repeat: true
                property int scrollStep: 0
                onTriggered: {
                    fileView.contentY += scrollStep;
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 15
                spacing: 10

                Loader {
                    sourceComponent: scrollButtonComponent
                    onLoaded: {
                        item.text = "▲";
                        item.scrollAmount = -10;
                    }
                }
                Loader {
                    sourceComponent: scrollButtonComponent
                    onLoaded: {
                        item.text = "▼";
                        item.scrollAmount = 10;
                    }
                }
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
                    border.color: "#555"

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
                            scrollTimer.scrollStep = scrollAmount;
                            scrollTimer.start();
                        }
                        onExited: {
                            scrollTimer.stop();
                        }
                    }
                }
            }
        }
    }

    GlowStyling {
        target: videoPanel
    }

    Rectangle {
        id: videoPanel
        height: parent.height * 0.25
        width: height * 16 / 9
        anchors.horizontalCenter: parent.horizontalCenter
        y: isVideoPanelVisible ? parent.height - height : parent.height
        z: 2

        color: "transparent"
        radius: 25
        border.color: "yellow"
        border.width: 1

        Behavior on y {
            NumberAnimation { duration: 1500; easing.type: Easing.OutCubic }
        }

        Rectangle {
            // This is the background
            anchors.fill: parent
            anchors.margins: 5
            color: "#1e1e1e"
            radius: 20
            border.width: 0

            // In the future, the video player component will go here
            Text {
                anchors.centerIn: parent
                text: "Mini Video Player"
                color: "white"
                font.pixelSize: 24
            }
        }
    }

    property bool isVideoPanelVisible: false

    Row {
        id: buttonRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80
        spacing: 40

        Button {
            id: menuButton
            text: "Menu"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: sidePanel.x = (sidePanel.x === 0) ? -sidePanel.width : 0
        }

        Button {
            id: videoButton
            text: "Video"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: isVideoPanelVisible = !isVideoPanelVisible
        }

        Button {
            text: "Close"
            width: 320
            height: 120

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: Qt.quit()
        }
    }
}