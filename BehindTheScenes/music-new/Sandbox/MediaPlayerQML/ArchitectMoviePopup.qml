import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Popup {
    id: moviePopup
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Component.onCompleted: console.log(">>> ArchitectMoviePopup LOADED (THIS ONE)")

    property string selectedFolder: ""

    ListModel { id: popupModel }

    function openWith(folderName, list) {
        selectedFolder = folderName
        popupModel.clear()
        if (list) {
            for (var i = 0; i < list.length; i++) {
                var rawItem = list[i]
                var path = rawItem["filePath"] || rawItem["Filename"] || "Unknown Path"
                popupModel.append({ "filePath": path })
            }
        }
        moviePopup.open()
    }

    width:  parent ? parent.width  * 0.34 : 500
    height: parent ? parent.height * 0.60 : 520

    // Shadow + frame via layer.effect — correct Qt5Compat pattern
    background: Rectangle {
        radius: 14
        color: "#141414"
        border.width: 1
        border.color: "#55d4af37"
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 10
            radius: 26
            samples: 48
            color: Qt.rgba(0, 0, 0, 0.82)
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 46

        Text {
            anchors.centerIn: parent
            anchors.rightMargin: 44   // keep away from close button
            text: moviePopup.selectedFolder
            font.pixelSize: 17
            font.bold: true
            font.letterSpacing: 1
            color: "#d4af37"
            elide: Text.ElideRight
        }

        // Small circular close button
        Item {
            id: closeBtn
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: closeMouse.containsMouse ? "#44ffffff" : "transparent"
                border.color: "#55ffffff"
                border.width: 1
            }
            Text {
                anchors.centerIn: parent
                text: "×"
                font.pixelSize: 19
                color: closeMouse.containsMouse ? "white" : "#aaaaaa"
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: moviePopup.close()
            }
        }

        // Divider
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 1
            color: "#33ffffff"
        }
    }

    // ── Movie list ─────────────────────────────────────────────────────────────
    ListView {
        id: movieList
        anchors {
            top: header.bottom; topMargin: 8
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 10; rightMargin: 10; bottomMargin: 12
        }
        model: popupModel
        clip: true
        spacing: 3

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Item {
            width: parent ? parent.width : 0
            height: 32

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: rowMouse.containsMouse ? "#22ffffff" : "transparent"
            }

            Text {
                // Strip path and extension — show clean title only
                text: {
                    var parts = model.filePath.replace(/\\/g, "/").split("/")
                    var fname = parts[parts.length - 1]
                    return fname.replace(/\.[^/.]+$/, "")
                }
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 8
                color: "#dddddd"
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }
}
