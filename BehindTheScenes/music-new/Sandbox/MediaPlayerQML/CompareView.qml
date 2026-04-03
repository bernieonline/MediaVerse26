import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  CompareView — VMAF file comparison panel
//
//  Loaded into the display area when Compare Files is clicked.
//  Picks two files via dialog (Python side), runs ffmpeg libvmaf, and
//  displays the score with colour coding plus the raw ffmpeg output.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    readonly property color green:     "#39FF14"
    readonly property color panelBg:   "#0d1a08"
    readonly property color borderCol: "#39FF14"

    property bool comparing: false
    property real scoreA:   -1
    property real scoreB:   -1

    function scoreColor(s) {
        if (s >= 80) return "#39FF14"
        if (s >= 60) return "#FFB300"
        if (s >= 40) return "#FF6600"
        return "#FF3333"
    }

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

        property bool ready: false
        anchors.rightMargin: ready ? 0 : -width
        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        // ── Title bar ────────────────────────────────────────────────────────
        Item {
            id: titleBar
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.margins: 14
            height: 26

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "FILE COMPARE"
                font.family:        "Segoe UI"
                font.pixelSize:     15
                font.bold:          true
                font.letterSpacing: 2.5
                color: root.green
            }

            // ── Info button ──────────────────────────────────────────────────
            Rectangle {
                id: infoBtn
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 22; height: 22; radius: 11
                color:        infoMa.containsMouse ? Qt.rgba(0.22, 1, 0.08, 0.18) : "transparent"
                border.color: root.green
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "i"
                    font.family:    "Segoe UI"
                    font.pixelSize: 13
                    font.italic:    true
                    font.bold:      true
                    color: root.green
                }

                MouseArea {
                    id: infoMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: infoOverlay.visible = !infoOverlay.visible
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Rectangle {
            id: divider
            anchors.top:   titleBar.bottom
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            height: 1; color: root.borderCol; opacity: 0.4
        }

        // ── Pulsing bar (visible while comparing) ─────────────────────────────
        Item {
            id: progressRow
            anchors.top:   divider.bottom; anchors.topMargin: 6
            anchors.left:  parent.left;    anchors.leftMargin:  14
            anchors.right: parent.right;   anchors.rightMargin: 14
            height: visible ? 26 : 0
            visible: root.comparing

            ProgressBar {
                id: progressBar
                anchors.fill: parent
                from: 0; to: 100; value: 0

                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Item {
                    Rectangle {
                        id: pulseBar
                        width:  parent.width * 0.35
                        height: parent.height; radius: 3
                        color:  root.green; opacity: 0.85
                        SequentialAnimation on x {
                            running: root.comparing
                            loops:   Animation.Infinite
                            NumberAnimation {
                                from: -pulseBar.width; to: progressBar.width
                                duration: 1200; easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        // ── Header (file names + score line) ─────────────────────────────────
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
            wrapMode:  TextArea.Wrap
            visible:   text !== ""
        }

        // ── Dual score display ───────────────────────────────────────────────
        Item {
            id: scoreDisplay
            anchors.top:   headerArea.bottom; anchors.topMargin: 12
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            height: visible ? 72 : 0
            visible: root.scoreA >= 0 && root.scoreB >= 0

            Row {
                anchors.fill: parent
                spacing: 6

                // ── File A score ─────────────────────────────────────────────
                Rectangle {
                    width:  (parent.width - 6) / 2
                    height: parent.height
                    color:  Qt.rgba(0, 0, 0, 0.35)
                    radius: 6
                    border.color: root.scoreColor(root.scoreA)
                    border.width: root.scoreA >= root.scoreB ? 2 : 1
                    opacity:      root.scoreA >= root.scoreB ? 1.0 : 0.65

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "FILE A"
                            font.family: "Segoe UI"; font.pixelSize: 10
                            font.letterSpacing: 1.5
                            color: "#808080"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreA >= 0 ? root.scoreA.toFixed(1) : ""
                            font.family: "Segoe UI"; font.pixelSize: 30
                            font.bold: true
                            color: root.scoreColor(root.scoreA)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreA > root.scoreB ? "▲ WINNER" : (root.scoreA === root.scoreB ? "EQUAL" : "")
                            font.family: "Segoe UI"; font.pixelSize: 10
                            font.bold: true
                            color: root.scoreColor(root.scoreA)
                            visible: text !== ""
                        }
                    }
                }

                // ── File B score ─────────────────────────────────────────────
                Rectangle {
                    width:  (parent.width - 6) / 2
                    height: parent.height
                    color:  Qt.rgba(0, 0, 0, 0.35)
                    radius: 6
                    border.color: root.scoreColor(root.scoreB)
                    border.width: root.scoreB >= root.scoreA ? 2 : 1
                    opacity:      root.scoreB >= root.scoreA ? 1.0 : 0.65

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "FILE B"
                            font.family: "Segoe UI"; font.pixelSize: 10
                            font.letterSpacing: 1.5
                            color: "#808080"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreB >= 0 ? root.scoreB.toFixed(1) : ""
                            font.family: "Segoe UI"; font.pixelSize: 30
                            font.bold: true
                            color: root.scoreColor(root.scoreB)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreB > root.scoreA ? "▲ WINNER" : (root.scoreB === root.scoreA ? "EQUAL" : "")
                            font.family: "Segoe UI"; font.pixelSize: 10
                            font.bold: true
                            color: root.scoreColor(root.scoreB)
                            visible: text !== ""
                        }
                    }
                }
            }
        }

        // ── Action buttons ────────────────────────────────────────────────────
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
                    ffmpegBackend.saveReport(headerArea.text + "\n" + bodyArea.text)
                    reportPanel.ready = false
                    headerArea.text   = ""
                    bodyArea.text     = ""
                    root.scoreA       = -1
                    root.scoreB       = -1
                }
            }

        }

        // ── Raw output area ───────────────────────────────────────────────────
        Rectangle {
            anchors.top:          scoreDisplay.bottom; anchors.topMargin:    8
            anchors.bottom:       actionRow.top;       anchors.bottomMargin: 8
            anchors.left:         parent.left;         anchors.leftMargin:   14
            anchors.right:        parent.right;        anchors.rightMargin:  14
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
                    placeholderText: "ffmpeg output will appear here…"
                    placeholderTextColor: "#2a5a1a"
                }
            }
        }
    }

    // ── Info overlay ─────────────────────────────────────────────────────────
    Rectangle {
        id: infoOverlay
        anchors.fill:        reportPanel
        anchors.leftMargin:  1
        anchors.rightMargin: 1
        color:   "#0d1a08"
        radius:  0
        visible: false
        z:       100

        // Dismiss on click outside the content
        MouseArea { anchors.fill: parent; onClicked: infoOverlay.visible = false }

        Column {
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: closeRow.top
            anchors.margins: 18
            spacing: 14

            Text {
                text: "HOW IT WORKS"
                font.family: "Segoe UI"; font.pixelSize: 13
                font.bold: true; font.letterSpacing: 2
                color: root.green
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                font.family: "Segoe UI"; font.pixelSize: 12
                color: "#b0d4a0"
                lineHeight: 1.4
                text:
                    "Each file is read by ffprobe (no decoding, completes in seconds). " +
                    "Four technical factors are measured and combined into a Quality Score out of 100."
            }

            // Score breakdown table
            Column {
                width: parent.width
                spacing: 5

                Repeater {
                    model: [
                        { factor: "Video Codec",    pts: "25 pts", detail: "HEVC / AV1 score highest. H.264 is mid-range. Older codecs (MPEG-2, VC-1) score low. A modern codec delivers more quality per bit." },
                        { factor: "Resolution",     pts: "30 pts", detail: "4K = 30 pts, 1080p = 22, 720p = 14, 576p = 8. Higher resolution means more visual detail available." },
                        { factor: "Video Bitrate",  pts: "30 pts", detail: "Scored on a log scale up to 80 Mbps. More bits per second means more detail is preserved, especially in fast motion." },
                        { factor: "Audio Quality",  pts: "15 pts", detail: "TrueHD / DTS-MA / PCM (lossless) score highest. DTS / Dolby Digital mid-range. AAC and MP3 score lower." },
                    ]

                    delegate: Column {
                        width: parent.width
                        spacing: 3

                        Row {
                            spacing: 8
                            Text {
                                text: modelData.factor
                                font.family: "Segoe UI"; font.pixelSize: 12
                                font.bold: true; color: root.green
                                width: 100
                            }
                            Text {
                                text: modelData.pts
                                font.family: "Segoe UI"; font.pixelSize: 12
                                color: "#FFB300"
                            }
                        }
                        Text {
                            width: parent.width
                            text: modelData.detail
                            wrapMode: Text.WordWrap
                            font.family: "Segoe UI"; font.pixelSize: 11
                            color: "#7a9a70"; lineHeight: 1.3
                        }
                    }
                }
            }

            Text {
                text: "READING THE RESULTS"
                font.family: "Segoe UI"; font.pixelSize: 13
                font.bold: true; font.letterSpacing: 2
                color: root.green
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: [
                        { score: "80 – 100", col: "#39FF14", label: "Excellent" },
                        { score: "60 – 79",  col: "#FFB300", label: "Good" },
                        { score: "40 – 59",  col: "#FF6600", label: "Fair" },
                        { score: "0  – 39",  col: "#FF3333", label: "Poor" },
                    ]
                    delegate: Row {
                        spacing: 10
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: modelData.col
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.score + "  —  " + modelData.label
                            font.family: "Segoe UI"; font.pixelSize: 12
                            color: modelData.col
                        }
                    }
                }

                Text {
                    width: parent.width
                    topPadding: 6
                    wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 11
                    color: "#7a9a70"; lineHeight: 1.3
                    text:
                        "A gap under 5 pts is marginal — either file is fine. " +
                        "5–15 pts is a moderate advantage. Over 15 pts is significant — " +
                        "the higher-scoring file will deliver a noticeably better experience."
                }
            }
        }

        // Close button
        Row {
            id: closeRow
            anchors.bottom:       parent.bottom
            anchors.right:        parent.right
            anchors.bottomMargin: 14
            anchors.rightMargin:  18

            WorkbenchActionButton {
                label: "Close"
                accent: root.green
                onActivated: infoOverlay.visible = false
            }
        }
    }

    // ── Backend connections ───────────────────────────────────────────────────
    Connections {
        target: ffmpegBackend

        function onCompareReady(header, body, scoreA, scoreB) {
            headerArea.text   = header
            bodyArea.text     = body
            root.scoreA       = scoreA
            root.scoreB       = scoreB
            root.comparing    = false
            reportPanel.ready = true
        }

        function onStatusMessage(msg) {
            if (msg.indexOf("Analysing") !== -1 || msg.indexOf("comparison") !== -1) {
                root.comparing    = true
                reportPanel.ready = true
                bodyArea.text     = ""
                headerArea.text   = ""
                root.scoreA       = -1
                root.scoreB       = -1
            }
        }

        function onFfmpegMissing() { installDialog.open() }

        function onDownloadProgress(pct) { dlProgress.value = pct }
        function onDownloadComplete()    { installDialog.close() }
        function onDownloadFailed(reason) {
            dlErrorText.text    = "Download failed: " + reason
            dlProgress.visible  = false
            dlErrorText.visible = true
        }
    }

    // ── FFmpeg install dialog ─────────────────────────────────────────────────
    Rectangle {
        id: installDialog
        anchors.centerIn: parent
        width: 420; height: 200
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
                text: "FFmpeg Not Found"
                font.pixelSize: 16; font.bold: true
                color: root.green
            }

            Text {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                text:  "FFmpeg is required for Workbench features.\nWould you like to download it now?"
                font.pixelSize: 13; color: "#b0d4a0"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            ProgressBar {
                id: dlProgress
                width: parent.width; height: 20
                from: 0; to: 100; value: 0
                visible: false
                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Rectangle {
                    width:  dlProgress.visualPosition * dlProgress.width
                    height: parent.height; radius: 3
                    color:  root.green
                }
            }

            Text {
                id: dlErrorText
                visible: false; width: parent.width; text: ""
                color: "#FF5555"; font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                WorkbenchActionButton {
                    label: "Download"; accent: root.green
                    onActivated: {
                        dlProgress.value   = 0
                        dlProgress.visible = true
                        ffmpegBackend.downloadFFmpeg()
                    }
                }
                WorkbenchActionButton {
                    label: "Not Now"; accent: "#888888"
                    onActivated: installDialog.close()
                }
            }
        }
    }
}
