import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

// ─────────────────────────────────────────────────────────────────────────────
//  FolderTestView — FFmpeg folder test panel
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

    property bool running:       false
    property bool done:          false
    property int  fileTotal:     0
    property int  fileCurrent:   0
    property string currentFileName: ""
    property string summaryText: ""

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
                text: "FOLDER TEST"
                font.family: "Segoe UI"; font.pixelSize: 26; font.bold: true; font.letterSpacing: 4
                color: root.green
            }

            Row {
                id: modeToggle
                anchors.right: parent.right; anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                property string mode: "standard"
                enabled: !root.running

                Rectangle {
                    width: 100; height: 30; radius: 4
                    color: modeToggle.mode === "standard" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    opacity: modeToggle.enabled ? 1.0 : 0.4
                    Text { anchors.centerIn: parent; text: "Standard"; font.pixelSize: 14; font.family: "Segoe UI"; font.bold: true; color: root.green }
                    MouseArea { anchors.fill: parent; enabled: modeToggle.enabled; onClicked: modeToggle.mode = "standard" }
                }
                Rectangle {
                    width: 100; height: 30; radius: 4
                    color: modeToggle.mode === "thorough" ? root.dimGreen : "transparent"
                    border.color: root.borderCol; border.width: 1
                    opacity: modeToggle.enabled ? 1.0 : 0.4
                    Text { anchors.centerIn: parent; text: "Thorough"; font.pixelSize: 14; font.family: "Segoe UI"; font.bold: true; color: root.green }
                    MouseArea { anchors.fill: parent; enabled: modeToggle.enabled; onClicked: modeToggle.mode = "thorough" }
                }
            }
        }

        Rectangle {
            id: divider
            anchors.top: titleBar.bottom
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 1; color: root.borderCol; opacity: 0.30
        }

        // ── Status line ───────────────────────────────────────────────────────
        Text {
            id: statusLine
            anchors.top:   divider.bottom; anchors.topMargin: 12
            anchors.left:  parent.left;  anchors.leftMargin:  24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 26
            text: {
                if (root.done)    return "Complete \u2014 see summary below"
                if (root.running) return "Testing " + root.fileCurrent + " / " + root.fileTotal + ":  " + root.currentFileName
                return "Select a folder to begin\u2026"
            }
            font.family: "Segoe UI"; font.pixelSize: 18
            color: root.done ? "#aaccbb" : root.green
            elide: Text.ElideMiddle
        }

        // ── Overall progress bar ──────────────────────────────────────────────
        Item {
            id: progressRow
            anchors.top:   statusLine.bottom; anchors.topMargin: 8
            anchors.left:  parent.left;       anchors.leftMargin:  24
            anchors.right: parent.right;      anchors.rightMargin: 24
            height: 28; visible: root.running || root.done

            ProgressBar {
                id: progressBar
                anchors.left:           parent.left
                anchors.right:          pctLabel.left; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 24; from: 0; to: 100; value: 0

                background: Rectangle { color: "#0a1820"; radius: 4; border.color: root.borderCol; border.width: 1 }
                contentItem: Item {
                    clip: true
                    Rectangle {
                        id: fillBar
                        width:  progressBar.visualPosition * progressBar.width
                        height: parent.height; radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.dimGreen }
                            GradientStop { position: 1.0; color: root.green }
                        }
                    }
                    Rectangle {
                        id: pulseStrip
                        visible: root.running
                        x: fillBar.width - width / 2
                        width: parent.width * 0.22; height: parent.height; radius: 4
                        color: Qt.rgba(0.22, 1, 0.08, 0.55)
                        SequentialAnimation on x {
                            running: pulseStrip.visible; loops: Animation.Infinite
                            NumberAnimation { from: fillBar.width - pulseStrip.width/2; to: progressBar.width; duration: 1100; easing.type: Easing.InOutSine }
                            NumberAnimation { from: progressBar.width; to: fillBar.width - pulseStrip.width/2; duration: 0 }
                        }
                    }
                }
            }

            Text {
                id: pctLabel
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: Math.round(progressBar.value) + "%"
                font.pixelSize: 18; font.family: "Segoe UI"; font.bold: true
                color: root.green; width: 44
            }
        }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            id: actionRow
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            anchors.left:   parent.left;   anchors.leftMargin:   24
            spacing: 14

            WorkbenchActionButton {
                label: "Save Summary"; accent: root.green
                visible: root.done && root.summaryText !== ""
                onActivated: ffmpegBackend.saveFolderSummary(root.summaryText)
            }
            WorkbenchActionButton {
                label: "New Test"; accent: "#00BFFF"
                visible: root.done
                onActivated: {
                    root.running = false; root.done = false; root.fileTotal = 0
                    root.fileCurrent = 0; root.currentFileName = ""; root.summaryText = ""
                    logArea.text = ""; progressBar.value = 0
                    ffmpegBackend.testFolder(modeToggle.mode)
                }
            }
            WorkbenchActionButton {
                label: "Cancel"; accent: "#FF5555"
                visible: root.running
                onActivated: ffmpegBackend.cancelFolderTest()
            }
        }

        // ── Live log body ─────────────────────────────────────────────────────
        Rectangle {
            anchors.top:    progressRow.bottom; anchors.topMargin:    10
            anchors.bottom: actionRow.top;      anchors.bottomMargin: 12
            anchors.left:   parent.left;        anchors.leftMargin:   24
            anchors.right:  parent.right;       anchors.rightMargin:  24
            color: root.bodyBg; border.color: root.borderCol; border.width: 1; radius: 6; clip: true

            ScrollView {
                id: logScroll; anchors.fill: parent; anchors.margins: 8
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: ScrollBar {
                    width: 6; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 3; color: "#39FF14"; opacity: 0.55 }
                    background:  Rectangle { color: Qt.rgba(0.22, 1, 0.08, 0.07); radius: 3 }
                }
                TextArea {
                    id: logArea; width: parent.width; readOnly: true
                    wrapMode: TextArea.Wrap; text: ""
                    color: root.green; font.family: "Consolas"; font.pixelSize: 20
                    background: Rectangle { color: "transparent" }
                    placeholderText: "Results will appear here as each file is tested\u2026"
                    placeholderTextColor: "#1f4a18"
                }
            }
        }
    }

    // ── Backend signal connections ────────────────────────────────────────────
    Connections {
        target: ffmpegBackend

        function onFolderTestStarted(total) {
            root.fileTotal = total; root.fileCurrent = 0; root.currentFileName = ""
            root.running = true; root.done = false; root.summaryText = ""
            logArea.text = ""; progressBar.value = 0
        }

        function onFolderTestFileStarted(filename, current, total) {
            root.fileCurrent = current; root.fileTotal = total; root.currentFileName = filename
        }

        function onFolderTestFileDone(filename, hadErrors) {
            var icon   = hadErrors ? "\u2717" : "\u2713"
            var status = hadErrors ? "errors" : "Clean"
            var line   = "[" + root.fileCurrent + "/" + root.fileTotal + "]  " + icon + "  " + filename + "  \u2014  " + status
            logArea.text += (logArea.text === "" ? "" : "\n") + line
            logScroll.ScrollBar.vertical.position = 1.0
        }

        function onFolderTestComplete(summary) {
            root.running = false; root.done = true; root.summaryText = summary
            progressBar.value = 100
            logArea.text += summary === "" ? "\n\n\u2500 Cancelled" : "\n\n" + summary
            Qt.callLater(function() { logArea.cursorPosition = logArea.length - 1 })
        }

        function onProgressChanged(pct) { if (root.running) progressBar.value = pct }
        function onStatusMessage(msg)   { console.log("FolderTest status: " + msg) }
        function onFfmpegMissing()      { installDialog.open() }
        function onDownloadProgress(pct){ dlProgress.value = pct }
        function onDownloadComplete()   { installDialog.close() }
        function onDownloadFailed(reason) {
            dlErrorText.text = "Download failed: " + reason
            dlProgress.visible = false; dlErrorText.visible = true
        }
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
