import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  WorkbenchView — FFMPEG test report panel
//
//  Loaded into the RIGHT third of the display area when a test runs.
//  Left two-thirds stay available for splash / landing content.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    readonly property color green:     "#39FF14"
    readonly property color dimGreen:  "#1a4a0a"
    readonly property color panelBg:   "#0d1a08"
    readonly property color borderCol: "#39FF14"

    // true while ffmpeg is running; false when report received or idle
    property bool testing:   false
    property bool analysing: false

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

        // Slide in from right — visible as soon as testing starts
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
                text: "TEST REPORT"
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

                Rectangle {
                    width: 78; height: 22; radius: 4
                    color:        modeToggle.mode === "standard" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Standard"
                        font.pixelSize: 11; font.family: "Segoe UI"
                        color: root.green
                    }
                    MouseArea { anchors.fill: parent; onClicked: modeToggle.mode = "standard" }
                }
                Rectangle {
                    width: 78; height: 22; radius: 4
                    color:        modeToggle.mode === "thorough" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Thorough"
                        font.pixelSize: 11; font.family: "Segoe UI"
                        color: root.green
                    }
                    MouseArea { anchors.fill: parent; onClicked: modeToggle.mode = "thorough" }
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

        // ── Progress bar (visible while testing) ─────────────────────────────
        Item {
            id: progressRow
            anchors.top:   divider.bottom; anchors.topMargin: 6
            anchors.left:  parent.left;    anchors.leftMargin:  14
            anchors.right: parent.right;   anchors.rightMargin: 14
            height: visible ? 26 : 0
            visible: root.testing

            ProgressBar {
                id: progressBar
                anchors.left:           parent.left
                anchors.right:          pctLabel.left
                anchors.rightMargin:    6
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                from: 0; to: 100; value: 0
                // indeterminate when we have no duration info (value stays 0)
                indeterminate: value === 0

                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Item {
                    // real fill bar
                    Rectangle {
                        visible: !progressBar.indeterminate
                        width:  progressBar.visualPosition * progressBar.width
                        height: parent.height; radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#1a4a0a" }
                            GradientStop { position: 1.0; color: root.green }
                        }
                    }
                    // pulsing bar for indeterminate
                    Rectangle {
                        id: pulseBar
                        visible: progressBar.indeterminate
                        width:  parent.width * 0.35
                        height: parent.height; radius: 3
                        color:  root.green; opacity: 0.85

                        SequentialAnimation on x {
                            running: pulseBar.visible
                            loops:   Animation.Infinite
                            NumberAnimation { from: -pulseBar.width; to: progressBar.width; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            Text {
                id: pctLabel
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                text:  progressBar.indeterminate ? "…" : (progressBar.value + "%")
                font.pixelSize: 12; font.family: "Segoe UI"
                color: root.green; width: 34
            }
        }

        // ── Header (read-only) ────────────────────────────────────────────────
        TextArea {
            id: headerArea
            anchors.top:   progressRow.bottom; anchors.topMargin: 6
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            height:   visible ? contentHeight + 8 : 0
            readOnly: true
            text:     ""
            color:    "#b0d4a0"
            font.family:    "Courier New"
            font.pixelSize: 12
            background: Rectangle { color: "transparent" }
            wrapMode: TextArea.NoWrap
            visible:  text !== ""
        }

        // ── Action buttons (anchored to bottom) ───────────────────────────────
        Row {
            id: actionRow
            anchors.bottom:       parent.bottom; anchors.bottomMargin: 14
            anchors.left:         parent.left;   anchors.leftMargin:   14
            spacing: 10

            WorkbenchActionButton {
                label: "Save"
                accent: root.green
                enabled: bodyArea.text !== ""
                onActivated: {
                    var full = headerArea.text + "\n" + bodyArea.text
                    ffmpegBackend.saveReport(full)
                    reportPanel.ready = false
                    headerArea.text   = ""
                    bodyArea.text     = ""
                    progressBar.value = 0
                }
            }

            WorkbenchActionButton {
                id: analyseBtn
                label: "Analyse"
                accent: "#00BFFF"
                enabled: bodyArea.text !== "" && !root.analysing
                onActivated: {
                    root.analysing = true
                    // extract just the body errors (below the header divider)
                    var txt = bodyArea.text
                    var divPos = txt.indexOf("\u2500\u2500\u2500")
                    var errors = divPos >= 0 ? txt.substring(divPos + 46) : txt
                    ffmpegBackend.analyseReport(headerArea.text.split("\n")[0].replace("File:","").trim(), errors)
                }
            }
        }

        // ── Body (editable — fills remaining space) ───────────────────────────
        Rectangle {
            anchors.top:          headerArea.bottom; anchors.topMargin:    8
            anchors.bottom:       actionRow.top;     anchors.bottomMargin: 8
            anchors.left:         parent.left;       anchors.leftMargin:   14
            anchors.right:        parent.right;      anchors.rightMargin:  14
            color:        "#0a120a"
            border.color: root.borderCol
            border.width: 1
            radius:       3
            clip:         true

            ScrollView {
                anchors.fill:    parent
                anchors.margins: 4
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextArea {
                    id: bodyArea
                    width:    parent.width
                    wrapMode: TextArea.Wrap
                    text:     ""
                    color:    root.green
                    font.family:    "Courier New"
                    font.pixelSize: 12
                    background: Rectangle { color: "transparent" }
                    placeholderText: "Results will appear here…"
                    placeholderTextColor: "#2a5a1a"
                }
            }
        }
    }

    // ── Backend signal connections ────────────────────────────────────────────
    Connections {
        target: ffmpegBackend

        function onProgressChanged(pct) {
            progressBar.value = pct
        }

        function onReportReady(header, body) {
            headerArea.text   = header
            bodyArea.text     = body
            progressBar.value = 100
            root.testing      = false
            reportPanel.ready = true
        }

        function onStatusMessage(msg) {
            console.log("Workbench status: " + msg)
            // Open the panel and start pulsing as soon as the test begins
            if (msg.indexOf("Running") !== -1) {
                root.testing      = true
                reportPanel.ready = true
                bodyArea.text     = ""
                headerArea.text   = ""
                progressBar.value = 0
            }
        }

        function onAnalysisDone(verdict, summary) {
            root.analysing = false
            var divider = "\n\n\u2500\u2500\u2500 Analysis \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n"
            if (verdict === "none") {
                bodyArea.text += divider + "\u2713 No significant issues found."
            } else {
                bodyArea.text += divider + summary
                // AI feedback will follow automatically for major/critical
                if (verdict === "major" || verdict === "critical") {
                    bodyArea.text += "\n\n\u2500\u2500\u2500 AI Feedback \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\nAsking AI\u2026"
                }
            }
        }

        // ffmpeg not installed — show install dialog
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
            dlErrorText.text = "Download failed: " + reason
            dlProgress.visible = false
            dlErrorText.visible = true
        }
    }

    // ── AI response — replace "Asking AI…" placeholder with real answer ───────
    Connections {
        target: aiController
        function onAnswerReady(answer) {
            var placeholder = "Asking AI\u2026"
            var pos = bodyArea.text.lastIndexOf(placeholder)
            if (pos >= 0) {
                bodyArea.text = bodyArea.text.substring(0, pos) + answer
            }
        }
    }

    // ── FFmpeg install dialog ─────────────────────────────────────────────────
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
                    height: parent.height
                    radius: 3
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
