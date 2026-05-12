"""
design_preview_fan.py -- Fan Card Preview
Standalone design tool: fan cards inside an accurate Framework-1.qml frame.

  Background  : dvds.jpg shelf photo + black veil 0.45 (CategoryMenu style, no blur)
  Card panels : CollectionsGallery cardRect -- #1A1A1A, radius 20, blue border on hover
  No outer group panel.
  5 cols × 2 rows, 4 fan posters per card.

Run:
  PYTHONUTF8=1 /d/MediaVerse1.0/BehindTheScenes/venv/Scripts/python.exe design_preview_fan.py
"""
import os
import sys
from pathlib import Path

SCRIPT_DIR    = Path(__file__).parent
PROJECT_ROOT  = SCRIPT_DIR.parent.parent          # .../music-new
DISPLAY_CACHE = PROJECT_ROOT / "cacheV2" / "images" / "display"
SHELF_BG      = PROJECT_ROOT / "Assets" / "Splash" / "dvds.jpg"


def collect_images(folder: Path, count: int) -> list:
    exts = {".jpg", ".jpeg", ".png"}
    uris = []
    for p in sorted(folder.iterdir()):
        if p.suffix.lower() in exts:
            uris.append(p.as_uri())
            if len(uris) >= count:
                break
    return uris


display_images = collect_images(DISPLAY_CACHE, 40)
if len(display_images) < 4:
    print("ERROR: not enough images in display cache:", DISPLAY_CACHE)
    sys.exit(1)

while len(display_images) % 4:
    display_images.append(display_images[-1])

if not SHELF_BG.exists():
    print(f"WARNING: background image not found: {SHELF_BG}")
bg_uri = SHELF_BG.as_uri() if SHELF_BG.exists() else ""

