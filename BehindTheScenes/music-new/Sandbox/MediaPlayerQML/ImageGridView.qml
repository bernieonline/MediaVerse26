import QtQuick 2.15

import QtQuick.Controls 2.15

//this creates my grid and the delegate uses a custom component ImageHolder.qml
//i modify the Image property in that file to set anchors.margins: 20 to set a border around the image and leaving space between it and the frame

Rectangle {

    id: root

    color: "transparent"
    signal imageClicked(string filePath)

    GridView {

        id: imageGridView

        anchors.fill: parent

        clip: true

        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        
        }
        //spacing: 10

        anchors.margins: 10   // space around the entire grid


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
                   
                    //onClicked: {
                        print("i just clicked this yes?", modelData.filePath)
                        root.imageClicked(modelData.filePath)
                    //}

                    console.log("Image clicked need to save it:", modelData.filePath)

                }
                //propagateComposedEvents: true  // allows the GridView to process vertical drags

            }

        }

    }

}