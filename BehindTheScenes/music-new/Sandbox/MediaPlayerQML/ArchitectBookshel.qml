import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: shelfRoot
    height: 220
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 20

    // Background shelf glow
    Rectangle {
        anchors.fill: parent
        color: "#0A0A0A"
        opacity: 0.8
        radius: 10
        border.color: "#1AFFFFFF"
        border.width: 1
    }

    ListView {
        id: thumbList
        anchors.fill: parent
        anchors.margins: 15
        orientation: ListView.Horizontal
        spacing: 15
        model: bookshelfModel // We will link this to Python results
        clip: true

        delegate: Item {
            width: 120
            height: 180

            Image {
                id: poster
                anchors.fill: parent
                source: modelData // Path resolved by Python matching rule
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                
                // Placeholder while loading
                Rectangle {
                    anchors.fill: parent
                    color: "#222"
                    visible: poster.status !== Image.Ready
                }
            }

            // Subtle glow on each poster
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 8
                samples: 17
                color: "#aa000000"
            }
        }

        // DYNAMIC REACTIONS: Animations for adding/removing movies
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400 }
            NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: 400; easing.type: Easing.OutBack }
        }

        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 300 }
            NumberAnimation { property: "scale"; to: 0.5; duration: 300 }
        }

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 600; easing.type: Easing.OutExpo }
        }
    }
}