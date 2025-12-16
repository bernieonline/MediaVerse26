import sys
import urllib.parse
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

# --- QML code ---
qml_step1 = """
import QtQuick 6.5
import QtQuick.Layouts 6.5
import QtQuick.Window 6.5
import QtQuick.Controls 6.5

Rectangle {
    width: 1000
    height: 600
    color: "black"

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // LEFT PANEL: IMAGE
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "#303030"

            Image {
                anchors.fill: parent
                source: imagePath
                fillMode: Image.PreserveAspectFit
            }
        }

        // RIGHT PANEL: BLANK DETAILS
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#202020"

            Label {
                anchors.centerIn: parent
                text: "Details panel (placeholder)"
                color: "lightgray"
            }
        }
    }
}
"""

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # --- UNC path to TrueNAS image ---
    unc_path = r"\\freenas\Collection\1960s 70s 80s\A Hard Days Night (1964).jpg"

    # Convert backslashes to forward slashes and URL-encode
    forward_path = unc_path.replace("\\", "/")
    url_encoded_path = urllib.parse.quote(forward_path.lstrip("/"))  # remove leading slash
    image_path = f"file:///{url_encoded_path}"  # exactly 4 slashes

    print("Final QML Image URL:", image_path)

    # Expose to QML
    engine.rootContext().setContextProperty("imagePath", image_path)

    # Load QML
    engine.loadData(qml_step1.encode("utf-8"))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
