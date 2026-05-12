"""
design_preview_grid.py -- Grid Hover Effects Preview
Standalone design tool: 6-column poster grid with switchable hover styles.

Run with:
  PYTHONUTF8=1 /d/MediaVerse1.0/BehindTheScenes/venv/Scripts/python.exe design_preview_grid.py

Variants:
  V1 -- white border, no hover effect (current)
  V2 -- MediaVerse blue border on hover only
  V3 -- blue border + scale 1.0->1.05 + DropShadow lift
  V4 -- blue border + scale + DropShadow + year badge enlarges on hover
"""
import os
import sys
from pathlib import Path

SCRIPT_DIR    = Path(__file__).parent
PROJECT_ROOT  = SCRIPT_DIR.parent.parent
DISPLAY_CACHE = PROJECT_ROOT / "cacheV2" / "images" / "display"


def collect_images(folder: Path, count: int) -> list:
    exts = {".jpg", ".jpeg", ".png"}
    uris = []
    for p in sorted(folder.iterdir()):
        if p.suffix.lower() in exts:
            uris.append(p.as_uri())
            if len(uris) >= count:
                break
    return uris


display_images = collect_images(DISPLAY_CACHE, 36)
if len(display_images) < 6:
    print("ERROR: not enough images in display cache:", DISPLAY_CACHE)
    sys.exit(1)

# Extract year from filename stem e.g. "Rocky (1976)" -> "1976"
def extract_year(uri: str) -> str:
    import re
    stem = Path(uri.split("/")[-1]).stem
    m = re.search(r"\((\d{4})\)", stem)
    return m.group(1) if m else ""

years = [extract_year(u) for u in display_images]

QML = """
import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: root
    visibility: ApplicationWindow.FullScreen
    visible: true
    title: "Grid Hover Preview"

    property int variant: 1

    Rectangle { anchors.fill: parent; color: "#111111" }

    // 6-column grid centred in view
    GridView {
        id: grid
        anchors.centerIn: parent
        width:  cols * (cellSize + cellSpacing) - cellSpacing
        height: rows * (cellSize * 1.48 + cellSpacing) - cellSpacing
        cellWidth:  cellSize + cellSpacing
        cellHeight: cellSize * 1.48 + cellSpacing
        interactive: false
        clip: false

        property int cols: 6
        property int rows: Math.ceil(model.count / cols)
        property int cellSize:    160
        property int cellSpacing: 16

        model: imgPaths

        delegate: Item {
            id: cell
            width:  grid.cellSize
            height: grid.cellSize * 1.48

            property bool hov: false
            property string year: yearList[index] || ""
            HoverHandler { onHoveredChanged: cell.hov = hovered }

            // Scale (V3 / V4)
            scale: (root.variant >= 3 && cell.hov) ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            // Drop shadow (V3 / V4)
            DropShadow {
                anchors.fill: posterRect
                source: posterRect
                visible: root.variant >= 3
                radius:  cell.hov ? 20 : 0
                samples: 28
                color: cell.hov ? "#802566c2" : "#00000000"
                Behavior on radius { NumberAnimation { duration: 200 } }
                Behavior on color  { ColorAnimation  { duration: 200 } }
            }

            Rectangle {
                id: posterRect
                anchors.fill: parent
                color: "transparent"; radius: 6
                layer.enabled: root.variant >= 3   // required for DropShadow

                border.color: {
                    if (root.variant === 1) return "#555555"
                    return cell.hov ? "#2566c2" : "transparent"
                }
                border.width: cell.hov && root.variant >= 2 ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Image {
                    id: img
                    anchors.fill: parent
                    anchors.margins: root.variant === 1 ? 1 : (cell.hov ? 2 : 1)
                    source: modelData
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    Behavior on anchors.margins { NumberAnimation { duration: 150 } }
                }

                // Year badge (V4: enlarges on hover)
                Rectangle {
                    visible: root.variant === 4 && cell.year !== ""
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    anchors.margins: 4
                    width:  yearText.implicitWidth + 10
                    height: cell.hov ? 26 : 20
                    color: "#CC000000"; radius: 4
                    Behavior on height { NumberAnimation { duration: 150 } }

                    Text {
                        id: yearText
                        anchors.centerIn: parent
                        text: cell.year
                        font.pixelSize: cell.hov ? 14 : 11
                        font.bold: true
                        color: cell.hov ? "#2566c2" : "#AAAAAA"
                        Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }

    // Control bar
    Rectangle {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        width: btnRow.implicitWidth + 40; height: 52
        color: "#CC000000"; radius: 10
        border.color: "#2566c2"; border.width: 1

        Row {
            id: btnRow; anchors.centerIn: parent; spacing: 10
            Repeater {
                model: [{ v: 1, lbl: "V1 -- Current"          },
                        { v: 2, lbl: "V2 -- Blue Border"       },
                        { v: 3, lbl: "V3 -- Scale + Shadow"    },
                        { v: 4, lbl: "V4 -- + Year Badge"      }]
                delegate: Rectangle {
                    width: btnLbl.implicitWidth + 22; height: 36; radius: 6
                    color: root.variant === modelData.v ? "#2566c2" : "#333333"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { id: btnLbl; anchors.centerIn: parent; text: modelData.lbl; font.pixelSize: 16; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: root.variant = modelData.v }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
}
"""

os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Material")
os.environ.setdefault("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark")

from PySide6.QtGui  import QGuiApplication
from PySide6.QtQml  import QQmlApplicationEngine
from PySide6.QtCore import QUrl

qt_app = QGuiApplication(sys.argv)
engine  = QQmlApplicationEngine()

engine.rootContext().setContextProperty("imgPaths",  display_images)
engine.rootContext().setContextProperty("yearList",  years)

QML_PATH = SCRIPT_DIR / "_grid_preview.qml"
QML_PATH.write_text(QML, encoding="utf-8")
engine.load(QUrl.fromLocalFile(str(QML_PATH)))

if not engine.rootObjects():
    print("ERROR: QML failed to load")
    QML_PATH.unlink(missing_ok=True)
    sys.exit(1)

exit_code = qt_app.exec()
QML_PATH.unlink(missing_ok=True)
sys.exit(exit_code)
