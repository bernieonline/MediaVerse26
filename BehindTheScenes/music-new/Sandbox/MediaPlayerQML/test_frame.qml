// test_frame.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    color: "#1e1e1e"
    title: "Test Frame"

    property bool isVideoPanelVisible: false

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        padding: 10

        Row {
            spacing: 20
            Button {
                text: "Open"
                onClicked: isVideoPanelVisible = true
            }
            Button {
                text: "Close"
                onClicked: isVideoPanelVisible = false
            }
        }
    }

    // --- PlayerPanel sliding from bottom ---
    PlayerPanel {
        id: videoPanel
        anchors.horizontalCenter: parent.horizontalCenter
        y: isVideoPanelVisible ? window.height - height : window.height
        z: 2

        Behavior on y {
            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
        }
    }

    // --- Glow styling wrapper ---
    UltraGlowFrame2 {
        target: videoPanel
    }
}