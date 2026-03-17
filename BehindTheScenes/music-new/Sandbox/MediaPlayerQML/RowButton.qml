import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Column {
    id: buttonColumn
    width: parent.width
    spacing: 0
    z: 9999

    signal architectClicked()
    signal tvSeriesClicked()
    signal quickCreatorClicked()

    // ─────────────────────────────────────────────────────────────────────────
    //  Glossy 3-D nav button component
    //  line1  – primary label (always uppercase + bold)
    //  line2  – secondary label; leave "" for single-line
    //  accent – per-button colour used for glow, border and label tint
    // ─────────────────────────────────────────────────────────────────────────
    component NavButton: Item {
        id: root
        width:  150
        height: 66

        property string line1:  ""
        property string line2:  ""
        property color  accent: "#aaaaaa"

        signal activated()

        // ── 1. Outer glow rings (hover only) ─────────────────────────────────
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

        // ── 2. Drop shadow ───────────────────────────────────────────────────
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

        // ── 3-7. Animated group (sinks 3 px on press) ────────────────────────
        Item {
            id: movingGroup
            x:      2
            y:      ma.pressed ? 5 : 2
            width:  parent.width  - 4
            height: parent.height - 4
            Behavior on y { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }

            // ── 3. Bevel frame ───────────────────────────────────────────────
            Rectangle {
                anchors.fill:    face
                anchors.margins: -1
                radius:          face.radius + 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: ma.pressed ? "#0e0e0e" : "#585858" }
                    GradientStop { position: 1.0; color: ma.pressed ? "#505050" : "#0a0a0a" }
                }
            }

            // ── 4. Face base ─────────────────────────────────────────────────
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

                // ── 5. Gloss overlay ─────────────────────────────────────────
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

                // ── 6. Accent border ─────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    radius:       parent.radius
                    color:        "transparent"
                    border.color: root.accent
                    border.width: 1
                    opacity:      ma.containsMouse ? (ma.pressed ? 0.30 : 0.75) : 0.20
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // ── 7. Labels ────────────────────────────────────────────────
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

        // --- 1. FREESTYLE / MEDIA EXPLORER ---
        NavButton {
            line1: "Freestyle"; line2: "Media Explorer"; accent: "#D4A853"
            onActivated: {
                if (typeof splash !== "undefined") splash.deactivate()
                contentLoader.setSource("Freestyle.qml")
            }
        }

        // --- 2. ARCHITECT CREATOR ---
        NavButton {
            line1: "Architect"; line2: "Creator"; accent: "#00D4E8"
            onActivated: {
                if (typeof splash !== "undefined") splash.deactivate()
                architectHUD.visible = true
            }
        }

        // --- 3. ARCHITECT COLLECTIONS ---
        NavButton {
            line1: "Architect"; line2: "Collections"; accent: "#D4A853"
            onActivated: {
                if (typeof splash !== "undefined") splash.deactivate()
                buttonColumn.architectClicked()
                contentLoader.setSource("ArchitectGallery.qml")
                if (typeof utilitySidebar !== "undefined") utilitySidebar.isOpen = false
                if (typeof architectHUD    !== "undefined") architectHUD.visible = false
            }
        }

        // --- 4. QUICK CREATOR ---
        NavButton {
            line1: "Quick"; line2: "Creator"; accent: "#FF9800"
            onActivated: buttonColumn.quickCreatorClicked()
        }

        // --- 5. QUICK COLLECTIONS ---
        NavButton {
            line1: "Quick"; line2: "Collections"; accent: "#C0C0C0"
            onActivated: {
                if (typeof splash !== "undefined") splash.deactivate()
                contentLoader.setSource("CategoryMenu.qml")
            }
        }

        // --- 6. TV SERIES ---
        NavButton {
            line1: "TV"; line2: "Series"; accent: "#39FF14"
            onActivated: buttonColumn.tvSeriesClicked()
        }

        // --- 7. CLOSE ---
        NavButton {
            line1: "Close"; width: 110; accent: "#FF5555"
            onActivated: Qt.quit()
        }
    }
}