# -- QML -----------------------------------------------------------------------
QML = """
import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: root
    visibility: ApplicationWindow.FullScreen
    visible: true
    title: "Fan Card Preview"

    // -- Full-screen dark base -------------------------------------------------
    Rectangle { anchors.fill: parent; color: "#111111" }

    // -- Simulated Framework-1.qml top bar ------------------------------------
    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: parent.height * 0.18; color: "transparent"
        Text { anchors.centerIn: parent; text: "[ RowButton bar  .  Search  ]"
               color: "#2A2A2A"; font.pixelSize: 18 }
    }

    // -- Content frame -- Framework-1.qml proportions + blue border ------------
    Rectangle {
        id: contentFrame
        anchors.top:          parent.top;    anchors.topMargin:    parent.height * 0.18
        anchors.bottom:       parent.bottom; anchors.bottomMargin: 50
        anchors.left:         parent.left;   anchors.leftMargin:   50
        anchors.right:        parent.right;  anchors.rightMargin:  50
        radius: 25; color: "transparent"
        border.color: "#2566c2"; border.width: 2
        clip: true

        // -- dvds.jpg background -- CategoryMenu style: image + dark veil, no blur --
        Image {
            anchors.fill: parent
            source: bgImageUri
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle {
            anchors.fill: parent
            color: "black"; opacity: 0.45
        }

        // -- Card grid -- no outer container panel -----------------------------
        Item {
            id: cardArea
            anchors.centerIn: parent

            property int availH: contentFrame.height - 80
            property int rows:   2
            property int cols:   5
            property int gap:    64
            property int cardH:  Math.floor((availH - gap) / 2)
            property int cardW:  Math.floor(cardH * 300 / 380)
            property int cards:  cols * rows

            width:  cols * (cardW + gap) - gap
            height: rows * (cardH + gap) - gap

            Repeater {
                model: cardArea.cards
                delegate: Item {
                    id: card
                    property int ci: index
                    property var fanPaths: {
                        var s = ci * 4;
                        return [imgPaths[s]   || "",
                                imgPaths[s+1] || "",
                                imgPaths[s+2] || "",
                                imgPaths[s+3] || ""];
                    }

                    width:  cardArea.cardW
                    height: cardArea.cardH
                    x: (ci % cardArea.cols) * (cardArea.cardW + cardArea.gap)
                    y: Math.floor(ci / cardArea.cols) * (cardArea.cardH + cardArea.gap)

                    // -- DropShadow -- gold glow on hover ----------------------
                    DropShadow {
                        anchors.fill: cardRect
                        radius: 18; samples: 24
                        color: (cardHover.hovered || actionRow.anyHover)
                               ? "#CCFFD700" : "#55000000"
                        source: cardRect
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // -- Card panel -- gold border, thin at rest, glows on hover -
                    Rectangle {
                        id: cardRect
                        anchors.centerIn: parent
                        width:  parent.width
                        height: parent.height
                        color: "#1A1A1A"
                        radius: 20
                        border.color: (cardHover.hovered || actionRow.anyHover)
                                      ? "#FFD700" : "#7A5C00"
                        border.width: (cardHover.hovered || actionRow.anyHover) ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        HoverHandler { id: cardHover }

                        // -- Fan image area ------------------------------------
                        Item {
                            id: fanContainer
                            anchors.top: parent.top; anchors.topMargin: 15
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 15; anchors.rightMargin: 15
                            height: Math.floor(parent.height * 0.68)
                            clip: true

                            Repeater {
                                model: 4
                                delegate: Item {
                                    id: fanItem
                                    property int fi: index
                                    property int pw: Math.floor(cardArea.cardW * 0.52)
                                    property int ph: Math.floor(pw * 1.48)
                                    width: pw; height: ph
                                    anchors.centerIn: parent
                                    rotation: fi === 0 ? -30 : (fi === 1 ? -10 : (fi === 2 ? 10 : 30))
                                    x: fi === 0 ? -Math.floor(pw * 0.46)
                                       : (fi === 1 ? -Math.floor(pw * 0.15)
                                       : (fi === 2 ?  Math.floor(pw * 0.15)
                                       :              Math.floor(pw * 0.46)))
                                    z: (fi === 1 || fi === 2) ? 2 : 1
                                    opacity: (fi === 0 || fi === 3) ? 0.85 : 1.0

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8; color: "#000"
                                        border.color: "white"; border.width: 2
                                        clip: true

                                        Image {
                                            id: fanImg
                                            anchors.fill: parent; anchors.margins: 2
                                            source: card.fanPaths[fi]
                                            fillMode: Image.PreserveAspectCrop
                                            visible: false
                                        }
                                        Rectangle { id: fanMask; anchors.fill: parent; radius: 6; visible: false }
                                        OpacityMask { anchors.fill: parent; source: fanImg; maskSource: fanMask }
                                    }
                                }
                            }
                        }

                        // -- Collection name -- CollectionsGallery style --------
                        Text {
                            id: nameLabel
                            anchors.bottom: actionRow.top; anchors.bottomMargin: 6
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            text: "Collection " + (card.ci + 1)
                            color: "white"
                            font.pixelSize: 18; font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // -- Action row -- FAV / EDIT / DEL (CollectionsGallery) -
                        Row {
                            id: actionRow
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10
                            z: 10

                            property bool anyHover: favHov.containsMouse
                                                 || editHov.containsMouse
                                                 || delHov.containsMouse

                            opacity: (cardHover.hovered || anyHover) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250 } }

                            // FAV
                            Item {
                                width: 48; height: 26
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { text: ""; font.pixelSize: 14
                                           color: favHov.containsMouse ? "#FFE040" : "#BBBBBB"
                                           Behavior on color { ColorAnimation { duration: 100 } } }
                                    Text { text: "FAV"; font.pixelSize: 12; font.bold: true
                                           color: favHov.containsMouse ? "#FFE040" : "#BBBBBB"
                                           Behavior on color { ColorAnimation { duration: 100 } } }
                                }
                                MouseArea { id: favHov; anchors.fill: parent; hoverEnabled: true }
                            }

                            // EDIT
                            Item {
                                width: 52; height: 26
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { text: "[EDIT]"; font.pixelSize: 14
                                           color: editHov.containsMouse ? "#66AAFF" : "#BBBBBB"
                                           Behavior on color { ColorAnimation { duration: 100 } } }
                                    Text { text: "EDIT"; font.pixelSize: 12; font.bold: true
                                           color: editHov.containsMouse ? "#66AAFF" : "#BBBBBB"
                                           Behavior on color { ColorAnimation { duration: 100 } } }
                                }
                                MouseArea { id: editHov; anchors.fill: parent; hoverEnabled: true }
                            }

                            // DEL
                            Item {
                                width: 46; height: 26
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { text: "[DEL]"; font.pixelSize: 14
                                           color: delHov.containsMouse ? "#FF6060" : "#BBBBBB"
                                           Behavior on color { ColorAnimation { duration: 100 } } }
                                    Text { text: "DEL"; font.pixelSize: 12; font.bold: true
                                           color: delHov.containsMouse ? "#FF6060" : "#BBBBBB"
                                           Behavior on color { ColorAnimation { duration: 100 } } }
                                }
                                MouseArea { id: delHov; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
}
"""

# -- Launch --------------------------------------------------------------------
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
