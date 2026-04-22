import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  CompareView — VMAF file comparison panel
//
//  Centred modal panel over a static movie poster backdrop.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color green:     "#39FF14"
    readonly property color panelBg:   "#06101c"
    readonly property color borderCol: "#39FF14"
    readonly property color bodyBg:    "#080f18"

    property bool comparing: false
    property real scoreA:   -1
    property real scoreB:   -1

    function scoreColor(s) {
        if (s >= 80) return "#39FF14"
        if (s >= 60) return "#FFB300"
        if (s >= 40) return "#FF6600"
        return "#FF3333"
    }

    // ── Static poster backdrop ────────────────────────────────────────────────
    WorkbenchSplash { anchors.fill: parent; z: 0 }

    // ── Outer glow ring ───────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  panel.width  + 10
        height: panel.height + 10
        radius: 20; color: "transparent"
        border.color: root.green; border.width: 1; opacity: 0.07; z: 1
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
            Rectangle {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                height: parent.radius; color: parent.color
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: "FILE COMPARE"
                font.family: "Segoe UI"; font.pixelSize: 26; font.bold: true; font.letterSpacing: 4
                color: root.green
            }

            // Info button
            Rectangle {
                id: infoBtn
                anchors.right: parent.right; anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: infoMa.containsMouse ? Qt.rgba(0.22,1,0.08,0.18) : "transparent"
                border.color: root.green; border.width: 1
                Text {
                    anchors.centerIn: parent; text: "i"
                    font.family: "Segoe UI"; font.pixelSize: 16; font.italic: true; font.bold: true
                    color: root.green
                }
                MouseArea { id: infoMa; anchors.fill: parent; hoverEnabled: true; onClicked: infoOverlay.visible = !infoOverlay.visible }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Rectangle {
            id: divider
            anchors.top: titleBar.bottom
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 1; color: root.borderCol; opacity: 0.30
        }

        // ── Pulsing progress bar (while comparing) ────────────────────────────
        Item {
            id: progressRow
            anchors.top: divider.bottom; anchors.topMargin: 10
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: visible ? 32 : 0; visible: root.comparing

            ProgressBar {
                id: progressBar
                anchors.fill: parent; from: 0; to: 100; value: 0
                background: Rectangle { color: "#0a1820"; radius: 4; border.color: root.borderCol; border.width: 1 }
                contentItem: Item {
                    Rectangle {
                        id: pulseBar; width: parent.width * 0.35; height: parent.height; radius: 4
                        color: root.green; opacity: 0.85
                        SequentialAnimation on x {
                            running: root.comparing; loops: Animation.Infinite
                            NumberAnimation { from: -pulseBar.width; to: progressBar.width; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        // ── File info header ──────────────────────────────────────────────────
        TextArea {
            id: headerArea
            anchors.top: progressRow.bottom; anchors.topMargin: 8
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: visible ? contentHeight + 8 : 0
            readOnly: true; text: ""
            color: "#aaccbb"
            font.family: "Consolas"; font.pixelSize: 18
            background: Rectangle { color: "transparent" }
            wrapMode: TextArea.Wrap; visible: text !== ""
        }

        // ── Dual score display ────────────────────────────────────────────────
        Item {
            id: scoreDisplay
            anchors.top: headerArea.bottom; anchors.topMargin: 16
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: visible ? 100 : 0
            visible: root.scoreA >= 0 && root.scoreB >= 0

            Row {
                anchors.fill: parent; spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2; height: parent.height
                    color: Qt.rgba(0,0,0,0.35); radius: 8
                    border.color: root.scoreColor(root.scoreA)
                    border.width: root.scoreA >= root.scoreB ? 2 : 1
                    opacity:      root.scoreA >= root.scoreB ? 1.0 : 0.65

                    Column {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter; text: "FILE A"
                            font.family: "Segoe UI"; font.pixelSize: 14; font.letterSpacing: 2
                            color: "#808080"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreA >= 0 ? root.scoreA.toFixed(1) : ""
                            font.family: "Segoe UI"; font.pixelSize: 36; font.bold: true
                            color: root.scoreColor(root.scoreA)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreA > root.scoreB ? "▲ WINNER" : (root.scoreA === root.scoreB ? "EQUAL" : "")
                            font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true
                            color: root.scoreColor(root.scoreA); visible: text !== ""
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2; height: parent.height
                    color: Qt.rgba(0,0,0,0.35); radius: 8
                    border.color: root.scoreColor(root.scoreB)
                    border.width: root.scoreB >= root.scoreA ? 2 : 1
                    opacity:      root.scoreB >= root.scoreA ? 1.0 : 0.65

                    Column {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter; text: "FILE B"
                            font.family: "Segoe UI"; font.pixelSize: 14; font.letterSpacing: 2
                            color: "#808080"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreB >= 0 ? root.scoreB.toFixed(1) : ""
                            font.family: "Segoe UI"; font.pixelSize: 36; font.bold: true
                            color: root.scoreColor(root.scoreB)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.scoreB > root.scoreA ? "▲ WINNER" : (root.scoreB === root.scoreA ? "EQUAL" : "")
                            font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true
                            color: root.scoreColor(root.scoreB); visible: text !== ""
                        }
                    }
                }
            }
        }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            id: actionRow
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            anchors.left:   parent.left;   anchors.leftMargin:   24
            spacing: 14

            WorkbenchActionButton {
                label: "Save"; accent: root.green
                enabled: bodyArea.text !== ""
                onActivated: {
                    ffmpegBackend.saveReport(headerArea.text + "\n" + bodyArea.text)
                    headerArea.text = ""; bodyArea.text = ""; root.scoreA = -1; root.scoreB = -1
                }
            }
        }

        // ── Raw output area ───────────────────────────────────────────────────
        Rectangle {
            anchors.top:    scoreDisplay.bottom; anchors.topMargin:    10
            anchors.bottom: actionRow.top;       anchors.bottomMargin: 12
            anchors.left:   parent.left;         anchors.leftMargin:   24
            anchors.right:  parent.right;        anchors.rightMargin:  24
            color: root.bodyBg; border.color: root.borderCol; border.width: 1; radius: 6; clip: true

            ScrollView {
                anchors.fill: parent; anchors.margins: 6
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                TextArea {
                    id: bodyArea; width: parent.width; wrapMode: TextArea.Wrap; text: ""
                    color: root.green; font.family: "Consolas"; font.pixelSize: 20
                    background: Rectangle { color: "transparent" }
                    placeholderText: "ffmpeg output will appear here…"
                    placeholderTextColor: "#1f4a18"
                }
            }
        }
    }

    // ── Info overlay ──────────────────────────────────────────────────────────
    Rectangle {
        id: infoOverlay
        anchors.fill: panel; anchors.margins: 2
        color: "#06101c"; radius: 12; visible: false; z: 100

        MouseArea { anchors.fill: parent; onClicked: infoOverlay.visible = false }

        Column {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: closeRow.top; anchors.margins: 24; spacing: 16

            Text {
                text: "HOW IT WORKS"
                font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 2
                color: root.green
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                font.family: "Segoe UI"; font.pixelSize: 16; color: "#aaccbb"; lineHeight: 1.5
                text: "Each file is read by ffprobe (no decoding). Four technical factors are measured and combined into a Quality Score out of 100."
            }

            Column {
                width: parent.width; spacing: 8
                Repeater {
                    model: [
                        { factor: "Video Codec",   pts: "25 pts", detail: "HEVC / AV1 score highest. H.264 is mid-range. Older codecs score low." },
                        { factor: "Resolution",    pts: "30 pts", detail: "4K = 30 pts, 1080p = 22, 720p = 14, 576p = 8." },
                        { factor: "Video Bitrate", pts: "30 pts", detail: "Scored on a log scale up to 80 Mbps." },
                        { factor: "Audio Quality", pts: "15 pts", detail: "TrueHD / DTS-MA score highest. AAC and MP3 score lower." },
                    ]
                    delegate: Column {
                        width: parent.width; spacing: 4
                        Row {
                            spacing: 10
                            Text { text: modelData.factor; font.family: "Segoe UI"; font.pixelSize: 16; font.bold: true; color: root.green; width: 130 }
                            Text { text: modelData.pts;    font.family: "Segoe UI"; font.pixelSize: 16; color: "#FFB300" }
                        }
                        Text { width: parent.width; text: modelData.detail; wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 14; color: "#7a9a70"; lineHeight: 1.3 }
                    }
                }
            }

            Text { text: "SCORE BANDS"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 2; color: root.green }
            Column {
                width: parent.width; spacing: 6
                Repeater {
                    model: [{ score:"80–100", col:"#39FF14", label:"Excellent"}, {score:"60–79", col:"#FFB300", label:"Good"}, {score:"40–59", col:"#FF6600", label:"Fair"}, {score:"0–39", col:"#FF3333", label:"Poor"}]
                    delegate: Row {
                        spacing: 12
                        Rectangle { width: 12; height: 12; radius: 6; color: modelData.col; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.score + "  —  " + modelData.label; font.family: "Segoe UI"; font.pixelSize: 16; color: modelData.col }
                    }
                }
            }
        }

        Row {
            id: closeRow
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.bottomMargin: 20; anchors.rightMargin: 24
            WorkbenchActionButton { label: "Close"; accent: root.green; onActivated: infoOverlay.visible = false }
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
        }

        function onStatusMessage(msg) {
            if (msg.indexOf("Analysing") !== -1 || msg.indexOf("comparison") !== -1) {
                root.comparing  = true
                bodyArea.text   = ""
                headerArea.text = ""
                root.scoreA     = -1
                root.scoreB     = -1
            }
        }

        function onFfmpegMissing()          { installDialog.open() }
        function onDownloadProgress(pct)    { dlProgress.value = pct }
        function onDownloadComplete()       { installDialog.close() }
        function onDownloadFailed(reason)   {
            dlErrorText.text = "Download failed: " + reason
            dlProgress.visible = false; dlErrorText.visible = true
        }
    }

    // ── FFmpeg install dialog ─────────────────────────────────────────────────
    Rectangle {
        id: installDialog
        anchors.centerIn: parent; width: 460; height: 220; radius: 12
        color: "#0a1520"; border.color: root.borderCol; border.width: 2; visible: false; z: 500

        function open()  { visible = true  }
        function close() { visible = false }

        Column {
            anchors.centerIn: parent; spacing: 20; width: parent.width - 48
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "FFmpeg Not Found"; font.pixelSize: 20; font.bold: true; color: root.green }
            Text { width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; text: "FFmpeg is required for Workbench features.\nWould you like to download it now?"; font.pixelSize: 16; color: "#aaccbb"; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
            ProgressBar { id: dlProgress; width: parent.width; height: 22; from: 0; to: 100; value: 0; visible: false
                background: Rectangle { color: "#0a1820"; radius: 4; border.color: root.borderCol; border.width: 1 }
                contentItem: Rectangle { width: dlProgress.visualPosition * dlProgress.width; height: parent.height; radius: 4; color: root.green }
            }
            Text { id: dlErrorText; visible: false; width: parent.width; text: ""; color: "#FF5555"; font.pixelSize: 14; wrapMode: Text.WordWrap }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 16
                WorkbenchActionButton { label: "Download"; accent: root.green; onActivated: { dlProgress.value = 0; dlProgress.visible = true; ffmpegBackend.downloadFFmpeg() } }
                WorkbenchActionButton { label: "Not Now"; accent: "#888888"; onActivated: installDialog.close() }
            }
        }
    }
}
