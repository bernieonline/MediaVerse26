// main.qml
import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 600
    height: 400
    title: "CinemaButton Test"

    Rectangle {
        anchors.fill: parent
        color: "#111"

        CinemaButton {
            anchors.centerIn: parent
            text: "Play"
            onClicked: {
                console.log("CinemaButton clicked: Play")
            }
        }
    }
}