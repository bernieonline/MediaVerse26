import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5
import QtQuick.Window 6.5
import "."

Rectangle {
    id: detailViewRoot
    anchors.fill: parent
    color: "transparent"

    // Path of selected image, passed in externally
    property string imagePath: ""

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // LEFT PANEL: IMAGE VIEW
        SoftGlowFrame {
            id: leftPanel
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.55
            //color: "transparent"

            Image {
                id: posterImage
                anchors.fill: parent
                //anchors.margins: 20
                source: detailViewRoot.imagePath
                //fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // RIGHT PANEL: TAB BAR + STACK
        SoftGlowFrame {
            id: rightPanel
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.45
            //color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                // Tab buttons
                TabBar {
                    id: tabBar
                    Layout.fillWidth: true

                    TabButton { text: "Details"; checked: true }
                    TabButton { text: "Actors" }
                    TabButton { text: "Director" }
                    TabButton { text: "Filming" }
                }

                // Content stack
                StackLayout {
                    id: stack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex

                    Rectangle {
                        color: "transparent"
                        anchors.fill: parent
                        Text { anchors.centerIn: parent; text: "Details content"; color: "white" }
                    }

                    Rectangle {
                        color: "transparent"
                        anchors.fill: parent
                        Text { anchors.centerIn: parent; text: "Actors content"; color: "white" }
                    }

                    Rectangle {
                        color: "transparent"
                        anchors.fill: parent
                        Text { anchors.centerIn: parent; text: "Director content"; color: "white" }
                    }

                    Rectangle {
                        color: "transparent"
                        anchors.fill: parent
                        Text { anchors.centerIn: parent; text: "Filming content"; color: "white" }
                    }
                }
            }
        }
    }
}
