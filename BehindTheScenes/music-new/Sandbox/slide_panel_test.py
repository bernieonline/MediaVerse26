#!/usr/bin/env python3
"""
Slide panel prototype -- v4.
Fixed icon panel, cover slides down over it to hide and up to reveal.
HoverHandler drives open/close -- composable, never steals hover from icons.

Run: D:\MediaVerse1.0\BehindTheScenes\venv\Scripts\python.exe slide_panel_test.py
"""

import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

QML = r"""
import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    visible: true
    width:  1280
    height: 820
    color:  "#1e1e1e"
    title:  "MediaVerse -- Slide Panel v4"

    // -- Simulated button bar --------------------------------------------------
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 110; color: "transparent"
        Text { anchors.centerIn: parent; text: "[ Button bar ]"; color: "#303030"; font.pixelSize: 18 }
    }

    // -- Simulated display area ------------------------------------------------
    Rectangle {
        id: displayArea
        anchors.top:          parent.top
        anchors.topMargin:    110
        anchors.bottom:       parent.bottom
        anchors.left:         parent.left
        anchors.right:        parent.right
        anchors.bottomMargin: 40
        anchors.leftMargin:   40
        anchors.rightMargin:  40
        color:  "#141414"
        radius: 20
        clip:   true

        Text {
            anchors.centerIn: parent
            text: "Display Area"; color: "#232323"; font.pixelSize: 48; font.bold: true
        }
        Text {
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 20
            text: "Move mouse to top-left corner to reveal the panel"
            color: "#383838"; font.pixelSize: 16; font.italic: true
        }


        // ---------------------------------------------------------------------
        //  Inline component: glossy icon button
        // ---------------------------------------------------------------------
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

            // Moving group
            Item {
                id: ibGroup
                x: 2; y: ibMa.pressed ? 4 : 2
                width: parent.width - 4; height: parent.height - 4
                Behavior on y { NumberAnimation { duration: 65; easing.type: Easing.OutQuad } }

                Rectangle {
                    anchors.fill: ibFace; anchors.margins: -1; radius: ibFace.radius + 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: ibMa.pressed ? "#0e0e0e" : "#545454" }
                        GradientStop { position: 1.0; color: ibMa.pressed ? "#4c4c4c" : "#0c0c0c" }
                    }
                }

                Rectangle {
                    id: ibFace
                    anchors.fill: parent; anchors.margins: 1; radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: ibMa.pressed ? "#1a1a1a" : (ibMa.containsMouse ? "#3e3e3e" : "#333333") }
                        GradientStop { position: 0.50; color: ibMa.pressed ? "#202020" : (ibMa.containsMouse ? "#2c2c2c" : "#262626") }
                        GradientStop { position: 1.0;  color: ibMa.pressed ? "#2c2c2c" : "#131313" }
                    }

                    // Gloss
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
                        font.pixelSize: 30; font.family: "Segoe UI Symbol"
                        color: ibMa.pressed
                               ? Qt.darker(iconRoot.accent, 1.4)
                               : (ibMa.containsMouse ? Qt.lighter(iconRoot.accent, 1.6) : iconRoot.accent)
                        Behavior on color { ColorAnimation { duration: 170 } }
                    }

                    // Stacked cards (Collection Curator)
                    Item {
                        visible: iconRoot.isStack
                        anchors.centerIn: parent
                        width: 44; height: 40

                        property color c: ibMa.pressed
                            ? Qt.darker(iconRoot.accent, 1.4)
                            : (ibMa.containsMouse ? Qt.lighter(iconRoot.accent, 1.6) : iconRoot.accent)
                        Behavior on c { ColorAnimation { duration: 170 } }

                        Rectangle { x:8; y:18; width:36; height:18; radius:3; color: Qt.rgba(parent.c.r,parent.c.g,parent.c.b,0.35) }
                        Rectangle {
                            x:4; y:11; width:36; height:18; radius:3
                            color: Qt.rgba(parent.c.r,parent.c.g,parent.c.b,0.60)
                            Rectangle { x:0;y:0;width:4;height:parent.height;radius:3;color:Qt.rgba(1,1,1,0.15) }
                        }
                        Rectangle {
                            x:0; y:4; width:36; height:18; radius:3; color: parent.c
                            Rectangle { x:0;y:0;width:4;height:parent.height;radius:3;color:Qt.rgba(1,1,1,0.25) }
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
        // -- End component IconButton ------------------------------------------


        // ---------------------------------------------------------------------
        //  PANEL -- always at full fixed size
        //
        //  Layers (back -> front):
        //    z:1  icon body  -- always present
        //    z:3  cover      -- slides DOWN to hide (clipped), UP to reveal
        //    z:5  handle     -- always visible on top
        //
        //  HoverHandler on the panel Item drives isOpen.
        //  HoverHandler is composable -- it never steals hover from icon buttons.
        // ---------------------------------------------------------------------

        // Shadow -- declared BEFORE panel so it sits behind at same z:0
        Rectangle {
            id: panelShadow
            x: 18 + 5; y: 18 + 5
            width:  panel.panelW
            height: panel.handleH + panel.bodyH
            radius: 10
            color: "#000000"; opacity: 0.72

            // Right-edge accent shadow (more intense on the right side)
            Rectangle {
                anchors.right:  parent.right
                anchors.top:    parent.top; anchors.topMargin: 4
                anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                width: 8; radius: 4
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.0)  }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.55) }
                }
            }
            // Bottom-edge accent shadow
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left; anchors.leftMargin: 4
                anchors.right:  parent.right; anchors.rightMargin: 4
                height: 8; radius: 4
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.0)  }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.55) }
                }
            }
        }

        Item {
            id: panel

            // -- Single value to tune -- everything else derives from it ---------
            readonly property int iconSize: 52      // try 52 -> 56 -> 60 -> 64

            readonly property int iconGap:  8       // gap between icons in grid
            readonly property int padding:  14      // body inner padding each side
            readonly property int handleH:  22      // handle strip height (fixed)
            readonly property int bodyH:    iconSize * 2 + iconGap + padding * 2
            readonly property int panelW:   iconSize * 2 + iconGap + padding * 2

            property bool isOpen: false

            // -- Top-left corner locked here -- panel grows down + right ---------
            anchors.top:        parent.top
            anchors.topMargin:  18          // margin from top of display area
            anchors.left:       parent.left
            anchors.leftMargin: 18          // margin from left of display area

            width:  panelW
            height: handleH + bodyH
            clip:   true   // clips the cover as it slides out of bounds

            // -- HoverHandler -- composable, never steals icon hover ------------
            HoverHandler {
                id: panelHover
                onHoveredChanged: panel.isOpen = hovered
            }

            // -- z:1  Icon body (always present, behind cover) -----------------
            Rectangle {
                id: iconBody
                z: 1
                y: panel.handleH
                width: panel.panelW; height: panel.bodyH

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#303030" }
                    GradientStop { position: 1.0; color: "#1e1e1e" }
                }

                // Gloss
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.10) }
                        GradientStop { position: 0.45; color: Qt.rgba(1,1,1,0.02) }
                        GradientStop { position: 0.46; color: Qt.rgba(1,1,1,0.0)  }
                        GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                    }
                }

                // Prominent border
                Rectangle {
                    anchors.fill: parent; color: "transparent"
                    border.color: "#505050"; border.width: 1; radius: 4
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: -1; color: "transparent"
                    border.color: "#000000"; border.width: 1; radius: 5; opacity: 0.40
                }

                // Bottom edge reflection
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    height: 1; color: "#ffffff"; opacity: 0.07
                }

                // 2×2 Icon grid
                Grid {
                    anchors.centerIn: parent
                    columns: 2; spacing: panel.iconGap

                    IconButton {
                        width: panel.iconSize; height: panel.iconSize
                        iconChar: "\u266B"; accent: "#00EEFF"; tooltipText: "Qobuz Music"
                        onActivated: console.log("Qobuz Music")
                    }
                    IconButton {
                        width: panel.iconSize; height: panel.iconSize
                        iconChar: "\u2702"; accent: "#FFB300"; tooltipText: "Media Edit"
                        onActivated: console.log("Media Edit")
                    }
                    IconButton {
                        width: panel.iconSize; height: panel.iconSize
                        isStack: true; accent: "#E8E8E8"; tooltipText: "Collection Curator"
                        onActivated: console.log("Collection Curator")
                    }
                    IconButton {
                        width: panel.iconSize; height: panel.iconSize
                        iconChar: "+"; accent: "#505050"; tooltipText: "Coming Soon"
                    }
                }
            }

            // -- z:3  Cover -- slides DOWN to hide icons, UP to reveal ----------
            // Closed: y = handleH  -> sits exactly over the icon body
            // Open:   y = handleH + bodyH -> fully below panel bottom, clipped
            Rectangle {
                id: cover
                z: 3
                y: panel.isOpen ? panel.handleH + panel.bodyH : panel.handleH
                width: panel.panelW; height: panel.bodyH

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2e2e2e" }
                    GradientStop { position: 1.0; color: "#1c1c1c" }
                }

                // Gloss (matches closed panel look)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.12) }
                        GradientStop { position: 0.45; color: Qt.rgba(1,1,1,0.03) }
                        GradientStop { position: 0.46; color: Qt.rgba(1,1,1,0.0)  }
                        GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                    }
                }

                // Border -- prominent
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

            // -- z:5  Handle strip -- always on top -----------------------------
            Rectangle {
                id: handleStrip
                z: 5
                y: 0; width: panel.panelW; height: panel.handleH
                radius: 8

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#404040" }
                    GradientStop { position: 1.0; color: "#282828" }
                }

                // Gloss
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.18) }
                        GradientStop { position: 0.50; color: Qt.rgba(1,1,1,0.05) }
                        GradientStop { position: 0.51; color: Qt.rgba(1,1,1,0.0)  }
                        GradientStop { position: 1.0;  color: Qt.rgba(1,1,1,0.0)  }
                    }
                }

                // Prominent border
                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "transparent"
                    border.color: panel.isOpen ? "#787878" : "#505050"
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 300 } }
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: -1; radius: parent.radius + 1
                    color: "transparent"; border.color: "#000000"; border.width: 1; opacity: 0.40
                }

                // Bright bottom-edge highlight
                Rectangle {
                    anchors.bottom:      parent.bottom
                    anchors.left:        parent.left;  anchors.leftMargin:  14
                    anchors.right:       parent.right; anchors.rightMargin: 14
                    height: 2; radius: 1
                    color:   "#999999"
                    opacity: panel.isOpen ? 1.0 : 0.55
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                // Chevron
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.isOpen ? "\u25B4" : "\u25BE"
                    font.pixelSize: 11; color: "#999999"
                    opacity: panel.isOpen ? 1.0 : 0.55
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                // Grip dots
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
        // -- End panel ---------------------------------------------------------

    } // end displayArea
}
"""

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    engine.loadData(QML.encode("utf-8"))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())
