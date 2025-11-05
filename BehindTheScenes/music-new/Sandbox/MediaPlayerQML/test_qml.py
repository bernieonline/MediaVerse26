import sys
import os
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QLibraryInfo

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)

    QCoreApplication.addLibraryPath(str(Path(sys.modules["PySide6"].__file__).parent / "plugins"))

    # Add the PySide6 package directory to the DLL search path.
    # This is required on Windows for QML to find its dependent Qt DLLs.
    pyside6_dir = Path(sys.modules["PySide6"].__file__).parent
    os.add_dll_directory(str(pyside6_dir))

    engine = QQmlApplicationEngine()

    # Use QLibraryInfo to get the built-in QML import path
    qml_import_path = QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath)
    engine.addImportPath(qml_import_path)

    qml = """
    import QtQuick 2.15
    import QtQuick.Controls 2.15
    import QtQuick
    import QtQuick.Controls
    //import QtQuick.GraphicalEffects
    
    ApplicationWindow {
        id: window
        // Set the visibility to FullScreen to make the window take up the entire screen.
        visibility: ApplicationWindow.FullScreen
        title: "MediaVerse"
    
        // A background rectangle to set the color of the window.
        Rectangle {
            id: background
            anchors.fill: parent
            color: "#1e1e1e"
        }

        // A rectangle for the border
        Rectangle {
            id: border
            anchors.fill: parent
            anchors.margins: 10
            radius: 25
            color: "transparent" // We only want the border
            border.color: "#f1ba54"
            border.width: 5
        }

        // Glow effect for the side panel
        //Glow {
            //id: sidePanelGlow
            //anchors.fill: sidePanel
            //source: sidePanel
            //radius: 20
            //samples: 16
            //color: "#f1ba54"
            //spread: 0.5
            // The glow should only be visible when the panel is
            //visible: sidePanel.x === 0
            // Animate the glow's visibility
            //Behavior on visible { Animation { duration: 300 } }
        //}

        // Hidden side panel for file structure
        Rectangle {
            id: sidePanel
            width: 300
            height: parent.height * 2 / 3
            anchors.verticalCenter: parent.verticalCenter
            // Initially positioned off-screen to the left
            x: -width

            // The panel's main color
            color: "transparent" // Make panel transparent to see glow behind it

            // Rounded corners on the right side
            radius: 25

            // A subtle border on the right to give a 3D layered effect
            border.color: "#444444" // A lighter grey for the highlight
            border.width: 1

            // Animation for sliding in and out
            Behavior on x {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            // A rectangle inside the panel to hold the content and background color
            Rectangle {
                anchors.fill: parent
                color: "#1e1e1e"
                radius: parent.radius
                // We don't want this inner rectangle to have a border
                border.width: 0
            }

            // A scrollable list view for the file structure
            ListView {
                id: fileView
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 80 // Make space for scroll controls
                clip: true // Ensures content doesn't spill out

                // Dummy model for demonstration
                model: 50
                delegate: Item {
                    width: parent.width
                    height: 40
                    Text {
                        text: "Folder or File " + (index + 1)
                        color: "white"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                    }
                }
            }

            // Timer to handle continuous scrolling
            Timer {
                id: scrollTimer
                interval: 50 // Scroll every 50ms
                repeat: true
                property int scrollStep: 0 // positive for down, negative for up
                onTriggered: {
                    fileView.contentY += scrollStep;
                }
            }

            // Container for adjacent scroll controls
            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 15
                spacing: 10

                // "Up" and "Down" hot zones
                Loader {
                    sourceComponent: scrollButtonComponent
                    onLoaded: {
                        item.text = "▲";
                        item.scrollAmount = -10;
                    }
                }
                Loader {
                    sourceComponent: scrollButtonComponent
                    onLoaded: {
                        item.text = "▼";
                        item.scrollAmount = 10;
                    }
                }
            }
        }

        // Button to toggle the side panel
        Button {
            id: menuButton
            text: "Menu"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 20
            onClicked: sidePanel.x = (sidePanel.x === 0) ? -sidePanel.width : 0
        }

        // Button to close the application
        Button {
            text: "Close"
            width: 200
            height: 75
            anchors.centerIn: parent
            onClicked: Qt.quit()
        }

        // Component definition for the scroll button
        Component {
            id: scrollButtonComponent
            Rectangle {
                property string text
                property int scrollAmount

                width: 80
                height: 50
                color: "#333"
                radius: 8
                border.color: "#555"

                Text {
                    anchors.centerIn: parent
                    text: parent.text
                    color: "white"
                    font.pixelSize: 24
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        scrollTimer.scrollStep = scrollAmount;
                        scrollTimer.start();
                    }
                    onExited: {
                        scrollTimer.stop();
                    }
                }
            }
        }
    }
    """

    engine.loadData(bytes(qml, encoding="utf-8"))

    if not engine.rootObjects():
        print("QML FAILED ❌")
        sys.exit(-1)

    sys.exit(app.exec())
