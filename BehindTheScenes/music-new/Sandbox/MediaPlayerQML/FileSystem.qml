import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick
import QtQuick.Controls
//version 1.0.1 border edge added to left panel
//1.o.2 sliding video panel added
//1.0.3 centre button moved to toolbar
//1.0.4 final adjustments made before applying styling to panels
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
        id: mainDisplayPanel
        color: "#2e2e2e"
        anchors.top: toolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
    }

    Rectangle {
        id: sidePanel
        width: 400
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

            Loader {
                anchors.fill: parent
                source: "FileSystem.qml"
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
        id: toolbar
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
