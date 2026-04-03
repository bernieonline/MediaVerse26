import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  RepairView — ffmpeg file repair panel
//
//  User selects Remux or Transcode, then clicks Start Repair (file dialog
//  opens in Python). Progress bar tracks transcode; pulses for fast remux.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    readonly property color green:     "#39FF14"
    readonly property color dimGreen:  "#1a4a0a"
    readonly property color panelBg:   "#0d1a08"
    readonly property color borderCol: "#39FF14"

    property bool repairing: false
    property bool done:      false

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

        property bool ready: true   // panel always visible for repair (user needs to choose mode first)
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
                text: "FILE REPAIR"
                font.family:        "Segoe UI"
                font.pixelSize:     15
                font.bold:          true
                font.letterSpacing: 2.5
                color: root.green
            }

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
                    font.family: "Segoe UI"; font.pixelSize: 13
                    font.italic: true; font.bold: true
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

        // ── Mode toggle ───────────────────────────────────────────────────────
        Item {
            id: modeSection
            anchors.top:   divider.bottom; anchors.topMargin: 14
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            height: 60
            visible: !root.repairing && !root.done

            property string mode: "remux"

            Column {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "Select repair mode:"
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#808080"
                }

                Row {
                    spacing: 0

                    Rectangle {
                        width: 110; height: 28; radius: 4
                        color:        modeSection.mode === "remux" ? root.dimGreen : "transparent"
                        border.color: root.borderCol; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Remux"
                            font.family: "Segoe UI"; font.pixelSize: 12
                            color: root.green
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: modeSection.mode = "remux"
                        }
                    }

                    Rectangle {
                        width: 110; height: 28; radius: 4
                        color:        modeSection.mode === "transcode" ? root.dimGreen : "transparent"
                        border.color: root.borderCol; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Transcode"
                            font.family: "Segoe UI"; font.pixelSize: 12
                            color: root.green
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: modeSection.mode = "transcode"
                        }
                    }
                }
            }
        }

        // Mode description line
        Text {
            anchors.top:   modeSection.bottom; anchors.topMargin: 4
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            visible: !root.repairing && !root.done
            wrapMode: Text.WordWrap
            font.family: "Segoe UI"; font.pixelSize: 11
            color: "#7a9a70"
            text: modeSection.mode === "remux"
                  ? "Lossless — rebuilds container in seconds. No quality change."
                  : "Re-encodes every frame as H.264. Fixes corrupted data. Takes longer."
        }

        // ── Start Repair button ───────────────────────────────────────────────
        WorkbenchActionButton {
            id: startBtn
            anchors.top:              modeSection.bottom; anchors.topMargin: 36
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160; height: 40
            label: "Start Repair"
            accent: root.green
            visible: !root.repairing && !root.done
            onActivated: {
                root.repairing = true
                root.done      = false
                bodyArea.text  = ""
                headerArea.text = ""
                progressBar.value = 0
                ffmpegBackend.repairFile(modeSection.mode)
            }
        }

        // ── Progress bar ──────────────────────────────────────────────────────
        Item {
            id: progressRow
            anchors.top:   divider.bottom; anchors.topMargin: 20
            anchors.left:  parent.left;    anchors.leftMargin:  14
            anchors.right: parent.right;   anchors.rightMargin: 14
            height: visible ? 26 : 0
            visible: root.repairing

            ProgressBar {
                id: progressBar
                anchors.left:           parent.left
                anchors.right:          pctLabel.left
                anchors.rightMargin:    6
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                from: 0; to: 100; value: 0
                indeterminate: value === 0

                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Item {
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
                    Rectangle {
                        id: pulseBar
                        visible: progressBar.indeterminate
                        width:  parent.width * 0.35
                        height: parent.height; radius: 3
                        color:  root.green; opacity: 0.85
                        SequentialAnimation on x {
                            running: pulseBar.visible
                            loops:   Animation.Infinite
                            NumberAnimation {
                                from: -pulseBar.width; to: progressBar.width
                                duration: 1200; easing.type: Easing.InOutSine
                            }
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
            anchors.top:   progressRow.visible ? progressRow.bottom : divider.bottom
            anchors.topMargin: 8
            anchors.left:  parent.left;  anchors.leftMargin:  14
            anchors.right: parent.right; anchors.rightMargin: 14
            height:   visible ? contentHeight + 8 : 0
            readOnly: true; text: ""
            color:    "#b0d4a0"
            font.family: "Courier New"; font.pixelSize: 12
            background: Rectangle { color: "transparent" }
            wrapMode:  TextArea.Wrap
            visible:   text !== ""
        }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            id: actionRow
            anchors.bottom:       parent.bottom; anchors.bottomMargin: 14
            anchors.left:         parent.left;   anchors.leftMargin:   14
            spacing: 10

            WorkbenchActionButton {
                label: "Save Log"
                accent: root.green
                visible: root.done && bodyArea.text !== ""
                onActivated: {
                    ffmpegBackend.saveReport(headerArea.text + "\n" + bodyArea.text)
                }
            }

            WorkbenchActionButton {
                label: "New Repair"
                accent: "#808080"
                visible: root.done
                onActivated: {
                    root.done       = false
                    root.repairing  = false
                    headerArea.text = ""
                    bodyArea.text   = ""
                    progressBar.value = 0
                }
            }

            WorkbenchActionButton {
                label: "Cancel"
                accent: "#FF5555"
                visible: root.repairing
                onActivated: ffmpegBackend.cancelRepair()
            }
        }

        // ── Body — result / log ───────────────────────────────────────────────
        Rectangle {
            anchors.top:          headerArea.bottom; anchors.topMargin:    8
            anchors.bottom:       actionRow.top;     anchors.bottomMargin: 8
            anchors.left:         parent.left;       anchors.leftMargin:   14
            anchors.right:        parent.right;      anchors.rightMargin:  14
            visible:              root.done
            color:        "#0a120a"
            border.color: root.borderCol
            border.width: 1
            radius:       3
            clip:         true

            ScrollView {
                anchors.fill: parent; anchors.margins: 4
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TextArea {
                    id: bodyArea
                    width: parent.width
                    wrapMode: TextArea.Wrap
                    text: ""
                    color: root.green
                    font.family: "Courier New"; font.pixelSize: 12
                    background: Rectangle { color: "transparent" }
                }
            }
        }
    }

    // ── Info overlay ──────────────────────────────────────────────────────────
    Rectangle {
        id: infoOverlay
        anchors.fill:        reportPanel
        anchors.leftMargin:  1
        anchors.rightMargin: 1
        color:   "#0d1a08"
        visible: false
        z:       100

        MouseArea { anchors.fill: parent; onClicked: infoOverlay.visible = false }

        Flickable {
            id: infoFlick
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: infoCloseRow.top
            anchors.margins: 18
            clip: true
            contentHeight: infoCol.implicitHeight

            Column {
                id: infoCol
                width: parent.width
                spacing: 14

                Text {
                    text: "REMUX  —  FAST LOSSLESS"
                    font.family: "Segoe UI"; font.pixelSize: 13
                    font.bold: true; font.letterSpacing: 1.5
                    color: root.green
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#b0d4a0"; lineHeight: 1.4
                    text: "Reads the video and audio streams and writes them into a " +
                          "fresh container — no frame is decoded or re-encoded. " +
                          "Completes in seconds and the output is bit-for-bit identical quality."
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#b0d4a0"; lineHeight: 1.4
                    text: "✓  Fixes:  broken container index, wrong timestamps, " +
                          "audio/video sync drift, truncated file headers\n" +
                          "✗  Does not fix:  corrupted frame data, missing reference frames, " +
                          "damaged audio samples"
                }

                Rectangle { width: parent.width; height: 1; color: root.borderCol; opacity: 0.3 }

                Text {
                    text: "TRANSCODE  —  FULL RE-ENCODE"
                    font.family: "Segoe UI"; font.pixelSize: 13
                    font.bold: true; font.letterSpacing: 1.5
                    color: root.green
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#b0d4a0"; lineHeight: 1.4
                    text: "Every frame is decoded and re-encoded as H.264 (CRF 18 — " +
                          "high quality). Corrupted frames are replaced by the encoder's " +
                          "best reconstruction. Audio is copied unchanged. " +
                          "Takes minutes to hours depending on file length."
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#b0d4a0"; lineHeight: 1.4
                    text: "✓  Fixes:  corrupted or missing frame data, unrecoverable " +
                          "container errors, anything remux cannot resolve\n" +
                          "✗  Trade-off:  output is excellent quality but not mathematically " +
                          "lossless — a small re-encode penalty applies"
                }

                Rectangle { width: parent.width; height: 1; color: root.borderCol; opacity: 0.3 }

                Text {
                    text: "WHICH SHOULD I USE?"
                    font.family: "Segoe UI"; font.pixelSize: 13
                    font.bold: true; font.letterSpacing: 1.5
                    color: root.green
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#b0d4a0"; lineHeight: 1.4
                    text: "Always try Remux first — it is instant and lossless. " +
                          "Run Test File on the result. If errors persist, switch to Transcode.\n\n" +
                          "Test File shows container / timestamp errors  →  Remux is enough\n" +
                          "Test File shows missing reference frames or corrupted data  →  Transcode"
                }

                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    font.family: "Segoe UI"; font.pixelSize: 12
                    color: "#b0d4a0"; lineHeight: 1.4
                    text: "Output is saved in the same folder as the source file " +
                          "with '_repair' added to the filename."
                }
            }
        }

        Row {
            id: infoCloseRow
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

        function onRepairReady(header, body) {
            headerArea.text = header
            bodyArea.text   = body
            root.repairing  = false
            root.done       = true
        }

        function onRepairProgress(pct) {
            progressBar.value = pct
        }

        function onStatusMessage(msg) {
            if (msg === "Remuxing…" || msg === "Transcoding…") {
                progressBar.value = 0
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
        width: 420; height: 200; radius: 10
        color: "#111a0d"; border.color: root.borderCol; border.width: 2
        visible: false; z: 500

        function open()  { visible = true  }
        function close() { visible = false }

        Column {
            anchors.centerIn: parent
            spacing: 18; width: parent.width - 40

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "FFmpeg Not Found"
                font.pixelSize: 16; font.bold: true; color: root.green
            }
            Text {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                text:  "FFmpeg is required for Workbench features.\nWould you like to download it now?"
                font.pixelSize: 13; color: "#b0d4a0"
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
            ProgressBar {
                id: dlProgress
                width: parent.width; height: 20; from: 0; to: 100; value: 0
                visible: false
                background: Rectangle {
                    color: "#1a1a1a"; radius: 3
                    border.color: root.borderCol; border.width: 1
                }
                contentItem: Rectangle {
                    width:  dlProgress.visualPosition * dlProgress.width
                    height: parent.height; radius: 3; color: root.green
                }
            }
            Text {
                id: dlErrorText; visible: false; width: parent.width; text: ""
                color: "#FF5555"; font.pixelSize: 12; wrapMode: Text.WordWrap
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16
                WorkbenchActionButton {
                    label: "Download"; accent: root.green
                    onActivated: { dlProgress.value = 0; dlProgress.visible = true; ffmpegBackend.downloadFFmpeg() }
                }
                WorkbenchActionButton {
                    label: "Not Now"; accent: "#888888"
                    onActivated: installDialog.close()
                }
            }
        }
    }
}
