import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs

// ─────────────────────────────────────────────────────────────────────────────
//  QualityAuditView — Media Info Reporting panel
//
//  Centred modal panel over a static movie poster backdrop.
//  Context property required: qualityAuditBackend (QualityAuditBackend)
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── State ─────────────────────────────────────────────────────────────────
    property string selectedFolder:  ""
    property string displayFolder:   "No folder selected"
    property int    filesCompleted:  0
    property int    filesTotal:      0
    property bool   isRunning:       false
    property bool   auditDone:       false
    property string lastReportPath:  ""
    property var    reportPaths:     []
    property var    reportNames:     []

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color green:     "#39FF14"
    readonly property color panelBg:   "#06101c"
    readonly property color borderCol: "#39FF14"
    readonly property color bodyBg:    "#080f18"
    readonly property color cMuted:    "#aaccbb"
    readonly property color cDim:      "#4a6070"
    readonly property color cCyan:     "#00BFFF"
    readonly property color cRed:      "#FF5555"
    readonly property color cTeal:     "#3ea87a"

    // ── Helpers ───────────────────────────────────────────────────────────────
    function refreshReports() {
        var paths = qualityAuditBackend.getReportList()
        root.reportPaths = paths
        var names = []
        for (var i = 0; i < paths.length; i++) names.push(formatReportName(paths[i]))
        root.reportNames = names
        if (reportCombo.currentIndex >= paths.length && paths.length > 0)
            reportCombo.currentIndex = 0
    }

    function formatReportName(path) {
        if (!path) return ""
        var fn = path.split(/[\/\\]/).pop()
        var m  = fn.match(/^QA_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})\d{2}_(.+)\.html$/)
        if (m) return m[1]+"-"+m[2]+"-"+m[3]+"  "+m[4]+":"+m[5]+"  —  "+m[6].replace(/_/g," ")
        return fn
    }

    // ── Folder dialog ─────────────────────────────────────────────────────────
    FolderDialog {
        id: folderPicker; title: "Select Folder to Audit"
        onAccepted: {
            var raw = folderPicker.selectedFolder.toString()
            root.selectedFolder = raw
            root.displayFolder  = raw.replace(/^file:\/\/\//, "").replace(/\//g, "\\")
            root.auditDone      = false; root.filesCompleted = 0; root.filesTotal = 0
            statusText.text     = "Folder selected. Press Start Audit to begin."
        }
    }

    // ── Backend connections ───────────────────────────────────────────────────
    Connections {
        target: qualityAuditBackend

        function onProgressChanged(completed, total) {
            root.filesCompleted = completed; root.filesTotal = total
        }
        function onAuditComplete(reportPath) {
            root.isRunning = false; root.auditDone = true; root.lastReportPath = reportPath
            refreshReports(); statusText.text = "\u2713 Complete \u2014 report saved"
        }
        function onStatusMessage(msg) {
            statusText.text = msg
            if (msg === "Audit cancelled." || msg.indexOf("Error:") === 0)
                root.isRunning = false
        }
    }

    // ── Outer glow ring ───────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width: panel.width + 10; height: panel.height + 10; radius: 20
        color: "transparent"; border.color: root.green; border.width: 1; opacity: 0.07; z: 1
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
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: parent.radius; color: parent.color }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: "MEDIA INFO REPORTING"
                font.family: "Segoe UI"; font.pixelSize: 26; font.bold: true; font.letterSpacing: 4
                color: root.green
            }
        }

        Rectangle {
            id: divider
            anchors.top: titleBar.bottom
            anchors.left: parent.left; anchors.leftMargin: 24
            anchors.right: parent.right; anchors.rightMargin: 24
            height: 1; color: root.borderCol; opacity: 0.30
        }

        // ── Scrollable content ────────────────────────────────────────────────
        Flickable {
            anchors.top:    divider.bottom; anchors.topMargin: 4
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            contentHeight:  mainCol.implicitHeight + 28
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: mainCol
                width: parent.width
                spacing: 0

                // ── SCAN FOLDER ───────────────────────────────────────────────
                Item { width: parent.width; height: 24 }

                Text { x: 24; text: "SCAN FOLDER"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 2.5; color: root.cDim }

                Item { width: parent.width; height: 10 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 48; height: 58; radius: 8
                    color: root.bodyBg
                    border.color: root.selectedFolder !== "" ? root.green : root.cDim
                    border.width: 1

                    Text {
                        anchors.fill: parent; anchors.margins: 12
                        text: root.displayFolder
                        color: root.selectedFolder !== "" ? root.cMuted : root.cDim
                        font.pixelSize: 16; font.family: "Consolas"
                        elide: Text.ElideLeft; verticalAlignment: Text.AlignVCenter
                    }
                }

                Item { width: parent.width; height: 12 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                    QaButton { label: "Browse\u2026"; accent: root.green; isEnabled: !root.isRunning; onQaClicked: folderPicker.open() }
                    QaButton { label: "Diagnose"; accent: root.cMuted; isEnabled: root.selectedFolder !== "" && !root.isRunning; onQaClicked: qualityAuditBackend.diagnoseFirst(root.selectedFolder) }
                }

                Item { width: parent.width; height: 24 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 48; height: 1; color: root.green; opacity: 0.18 }

                // ── PROGRESS ──────────────────────────────────────────────────
                Item { width: parent.width; height: 24 }

                Text { x: 24; text: "PROGRESS"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 2.5; color: root.cDim }

                Item { width: parent.width; height: 12 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.filesTotal > 0 ? root.filesCompleted + " / " + root.filesTotal + " files analysed" : "Waiting to start"
                    color: root.isRunning ? root.green : root.cMuted
                    font.pixelSize: 18; font.family: "Segoe UI"
                }

                Item { width: parent.width; height: 10 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 48; height: 14; radius: 7
                    color: "#0a1820"; border.color: root.green; border.width: 1

                    Rectangle {
                        width: root.filesTotal > 0 ? Math.min(parent.width * root.filesCompleted / root.filesTotal, parent.width) : 0
                        height: parent.height; radius: parent.radius
                        color: root.auditDone ? root.cTeal : root.green
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Item { width: parent.width; height: 12 }

                Text {
                    id: statusText
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 48
                    text: "Select a folder and press Start Audit"
                    color: root.auditDone ? root.cTeal : root.cDim
                    font.pixelSize: 16; font.family: "Segoe UI"
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                }

                Item { width: parent.width; height: 16 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                    QaButton {
                        label: "Start Audit"; accent: root.green
                        isEnabled: root.selectedFolder !== "" && !root.isRunning
                        onQaClicked: {
                            root.auditDone = false; root.filesCompleted = 0; root.filesTotal = 0
                            root.isRunning = true; statusText.text = "Starting\u2026"
                            qualityAuditBackend.startAudit(root.selectedFolder)
                        }
                    }
                    QaButton { label: "Cancel"; accent: root.cRed; visible: root.isRunning; onQaClicked: qualityAuditBackend.cancelAudit() }
                    QaButton { label: "View Report"; accent: root.cCyan; visible: root.auditDone; isEnabled: root.lastReportPath !== ""; onQaClicked: qualityAuditBackend.openReport(root.lastReportPath) }
                }

                Item { width: parent.width; height: 24 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 48; height: 1; color: root.green; opacity: 0.18 }

                // ── PREVIOUS REPORTS ──────────────────────────────────────────
                Item { width: parent.width; height: 24 }

                Text { x: 24; text: "PREVIOUS REPORTS"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 2.5; color: root.cDim }

                Item { width: parent.width; height: 12 }

                ComboBox {
                    id: reportCombo
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 48; height: 44
                    model: root.reportNames

                    background: Rectangle {
                        radius: 8; color: root.bodyBg
                        border.color: root.reportNames.length > 0 ? root.green : root.cDim
                        border.width: 1
                    }
                    contentItem: Text {
                        leftPadding: 12
                        text:  reportCombo.count > 0 ? (reportCombo.displayText || "") : "No reports found"
                        color: reportCombo.count > 0 ? root.cMuted : root.cDim
                        font.pixelSize: 16; font.family: "Segoe UI"
                        verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                    }
                    delegate: ItemDelegate {
                        width: reportCombo.width
                        contentItem: Text {
                            text: modelData || ""; color: root.cMuted
                            font.pixelSize: 15; font.family: "Segoe UI"
                            elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; leftPadding: 12
                        }
                        background: Rectangle { color: parent.highlighted ? "#0f2030" : root.bodyBg }
                        highlighted: reportCombo.highlightedIndex === index
                    }
                    popup: Popup {
                        y: reportCombo.height + 2; width: reportCombo.width; padding: 0
                        background: Rectangle { color: root.bodyBg; border.color: root.green; border.width: 1; radius: 8 }
                        contentItem: ListView {
                            clip: true; implicitHeight: Math.min(contentHeight, 240)
                            model: reportCombo.delegateModel
                            ScrollBar.vertical: ScrollBar {}
                        }
                    }
                }

                Item { width: parent.width; height: 12 }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                    QaButton {
                        label: "View Selected"; accent: root.cCyan
                        isEnabled: root.reportPaths.length > 0 && reportCombo.currentIndex >= 0
                        onQaClicked: {
                            var idx = reportCombo.currentIndex
                            if (idx >= 0 && idx < root.reportPaths.length)
                                qualityAuditBackend.openReport(root.reportPaths[idx])
                        }
                    }
                    QaButton { label: "Refresh"; accent: root.cDim; onQaClicked: refreshReports() }
                }

                Item { width: parent.width; height: 24 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 48; height: 1; color: root.green; opacity: 0.18 }

                // ── HELP ──────────────────────────────────────────────────────
                Item { width: parent.width; height: 24 }
                QaButton { anchors.horizontalCenter: parent.horizontalCenter; label: "? Help"; accent: root.cMuted; onQaClicked: qualityAuditBackend.openHelp() }
                Item { width: parent.width; height: 32 }
            }
        }
    }

    // ── Inline button component ───────────────────────────────────────────────
    component QaButton: Rectangle {
        property string label:     ""
        property color  accent:    "#39FF14"
        property bool   isEnabled: true

        signal qaClicked()

        implicitWidth:  150
        implicitHeight: 42
        radius: 8
        color: btnMa.pressed
               ? Qt.darker(accent, 3.5)
               : (btnMa.containsMouse ? Qt.darker(accent, 2.8) : "#0a1218")
        border.color: accent; border.width: 1
        opacity: isEnabled ? 1.0 : 0.30
        Behavior on color { ColorAnimation { duration: 110 } }

        Text {
            anchors.centerIn: parent; text: parent.label; color: parent.accent
            font.pixelSize: 16; font.bold: true; font.letterSpacing: 1.5
            font.capitalization: Font.AllUppercase
        }
        MouseArea { id: btnMa; anchors.fill: parent; hoverEnabled: true; enabled: parent.isEnabled; onClicked: parent.qaClicked() }
    }

    Component.onCompleted: { refreshReports() }
}
