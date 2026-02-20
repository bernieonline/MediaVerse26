import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Popup {
    id: moviePopup
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Component.onCompleted: console.log(">>> ArchitectMoviePopup LOADED (THIS ONE)")

    // Public properties
    property string selectedFolder: ""

    // Internal model
    ListModel { id: popupModel }

    // --- PUBLIC API (FIXED) ---
    function openWith(folderName, list) {
        selectedFolder = folderName
        popupModel.clear()
        
        if (list) {
            for (var i = 0; i < list.length; i++) {
                var rawItem = list[i];
                
                // We use Bracket notation to safely extract the path
                // This bypasses the "value is not an object" error
                var path = rawItem["filePath"] || rawItem["Filename"] || "Unknown Path";

                popupModel.append({"filePath": path});
            }
        }
        moviePopup.open()
    }

    width: parent ? parent.width * 0.45 : 600
    height: parent ? parent.height * 0.55 : 500

    background: Rectangle {
        id: bg
        radius: 18
        color: "#1a1a1a"
        border.width: 2
        border.color: "#d4af37"

        DropShadow {
            anchors.fill: bg
            source: bg
            horizontalOffset: 0
            verticalOffset: 6
            radius: 24
            samples: 32
            color: "#000000"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        // --- TITLE ---
        Text {
            text: selectedFolder
            font.pixelSize: 28
            font.bold: true
            color: "#f5f5f5"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        // --- DIVIDER ---
        Rectangle {
            height: 1
            Layout.fillWidth: true
            color: "#444"
        }

        // --- MOVIE LIST ---
        ListView {
            id: movieList
            model: popupModel
            clip: true
            spacing: 8
            Layout.fillWidth: true
            Layout.fillHeight: true

            delegate: Rectangle {
                //width: parent.width
                width: parent ? parent.width : 0
                height: 42
                radius: 8
                color: hovered ? "#333333" : "transparent"

                property bool hovered: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }

                Text {
                    // This matches the key we used in popupModel.append
                    text: model.filePath 
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    color: "#e0e0e0"
                    font.pixelSize: 20
                }
            }
        }

        // --- CLOSE BUTTON ---
        Rectangle {
            id: closeButton
            Layout.fillWidth: true
            height: 46
            radius: 10
            color: "#d4af37"

            Text {
                anchors.centerIn: parent
                text: "Close"
                font.pixelSize: 20
                font.bold: true
                color: "#1a1a1a"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: moviePopup.close()
            }
        }
    }
}