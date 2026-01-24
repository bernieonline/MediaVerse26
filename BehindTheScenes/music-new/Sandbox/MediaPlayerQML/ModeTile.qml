import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: tileRoot
    width: 100; height: 120
    property string icon: ""
    property string label: ""
    signal clicked()

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#1AFFFFFF"
        radius: 10
        border.color: mouseArea.containsMouse ? "#00F2FF" : "#33FFFFFF"
        border.width: mouseArea.containsMouse ? 2 : 1

        Column {
            anchors.centerIn: parent
            spacing: 10
            
            Text { 
                text: tileRoot.icon // Use an emoji or icon font 
                font.pixelSize: 30
                anchors.horizontalCenter: parent.horizontalCenter 
            }
            
            Text { 
                text: tileRoot.label
                color: "white"
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter 
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tileRoot.clicked()
        }
    }

    // Subtle glow effect on hover
    DropShadow {
        anchors.fill: bg
        visible: mouseArea.containsMouse
        horizontalOffset: 0; verticalOffset: 0
        radius: 10
        samples: 17
        color: "#00F2FF"
        source: bg
    }
}