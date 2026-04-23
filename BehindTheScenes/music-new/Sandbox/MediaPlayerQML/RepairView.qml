import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

// ─────────────────────────────────────────────────────────────────────────────
//  RepairView — FFmpeg file repair panel
//
//  Centred modal panel over the cinematic rotating backdrop.
//  Frosted glass effect: blurred backdrop + dark tint behind the panel.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    property var backdropLayer: null

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color green:     "#39FF14"
    readonly property color dimGreen:  "#162e08"
    readonly property color panelBg:   Qt.rgba(0, 0, 0, 0.08)
    readonly property color borderCol: "#39FF14"
    readonly property color bodyBg:    "transparent"

    property bool repairing: false
    property bool done:      false

    // ── Outer glow ring ───────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width: panel.width + 10; height: panel.height + 10; radius: 20
        color: "transparent"; border.color: root.green; border.width: 1; opacity: 0.12; z: 1
    }

    // ── Frosted glass base ────────────────────────────────────────────────────
    Item {
        id: glassBg
        anchors.centerIn: parent
        width:  parent.width  * 0.70
        height: parent.height * 0.84
        z: 1
        visible: root.backdropLayer !== null

        FastBlur {
            anchors.fill: parent; radius: 40
            source: ShaderEffectSource {
                sourceItem: root.backdropLayer; live: true; hideSource: false
                sourceRect: Qt.rect(glassBg.x, glassBg.y, glassBg.width, glassBg.height)
            }
        }
        Rectangle { anchors.fill: parent; color: "#010306"; opacity: 0.55 }
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
            height: 62; color: Qt.rgba(0,0,0,0.45); radius: 14
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: parent.radius; color: parent.color }
            Rectangle {
                anchors.top: parent.top; anchors.topMargin: 10
                anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                anchors.left: parent.left
                width: 4; color: root.green; radius: 2
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "FILE REPAIR"
                font.family: "Segoe UI"; font.pixelSize: 26; font.bold: true; font.letterSpacing: 4
                color: root.green
            }

            Rectangle {
                id: infoBtn
                anchors.right: parent.right; anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: infoMa.containsMouse ? Qt.rgba(0.22,1,0.08,0.18) : "transparent"
                border.color: root.green; border.width: 1
                Text { anchors.centerIn: parent; text: "i"; font.family: "Segoe UI"; font.pixelSize: 16; font.italic: true; font.bold: true; color: root.green }
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

        // ── Mode selection (when idle) ────────────────────────────────────────
        Item {
            id: modeSection
            anchors.top:   divider.bottom; anchors.topMargin: 24
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 80
            visible: !root.repairing && !root.done
            property string mode: "remux"

            Column {
                anchors.fill: parent; spacing: 12

                Text {
                    text: "Select repair mode:"
                    font.family: "Segoe UI"; font.pixelSize: 18; color: "#7aaabb"
                }
                Row {
                    spacing: 0
                    Rectangle {
                        width: 140; height: 36; radius: 4
                        color: modeSection.mode === "remux" ? root.dimGreen : "transparent"
                        border.color: root.borderCol; border.width: 1
                        Text { anchors.centerIn: parent; text: "Remux"; font.family: "Segoe UI"; font.pixelSize: 16; font.bold: true; color: root.green }
                        MouseArea { anchors.fill: parent; onClicked: modeSection.mode = "remux" }
                    }
                    Rectangle {
                        width: 140; height: 36; radius: 4
                        color: modeSection.mode === "transcode" ? root.dimGreen : "transparent"
                        border.color: root.borderCol; border.width: 1
                        Text { anchors.centerIn: parent; text: "Transcode"; font.family: "Segoe UI"; font.pixelSize: 16; font.bold: true; color: root.green }
                        MouseArea { anchors.fill: parent; onClicked: modeSection.mode = "transcode" }
                    }
                }
            }
        }

        Text {
            anchors.top:   modeSection.bottom; anchors.topMargin: 6
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            visible: !root.repairing && !root.done
            wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 16; color: "#7a9a70"; lineHeight: 1.4
            text: modeSection.mode === "remux"
                  ? "Lossless — rebuilds container in seconds. No quality change."
                  : "Re-encodes every frame as H.264. Fixes corrupted data. Takes longer."
        }

        WorkbenchActionButton {
            anchors.top:              modeSection.bottom; anchors.topMargin: 56
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180; height: 48
            label: "Start Repair"; accent: root.green
            visible: !root.repairing && !root.done
            onActivated: {
                root.repairing = true; root.done = false
                bodyArea.text = ""; headerArea.text = ""; progressBar.value = 0
                ffmpegBackend.repairFile(modeSection.mode)
            }
        }

        // ── Progress bar ──────────────────────────────────────────────────────
        Item {
            id: progressRow
            anchors.top:   divider.bottom; anchors.topMargin: 20
            anchors.left:  parent.left;    anchors.leftMargin:  24
            anchors.right: parent.right;   anchors.rightMargin: 24
            height: visible ? 32 : 0; visible: root.repairing

            ProgressBar {
                id: progressBar
                anchors.left:           parent.left
                anchors.right:          pctLabel.left; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 28; from: 0; to: 100; value: 0; indeterminate: value === 0

                background: Rectangle { color: "#0a1820"; radius: 4; border.color: root.borderCol; border.width: 1 }
                contentItem: Item {
                    Rectangle {
                        visible: !progressBar.indeterminate
                        width: progressBar.visualPosition * progressBar.width
                        height: parent.height; radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.dimGreen }
                            GradientStop { position: 1.0; color: root.green }
                        }
                    }
                    Rectangle {
                        id: pulseBar; visible: progressBar.indeterminate
                        width: parent.width * 0.35; height: parent.height; radius: 4
                        color: root.green; opacity: 0.85
                        SequentialAnimation on x {
                            running: pulseBar.visible; loops: Animation.Infinite
                            NumberAnimation { from: -pulseBar.width; to: progressBar.width; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
            Text {
                id: pctLabel
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: progressBar.indeterminate ? "…" : (progressBar.value + "%")
                font.pixelSize: 18; font.family: "Segoe UI"; font.bold: true
                color: root.green; width: 44
            }
        }

        // ── Header (read-only) ────────────────────────────────────────────────
        TextArea {
            id: headerArea
            anchors.top: progressRow.visible ? progressRow.bottom : divider.bottom
            anchors.topMargin: 10
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            height:   visible ? contentHeight + 8 : 0
            readOnly: true; text: ""
            color:    "#aaccbb"; font.family: "Consolas"; font.pixelSize: 18
            background: Rectangle { color: "transparent" }
            wrapMode:  TextArea.Wrap; visible: text !== ""
        }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            id: actionRow
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            anchors.left:   parent.left;   anchors.leftMargin:   24
            spacing: 14

            WorkbenchActionButton {
                label: "Save Log"; accent: root.green
                visible: root.done && bodyArea.text !== ""
                onActivated: ffmpegBackend.saveReport(headerArea.text + "\n" + bodyArea.text)
            }
            WorkbenchActionButton {
                label: "New Repair"; accent: "#808080"
                visible: root.done
                onActivated: { root.done = false; root.repairing = false; headerArea.text = ""; bodyArea.text = ""; progressBar.value = 0 }
            }
            WorkbenchActionButton {
                label: "Cancel"; accent: "#FF5555"
                visible: root.repairing
                onActivated: ffmpegBackend.cancelRepair()
            }
        }

        // ── Body ──────────────────────────────────────────────────────────────
        Rectangle {
            anchors.top:    headerArea.bottom; anchors.topMargin:    10
            anchors.bottom: actionRow.top;     anchors.bottomMargin: 12
            anchors.left:   parent.left;       anchors.leftMargin:   24
            anchors.right:  parent.right;      anchors.rightMargin:  24
            visible: root.done
            color: root.bodyBg; border.color: root.borderCol; border.width: 1; radius: 6; clip: true

            ScrollView {
                anchors.fill: parent; anchors.margins: 8
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: ScrollBar {
                    width: 6; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 3; color: "#39FF14"; opacity: 0.55 }
                    background:  Rectangle { color: Qt.rgba(0.22, 1, 0.08, 0.07); radius: 3 }
                }
                TextArea {
                    id: bodyArea; width: parent.width; wrapMode: TextArea.Wrap; text: ""
                    color: root.green; font.family: "Consolas"; font.pixelSize: 20
                    background: Rectangle { color: "transparent" }
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

        Flickable {
            id: infoFlick
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: infoCloseRow.top; anchors.margins: 24
            clip: true; contentHeight: infoCol.implicitHeight
            Column {
                id: infoCol; width: parent.width; spacing: 16

                Text { text: "REMUX  —  FAST LOSSLESS"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5; color: root.green }
                Text { width: parent.width; wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 16; color: "#aaccbb"; lineHeight: 1.5
                    text: "Reads the video and audio streams and writes them into a fresh container — no frame is decoded or re-encoded. Completes in seconds and the output is bit-for-bit identical quality." }
                Text { width: parent.width; wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 16; color: "#aaccbb"; lineHeight: 1.5
                    text: "✓  Fixes:  broken container index, wrong timestamps, audio/video sync drift\n✗  Does not fix:  corrupted frame data, missing reference frames" }
                Rectangle { width: parent.width; height: 1; color: root.borderCol; opacity: 0.3 }
                Text { text: "TRANSCODE  —  FULL RE-ENCODE"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5; color: root.green }
                Text { width: parent.width; wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 16; color: "#aaccbb"; lineHeight: 1.5
                    text: "Every frame is decoded and re-encoded as H.264 (CRF 18). Corrupted frames are replaced by the encoder's best reconstruction. Takes minutes to hours depending on file length." }
                Text { width: parent.width; wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 16; color: "#aaccbb"; lineHeight: 1.5
                    text: "✓  Fixes:  corrupted or missing frame data, unrecoverable container errors\n✗  Trade-off:  not mathematically lossless — small re-encode penalty" }
                Rectangle { width: parent.width; height: 1; color: root.borderCol; opacity: 0.3 }
                Text { text: "WHICH SHOULD I USE?"; font.family: "Segoe UI"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5; color: root.green }
                Text { width: parent.width; wrapMode: Text.WordWrap; font.family: "Segoe UI"; font.pixelSize: 16; color: "#aaccbb"; lineHeight: 1.5
                    text: "Always try Remux first — it is instant and lossless. Run Test File on the result. If errors persist, switch to Transcode.\n\nOutput is saved in the same folder with '_repair' added to the filename." }
            }
        }
        Row {
            id: infoCloseRow
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.bottomMargin: 20; anchors.rightMargin: 24
            WorkbenchActionButton { label: "Close"; accent: root.green; onActivated: infoOverlay.visible = false }
        }
    }

    // ── Backend connections ───────────────────────────────────────────────────
    Connections {
        target: ffmpegBackend

        function onRepairReady(header, body) {
            headerArea.text = header; bodyArea.text = body
            root.repairing = false; root.done = true
        }
        function onRepairProgress(pct)  { progressBar.value = pct }
        function onStatusMessage(msg)   { if (msg === "Remuxing…" || msg === "Transcoding…") progressBar.value = 0 }
        function onFfmpegMissing()      { installDialog.open() }
        function onDownloadProgress(pct){ dlProgress.value = pct }
        function onDownloadComplete()   { installDialog.close() }
        function onDownloadFailed(reason) { dlErrorText.text = "Download failed: " + reason; dlProgress.visible = false; dlErrorText.visible = true }
    }

    // ── FFmpeg install dialog ─────────────────────────────────────────────────
    Rectangle {
        id: installDialog; anchors.centerIn: parent; width: 460; height: 220; radius: 12
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
