import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs

// ─────────────────────────────────────────────────────────────────────────────
//  QualityAuditView — Media Info Reporting panel
//
//  Right-side compact control panel — same design language as other
//  FFMPEG workbench views (neon green on dark green).
//
//  Context property required: qualityAuditBackend (QualityAuditBackend)
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── State ─────────────────────────────────────────────────────────────
    property string selectedFolder:  ""          // raw URL from FolderDialog
    property string displayFolder:   "No folder selected"
    property int    filesCompleted:  0
    property int    filesTotal:      0
    property bool   isRunning:       false
    property bool   auditDone:       false
    property string lastReportPath:  ""
    property var    reportPaths:     []           // full paths (for openReport)
    property var    reportNames:     []           // display strings (for ComboBox)

    // ── Palette — FFMPEG workbench colours ────────────────────────────────
    readonly property color cBg:    "#0d1a08"
    readonly property color cDark:  "#0a120a"
    readonly property color cGreen: "#39FF14"
    readonly property color cMuted: "#b0d4a0"
    readonly property color cDim:   "#607060"
    readonly property color cCyan:  "#00BFFF"
    readonly property color cRed:   "#FF5555"
    readonly property color cTeal:  "#3ea87a"

    // ── Helpers ────────────────────────────────────────────────────────────

    function refreshReports() {
        var paths = qualityAuditBackend.getReportList()
        root.reportPaths = paths
        var names = []
        for (var i = 0; i < paths.length; i++) {
            names.push(formatReportName(paths[i]))
        }
        root.reportNames = names
        if (reportCombo.currentIndex >= paths.length && paths.length > 0)
            reportCombo.currentIndex = 0
    }

    // "QA_20260406_143022_Collection.html" → "2026-04-06  14:30  —  Collection"
    function formatReportName(path) {
        if (!path) return ""
        var fn = path.split(/[\/\\]/).pop()
        var m  = fn.match(/^QA_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})\d{2}_(.+)\.html$/)
        if (m) {
            return m[1] + "-" + m[2] + "-" + m[3] +
                   "  " + m[4] + ":" + m[5] +
                   "  —  " + m[6].replace(/_/g, " ")
        }
        return fn
    }

    // ── Folder dialog ──────────────────────────────────────────────────────
    FolderDialog {
        id: folderPicker
        title: "Select Folder to Audit"
        onAccepted: {
            var raw  = folderPicker.selectedFolder.toString()
            root.selectedFolder = raw
            // Convert file:///D:/path → D:\path for display
            root.displayFolder  = raw.replace(/^file:\/\/\//, "").replace(/\//g, "\\")
            root.auditDone      = false
            root.filesCompleted = 0
            root.filesTotal     = 0
            statusText.text     = "Folder selected. Press Start Audit to begin."
        }
    }

    // ── Backend connections ────────────────────────────────────────────────
    Connections {
        target: qualityAuditBackend

        function onProgressChanged(completed, total) {
            root.filesCompleted = completed
            root.filesTotal     = total
        }

        function onAuditComplete(reportPath) {
            root.isRunning      = false
            root.auditDone      = true
            root.lastReportPath = reportPath
            refreshReports()
            statusText.text = "\u2713 Complete \u2014 report saved"
        }

        function onStatusMessage(msg) {
            statusText.text = msg
            if (msg === "Audit cancelled." || msg.indexOf("Error:") === 0) {
                root.isRunning = false
            }
        }
    }

    // ── Panel (right-anchored, matches other workbench views) ──────────────
    Rectangle {
        id: panel
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width: Math.min(420, parent.width * 0.40)
        color: cBg
        border.color: cGreen
        border.width: 1

        // Title bar
        Rectangle {
            id: titleBar
            width:  parent.width
            height: 38
            color:  cDark

            Text {
                anchors.centerIn: parent
                text:             "MEDIA INFO REPORTING"
                font.pixelSize:   12
                font.bold:        true
                font.letterSpacing: 3
                color:            cGreen
            }
        }

        // Thin accent line under title
        Rectangle {
            anchors.top:  titleBar.bottom
            width:  parent.width
            height: 1
            color:  cGreen
            opacity: 0.4
        }

        // Scrollable content
        Flickable {
            anchors.top:    titleBar.bottom
            anchors.topMargin: 1
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            contentHeight:  mainCol.implicitHeight + 24
            clip:           true

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: mainCol
                width: parent.width
                spacing: 0

                // ══════════════════════════════════════════════════════
                //  SECTION: SCAN FOLDER
                // ══════════════════════════════════════════════════════

                Item { width: parent.width; height: 22 }

                Text {
                    x: 16
                    text: "SCAN FOLDER"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2.5
                    color: cDim
                }

                Item { width: parent.width; height: 8 }

                // Folder path display
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32
                    height: 50
                    radius: 6
                    color: cDark
                    border.color: root.selectedFolder !== "" ? cGreen : cDim
                    border.width: 1

                    Text {
                        anchors {
                            fill:    parent
                            margins: 10
                        }
                        text:  root.displayFolder
                        color: root.selectedFolder !== "" ? cMuted : cDim
                        font.pixelSize: 11
                        font.family: "Consolas"
                        elide: Text.ElideLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item { width: parent.width; height: 10 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    WbButton {
                        label:     "Browse\u2026"
                        accent:    cGreen
                        isEnabled: !root.isRunning
                        onWbClicked: folderPicker.open()
                    }

                    WbButton {
                        label:     "Diagnose"
                        accent:    cMuted
                        isEnabled: root.selectedFolder !== "" && !root.isRunning
                        onWbClicked: qualityAuditBackend.diagnoseFirst(root.selectedFolder)
                    }
                }

                Item { width: parent.width; height: 22 }

                // Section divider
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32; height: 1
                    color: cGreen; opacity: 0.18
                }

                // ══════════════════════════════════════════════════════
                //  SECTION: PROGRESS
                // ══════════════════════════════════════════════════════

                Item { width: parent.width; height: 22 }

                Text {
                    x: 16
                    text: "PROGRESS"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2.5
                    color: cDim
                }

                Item { width: parent.width; height: 10 }

                // Count label
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.filesTotal > 0
                          ? root.filesCompleted + " / " + root.filesTotal + " files analysed"
                          : "Waiting to start"
                    color: root.isRunning ? cGreen : cMuted
                    font.pixelSize: 13
                    font.family:    "Segoe UI"
                }

                Item { width: parent.width; height: 8 }

                // Progress bar
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:  parent.width - 32
                    height: 10
                    radius: 5
                    color:  "#0a1e0a"
                    border.color: cGreen
                    border.width: 1

                    Rectangle {
                        width: root.filesTotal > 0
                               ? Math.min(parent.width * root.filesCompleted / root.filesTotal,
                                          parent.width)
                               : 0
                        height: parent.height
                        radius: parent.radius
                        color:  root.auditDone ? cTeal : cGreen
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Item { width: parent.width; height: 10 }

                // Status text
                Text {
                    id: statusText
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32
                    text:  "Select a folder and press Start Audit"
                    color: root.auditDone ? cTeal : cDim
                    font.pixelSize: 12
                    font.family:    "Segoe UI"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                Item { width: parent.width; height: 14 }

                // Button row: Start / Cancel / View Report
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    WbButton {
                        label:     "Start Audit"
                        accent:    cGreen
                        isEnabled: root.selectedFolder !== "" && !root.isRunning
                        onWbClicked: {
                            root.auditDone      = false
                            root.filesCompleted = 0
                            root.filesTotal     = 0
                            root.isRunning      = true
                            statusText.text     = "Starting\u2026"
                            qualityAuditBackend.startAudit(root.selectedFolder)
                        }
                    }

                    WbButton {
                        label:   "Cancel"
                        accent:  cRed
                        visible: root.isRunning
                        onWbClicked: qualityAuditBackend.cancelAudit()
                    }

                    WbButton {
                        label:     "View Report"
                        accent:    cCyan
                        visible:   root.auditDone
                        isEnabled: root.lastReportPath !== ""
                        onWbClicked: qualityAuditBackend.openReport(root.lastReportPath)
                    }
                }

                Item { width: parent.width; height: 22 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32; height: 1
                    color: cGreen; opacity: 0.18
                }

                // ══════════════════════════════════════════════════════
                //  SECTION: PREVIOUS REPORTS
                // ══════════════════════════════════════════════════════

                Item { width: parent.width; height: 22 }

                Text {
                    x: 16
                    text: "PREVIOUS REPORTS"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2.5
                    color: cDim
                }

                Item { width: parent.width; height: 10 }

                // Dropdown
                ComboBox {
                    id: reportCombo
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:   parent.width - 32
                    height:  36
                    model:   root.reportNames

                    background: Rectangle {
                        radius: 6
                        color:  cDark
                        border.color: root.reportNames.length > 0 ? cGreen : cDim
                        border.width: 1
                    }

                    contentItem: Text {
                        leftPadding: 10
                        text:  reportCombo.count > 0
                               ? (reportCombo.displayText || "")
                               : "No reports found"
                        color: reportCombo.count > 0 ? cMuted : cDim
                        font.pixelSize: 11
                        font.family:    "Segoe UI"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    delegate: ItemDelegate {
                        width: reportCombo.width
                        contentItem: Text {
                            text:  modelData || ""
                            color: cMuted
                            font.pixelSize: 11
                            font.family:    "Segoe UI"
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                        background: Rectangle {
                            color: parent.highlighted ? "#1a3a0a" : cDark
                        }
                        highlighted: reportCombo.highlightedIndex === index
                    }

                    popup: Popup {
                        y:       reportCombo.height + 2
                        width:   reportCombo.width
                        padding: 0
                        background: Rectangle {
                            color:  cDark
                            border.color: cGreen
                            border.width: 1
                            radius: 6
                        }
                        contentItem: ListView {
                            clip:           true
                            implicitHeight: Math.min(contentHeight, 200)
                            model:          reportCombo.delegateModel
                            ScrollBar.vertical: ScrollBar {}
                        }
                    }
                }

                Item { width: parent.width; height: 10 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    WbButton {
                        label:     "View Selected"
                        accent:    cCyan
                        isEnabled: root.reportPaths.length > 0 &&
                                   reportCombo.currentIndex >= 0
                        onWbClicked: {
                            var idx = reportCombo.currentIndex
                            if (idx >= 0 && idx < root.reportPaths.length) {
                                qualityAuditBackend.openReport(root.reportPaths[idx])
                            }
                        }
                    }

                    WbButton {
                        label:  "Refresh"
                        accent: cDim
                        onWbClicked: refreshReports()
                    }
                }

                Item { width: parent.width; height: 22 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32; height: 1
                    color: cGreen; opacity: 0.18
                }

                // ══════════════════════════════════════════════════════
                //  SECTION: HELP
                // ══════════════════════════════════════════════════════

                Item { width: parent.width; height: 22 }

                WbButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    label:  "? Help"
                    accent: cMuted
                    onWbClicked: qualityAuditBackend.openHelp()
                }

                Item { width: parent.width; height: 30 }
            }
        }
    }

    // ── Inline button component (matches FFMPEG workbench style) ──────────
    component WbButton: Rectangle {
        property string label:     ""
        property color  accent:    "#39FF14"
        property bool   isEnabled: true

        signal wbClicked()

        implicitWidth:  130
        implicitHeight: 34
        radius: 6
        color: btnMa.pressed
               ? Qt.darker(accent, 3.5)
               : (btnMa.containsMouse ? Qt.darker(accent, 2.8) : "#111811")
        border.color: accent
        border.width: 1
        opacity: isEnabled ? 1.0 : 0.30

        Behavior on color { ColorAnimation { duration: 110 } }

        Text {
            anchors.centerIn: parent
            text:  parent.label
            color: parent.accent
            font.pixelSize: 12
            font.bold:      true
            font.letterSpacing: 1.5
            font.capitalization: Font.AllUppercase
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            enabled:      parent.isEnabled
            onClicked:    parent.wbClicked()
        }
    }

    // ── Initialise report list when panel loads ────────────────────────────
    Component.onCompleted: {
        refreshReports()
    }
}
