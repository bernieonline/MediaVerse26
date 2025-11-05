import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick
import QtQuick.Controls
//version 1.0.1 border edge added to left panel
//1.o.2 sliding video panel added
//1.0.3 centre button moved to toolbar
ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"

    // The colors used in this file are standard hex color codes.
    // If your editor is highlighting them as invalid, it might be a linter configuration issue.

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1e1e1e"
    }

    Rectangle {
        id: border
        anchors.fill: parent
        anchors.margins: 10
        radius: 25
        color: "transparent"
        border.color: "#f1ba54"
        border.width: 5
    }

    Rectangle {
        id: sidePanel
        width: 300
        height: parent.height * 2 / 3
        anchors.verticalCenter: parent.verticalCenter
        x: -width
        color: "transparent"
        radius: 25
        border.color: "#f1ba54"
        border.width: 5

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

            ListView {
                id: fileView
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 80
                clip: true
                model: 50
                delegate: Item {
                    width: fileView.width
                    height: 40
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

    Rectangle {
        id: videoPanel
        height: parent.height * 0.25
        width: height * 16 / 9
        anchors.horizontalCenter: parent.horizontalCenter
        y: isVideoPanelVisible ? parent.height - height : parent.height

        color: "transparent"
        radius: 25
        border.color: "#f1ba54"
        border.width: 5

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
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 10

        Button {
            id: menuButton
            text: "Menu"
            onClicked: sidePanel.x = (sidePanel.x === 0) ? -sidePanel.width : 0
        }

        Button {
            id: videoButton
            text: "Video"
            onClicked: isVideoPanelVisible = !isVideoPanelVisible
        }

        Button {
            text: "Close"
            onClicked: Qt.quit()
        }
    }
}
