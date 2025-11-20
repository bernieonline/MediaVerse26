import QtQuick 2.15

import QtQuick.Controls 2.15

//this creates my grid and the delegate uses a custom component ImageHolder.qml
//i modify the Image property in that file to set anchors.margins: 20 to set a border around the image and leaving space between it and the frame

Rectangle {

    id: root

    color: "transparent"


    GridView {

        id: imageGridView

        anchors.fill: parent

        clip: true

        model: fileSystemManager.imageFiles

        cellWidth: imageGridView.width / 6

        cellHeight: (imageGridView.width / 6) * 1.5

        delegate: ImageHolder {

            width: imageGridView.width / 6

            height: (imageGridView.width / 6) * 1.5

            source: modelData.filePath



            MouseArea {

                anchors.fill: parent

                onClicked: {

                    console.log("Image clicked:", modelData.filePath)

                }

            }

        }

    }

}