import sys
from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

qml_code = b"""
import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5
import QtQuick.Window 6.5

Rectangle {
    id: detailViewRoot
    width: 1000
    height: 600
    color: "black"

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // LEFT PANEL: Poster image
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            color: "transparent"

            Image {
                id: posterImage
                anchors.fill: parent
                source: imagePath   // context property from Python
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // RIGHT PANEL: Tab bar + stack
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true

                TabButton { text: "Details"; checked: true }
                TabButton { text: "Actors" }
                TabButton { text: "Director" }
                TabButton { text: "Filming" }
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // Details tab: show XML text
                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: xmlText        // context property from Python
                        color: "white"
                        wrapMode: Text.Wrap
                        readOnly: true
                        font.family: "Courier New"
                        font.pixelSize: 14
                    }
                }

                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: "Actors content"
                        color: "white"
                    }
                }

                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: "Director content"
                        color: "white"
                    }
                }

                Rectangle {
                    color: "#202020"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: "Filming content"
                        color: "white"
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("Image path:", imagePath)
        console.log("XML text length:", xmlText.length)
    }
}
"""

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # Normalize image path
    image_path = QUrl.fromLocalFile(
        r"W:\Collection\1960s 70s 80s\A Hard Days Night (1964).jpg"
    ).toString()

    # Read XML file as plain text
    xml_file = r"W:\Collection\1960s 70s 80s\A Hard Days Night (1964)_m2ts_JRSidecar.xml"
    try:
        with open(xml_file, "r", encoding="utf-8") as f:
            xml_text = f.read()
        xml_text = xml_text.replace("\\", "\\\\")
    except Exception as e:
        print("Error reading XML file:", e)
        xml_text = "Failed to load XML file."

    # Debug logging
    print("Image path:", image_path)
    print("XML text length (Python side):", len(xml_text))

    # Expose both to QML
    engine.rootContext().setContextProperty("imagePath", image_path)
    engine.rootContext().setContextProperty("xmlText", xml_text)

    # Load QML from string
    engine.loadData(qml_code)

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())