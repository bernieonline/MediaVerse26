import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  WorkButtons — Workbench module button row
//
//  Same layout and component style as RowButton.qml.
//  Visual identity: neon green (#39FF14) accent on all buttons.
// ─────────────────────────────────────────────────────────────────────────────

Column {
    id: buttonColumn
    width: parent.width
    spacing: 0
    z: 9999

    property bool videoProcAvailable: true

    signal testFileClicked()
    signal compareFilesClicked()
    signal testFolderClicked()
    signal repairFileClicked()
    signal qualityAuditsClicked()
    signal fileDetailsClicked()
    signal videoProcClicked()
    signal closeWorkbenchClicked()

    // ─────────────────────────────────────────────────────────────────────────
    //  Glossy 3-D nav button — identical component to RowButton.qml
    // ─────────────────────────────────────────────────────────────────────────
    component NavButton: Item {
        id: root
        width:  150
        height: 66

        property string line1:  ""
        property string line2:  ""
        property color  accent: "#39FF14"

        signal activated()

        // ── Outer glow rings ─────────────────────────────────────────────────
        Repeater {
            model: 3
            delegate: Rectangle {
                readonly property int idx: index
                anchors.centerIn: movingGroup
                width:  movingGroup.width  + (idx + 1) * 8
                height: movingGroup.height + (idx + 1) * 8
                radius: 12 + (idx + 1) * 4
                color: "transparent"
                border.color: root.accent
                border.width: 1
                opacity: ma.containsMouse ? (ma.pressed ? 0.0 : (0.28 - idx * 0.09)) : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }

        // ── Drop shadow ──────────────────────────────────────────────────────
        Rectangle {
            x:       movingGroup.x + 3
            y:       movingGroup.y + 5
            width:   movingGroup.width  - 2
            height:  movingGroup.height
            radius:  11
            color:   "#000000"
            opacity: ma.pressed ? 0.0 : 0.70
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }

        // ── Animated group (sinks 3 px on press) ─────────────────────────────
        Item {
            id: movingGroup
            x:      2
            y:      ma.pressed ? 5 : 2
            width:  parent.width  - 4
            height: parent.height - 4
            Behavior on y { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }

            // Bevel frame
            Rectangle {
                anchors.fill:    face
                anchors.margins: -1
                radius:          face.radius + 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: ma.pressed ? "#0e0e0e" : "#585858" }
                    GradientStop { position: 1.0; color: ma.pressed ? "#505050" : "#0a0a0a" }
                }
            }

            // Face base
            Rectangle {
                id: face
                anchors.fill:    parent
                anchors.margins: 1
                radius: 10

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: ma.pressed ? "#1e1e1e" : (ma.containsMouse ? "#424242" : "#373737")
                    }
                    GradientStop {
                        position: 0.50
                        color: ma.pressed ? "#232323" : (ma.containsMouse ? "#2e2e2e" : "#272727")
                    }
                    GradientStop {
                        position: 1.0
                        color: ma.pressed ? "#2d2d2d" : "#141414"
                    }
                }

                // Gloss overlay
                Rectangle {
                    anchors.fill: parent
                    radius:       parent.radius
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: ma.pressed
                                   ? Qt.rgba(1,1,1,0.04)
                                   : (ma.containsMouse ? Qt.rgba(1,1,1,0.26) : Qt.rgba(1,1,1,0.18))
                        }
                        GradientStop {
                            position: 0.42
                            color: ma.pressed
                                   ? Qt.rgba(1,1,1,0.01)
                                   : (ma.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.05))
                        }
                        GradientStop { position: 0.43; color: Qt.rgba(1,1,1,0.0) }
                        GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0) }
                    }
                }

                // Bottom-edge reflection
                Rectangle {
                    width:  parent.width - 20
                    height: 1
                    anchors.bottom:           parent.bottom
                    anchors.bottomMargin:     3
                    anchors.horizontalCenter: parent.horizontalCenter
                    color:   "#ffffff"
                    opacity: ma.pressed ? 0.0 : (ma.containsMouse ? 0.12 : 0.07)
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                // Accent border
                Rectangle {
                    anchors.fill: parent
                    radius:       parent.radius
                    color:        "transparent"
                    border.color: root.accent
                    border.width: 1
                    opacity:      ma.containsMouse ? (ma.pressed ? 0.30 : 0.75) : 0.20
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Labels
                Column {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text:                root.line1
                        font.family:         "Segoe UI"
                        font.pixelSize:      root.line2 !== "" ? 13 : 15
                        font.bold:           true
                        font.letterSpacing:  2.2
                        font.capitalization: Font.AllUppercase
                        color: {
                            if (ma.pressed)       return Qt.darker(root.accent, 1.4)
                            if (ma.containsMouse) return Qt.lighter(root.accent, 1.6)
                            return root.accent
                        }
                        Behavior on color { ColorAnimation { duration: 170 } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text:    root.line2
                        visible: root.line2 !== ""
                        font.family:    "Segoe UI"
                        font.pixelSize: 13
                        color: ma.pressed ? "#606060" : (ma.containsMouse ? "#e0e0e0" : "#909090")
                        Behavior on color { ColorAnimation { duration: 170 } }
                    }
                }
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked:    root.activated()
        }
    }
    // ── End component NavButton ───────────────────────────────────────────────


    Row {
        id: buttonRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        // --- 1. TEST FILE ---
        NavButton {
            line1: "Test"; line2: "File"; accent: "#39FF14"
            onActivated: buttonColumn.testFileClicked()
        }

        // --- 2. COMPARE FILES ---
        NavButton {
            line1: "Compare"; line2: "Files"; accent: "#39FF14"
            onActivated: buttonColumn.compareFilesClicked()
        }

        // --- 3. TEST FOLDER ---
        NavButton {
            line1: "Test"; line2: "Folder"; accent: "#39FF14"
            onActivated: buttonColumn.testFolderClicked()
        }

        // --- 3. REPAIR FILE ---
        NavButton {
            line1: "Repair"; line2: "File"; accent: "#39FF14"
            onActivated: buttonColumn.repairFileClicked()
        }

        // --- 4. QUALITY AUDITS ---
        NavButton {
            line1: "Quality"; line2: "Audits"; accent: "#39FF14"
            onActivated: buttonColumn.qualityAuditsClicked()
        }

        // --- 5. FILE DETAILS ---
        NavButton {
            line1: "File"; line2: "Details"; accent: "#39FF14"
            onActivated: buttonColumn.fileDetailsClicked()
        }

        // --- 6. VIDEO PROC ---
        NavButton {
            line1: "Video"; line2: "Proc"; accent: "#39FF14"
            visible: buttonColumn.videoProcAvailable
            onActivated: buttonColumn.videoProcClicked()
        }

        // --- 7. CLOSE ---
        NavButton {
            id: closeBtn
            line1: "Close"; width: 110; accent: "#FF5555"
            onActivated: buttonColumn.closeWorkbenchClicked()
        }
    }
}
