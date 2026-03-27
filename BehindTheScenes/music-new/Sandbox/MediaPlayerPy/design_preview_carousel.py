"""
design_preview_carousel.py — Carousel 3D Effects Preview
Standalone design tool: 5-visible horizontal carousel with switchable 3D effects.

Run with:
  PYTHONUTF8=1 /d/MediaVerse1.0/BehindTheScenes/venv/Scripts/python.exe design_preview_carousel.py

Variants:
  V1 — scale + opacity only (current)
  V2 — + FastBlur depth-of-field on non-centre posters
  V3 — + DropShadow on centre poster
  V4 — + Y-axis perspective tilt on side posters
  V5 — Full combo: blur + shadow + tilt
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


display_images = collect_images(DISPLAY_CACHE, 20)
if len(display_images) < 5:
    print("ERROR: not enough images in display cache:", DISPLAY_CACHE)
    sys.exit(1)

QML = """
import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: root
    visibility: ApplicationWindow.FullScreen
    visible: true
    title: "Carousel 3D Preview"

    property int variant: 1

    Rectangle { anchors.fill: parent; color: "#0d0d0d" }

    // --- Carousel geometry ---
    readonly property real posterH:   root.height * 0.58
    readonly property real posterW:   posterH * (2/3)
    readonly property real centreX:   root.width  / 2
    readonly property real centreY:   root.height * 0.46

    // Scale/opacity by distance from centre
    function scaleFor(dist) {
        if (dist === 0) return 1.10
        if (dist === 1) return 0.86
        if (dist === 2) return 0.70
        return 0.0
    }
    function opacityFor(dist) {
        if (dist === 0) return 1.0
        if (dist === 1) return 0.80
        if (dist === 2) return 0.55
        return 0.0
    }
    function xOffsetFor(dist, side) {
        // side: -1 left, +1 right
        if (dist === 0) return 0
        var step = posterW * 0.82
        return side * dist * step
    }

    // Poster list with repeating items centred on currentIndex
    property int currentIndex: 2

    ListView {
        id: lv
        anchors.fill: parent
        interactive: false
        orientation: ListView.Horizontal
        model: imgPaths
        currentIndex: root.currentIndex

        delegate: Item {
            id: poster
            property int dist: Math.abs(index - root.currentIndex)
            property int side: index < root.currentIndex ? -1 : (index > root.currentIndex ? 1 : 0)

            width:  root.posterW
            height: root.posterH
            visible: dist <= 2

            x: root.centreX - root.posterW / 2 + xOffsetFor(dist, side)
            y: root.centreY - root.posterH / 2
            z: 10 - dist

            scale:   root.scaleFor(dist)
            opacity: root.opacityFor(dist)
            Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on x       { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            // --- Y-axis tilt (V4 / V5) ---
            transform: Rotation {
                origin.x: poster.width / 2
                origin.y: poster.height / 2
                axis.x: 0; axis.y: 1; axis.z: 0
                angle: (root.variant === 4 || root.variant === 5)
                       ? side * dist * 12
                       : 0
                Behavior on angle { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            // Drop shadow on centre poster (V3 / V5)
            DropShadow {
                anchors.fill: posterRect; source: posterRect
                visible: (root.variant === 3 || root.variant === 5) && dist === 0
                radius: 28; samples: 32
                color: "#CC2566c2"
            }

            Rectangle {
                id: posterRect
                anchors.fill: parent
                color: "transparent"; radius: 8
                // layer required for DropShadow source
                layer.enabled: (root.variant === 3 || root.variant === 5) && dist === 0

                Image {
                    id: posterImg
                    anchors.fill: parent
                    source: modelData
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    visible: false
                    layer.enabled: (root.variant === 2 || root.variant === 5) && dist > 0
                }

                Rectangle { id: imgMask; anchors.fill: parent; radius: 8; visible: false }

                OpacityMask {
                    id: maskedImg
                    anchors.fill: parent
                    source: posterImg; maskSource: imgMask
                    // FastBlur on non-centre (V2 / V5)
                    visible: !(root.variant === 2 || root.variant === 5) || dist === 0
                }

                // Blurred version for side posters (V2 / V5)
                // Pattern: separate Image with layer.enabled -> FastBlur
                Item {
                    anchors.fill: parent
                    visible: (root.variant === 2 || root.variant === 5) && dist > 0
                    clip: true

                    Image {
                        id: blurSrc
                        anchors.fill: parent
                        source: modelData
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                    }
                    FastBlur {
                        anchors.fill: blurSrc
                        source: blurSrc
                        radius: dist === 1 ? 18 : 36
                    }
                    // Darken slightly
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: dist === 1 ? 0.15 : 0.30
                    }
                }
            }
        }
    }

    // Nav arrows
    Text {
        id: leftArrow
        anchors.left: parent.left; anchors.leftMargin: 60
        anchors.verticalCenter: parent.verticalCenter
        text: "❮"; font.pixelSize: 70
        color: leftMa.containsMouse ? "#FFFFFF" : "#555555"
        Behavior on color { ColorAnimation { duration: 120 } }
        MouseArea {
            id: leftMa; anchors.fill: parent; hoverEnabled: true
            onClicked: if (root.currentIndex > 0) root.currentIndex--
        }
    }
    Text {
        id: rightArrow
        anchors.right: parent.right; anchors.rightMargin: 60
        anchors.verticalCenter: parent.verticalCenter
        text: "❯"; font.pixelSize: 70
        color: rightMa.containsMouse ? "#FFFFFF" : "#555555"
        Behavior on color { ColorAnimation { duration: 120 } }
        MouseArea {
            id: rightMa; anchors.fill: parent; hoverEnabled: true
            onClicked: if (root.currentIndex < imgPaths.length - 1) root.currentIndex++
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
            id: btnRow; anchors.centerIn: parent; spacing: 8
            Repeater {
                model: [{ v: 1, lbl: "V1 — Scale/Opacity"    },
                        { v: 2, lbl: "V2 — + Blur DoF"        },
                        { v: 3, lbl: "V3 — + Shadow"          },
                        { v: 4, lbl: "V4 — + Tilt"            },
                        { v: 5, lbl: "V5 — Full Combo"        }]
                delegate: Rectangle {
                    width: btnLbl.implicitWidth + 20; height: 36; radius: 6
                    color: root.variant === modelData.v ? "#2566c2" : "#333333"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { id: btnLbl; anchors.centerIn: parent; text: modelData.lbl; font.pixelSize: 15; color: "white" }
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

engine.rootContext().setContextProperty("imgPaths", display_images)

QML_PATH = SCRIPT_DIR / "_carousel_preview.qml"
QML_PATH.write_text(QML, encoding="utf-8")
engine.load(QUrl.fromLocalFile(str(QML_PATH)))

if not engine.rootObjects():
    print("ERROR: QML failed to load")
    QML_PATH.unlink(missing_ok=True)
    sys.exit(1)

exit_code = qt_app.exec()
QML_PATH.unlink(missing_ok=True)
sys.exit(exit_code)
