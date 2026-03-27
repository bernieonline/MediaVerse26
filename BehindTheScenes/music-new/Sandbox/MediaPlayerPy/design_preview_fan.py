"""
design_preview_fan.py — Fan Card Preview
Standalone design tool: fan cards inside an accurate Framework-1.qml frame.

Run with:
  PYTHONUTF8=1 /d/MediaVerse1.0/BehindTheScenes/venv/Scripts/python.exe design_preview_fan.py

Variants:
  V1 — 1 row, black background
  V2 — 1 row, blurred cinematic bg + 50% dark overlay
  V3 — 1 row, blurred bg + frosted glass panel behind cards
  V4 — 2 rows, blurred bg + frosted glass  [default]
"""
import os
import sys
from pathlib import Path

SCRIPT_DIR    = Path(__file__).parent
PROJECT_ROOT  = SCRIPT_DIR.parent.parent
DISPLAY_CACHE = PROJECT_ROOT / "cacheV2" / "images" / "display"
SPLASH_DIR    = PROJECT_ROOT / "Assets" / "Splash"


def collect_images(folder: Path, count: int) -> list:
    exts = {".jpg", ".jpeg", ".png"}
    uris = []
    for p in sorted(folder.iterdir()):
        if p.suffix.lower() in exts:
            uris.append(p.as_uri())
            if len(uris) >= count:
                break
    return uris


display_images = collect_images(DISPLAY_CACHE, 24)
if len(display_images) < 3:
    print("ERROR: not enough images in display cache:", DISPLAY_CACHE)
    sys.exit(1)

while len(display_images) % 3:
    display_images.append(display_images[-1])

bg_images = collect_images(SPLASH_DIR, 1)
bg_uri    = bg_images[0] if bg_images else ""

