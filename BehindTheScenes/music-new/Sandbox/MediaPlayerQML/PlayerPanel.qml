import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects 1.0

Rectangle {
    id: playerPanel
    property bool isVisible: false
    property bool isPlaying: false   // toggle for idle overlay

    width: parent ? parent.width * 0.5 : 400
    height: parent ? parent.height * 0.5 : 300

    anchors.horizontalCenter: parent.horizontalCenter
    y: isVisible ? parent.height - height : parent.height
    z: 2

    color: "#1e1e1e80"
    radius: 25
    border.color: "gold"
    border.width: 2

    Behavior on y {
        NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }

    // --- Internal video screen ---
    Rectangle {
        id: videoScreen
        anchors {
            top: parent.top
            topMargin: 15
            left: parent.left
            leftMargin: 15
            right: parent.right
            rightMargin: 15
            bottom: buttonArea.top
            bottomMargin: 15
        }
        radius: 16
        color: "#000000"
        border.width: 0
        clip: true

        property real aspect: 16/9
        onWidthChanged: height = width / aspect

        // Idle overlay when not playing
        ColorOverlay {
            anchors.fill: parent
            source: videoScreen
            color: "#00000080"
            visible: !playerPanel.isPlaying
        }

        Text {
            anchors.centerIn: parent
            text: "No movie playing"
            color: "white"
            font.pixelSize: 20
            visible: !playerPanel.isPlaying
        }
    }

    // --- Button bar locked to bottom ---
    Rectangle {
        id: buttonArea
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 15
            rightMargin: 15
            bottomMargin: 15
        }
        height: 120
        radius: 10
        color: "#333333"
        border.color: "gold"
        border.width: 1

        // RowLayout ensures buttons fill evenly
        RowLayout {
            anchors.fill: parent
            anchors.margins: 15   // 15px margin inside the bar
            spacing: 15

            Button { text: "Play"; Layout.fillWidth: true; Layout.fillHeight: true }
            Button { text: "Pause"; Layout.fillWidth: true; Layout.fillHeight: true }
            Button { text: "Stop"; Layout.fillWidth: true; Layout.fillHeight: true }
            Button { text: "Full Screen"; Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }
}