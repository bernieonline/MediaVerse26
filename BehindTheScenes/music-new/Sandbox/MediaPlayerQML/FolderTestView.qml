import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  FolderTestView — FFMPEG folder test panel
//
//  Loaded into the right 38% when the Test Folder button is clicked.
//  Shows per-file progress as each test completes, then a final summary.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    readonly property color green:     "#39FF14"
    readonly property color dimGreen:  "#1a4a0a"
    readonly property color panelBg:   "#0d1a08"
    readonly property color borderCol: "#39FF14"

    property bool running:   false   // true while folder test is in progress
    property bool done:      false   // true when folderTestComplete received
    property int  fileTotal: 0
    property int  fileCurrent: 0
    property string currentFileName: ""
    property string summaryText: ""

    // ── Report panel — right 38% ──────────────────────────────────────────────
    Rectangle {
        id: reportPanel
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        width: parent.width * 0.38

        color:        root.panelBg
        border.color: root.borderCol
        border.width: 1

        // Slide in when test starts
        property bool ready: false
        anchors.rightMargin: ready ? 0 : -width
        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        // ── Title bar ────────────────────────────────────────────────────────
        Item {
            id: titleBar
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.margins: 14
            height: 26

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "FOLDER TEST"
                font.family:        "Segoe UI"
                font.pixelSize:     15
                font.bold:          true
                font.letterSpacing: 2.5
                color: root.green
            }

            // Mode toggle: Standard / Thorough
            Row {
                id: modeToggle
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                property string mode: "standard"
                enabled: !root.running

                Rectangle {
                    width: 78; height: 22; radius: 4
                    color:        modeToggle.mode === "standard" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    opacity: modeToggle.enabled ? 1.0 : 0.4
                    Text {
                        anchors.centerIn: parent
                        text: "Standard"
                        font.pixelSize: 11; font.family: "Segoe UI"
                        color: root.green
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: modeToggle.enabled
                        onClicked: modeToggle.mode = "standard"
                    }
                }
                Rectangle {
                    width: 78; height: 22; radius: 4
                    color:        modeToggle.mode === "thorough" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    opacity: modeToggle.enabled ? 1.0 : 0.4
                    Text {
                        anchors.centerIn: parent
                        text: "Thorough"
                        font.pixelSize: 11; font.family: "Segoe UI"
                        color: root.green
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: modeToggle.enabled
                        onClicked: modeToggle.mode = "thorough"
                    }
                }
            }
        }

        // Divider
        Rectangle {
            id: divider
            anchors.top:   titleBar.bottom
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            height: 1; color: root.borderCol; opacity: 0.4
        }

        // ── Status line ──────────────────────────────────────────────────────
        Text {
            id: statusLine
            anchors.top:        divider.bottom; anchors.topMargin: 8
            anchors.left:       parent.left;    anchors.leftMargin:  14
            anchors.right:      parent.right;   anchors.rightMargin: 14
            height: 18
            text: {
                if (root.done)    return "Complete \u2014 see summary below"
                if (root.running) return "Testing " + root.fileCurrent + " / " + root.fileTotal + ":  " + root.currentFileName
                return "Select a folder to begin\u2026"
            }
            font.family:    "Segoe UI"
            font.pixelSize: 12
            color: root.done ? "#b0d4a0" : root.green
            elide: Text.ElideMiddle
        }

        // ── Overall progress bar ──────────────────────────────────────────────
        Item {
            id: progressRow
            anchors.top:   statusLine.bottom; anchors.topMargin: 6
            anchors.left:  parent.left;       anchors.leftMargin:  14
            anchors.right: parent.right;      anchors.rightMargin: 14
            height: 20
            visible: root.running || root.done

            ProgressBar {
                id: progressBar
                anchors.left:           parent.left
                anchors.right:          pctLabel.left
                anchors.rightMargin:    6
                anchors.verticalCenter: parent.verticalCenter
                height: 16
                from: 0; to: 100; value: 0

                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Item {
                    clip: true
                    // Filled portion — files completed so far
                    Rectangle {
                        id: fillBar
                        width:  progressBar.visualPosition * progressBar.width
                        height: parent.height; radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#1a4a0a" }
                            GradientStop { position: 1.0; color: root.green }
                        }
                    }
                    // Pulse strip — sweeps across the unfilled portion while a file is running
                    Rectangle {
                        id: pulseStrip
                        visible: root.running
                        x: fillBar.width - width / 2
                        width:  parent.width * 0.22
                        height: parent.height
                        radius: 3
                        color:  Qt.rgba(0.22, 1, 0.08, 0.55)

                        SequentialAnimation on x {
                            running: pulseStrip.visible
                            loops:   Animation.Infinite
                            NumberAnimation {
                                from:     fillBar.width - pulseStrip.width / 2
                                to:       progressBar.width
                                duration: 1100
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from:     progressBar.width
                                to:       fillBar.width - pulseStrip.width / 2
                                duration: 0
                            }
                        }
                    }
                }
            }

            Text {
                id: pctLabel
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                text:  Math.round(progressBar.value) + "%"
                font.pixelSize: 12; font.family: "Segoe UI"
                color: root.green; width: 34
            }
        }

        // ── Action buttons (anchored to bottom) ───────────────────────────────
        Row {
            id: actionRow
            anchors.bottom:       parent.bottom; anchors.bottomMargin: 14
            anchors.left:         parent.left;   anchors.leftMargin:   14
            spacing: 10

            // Save Summary — visible when done
            WorkbenchActionButton {
                label: "Save Summary"
                accent: root.green
                visible: root.done && root.summaryText !== ""
                onActivated: ffmpegBackend.saveFolderSummary(root.summaryText)
            }

            // New Test — visible when done
            WorkbenchActionButton {
                label: "New Test"
                accent: "#00BFFF"
                visible: root.done
                onActivated: {
                    root.running        = false
                    root.done           = false
                    root.fileTotal      = 0
                    root.fileCurrent    = 0
                    root.currentFileName = ""
                    root.summaryText    = ""
                    logArea.text        = ""
                    progressBar.value   = 0
                    reportPanel.ready   = false

                    // Start a fresh test immediately
                    ffmpegBackend.testFolder(modeToggle.mode)
                }
            }

            // Cancel — visible while running
            WorkbenchActionButton {
                label: "Cancel"
                accent: "#FF5555"
                visible: root.running
                onActivated: ffmpegBackend.cancelFolderTest()
            }
        }

        // ── Live log body (fills remaining space) ─────────────────────────────
        Rectangle {
            anchors.top:          progressRow.bottom; anchors.topMargin:    8
            anchors.bottom:       actionRow.top;      anchors.bottomMargin: 8
            anchors.left:         parent.left;        anchors.leftMargin:   14
            anchors.right:        parent.right;       anchors.rightMargin:  14
            color:        "#0a120a"
            border.color: root.borderCol
            border.width: 1
            radius:       3
            clip:         true

            ScrollView {
                id: logScroll
                anchors.fill:    parent
                anchors.margins: 4
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextArea {
                    id: logArea
                    width:    parent.width
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    text:     ""
                    color:    root.green
                    font.family:    "Courier New"
                    font.pixelSize: 11
                    background: Rectangle { color: "transparent" }
                    placeholderText: "Results will appear here as each file is tested\u2026"
                    placeholderTextColor: "#2a5a1a"
                }
            }
        }
    }

    // ── Backend signal connections ────────────────────────────────────────────
    Connections {
        target: ffmpegBackend

        function onFolderTestStarted(total) {
            root.fileTotal      = total
            root.fileCurrent    = 0
            root.currentFileName = ""
            root.running        = true
            root.done           = false
            root.summaryText    = ""
            logArea.text        = ""
            progressBar.value   = 0
            reportPanel.ready   = true
        }

        function onFolderTestFileStarted(filename, current, total) {
            root.fileCurrent     = current
            root.fileTotal       = total
            root.currentFileName = filename
        }

        function onFolderTestFileDone(filename, hadErrors) {
            var icon   = hadErrors ? "\u2717" : "\u2713"
            var status = hadErrors ? "errors" : "Clean"
            var num    = root.fileCurrent
            var total  = root.fileTotal
            var line   = "[" + num + "/" + total + "]  " + icon + "  " + filename + "  \u2014  " + status
            logArea.text += (logArea.text === "" ? "" : "\n") + line
            // Auto-scroll to bottom
            logScroll.ScrollBar.vertical.position = 1.0
        }

        function onFolderTestComplete(summary) {
            root.running      = false
            root.done         = true
            root.summaryText  = summary
            progressBar.value = 100
            if (summary === "") {
                logArea.text += "\n\n\u2500 Cancelled"
            } else {
                logArea.text += "\n\n" + summary
            }
            // Defer scroll until after layout recalculates for the new content
            Qt.callLater(function() {
                logArea.cursorPosition = logArea.length - 1
            })
        }

        function onProgressChanged(pct) {
            if (root.running) {
                progressBar.value = pct
            }
        }

        function onStatusMessage(msg) {
            // No-op — status displayed via folderTestFileStarted bindings
            console.log("FolderTest status: " + msg)
        }

        function onFfmpegMissing() {
            installDialog.open()
        }

        function onDownloadProgress(pct) {
            dlProgress.value = pct
        }

        function onDownloadComplete() {
            installDialog.close()
        }

        function onDownloadFailed(reason) {
            dlErrorText.text    = "Download failed: " + reason
            dlProgress.visible  = false
            dlErrorText.visible = true
        }
    }

    // ── FFmpeg install dialog (same as WorkbenchView) ─────────────────────────
    Rectangle {
        id: installDialog
        anchors.centerIn: parent
        width:  420
        height: 200
        radius: 10
        color:        "#111a0d"
        border.color: root.borderCol
        border.width: 2
        visible: false
        z: 500

        function open()  { visible = true  }
        function close() { visible = false }

        Column {
            anchors.centerIn: parent
            spacing: 18
            width: parent.width - 40

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  "FFmpeg Not Found"
                font.pixelSize: 16; font.bold: true
                color: root.green
            }

            Text {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                text:  "FFmpeg is required for Workbench features.\nWould you like to download it now?"
                font.pixelSize: 13
                color: "#b0d4a0"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            ProgressBar {
                id: dlProgress
                width:  parent.width
                height: 20
                from: 0; to: 100; value: 0
                visible: false

                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Rectangle {
                    width:  dlProgress.visualPosition * dlProgress.width
                    height: parent.height; radius: 3
                    color: root.green
                }
            }

            Text {
                id: dlErrorText
                visible: false
                width: parent.width
                text: ""
                color: "#FF5555"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                WorkbenchActionButton {
                    label: "Download"
                    accent: root.green
                    onActivated: {
                        dlProgress.value   = 0
                        dlProgress.visible = true
                        ffmpegBackend.downloadFFmpeg()
                    }
                }

                WorkbenchActionButton {
                    label: "Not Now"
                    accent: "#888888"
                    onActivated: installDialog.close()
                }
            }
        }
    }
}