# ── QML ───────────────────────────────────────────────────────────────────────
QML = """
import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: root
    visibility: ApplicationWindow.FullScreen
    visible: true
    title: "Fan Card Preview"

    // Start on V4 (2 rows + blur + frosted) — the variant the user wants to judge
    property int variant: 4

    // ── Full-screen dark base ─────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: "#1e1e1e" }

    // ── Simulate Framework-1.qml top bar (button row + search area = 18%) ────
    Rectangle {
        id: topBar
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: parent.height * 0.18
        color: "transparent"
        // Faint row of dots/label so it's clear this is the nav area
        Text {
            anchors.centerIn: parent
            text: "[ RowButton bar  ·  Search  ]"
            color: "#333333"
            font.pixelSize: 18
        }
    }

    // ── Atmospheric blurred background inside content frame (V2 / V3 / V4) ──
    Item {
        anchors.fill: contentFrame
        anchors.margins: 2          // stay inside the blue border
        visible: root.variant >= 2
        clip: true

        Image {
            id: bgImg
            anchors.fill: parent
            source: bgImageUri
            fillMode: Image.PreserveAspectCrop
            layer.enabled: true
        }
        FastBlur { anchors.fill: bgImg; source: bgImg; radius: 80 }
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.50 }
    }

    // ── Content container — exact Framework-1.qml dimensions + blue border ───
    Rectangle {
        id: contentFrame
        anchors.top:          parent.top
        anchors.topMargin:    parent.height * 0.18
        anchors.bottom:       parent.bottom
        anchors.bottomMargin: 50
        anchors.left:         parent.left
        anchors.leftMargin:   50
        anchors.right:        parent.right
        anchors.rightMargin:  50
        radius: 25
        color: "transparent"
        border.color: "#2566c2"
        border.width: 2
        clip: true

        // ── Frosted glass panel behind card area (V3 / V4) ─────────────────
        Rectangle {
            visible: root.variant >= 3
            anchors.centerIn: parent
            width:  cardArea.width  + 80
            height: cardArea.height + 80
            color: "#CC000000"; radius: 24
            border.color: "#4D2566c2"; border.width: 2
        }

        // ── Card area — CollectionsGallery has anchors.margins: 40 ──────────
        Item {
            id: cardArea
            anchors.centerIn: parent

            // Card dimensions computed to fill the available space accurately.
            // Available height = contentFrame.height - 2*40 (gallery margins)
            property int availH: contentFrame.height - 80
            property int rows:   root.variant === 4 ? 2 : 1
            property int cols:   4
            property int gap:    36
            // For 2 rows: fit both rows + gap; for 1 row: use 85% of available height
            property int cardH:  rows === 2
                                 ? Math.floor((availH - gap) / 2)
                                 : Math.min(380, Math.floor(availH * 0.85))
            property int cardW:  Math.floor(cardH * 260 / 380)
            property int cards:  cols * rows

            width:  cols * (cardW + gap) - gap
            height: rows * (cardH + gap) - gap

            Repeater {
                model: cardArea.cards
                delegate: Item {
                    id: card
                    property int ci: index
                    property var fanPaths: {
                        var s = ci * 3;
                        return [imgPaths[s] || "", imgPaths[s+1] || "", imgPaths[s+2] || ""];
                    }

                    width:  cardArea.cardW
                    height: cardArea.cardH
                    x: (ci % cardArea.cols) * (cardArea.cardW + cardArea.gap)
                    y: Math.floor(ci / cardArea.cols) * (cardArea.cardH + cardArea.gap)

                    DropShadow {
                        anchors.fill: cardRect; source: cardRect
                        radius: 16; samples: 24
                        color: cardHover.hovered ? "#802566c2" : "#99000000"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: cardRect
                        anchors.fill: parent
                        color: "#1A1A1A"; radius: 18
                        border.color: cardHover.hovered ? "#2566c2" : "#333333"
                        border.width: cardHover.hovered ? 3 : 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: cardHover }

                        // Fan images
                        Item {
                            width: parent.width
                            height: parent.height - Math.floor(cardArea.cardH * 0.19)
                            anchors.top: parent.top; anchors.topMargin: 8
                            clip: true

                            Repeater {
                                model: 3
                                delegate: Item {
                                    id: fanItem
                                    property int fi: index
                                    // Scale fan poster proportionally to card width
                                    property int pw: Math.floor(cardArea.cardW * 0.58)
                                    property int ph: Math.floor(pw * 1.48)
                                    width: pw; height: ph
                                    anchors.centerIn: parent
                                    rotation: fi === 0 ? -22 : (fi === 1 ? 0 : 22)
                                    x:        fi === 0 ? -Math.floor(pw * 0.30)
                                              : (fi === 1 ? 0 : Math.floor(pw * 0.30))
                                    z:        fi === 1 ? 2 : 1

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 7; color: "#000"
                                        border.color: "white"; border.width: 2; clip: true
                                        Image {
                                            id: fanImg; anchors.fill: parent; anchors.margins: 2
                                            source: card.fanPaths[fanItem.fi]
                                            fillMode: Image.PreserveAspectCrop
                                            visible: false
                                        }
                                        Rectangle { id: fanMask; anchors.fill: parent; radius: 5; visible: false }
                                        OpacityMask { anchors.fill: parent; source: fanImg; maskSource: fanMask }
                                    }
                                }
                            }
                        }

                        // Collection name label
                        Text {
                            anchors.bottom: actionRow.top; anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Collection " + (card.ci + 1)
                            color: "white"
                            font.pixelSize: Math.max(12, Math.floor(cardArea.cardW * 0.062))
                            font.bold: true
                        }

                        // Action row — fades in on hover
                        Row {
                            id: actionRow
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 14
                            opacity: cardHover.hovered ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            Repeater {
                                model: [{ label: "FAV",  col: "#FFD700" },
                                        { label: "EDIT", col: "#2566c2" },
                                        { label: "DEL",  col: "#FF4444" }]
                                delegate: Item {
                                    width: 44; height: 22
                                    property bool hov: false
                                    HoverHandler { onHoveredChanged: parent.hov = hovered }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.pixelSize: Math.max(11, Math.floor(cardArea.cardW * 0.052))
                                        font.bold: true
                                        color: parent.hov ? modelData.col : "#888888"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Control bar ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        width: btnRow.implicitWidth + 40; height: 44
        color: "#DD000000"; radius: 8
        border.color: "#2566c2"; border.width: 1
        z: 100

        Row {
            id: btnRow; anchors.centerIn: parent; spacing: 8
            Repeater {
                model: [{ v: 1, lbl: "V1 — 1 Row / Black"    },
                        { v: 2, lbl: "V2 — 1 Row / Blur"      },
                        { v: 3, lbl: "V3 — 1 Row / Frosted"   },
                        { v: 4, lbl: "V4 — 2 Rows / Frosted"  }]
                delegate: Rectangle {
                    width: btnLbl.implicitWidth + 18; height: 32; radius: 5
                    color: root.variant === modelData.v ? "#2566c2" : "#333333"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { id: btnLbl; anchors.centerIn: parent; text: modelData.lbl; font.pixelSize: 14; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: root.variant = modelData.v }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
}
"""

# ── Launch ────────────────────────────────────────────────────────────────────
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Material")
os.environ.setdefault("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark")

from PySide6.QtGui  import QGuiApplication
from PySide6.QtQml  import QQmlApplicationEngine
from PySide6.QtCore import QUrl

qt_app = QGuiApplication(sys.argv)
engine  = QQmlApplicationEngine()

engine.rootContext().setContextProperty("imgPaths",   display_images)
engine.rootContext().setContextProperty("bgImageUri", bg_uri)

QML_PATH = SCRIPT_DIR / "_fan_preview.qml"
QML_PATH.write_text(QML, encoding="utf-8")
engine.load(QUrl.fromLocalFile(str(QML_PATH)))

if not engine.rootObjects():
    print("ERROR: QML failed to load")
    QML_PATH.unlink(missing_ok=True)
    sys.exit(1)

exit_code = qt_app.exec()
QML_PATH.unlink(missing_ok=True)
sys.exit(exit_code)
