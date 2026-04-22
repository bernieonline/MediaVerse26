import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  FileDetailsView — ffprobe file details panel
//
//  Centred modal panel over a static movie poster backdrop.
//  Unified with the rest of the Workbench panel design.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color green:     "#39FF14"
    readonly property color panelBg:   "#06101c"
    readonly property color borderCol: "#39FF14"
    readonly property color bodyBg:    "#080f18"

    // ── Outer glow ring ───────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width: panel.width + 10; height: panel.height + 10; radius: 20
        color: "transparent"; border.color: root.green; border.width: 1; opacity: 0.07; z: 1
    }

    // ── Centred panel ─────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width:  parent.width  * 0.70
        height: parent.height * 0.84
        radius: 14; color: root.panelBg
        border.color: root.borderCol; border.width: 2; z: 2

        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }

        // ── Title bar ─────────────────────────────────────────────────────────
        Rectangle {
            id: titleBar
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 62; color: Qt.rgba(0,0,0,0.28); radius: 14
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: parent.radius; color: parent.color }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: "FILE DETAILS"
                font.family: "Segoe UI"; font.pixelSize: 26; font.bold: true; font.letterSpacing: 4
                color: root.green
            }

            // Buttons — only when results are loaded
            Row {
                anchors.right: parent.right; anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                visible: bodyArea.text !== ""

                WorkbenchActionButton {
                    label: "Save"; accent: root.green
                    onActivated: ffmpegBackend.saveDetails(headerArea.text + "\n" + bodyArea.text)
                }
                WorkbenchActionButton {
                    label: "New File"; accent: "#AAAAAA"
                    onActivated: {
                        headerArea.text = ""; bodyArea.text = ""; statusBar.text = ""
                        ffmpegBackend.fileDetails()
                    }
                }
            }
        }

        Rectangle {
            id: divider
            anchors.top: titleBar.bottom
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 1; color: root.borderCol; opacity: 0.30
        }

        // ── Waiting state ─────────────────────────────────────────────────────
        Text {
            id: waitingLabel
            anchors.centerIn: parent
            text: "Select a file to view its technical details…"
            color: "#334455"; font.pixelSize: 20; font.italic: true
            visible: bodyArea.text === ""
        }

        // ── Header — filename / size / duration ───────────────────────────────
        TextArea {
            id: headerArea
            anchors.top:   divider.bottom; anchors.topMargin: 12
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            readOnly: true; wrapMode: TextArea.Wrap
            color: "#aaccbb"; font.pixelSize: 18; font.family: "Consolas"
            background: Rectangle { color: "transparent" }
            padding: 0; implicitHeight: contentHeight
            visible: text !== ""
        }

        // Divider between header and body
        Rectangle {
            anchors.top:   headerArea.bottom; anchors.topMargin: 8
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 1; color: "#1e2e3e"; visible: headerArea.text !== ""
        }

        // ── Body — scrollable technical detail ───────────────────────────────
        Rectangle {
            anchors.top:    headerArea.bottom; anchors.topMargin:    headerArea.text !== "" ? 18 : 0
            anchors.bottom: statusBar.visible ? statusBar.top : parent.bottom
            anchors.bottomMargin: statusBar.visible ? 8 : 24
            anchors.left:   parent.left;  anchors.leftMargin:  24
            anchors.right:  parent.right; anchors.rightMargin: 24
            color: root.bodyBg; border.color: root.borderCol; border.width: 1; radius: 6; clip: true
            visible: bodyArea.text !== ""

            ScrollView {
                anchors.fill: parent; anchors.margins: 8
                ScrollBar.vertical.policy:   ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                TextArea {
                    id: bodyArea; width: parent.width; readOnly: true
                    wrapMode: TextArea.NoWrap; text: ""
                    color: "white"; font.pixelSize: 20; font.family: "Consolas"
                    background: Rectangle { color: "transparent" }
                    padding: 0
                }
            }
        }

        // ── Status bar ────────────────────────────────────────────────────────
        Text {
            id: statusBar
            anchors.bottom: parent.bottom; anchors.bottomMargin: 16
            anchors.left:   parent.left;   anchors.leftMargin:   24
            anchors.right:  parent.right;  anchors.rightMargin:  24
            color: "#7aaabb"; font.pixelSize: 16; font.italic: true
            elide: Text.ElideRight; visible: text !== ""
        }
    }

    // ── Backend connections ───────────────────────────────────────────────────
    Connections {
        target: ffmpegBackend

        function onFileDetailsReady(header, body) {
            headerArea.text = header
            bodyArea.text   = body
            statusBar.text  = ""
        }

        function onStatusMessage(msg) {
            statusBar.text = msg
        }

        function onTestError(msg) {
            statusBar.text = "Error: " + msg
        }
    }
}
