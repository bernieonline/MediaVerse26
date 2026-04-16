import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

// ─────────────────────────────────────────────────────────────────────────────
//  MM_ScanMaster — Scan a folder into masterfiledetail (master collection)
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: scanRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Scan a folder tree and store\nall file records in the\nmaster collection table.\n\n" +
        "Choose Media Type and\nCollection Type, browse to\na folder, then press Start."

    readonly property color accent:  "#00BFFF"
    readonly property color bgDark:  "#080d14"

    // ── State ─────────────────────────────────────────────────────────────────
    property bool scanning:     false
    property int  filesCurrent: 0
    property int  filesTotal:   0

    // ── Folder browser ────────────────────────────────────────────────────────
    FolderDialog {
        id: folderDialog
        title: "Select master folder to scan"
        onAccepted: {
            var raw = selectedFolder.toString()
            raw = raw.replace(/^file:\/\/\//, "").replace(/\//g, "\\")
            folderField.text = raw
        }
    }

    // ── Backend connections ───────────────────────────────────────────────────
    Connections {
        target: mediaManagerBackend

        function onScanProgress(current, total, currentFile) {
            scanRoot.filesCurrent = current
            scanRoot.filesTotal   = total
            if (total > 0) progressBar.value = current / total
            if (currentFile !== "")
                logModel.append({ line: current + "  " + currentFile })
            if (logModel.count > 0)
                logView.positionViewAtEnd()
        }

        function onScanComplete(collectionName, recordCount) {
            scanRoot.scanning = false
            progressBar.value = 1.0
            logModel.append({ line: "✓ Complete — " + recordCount + " files in '" + collectionName + "'" })
            logView.positionViewAtEnd()
        }

        function onScanError(msg) {
            scanRoot.scanning = false
            logModel.append({ line: "✗ Error: " + msg })
            logView.positionViewAtEnd()
        }
    }

    // ── Log model ─────────────────────────────────────────────────────────────
    ListModel { id: logModel }

    // ── Helper ────────────────────────────────────────────────────────────────
    function doStartScan() {
        logModel.clear()
        progressBar.value = 0
        scanRoot.filesCurrent = 0
        scanRoot.filesTotal   = 0
        scanRoot.scanning = true
        var mt = mediaTypeBox.currentText
        var ct = collTypeBox.currentText
        logModel.append({ line: "Starting master scan [" + ct + " / " + mt + "]: " + folderField.text })
        mediaManagerBackend.start_master_scan(folderField.text, mt, ct)
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ── Section title ─────────────────────────────────────────────────────
        Text {
            text: "Scan Master Location → masterfiledetail"
            color: scanRoot.accent
            font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.25) }

        // ── Media Type + Collection Type row ──────────────────────────────────
        Row {
            width: parent.width; spacing: 20

            // Media Type
            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Media Type"; color: scanRoot.accent
                    font.pixelSize: 14; font.bold: true; opacity: 0.80
                }
                ComboBox {
                    id: mediaTypeBox
                    width: 140; height: 34
                    model: ["Video", "Music", "Images"]
                    font.pixelSize: 14
                    contentItem: Text {
                        leftPadding: 10
                        text: mediaTypeBox.displayText
                        color: "white"; font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: mediaTypeBox.pressed ? "#003344" : "#0a1a2a"
                        border.color: mediaTypeBox.activeFocus ? scanRoot.accent : "#1e3050"
                        border.width: mediaTypeBox.activeFocus ? 2 : 1; radius: 5
                    }
                    popup: Popup {
                        y: mediaTypeBox.height
                        width: mediaTypeBox.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 1
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: mediaTypeBox.popup.visible ? mediaTypeBox.delegateModel : null
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                        background: Rectangle {
                            color: "#0a1a2a"; border.color: scanRoot.accent
                            border.width: 1; radius: 4
                        }
                    }
                    delegate: ItemDelegate {
                        width: mediaTypeBox.width
                        contentItem: Text {
                            text: modelData; color: "white"; font.pixelSize: 13
                            leftPadding: 10; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: highlighted ? "#003355" : "transparent"
                        }
                        highlighted: mediaTypeBox.highlightedIndex === index
                    }
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 34; color: Qt.rgba(0,0.75,1,0.20)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Collection Type
            Row {
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Collection Type"; color: scanRoot.accent
                    font.pixelSize: 14; font.bold: true; opacity: 0.80
                }
                ComboBox {
                    id: collTypeBox
                    width: 150; height: 34
                    model: ["Master", "Secondary", "Clone"]
                    font.pixelSize: 14
                    contentItem: Text {
                        leftPadding: 10
                        text: collTypeBox.displayText
                        color: "white"; font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: collTypeBox.pressed ? "#003344" : "#0a1a2a"
                        border.color: collTypeBox.activeFocus ? scanRoot.accent : "#1e3050"
                        border.width: collTypeBox.activeFocus ? 2 : 1; radius: 5
                    }
                    popup: Popup {
                        y: collTypeBox.height
                        width: collTypeBox.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 1
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: collTypeBox.popup.visible ? collTypeBox.delegateModel : null
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                        background: Rectangle {
                            color: "#0a1a2a"; border.color: scanRoot.accent
                            border.width: 1; radius: 4
                        }
                    }
                    delegate: ItemDelegate {
                        width: collTypeBox.width
                        contentItem: Text {
                            text: modelData; color: "white"; font.pixelSize: 13
                            leftPadding: 10; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: highlighted ? "#003355" : "transparent"
                        }
                        highlighted: collTypeBox.highlightedIndex === index
                    }
                }
            }
        }

        // ── Folder path row ───────────────────────────────────────────────────
        Row {
            width: parent.width; spacing: 8

            Text {
                width: 80; anchors.verticalCenter: parent.verticalCenter
                text: "Folder"; color: scanRoot.accent
                font.pixelSize: 14; font.bold: true; opacity: 0.80
                horizontalAlignment: Text.AlignRight
            }

            TextField {
                id: folderField
                width: parent.width - 80 - 100 - 16
                height: 34
                placeholderText: "e.g. W:\\Collection"
                font.pixelSize: 14; color: "white"
                background: Rectangle {
                    color: "#111c2e"
                    border.color: folderField.activeFocus ? scanRoot.accent : "#1e3050"
                    border.width: folderField.activeFocus ? 2 : 1; radius: 5
                }
            }

            Rectangle {
                width: 92; height: 34; radius: 5
                color: browseMa.pressed ? "#003355" : (browseMa.containsMouse ? "#005577" : "#004466")
                border.color: scanRoot.accent; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "Browse…"; color: scanRoot.accent; font.pixelSize: 13 }
                MouseArea {
                    id: browseMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: folderDialog.open()
                }
            }
        }

        // ── Collection name note ───────────────────────────────────────────────
        Text {
            text: "Collection name auto-generated: device:drive:/subfolder:YYYY-MM-DD HH:MM:SS"
            color: "#445566"; font.pixelSize: 12; font.italic: true
            leftPadding: 88
        }

        // ── Progress bar ──────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 5

            Text {
                text: scanRoot.scanning
                      ? (scanRoot.filesCurrent + " / " + (scanRoot.filesTotal > 0 ? scanRoot.filesTotal : "?") + " files")
                      : (scanRoot.filesTotal > 0 ? "Done — " + scanRoot.filesTotal + " files" : "")
                color: "#888888"; font.pixelSize: 13
            }

            Rectangle {
                width: parent.width; height: 10; radius: 5
                color: "#111827"
                border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1

                Rectangle {
                    id: progressBar
                    property real value: 0.0
                    width: parent.width * value
                    height: parent.height
                    radius: parent.radius
                    color: scanRoot.accent
                    Behavior on width { NumberAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.0)  }
                            GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.18) }
                            GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.0)  }
                        }
                        visible: scanRoot.scanning
                    }
                }
            }
        }

        // ── Start / Cancel buttons ────────────────────────────────────────────
        Row {
            spacing: 12

            Rectangle {
                width: 140; height: 38; radius: 6
                enabled: !scanRoot.scanning && folderField.text.trim() !== ""
                opacity: enabled ? 1.0 : 0.4
                color: startMa.pressed ? "#003344" : (startMa.containsMouse ? "#005566" : "#004455")
                border.color: scanRoot.accent; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "▶  Start Scan"
                    color: scanRoot.accent; font.pixelSize: 14; font.bold: true
                }
                MouseArea {
                    id: startMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: doStartScan()
                }
            }

            Rectangle {
                width: 110; height: 38; radius: 6
                enabled: scanRoot.scanning
                opacity: enabled ? 1.0 : 0.35
                color: cancelMa.pressed ? "#330000" : (cancelMa.containsMouse ? "#550000" : "#3a0000")
                border.color: "#FF5555"; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "■  Cancel"
                    color: "#FF5555"; font.pixelSize: 14; font.bold: true
                }
                MouseArea {
                    id: cancelMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: mediaManagerBackend.cancel_scan()
                }
            }

            // Type badge — shows current selection as a confirmation label
            Rectangle {
                height: 38; radius: 6
                width: badgeText.implicitWidth + 24
                anchors.verticalCenter: parent.verticalCenter
                color: "#050f1a"
                border.color: Qt.rgba(0,0.75,1,0.25); border.width: 1
                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: collTypeBox.currentText + "  ·  " + mediaTypeBox.currentText
                    color: "#667788"; font.pixelSize: 13
                }
            }
        }

        // ── Scan log ──────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: scanRoot.height - y - 20
            color: scanRoot.bgDark
            border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1
            radius: 4
            clip: true

            Rectangle {
                id: logHeader
                width: parent.width; height: 26
                color: "#060d18"
                border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1

                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Scan Log"
                        color: scanRoot.accent; font.pixelSize: 12
                        font.bold: true; font.letterSpacing: 1.5; opacity: 0.75
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: logModel.count > 0 ? "(" + logModel.count + " lines)" : ""
                        color: "#445566"; font.pixelSize: 11
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44; height: 18; radius: 3
                        color: clrMa.containsMouse ? "#221100" : "transparent"
                        border.color: "#445566"; border.width: 1
                        Text { anchors.centerIn: parent; text: "Clear"; color: "#667788"; font.pixelSize: 11 }
                        MouseArea {
                            id: clrMa; anchors.fill: parent; hoverEnabled: true
                            onClicked: logModel.clear()
                        }
                    }
                }
            }

            ListView {
                id: logView
                anchors.top: logHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                clip: true
                model: logModel

                delegate: Text {
                    width: logView.width
                    text: model.line
                    color: model.line.startsWith("✓") ? "#00FF7F"
                         : model.line.startsWith("✗") ? "#FF5555"
                         : model.line.startsWith("Starting") ? scanRoot.accent
                         : "#778899"
                    font.pixelSize: 12
                    font.family: "Consolas"
                    elide: Text.ElideMiddle
                    leftPadding: 6
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }
        }
    }
}
