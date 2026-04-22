import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  WorkbenchView — FFmpeg test report panel  (Test File)
//
//  Centred modal panel over a static movie poster backdrop.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color green:     "#39FF14"
    readonly property color dimGreen:  "#162e08"
    readonly property color panelBg:   "#06101c"
    readonly property color borderCol: "#39FF14"
    readonly property color bodyBg:    "#080f18"
    readonly property color textMuted: "#7aaabb"

    property bool testing:   false
    property bool analysing: false

    // ── Outer glow ring ───────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  panel.width  + 10
        height: panel.height + 10
        radius: 20
        color:  "transparent"
        border.color: root.green
        border.width: 1
        opacity: 0.07
        z: 1
    }

    // ── Centred panel ─────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width:  parent.width  * 0.70
        height: parent.height * 0.84
        radius: 14
        color:  root.panelBg
        border.color: root.borderCol
        border.width: 2
        z: 2

        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }

        // ── Title bar ─────────────────────────────────────────────────────────
        Rectangle {
            id: titleBar
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 62
            color:  Qt.rgba(0, 0, 0, 0.28)
            radius: 14
            // extend bottom corners below clip so only top corners round
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: parent.radius
                color:  parent.color
            }

            Text {
                anchors.left:            parent.left
                anchors.leftMargin:      26
                anchors.verticalCenter:  parent.verticalCenter
                text: "TEST REPORT"
                font.family:        "Segoe UI"
                font.pixelSize:     26
                font.bold:          true
                font.letterSpacing: 4
                color: root.green
            }

            // Mode toggle: Standard / Thorough
            Row {
                id: modeToggle
                anchors.right:          parent.right
                anchors.rightMargin:    24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                property string mode: "standard"

                Rectangle {
                    width: 100; height: 30; radius: 4
                    color:        modeToggle.mode === "standard" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Standard"
                        font.pixelSize: 14; font.family: "Segoe UI"; font.bold: true
                        color: root.green
                    }
                    MouseArea { anchors.fill: parent; onClicked: modeToggle.mode = "standard" }
                }
                Rectangle {
                    width: 100; height: 30; radius: 4
                    color:        modeToggle.mode === "thorough" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Thorough"
                        font.pixelSize: 14; font.family: "Segoe UI"; font.bold: true
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
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 1; color: root.borderCol; opacity: 0.30
        }

        // ── Progress bar ──────────────────────────────────────────────────────
        Item {
            id: progressRow
            anchors.top:   divider.bottom; anchors.topMargin: 10
            anchors.left:  parent.left;    anchors.leftMargin:  24
            anchors.right: parent.right;   anchors.rightMargin: 24
            height: visible ? 32 : 0
            visible: root.testing

            ProgressBar {
                id: progressBar
                anchors.left:           parent.left
                anchors.right:          pctLabel.left
                anchors.rightMargin:    10
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                from: 0; to: 100; value: 0
                indeterminate: value === 0

                background: Rectangle {
                    color: "#0a1820"; radius: 4
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Item {
                    Rectangle {
                        visible: !progressBar.indeterminate
                        width:  progressBar.visualPosition * progressBar.width
                        height: parent.height; radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.dimGreen }
                            GradientStop { position: 1.0; color: root.green }
                        }
                    }
                    Rectangle {
                        id: pulseBar
                        visible: progressBar.indeterminate
                        width:  parent.width * 0.35
                        height: parent.height; radius: 4
                        color:  root.green; opacity: 0.85
                        SequentialAnimation on x {
                            running: pulseBar.visible; loops: Animation.Infinite
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
                font.pixelSize: 18; font.family: "Segoe UI"; font.bold: true
                color: root.green; width: 44
            }
        }

        // ── Header (file info) ────────────────────────────────────────────────
        TextArea {
            id: headerArea
            anchors.top:   progressRow.bottom; anchors.topMargin: 8
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            height:   visible ? contentHeight + 8 : 0
            readOnly: true; text: ""
            color:    "#aaccbb"
            font.family: "Consolas"; font.pixelSize: 18
            background: Rectangle { color: "transparent" }
            wrapMode:  TextArea.NoWrap
            visible:   text !== ""
        }

        // ── Action buttons (anchored to bottom) ───────────────────────────────
        Row {
            id: actionRow
            anchors.bottom:       parent.bottom; anchors.bottomMargin: 20
            anchors.left:         parent.left;   anchors.leftMargin:   24
            spacing: 14

            WorkbenchActionButton {
                label: "Save"
                accent: root.green
                enabled: bodyArea.text !== ""
                onActivated: {
                    var full = headerArea.text + "\n" + bodyArea.text
                    ffmpegBackend.saveReport(full)
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
                    var txt = bodyArea.text
                    var divPos = txt.indexOf("\u2500\u2500\u2500")
                    var errors = divPos >= 0 ? txt.substring(divPos + 46) : txt
                    ffmpegBackend.analyseReport(headerArea.text.split("\n")[0].replace("File:","").trim(), errors)
                }
            }

            WorkbenchActionButton {
                label: "Load Report"
                accent: "#AAAAAA"
                onActivated: ffmpegBackend.loadReport()
            }
        }

        // ── Body (scrollable output area) ─────────────────────────────────────
        Rectangle {
            anchors.top:          headerArea.bottom; anchors.topMargin:    10
            anchors.bottom:       actionRow.top;     anchors.bottomMargin: 12
            anchors.left:         parent.left;       anchors.leftMargin:   24
            anchors.right:        parent.right;      anchors.rightMargin:  24
            color:        root.bodyBg
            border.color: root.borderCol
            border.width: 1
            radius:       6
            clip:         true

            ScrollView {
                anchors.fill:    parent
                anchors.margins: 6
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextArea {
                    id: bodyArea
                    width:    parent.width
                    wrapMode: TextArea.Wrap
                    text:     ""
                    color:    root.green
                    font.family: "Consolas"; font.pixelSize: 20
                    background: Rectangle { color: "transparent" }
                    placeholderText: "Results will appear here…"
                    placeholderTextColor: "#1f4a18"
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
        }

        function onStatusMessage(msg) {
            console.log("Workbench status: " + msg)
            if (msg.indexOf("Running") !== -1) {
                root.testing      = true
                bodyArea.text     = ""
                headerArea.text   = ""
                progressBar.value = 0
            }
        }

        function onAnalysisDone(verdict, summary) {
            root.analysing = false
            var sep = "\n\n\u2500\u2500\u2500 Analysis \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n"
            if (verdict === "none") {
                bodyArea.text += sep + "\u2713 No significant issues found."
            } else {
                bodyArea.text += sep + summary
                if (verdict === "major" || verdict === "critical") {
                    bodyArea.text += "\n\n\u2500\u2500\u2500 AI Feedback \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\nAsking AI\u2026"
                }
            }
        }

        function onFfmpegMissing() { installDialog.open() }
        function onDownloadProgress(pct)    { dlProgress.value = pct }
        function onDownloadComplete()       { installDialog.close() }
        function onDownloadFailed(reason)   {
            dlErrorText.text    = "Download failed: " + reason
            dlProgress.visible  = false
            dlErrorText.visible = true
        }
    }

    // ── AI response ───────────────────────────────────────────────────────────
    Connections {
        target: aiController
        function onAnswerReady(answer) {
            var placeholder = "Asking AI\u2026"
            var pos = bodyArea.text.lastIndexOf(placeholder)
            if (pos >= 0)
                bodyArea.text = bodyArea.text.substring(0, pos) + answer
        }
    }

    // ── FFmpeg install dialog ─────────────────────────────────────────────────
    Rectangle {
        id: installDialog
        anchors.centerIn: parent
        width: 460; height: 220; radius: 12
        color: "#0a1520"; border.color: root.borderCol; border.width: 2
        visible: false; z: 500

        function open()  { visible = true  }
        function close() { visible = false }

        Column {
            anchors.centerIn: parent; spacing: 20; width: parent.width - 48

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "FFmpeg Not Found"
                font.pixelSize: 20; font.bold: true; color: root.green
            }
            Text {
                width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                text: "FFmpeg is required for Workbench features.\nWould you like to download it now?"
                font.pixelSize: 16; color: "#aaccbb"
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
            ProgressBar {
                id: dlProgress; width: parent.width; height: 22
                from: 0; to: 100; value: 0; visible: false
                background: Rectangle { color: "#0a1820"; radius: 4; border.color: root.borderCol; border.width: 1 }
                contentItem: Rectangle { width: dlProgress.visualPosition * dlProgress.width; height: parent.height; radius: 4; color: root.green }
            }
            Text {
                id: dlErrorText; visible: false; width: parent.width; text: ""
                color: "#FF5555"; font.pixelSize: 14; wrapMode: Text.WordWrap
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 16
                WorkbenchActionButton {
                    label: "Download"; accent: root.green
                    onActivated: { dlProgress.value = 0; dlProgress.visible = true; ffmpegBackend.downloadFFmpeg() }
                }
                WorkbenchActionButton { label: "Not Now"; accent: "#888888"; onActivated: installDialog.close() }
            }
        }
    }
}
