import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

// ─────────────────────────────────────────────────────────────────────────────
//  MM_Scan — Scan a folder into mediafiledetail (non-master collection)
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: scanRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Scan a folder tree and store\nall file records in the\nnon-master collection table.\n\n" +
        "Browse to a folder, give the\ncollection a name, then\npress Start Scan."

    readonly property color accent:  "#00BFFF"
    readonly property color bgPanel: "#0d1117"
    readonly property color bgDark:  "#080d14"

    // ── State ─────────────────────────────────────────────────────────────────
    property bool scanning:    false
    property int  filesCurrent: 0
    property int  filesTotal:   0

    // ── Folder browser ────────────────────────────────────────────────────────
    FolderDialog {
        id: folderDialog
        title: "Select folder to scan"
        onAccepted: {
            var raw = selectedFolder.toString()
            // Strip file:/// prefix on Windows → backslash path
            raw = raw.replace(/^file:\/\/\//, "").replace(/\//g, "\\")
            folderField.text = raw
        }
    }

    // ── Duplicate warning popup ───────────────────────────────────────────────
    Popup {
        id: dupePopup
        anchors.centerIn: parent
        width: 460; height: 200
        modal: true
        closePolicy: Popup.NoAutoClose
        z: 100

        background: Rectangle {
            color: "#0d1420"; radius: 12
            border.color: "#FFB300"; border.width: 2
        }

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 48

            Text {
                width: parent.width
                text: "⚠  Duplicate Collection"
                color: "#FFB300"; font.pixelSize: 18; font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: parent.width
                text: "A collection with this path already exists in the database.\nContinue anyway or abort?"
                color: "#CCCCCC"; font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    width: 120; height: 36; radius: 6
                    color: contMa.containsMouse ? "#553300" : "#3a2200"
                    border.color: "#FFB300"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "Continue"; color: "#FFB300"; font.pixelSize: 14 }
                    MouseArea {
                        id: contMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            dupePopup.close()
                            scanRoot.scanning = true
                            logModel.clear()
                            progressBar.value = 0
                            logModel.append({ line: "Continuing scan (duplicate confirmed): " + folderField.text })
                            mediaManagerBackend.start_scan_confirmed(folderField.text)
                        }
                    }
                }
                Rectangle {
                    width: 120; height: 36; radius: 6
                    color: abortMa.containsMouse ? "#330000" : "#200000"
                    border.color: "#FF5555"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "Abort"; color: "#FF5555"; font.pixelSize: 14 }
                    MouseArea {
                        id: abortMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: dupePopup.close()
                    }
                }
            }
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
            // Keep log scrolled to bottom
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
            if (msg.startsWith("DUPLICATE:")) {
                // Stop scanning state — user must choose continue or abort
                scanRoot.scanning = false
                dupePopup.open()
            } else {
                scanRoot.scanning = false
                logModel.append({ line: "✗ Error: " + msg })
                logView.positionViewAtEnd()
            }
        }
    }

    // ── Log model ─────────────────────────────────────────────────────────────
    ListModel { id: logModel }

    // ── Helper: kick off the actual scan ─────────────────────────────────────
    function doStartScan() {
        logModel.clear()
        progressBar.value = 0
        scanRoot.filesCurrent = 0
        scanRoot.filesTotal   = 0
        scanRoot.scanning = true
        logModel.append({ line: "Starting scan: " + folderField.text })
        mediaManagerBackend.start_scan(folderField.text)
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ── Section title ─────────────────────────────────────────────────────
        Text {
            text: "Scan Location → mediafiledetail"
            color: scanRoot.accent
            font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.25) }

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
                placeholderText: "e.g. T:\\Music\\FLAC"
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

        // Collection name is auto-generated by Python: device:drive:/subfolder:YYYY-MM-DD HH:MM:SS

        // ── Progress bar ──────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 5

            Row {
                width: parent.width

                Text {
                    text: scanRoot.scanning
                          ? (scanRoot.filesCurrent + " / " + (scanRoot.filesTotal > 0 ? scanRoot.filesTotal : "?") + " files")
                          : (scanRoot.filesTotal > 0 ? "Done — " + scanRoot.filesTotal + " files" : "")
                    color: "#888888"; font.pixelSize: 13
                }
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

                    // Shimmer overlay
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
                    onClicked: {
                        // Check for duplicates first via a quick status check
                        // The backend will emit statusMessage if duplicate found
                        doStartScan()
                    }
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
        }

        // ── Scan log ──────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: scanRoot.height - y - 20   // fill remaining space
            color: scanRoot.bgDark
            border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1
            radius: 4
            clip: true

            // Header
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
                        font.bold: true; font.letterSpacing: 1.5
                        opacity: 0.75
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: logModel.count > 0 ? "(" + logModel.count + " lines)" : ""
                        color: "#445566"; font.pixelSize: 11
                    }

                    // Clear button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44; height: 18; radius: 3
                        color: clrMa.containsMouse ? "#221100" : "transparent"
                        border.color: "#445566"; border.width: 1
                        Text {
                            anchors.centerIn: parent; text: "Clear"
                            color: "#667788"; font.pixelSize: 11
                        }
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
