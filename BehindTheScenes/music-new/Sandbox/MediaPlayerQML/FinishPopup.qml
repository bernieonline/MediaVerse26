import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: finishOverlay
    anchors.fill: parent
    color: "#F2121214"
    visible: false
    z: 10000 

    property var collectionData: null

    function prepareDNA(dna) {
        collectionData = dna;
        console.log("✅ DIALOG: DNA Captured successfully!");
    }

    Rectangle {
        anchors.centerIn: parent
        width: 500; height: 300
        color: "#1A1A1C"
        border.color: "gold"; border.width: 2
        radius: 10

        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "COLLECTION RECORDED"
                color: "gold"; font.pixelSize: 22; font.bold: true
            }

            Text {
                text: "DNA sequence captured.\nReady for MediaVerse V2."
                color: "white"; horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "CLOSE"
                width: 150; height: 40
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: finishOverlay.visible = false
            }
        }
    }
}