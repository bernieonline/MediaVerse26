import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  MediaManagerView — Physical Collection Management module outer shell
//
//  Layout:
//    ┌──────────────────────────────────────────────────────────┐
//    │  HEADER: DB status | start time                          │  h:50
//    ├─────────────┬────────────────────────────┬───────────────┤
//    │  TODO LIST  │   CENTRAL CONTENT LOADER   │  HELP PANEL   │
//    │  w:200      │   (MM_* sub-views)         │  w:220        │
//    ├─────────────┴────────────────────────────┴───────────────┤
//    │  FOOTER: statusMessage                   | thread info   │  h:36
//    └──────────────────────────────────────────────────────────┘
//
//  Central Loader source is swapped by CollectButtons signals wired in
//  Framework-1.qml.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: mmRoot
    anchors.fill: parent

    readonly property color accent:    "#00BFFF"
    readonly property color bgDark:    "#0d1117"
    readonly property color bgMid:     "#161b22"
    readonly property color borderCol: "#00BFFF"

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: mmRoot.bgDark
    }

    // ── Header ────────────────────────────────────────────────────────────────
    Rectangle {
        id: header
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: 50
        color: mmRoot.bgMid
        border.color: Qt.rgba(0, 0.75, 1.0, 0.25)
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin:  16
            anchors.rightMargin: 16
            spacing: 24

            // Module title
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Physical Collection Manager"
                color: mmRoot.accent
                font.family: "Segoe UI"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 1.5
            }

            // Separator
            Rectangle {
                width: 1; height: 30
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(1,1,1,0.15)
            }

            // DB connection indicator
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Rectangle {
                    id: dbIndicator
                    width: 10; height: 10; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#555555"

                    Connections {
                        target: mediaManagerBackend
                        function onDbConnected(ok) {
                            dbIndicator.color = ok ? "#00FF7F" : "#FF5555"
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "MediaManager2"
                    color: "#888888"
                    font.pixelSize: 14
                }
            }

            Item { Layout.fillWidth: true; width: 1 }

            // Start time
            Text {
                id: startTimeLabel
                anchors.verticalCenter: parent.verticalCenter
                property var t: new Date()
                text: Qt.formatDateTime(t, "hh:mm  dd MMM yyyy")
                color: "#666666"
                font.pixelSize: 13
            }
        }
    }

    // ── Body ─────────────────────────────────────────────────────────────────
    Item {
        id: body
        anchors.top:    header.bottom
        anchors.bottom: footer.top
        anchors.left:   parent.left
        anchors.right:  parent.right

        // ── Left: TODO panel ─────────────────────────────────────────────────
        Rectangle {
            id: todoPanel
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            width: 200
            color: mmRoot.bgMid
            border.color: Qt.rgba(0, 0.75, 1.0, 0.15)
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0

                Text {
                    width: parent.width
                    text: "TO-DO"
                    color: mmRoot.accent
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
                    horizontalAlignment: Text.AlignHCenter
                    bottomPadding: 8
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.2) }

                ListView {
                    id: todoList
                    width: parent.width
                    height: todoPanel.height - 40
                    clip: true
                    model: [
                        "Test DB connection",
                        "Configure media types",
                        "Add excluded folders",
                        "Scan first location",
                        "Run initial report"
                    ]
                    delegate: Item {
                        width: todoList.width
                        height: 34
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 8
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: mmRoot.accent; opacity: 0.6
                            }
                            Text {
                                width: parent.width - 22
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                color: "#AAAAAA"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        // ── Right: Help panel ─────────────────────────────────────────────────
        Rectangle {
            id: helpPanel
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.right:  parent.right
            width: 220
            color: mmRoot.bgMid
            border.color: Qt.rgba(0, 0.75, 1.0, 0.15)
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    width: parent.width
                    text: "HELP"
                    color: mmRoot.accent
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.2) }

                Text {
                    id: helpText
                    width: parent.width
                    text: mmContent.helpHint
                    color: "#BBBBBB"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    topPadding: 8
                }
            }
        }

        // ── Centre: content Loader ────────────────────────────────────────────
        Item {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.left:   todoPanel.right
            anchors.right:  helpPanel.left

            Loader {
                id: mmContent
                anchors.fill: parent

                property string helpHint: "Select a function from the\nbutton bar above."

                // Default placeholder
                sourceComponent: placeholderComp

                onLoaded: {
                    if (mmContent.item && mmContent.item.helpHint !== undefined)
                        mmContent.helpHint = mmContent.item.helpHint
                    else
                        mmContent.helpHint = "Select a function from the\nbutton bar above."
                }
            }
        }
    }

    // ── Footer ────────────────────────────────────────────────────────────────
    Rectangle {
        id: footer
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: 36
        color: mmRoot.bgMid
        border.color: Qt.rgba(0, 0.75, 1.0, 0.20)
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin:  16
            anchors.rightMargin: 16

            Text {
                id: statusLabel
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 160
                text: "Ready."
                color: "#AAAAAA"
                font.pixelSize: 14
                elide: Text.ElideRight

                Connections {
                    target: mediaManagerBackend
                    function onStatusMessage(msg) { statusLabel.text = msg }
                }
            }

            Item { width: 1; Layout.fillWidth: true }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "MediaManager2 · v1"
                color: "#444444"
                font.pixelSize: 12
            }
        }
    }

    // ── Placeholder component (shown before any button pressed) ──────────────
    Component {
        id: placeholderComp
        Item {
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uD83D\uDDC4"   // 🗄 filing cabinet
                    font.pixelSize: 64
                    color: Qt.rgba(0, 0.75, 1.0, 0.25)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Physical Collection Manager"
                    color: Qt.rgba(0, 0.75, 1.0, 0.45)
                    font.pixelSize: 22
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Select a function from the button bar above"
                    color: "#555555"
                    font.pixelSize: 16
                }

                // DB test button
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 220; height: 44; radius: 8
                    color: dbTestMa.pressed ? "#003355" : (dbTestMa.containsMouse ? "#004477" : "#002244")
                    border.color: "#00BFFF"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Test DB Connection"
                        color: "#00BFFF"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    MouseArea {
                        id: dbTestMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: mediaManagerBackend.test_connection()
                    }
                }
            }
        }
    }

    // ── Expose mmContent loader so Framework-1.qml can swap its source ────────
    function loadPanel(source) {
        mmContent.source = source
    }
}
