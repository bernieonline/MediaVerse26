// MainView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    visible: true
    width: 1200
    height: 800

    StackView {
        id: panelStack
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 320   // matches SlidingPanel width

        initialItem: SlidingPanel {
            id: rootPanel
            libraryModel: topLevelModel   // provided by backend
            folderModel: []
            onFolderSelected: function(path) {
                backend.listFolder(path)
            }
        }
    }

    // Navigation block
    Row {
        anchors.bottom: parent.bottom
        anchors.left: panelStack.right
        spacing: 10
        padding: 10

        // Back button
        Rectangle {
            width: 80; height: 50; color: "#333"; radius: 8
            border.color: "yellow"; border.width: 1
            Text { anchors.centerIn: parent; text: "◀ Back"; color: "white"; font.pixelSize: 18 }
            MouseArea {
                anchors.fill: parent
                enabled: panelStack.depth > 1
                onClicked: panelStack.pop()
            }
        }

        // Forward button (requires history logic)
        Rectangle {
            width: 80; height: 50; color: "#333"; radius: 8
            border.color: "yellow"; border.width: 1
            Text { anchors.centerIn: parent; text: "Forward ▶"; color: "white"; font.pixelSize: 18 }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // optional: implement forward history in backend
                }
            }
        }
    }

    Connections {
        target: backend
        onFolderListed: function(path, model) {
            panelStack.push({
                item: SlidingPanel {
                    libraryModel: []
                    folderModel: model
                    onFolderSelected: function(subPath) {
                        backend.listFolder(subPath)
                    }
                }
            })
        }
    }
}