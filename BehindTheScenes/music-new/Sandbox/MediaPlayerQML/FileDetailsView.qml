import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  FileDetailsView.qml — ffprobe file details panel
//  Slides in from the right (same 38% panel pattern as other Workbench views).
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── Slide-in ──────────────────────────────────────────────────────────────
    property real targetX: parent ? parent.width * 0.62 : 0
    x: targetX + 30
    opacity: 0

    Connections {
        target: ffmpegBackend

        function onFileDetailsReady(header, body) {
            headerArea.text = header
            bodyArea.text   = body
            statusBar.text  = ""
            root.state      = "visible"
        }

        function onStatusMessage(msg) {
            statusBar.text = msg
            if (msg.toLowerCase().indexOf("prob") !== -1 ||
                msg.toLowerCase().indexOf("detail") !== -1) {
                root.state = "visible"
            }
        }

        function onTestError(msg) {
            statusBar.text = "Error: " + msg
        }
    }

    states: State {
        name: "visible"
        PropertyChanges { target: root; x: root.targetX; opacity: 1 }
    }
    transitions: Transition {
        to: "visible"
        ParallelAnimation {
            NumberAnimation { property: "x";       duration: 320; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; duration: 260 }
        }
    }

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:   "#0d1117"
        opacity: 0.97
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: 20
        spacing:         12

        // Title bar
        RowLayout {
            Layout.fillWidth: true

            Text {
                text:              "FILE DETAILS"
                color:             "#39FF14"
                font.pixelSize:    18
                font.bold:         true
                font.letterSpacing: 3
            }

            Item { Layout.fillWidth: true }

            // Save button — only shown once results are loaded
            Rectangle {
                id:     saveBtn
                width:  90; height: 34
                color:  saveHover ? "#39FF14" : "#1a2a1a"
                radius: 6
                border.color: "#39FF14"
                border.width: 1
                visible: bodyArea.text !== ""
                property bool saveHover: false

                Text {
                    anchors.centerIn: parent
                    text:           "Save"
                    color:          parent.saveHover ? "#111" : "white"
                    font.pixelSize: 16
                    font.bold:      true
                }
                MouseArea {
                    anchors.fill:  parent
                    hoverEnabled:  true
                    cursorShape:   Qt.PointingHandCursor
                    onEntered:     parent.saveHover = true
                    onExited:      parent.saveHover = false
                    onClicked:     ffmpegBackend.saveDetails(headerArea.text + "\n" + bodyArea.text)
                }
            }

            // New File button — once results are loaded
            Rectangle {
                width:  100; height: 34
                color:  newHover ? "#333" : "#222"
                radius: 6
                border.color: "#555"
                border.width: 1
                visible: bodyArea.text !== ""
                property bool newHover: false

                Text {
                    anchors.centerIn: parent
                    text:           "New File"
                    color:          "white"
                    font.pixelSize: 15
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onEntered:    parent.newHover = true
                    onExited:     parent.newHover = false
                    onClicked: {
                        headerArea.text = ""
                        bodyArea.text   = ""
                        statusBar.text  = ""
                        ffmpegBackend.fileDetails()
                    }
                }
            }
        }

        // Accent line
        Rectangle { Layout.fillWidth: true; height: 1; color: "#39FF14"; opacity: 0.35 }

        // Waiting state
        Text {
            id: waitingLabel
            Layout.fillWidth: true
            text:           "Select a file to view its technical details…"
            color:          "#555"
            font.pixelSize: 16
            font.italic:    true
            horizontalAlignment: Text.AlignHCenter
            visible:        bodyArea.text === ""
        }

        // Header — filename / size / duration
        TextArea {
            id: headerArea
            Layout.fillWidth: true
            readOnly:    true
            wrapMode:    TextArea.Wrap
            color:       "#aaaaaa"
            font.pixelSize: 14
            font.family: "Consolas"
            background:  Rectangle { color: "transparent" }
            padding:     0
            implicitHeight: contentHeight
            visible:     text !== ""
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height:  1
            color:   "#333"
            visible: headerArea.text !== ""
        }

        // Body — scrollable details
        ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy:   ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            TextArea {
                id: bodyArea
                width:       parent.width
                readOnly:    true
                wrapMode:    TextArea.NoWrap
                color:       "white"
                font.pixelSize: 15
                font.family: "Consolas"
                background:  Rectangle { color: "transparent" }
                padding:     0
            }
        }

        // Status bar
        Text {
            id:             statusBar
            Layout.fillWidth: true
            color:          "#888"
            font.pixelSize: 13
            font.italic:    true
            elide:          Text.ElideRight
            visible:        text !== ""
        }
    }
}
