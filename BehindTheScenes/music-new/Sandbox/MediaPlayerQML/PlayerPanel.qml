import QtQuick 2.15

Rectangle {
    id: playerPanel
    property bool isVisible: false

    // Size: half width, 40% height of parent (same as old slider proportions)
    width: parent ? parent.width * 0.5 : 400
    height: parent ? parent.height * 0.4 : 240

    anchors.horizontalCenter: parent.horizontalCenter
    // Slide up from bottom edge
    y: isVisible ? parent.height - height : parent.height
    z: 2

    // Styling: opaque dark with 50% transparency, gold border, rounded corners
    color: "#1e1e1e80"   // 80 hex = ~50% transparency
    radius: 25
    border.color: "gold"
    border.width: 2

    Behavior on y {
        NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }

    // Example content inside panel
    Column {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: "Mini Panel"
            color: "white"
            font.pixelSize: 20
        }

        Rectangle {
            width: parent.width * 0.8
            height: 40
            radius: 8
            color: "gold"

            Text {
                anchors.centerIn: parent
                text: "Panel Content"
                color: "#1e1e1e"
                font.pixelSize: 16
            }
        }
    }
}