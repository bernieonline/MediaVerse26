import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  SlidePanel — top-left corner quick-access icon panel
//
//  A fixed 2×2 icon grid hidden behind a sliding cover.
//  HoverHandler drives open/close — composable, never steals icon hover.
//
//  Single tuning value: iconSize (try 52 → 56 → 60 → 64)
//  All panel dimensions derive from iconSize so the panel stays square.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: slidePanelRoot

    // ── Single tuning value ───────────────────────────────────────────────────
    readonly property int iconSize: 30      // reduced from 39 — ~88px total open height

    readonly property int iconGap:  5
    readonly property int padding:  8
    readonly property int handleH:  18
    readonly property int bodyH:    iconSize * 2 + iconGap + padding * 2
    readonly property int panelW:   iconSize * 2 + iconGap + padding * 2

    // ── Signals — wire these to modules when ready ────────────────────────────
    signal qobuzMusicClicked()
    signal mediaEditClicked()
    signal collectionCuratorClicked()

    // Size — position is set by the parent (Framework-1.qml)
    width:  panelW + 10     // extra room for drop shadow
    height: handleH + bodyH + 10

    // ─────────────────────────────────────────────────────────────────────────
    //  Inline component: glossy icon button
    // ─────────────────────────────────────────────────────────────────────────
    component IconButton: Item {
        id: iconRoot
        width:  68; height: 68

        property string iconChar:    ""
        property bool   isStack:     false
        property color  accent:      "#aaaaaa"
        property string tooltipText: ""
        signal activated()

        // Glow rings
        Repeater {
            model: 2
            delegate: Rectangle {
                anchors.centerIn: ibGroup
                width:  ibGroup.width  + (index + 1) * 7
                height: ibGroup.height + (index + 1) * 7
                radius: 12 + (index + 1) * 3
                color: "transparent"
                border.color: iconRoot.accent; border.width: 1
                opacity: ibMa.containsMouse ? (0.30 - index * 0.12) : 0.0
                Behavior on opacity { NumberAnimation { duration: 220 } }
            }
        }

        // Drop shadow
        Rectangle {
            x: ibGroup.x + 3; y: ibGroup.y + 4
            width: ibGroup.width - 2; height: ibGroup.height
            radius: 10; color: "#000000"
            opacity: ibMa.pressed ? 0.0 : 0.65
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }

        // Moving group (sinks on press)
        Item {
            id: ibGroup
            x: 2; y: ibMa.pressed ? 4 : 2
            width: parent.width - 4; height: parent.height - 4
            Behavior on y { NumberAnimation { duration: 65; easing.type: Easing.OutQuad } }

            // Bevel frame
            Rectangle {
                anchors.fill: ibFace; anchors.margins: -1; radius: ibFace.radius + 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: ibMa.pressed ? "#0e0e0e" : "#545454" }
                    GradientStop { position: 1.0; color: ibMa.pressed ? "#4c4c4c" : "#0c0c0c" }
                }
            }

            // Face
            Rectangle {
                id: ibFace
                anchors.fill: parent; anchors.margins: 1; radius: 10
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: ibMa.pressed ? "#1a1a1a" : (ibMa.containsMouse ? "#3e3e3e" : "#333333") }
                    GradientStop { position: 0.50; color: ibMa.pressed ? "#202020" : (ibMa.containsMouse ? "#2c2c2c" : "#262626") }
                    GradientStop { position: 1.0;  color: ibMa.pressed ? "#2c2c2c" : "#131313" }
                }

                // Gloss overlay
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: ibMa.pressed ? Qt.rgba(1,1,1,0.03) : Qt.rgba(1,1,1,0.17) }
                        GradientStop { position: 0.42; color: ibMa.pressed ? Qt.rgba(1,1,1,0.0)  : Qt.rgba(1,1,1,0.05) }
                        GradientStop { position: 0.43; color: Qt.rgba(1,1,1,0.0) }
                        GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0) }
                    }
                }

                // Accent border
                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "transparent"
                    border.color: iconRoot.accent; border.width: 1
                    opacity: ibMa.containsMouse ? (ibMa.pressed ? 0.30 : 0.70) : 0.18
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Unicode icon
                Text {
                    visible: !iconRoot.isStack
                    anchors.centerIn: parent
                    text: iconRoot.iconChar
                    font.pixelSize: 22; font.family: "Segoe UI Symbol"
                    color: ibMa.pressed
                           ? Qt.darker(iconRoot.accent, 1.4)
                           : (ibMa.containsMouse ? Qt.lighter(iconRoot.accent, 1.6) : iconRoot.accent)
                    Behavior on color { ColorAnimation { duration: 170 } }
                }

                // Stacked cards (Collection Curator)
                Item {
                    visible: iconRoot.isStack
                    anchors.centerIn: parent
                    width: 32; height: 28

                    property color c: ibMa.pressed
                        ? Qt.darker(iconRoot.accent, 1.4)
                        : (ibMa.containsMouse ? Qt.lighter(iconRoot.accent, 1.6) : iconRoot.accent)
                    Behavior on c { ColorAnimation { duration: 170 } }

                    Rectangle { x:6; y:14; width:26; height:12; radius:2; color: Qt.rgba(parent.c.r,parent.c.g,parent.c.b,0.35) }
                    Rectangle {
                        x:3; y:8;  width:26; height:12; radius:2
                        color: Qt.rgba(parent.c.r,parent.c.g,parent.c.b,0.60)
                        Rectangle { x:0;y:0;width:3;height:parent.height;radius:2;color:Qt.rgba(1,1,1,0.15) }
                    }
                    Rectangle {
                        x:0; y:2; width:26; height:12; radius:2; color: parent.c
                        Rectangle { x:0;y:0;width:3;height:parent.height;radius:2;color:Qt.rgba(1,1,1,0.25) }
                    }
                }
            }
        }

        MouseArea {
            id: ibMa; anchors.fill: parent; hoverEnabled: true
            onClicked: iconRoot.activated()
            ToolTip.visible: containsMouse
            ToolTip.text:    iconRoot.tooltipText
            ToolTip.delay:   500
        }
    }
    // ── End component IconButton ──────────────────────────────────────────────


    // ── Drop shadow — declared BEFORE panel so it sits behind at same z:0 ────
    Rectangle {
        id: panelShadow
        x: 5; y: 5
        width:  slidePanelRoot.panelW
        height: slidePanelRoot.handleH + slidePanelRoot.bodyH
        radius: 10
        color: "#000000"; opacity: 0.72

        Rectangle {
            anchors.right:  parent.right
            anchors.top:    parent.top;    anchors.topMargin:    4
            anchors.bottom: parent.bottom; anchors.bottomMargin: 4
            width: 8; radius: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.0)  }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.55) }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left;  anchors.leftMargin:  4
            anchors.right:  parent.right; anchors.rightMargin: 4
            height: 8; radius: 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.0)  }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.55) }
            }
        }
    }

    // ── Panel ─────────────────────────────────────────────────────────────────
    //  Layers (back → front):
    //    z:1  icon body  — always present
    //    z:3  cover      — slides DOWN to hide, UP to reveal (clipped)
    //    z:5  handle     — always visible on top
    // ─────────────────────────────────────────────────────────────────────────
    Item {
        id: panel
        x: 0; y: 0
        width:  slidePanelRoot.panelW
        height: slidePanelRoot.handleH + slidePanelRoot.bodyH
        clip:   true

        property bool isOpen: false

        HoverHandler {
            onHoveredChanged: panel.isOpen = hovered
        }

        // ── z:1  Icon body ─────────────────────────────────────────────────
        Rectangle {
            id: iconBody
            z: 1
            y: slidePanelRoot.handleH
            width: slidePanelRoot.panelW; height: slidePanelRoot.bodyH

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#303030" }
                GradientStop { position: 1.0; color: "#1e1e1e" }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.10) }
                    GradientStop { position: 0.45; color: Qt.rgba(1,1,1,0.02) }
                    GradientStop { position: 0.46; color: Qt.rgba(1,1,1,0.0)  }
                    GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                }
            }
            Rectangle {
                anchors.fill: parent; color: "transparent"
                border.color: "#505050"; border.width: 1; radius: 4
            }
            Rectangle {
                anchors.fill: parent; anchors.margins: -1; color: "transparent"
                border.color: "#000000"; border.width: 1; radius: 5; opacity: 0.40
            }
            Rectangle {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.right: parent.right; anchors.rightMargin: 16
                height: 1; color: "#ffffff"; opacity: 0.07
            }

            // 2×2 Icon grid
            Grid {
                anchors.centerIn: parent
                columns: 2; spacing: slidePanelRoot.iconGap

                IconButton {
                    width: slidePanelRoot.iconSize; height: slidePanelRoot.iconSize
                    iconChar: "\u266B"; accent: "#00EEFF"; tooltipText: "Qobuz Music"
                    onActivated: slidePanelRoot.qobuzMusicClicked()
                }
                IconButton {
                    width: slidePanelRoot.iconSize; height: slidePanelRoot.iconSize
                    iconChar: "\u2702"; accent: "#FFB300"; tooltipText: "Media Edit"
                    onActivated: slidePanelRoot.mediaEditClicked()
                }
                IconButton {
                    width: slidePanelRoot.iconSize; height: slidePanelRoot.iconSize
                    isStack: true; accent: "#E8E8E8"; tooltipText: "Collection Curator"
                    onActivated: slidePanelRoot.collectionCuratorClicked()
                }
                IconButton {
                    width: slidePanelRoot.iconSize; height: slidePanelRoot.iconSize
                    iconChar: "+"; accent: "#505050"; tooltipText: "Coming Soon"
                }
            }
        }

        // ── z:3  Cover — slides DOWN to hide, UP to reveal ────────────────
        // Closed: y = handleH  → sits exactly over icon body
        // Open:   y = handleH + bodyH → clipped by panel, fully hidden below
        Rectangle {
            id: cover
            z: 3
            y: panel.isOpen ? slidePanelRoot.handleH + slidePanelRoot.bodyH
                            : slidePanelRoot.handleH
            width: slidePanelRoot.panelW; height: slidePanelRoot.bodyH

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2e2e2e" }
                GradientStop { position: 1.0; color: "#1c1c1c" }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.12) }
                    GradientStop { position: 0.45; color: Qt.rgba(1,1,1,0.03) }
                    GradientStop { position: 0.46; color: Qt.rgba(1,1,1,0.0)  }
                    GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                }
            }
            Rectangle {
                anchors.fill: parent; color: "transparent"
                border.color: "#505050"; border.width: 1; radius: 4
            }
            Rectangle {
                anchors.fill: parent; anchors.margins: -1; color: "transparent"
                border.color: "#000000"; border.width: 1; radius: 5; opacity: 0.40
            }

            Behavior on y {
                NumberAnimation { duration: 420; easing.type: Easing.InOutQuart }
            }
        }

        // ── z:5  Handle strip — always visible ────────────────────────────
        Rectangle {
            id: handleStrip
            z: 5
            y: 0; width: slidePanelRoot.panelW; height: slidePanelRoot.handleH
            radius: 8

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#404040" }
                GradientStop { position: 1.0; color: "#282828" }
            }
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.18) }
                    GradientStop { position: 0.50; color: Qt.rgba(1,1,1,0.05) }
                    GradientStop { position: 0.51; color: Qt.rgba(1,1,1,0.0)  }
                    GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                }
            }
            Rectangle {
                anchors.fill: parent; radius: parent.radius; color: "transparent"
                border.color: panel.isOpen ? "#787878" : "#505050"; border.width: 1
                Behavior on border.color { ColorAnimation { duration: 300 } }
            }
            Rectangle {
                anchors.fill: parent; anchors.margins: -1; radius: parent.radius + 1
                color: "transparent"; border.color: "#000000"; border.width: 1; opacity: 0.40
            }
            Rectangle {
                anchors.bottom:      parent.bottom
                anchors.left:        parent.left;  anchors.leftMargin:  14
                anchors.right:       parent.right; anchors.rightMargin: 14
                height: 2; radius: 1; color: "#999999"
                opacity: panel.isOpen ? 1.0 : 0.55
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: panel.isOpen ? "\u25B4" : "\u25BE"
                font.pixelSize: 11; color: "#999999"
                opacity: panel.isOpen ? 1.0 : 0.55
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            Row {
                anchors.centerIn: parent; spacing: 5
                Repeater {
                    model: 4
                    Rectangle {
                        width: 4; height: 4; radius: 2; color: "#808080"
                        opacity: panel.isOpen ? 1.0 : 0.45
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }
    }
    // ── End panel ─────────────────────────────────────────────────────────────
}
