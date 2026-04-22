import QtQuick 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  WorkbenchActionButton — glossy action button used in Workbench views.
//  Scaled for 10ft / large-screen viewing: 140 × 44, 16px label.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    width:  140
    height: 44

    property string label:  ""
    property color  accent: "#39FF14"

    signal activated()

    Rectangle {
        id: shadow
        x: movingGroup.x + 2; y: movingGroup.y + 4
        width: movingGroup.width - 2; height: movingGroup.height
        radius: 8; color: "#000000"
        opacity: ma.pressed ? 0.0 : 0.65
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    Item {
        id: movingGroup
        x: 1; y: ma.pressed ? 5 : 1
        width: parent.width - 2; height: parent.height - 2
        Behavior on y { NumberAnimation { duration: 65; easing.type: Easing.OutQuad } }

        Rectangle {
            anchors.fill: face; anchors.margins: -1; radius: face.radius + 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: ma.pressed ? "#0e0e0e" : "#484848" }
                GradientStop { position: 1.0; color: ma.pressed ? "#404040" : "#080808" }
            }
        }

        Rectangle {
            id: face
            anchors.fill: parent; anchors.margins: 1; radius: 8
            gradient: Gradient {
                GradientStop { position: 0.0;  color: ma.pressed ? "#1a1a1a" : (ma.containsMouse ? "#3a3a3a" : "#2e2e2e") }
                GradientStop { position: 0.50; color: ma.pressed ? "#202020" : "#222222" }
                GradientStop { position: 1.0;  color: ma.pressed ? "#282828" : "#101010" }
            }

            // Gloss overlay
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: ma.pressed ? Qt.rgba(1,1,1,0.03) : Qt.rgba(1,1,1,0.18) }
                    GradientStop { position: 0.42; color: Qt.rgba(1,1,1,0.04) }
                    GradientStop { position: 0.43; color: Qt.rgba(1,1,1,0.0)  }
                    GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                }
            }

            // Accent border
            Rectangle {
                anchors.fill: parent; radius: parent.radius; color: "transparent"
                border.color: root.accent; border.width: 1
                opacity: ma.containsMouse ? (ma.pressed ? 0.30 : 0.85) : 0.28
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Text {
                anchors.centerIn: parent
                text:  root.label
                font.family:         "Segoe UI"
                font.pixelSize:      16
                font.bold:           true
                font.letterSpacing:  1.8
                font.capitalization: Font.AllUppercase
                color: ma.pressed
                       ? Qt.darker(root.accent, 1.4)
                       : (ma.containsMouse ? Qt.lighter(root.accent, 1.5) : root.accent)
                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.activated()
    }
}
