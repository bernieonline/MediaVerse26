import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: fileSystem
    anchors.fill: parent
    color: "transparent"

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        ComboBox {
            id: driveComboBox
            width: parent.width
            model: fileSystemManager.drives
            onCurrentIndexChanged: {
                fileSystemManager.update_folders(driveComboBox.currentText + "\\Collections")
            }
        }

        ListView {
            id: folderView
            width: parent.width
            height: parent.height - driveComboBox.height - 10
            clip: true
            model: fileSystemManager.folders
            delegate: Item {
                width: parent.width
                height: 30
                Text {
                    text: modelData
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                }
            }
        }
    }
}
