import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  MM_Report — Collection size chart + detail viewer
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: reportRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Press Load to fetch collections.\n\nFilter by category or device,\n" +
        "then click any bar to see\nits full file listing."

    readonly property color accent:  "#00BFFF"
    readonly property color bgDark:  "#080d14"

    // ── Data state ────────────────────────────────────────────────────────────
    property var    allData:             []
    property real   maxSize:             1
    property bool   loading:             false
    property string selectedCollection:  ""
    property string selectedTable:       "mediafiledetail"

    function categoryColor(cat) {
        if (cat === "Video")  return "#00BFFF"
        if (cat === "Music")  return "#00CC88"
        if (cat === "Images") return "#FFB300"
        return "#667788"
    }

    function formatSize(mb) {
        if (mb >= 1024) return (mb / 1024).toFixed(1) + " GB"
        return mb.toFixed(0) + " MB"
    }

    // ── Models ────────────────────────────────────────────────────────────────
    ListModel { id: chartModel  }
    ListModel { id: detailModel }
    ListModel { id: deviceModel }

    // ── Filter helpers ────────────────────────────────────────────────────────
    function applyFilters() {
        chartModel.clear()
        var catFilter = categoryBox.currentIndex === 0 ? "" : categoryBox.currentText
        var devFilter = deviceBox.currentIndex  === 0 ? "" : deviceBox.currentText
        var max = 0.001
        var filtered = []
        for (var i = 0; i < allData.length; i++) {
            var r = allData[i]
            if (catFilter && r.media_category !== catFilter) continue
            if (devFilter && r.device         !== devFilter)  continue
            filtered.push(r)
            if (r.total_size_mb > max) max = r.total_size_mb
        }
        reportRoot.maxSize = max
        for (var j = 0; j < filtered.length; j++)
            chartModel.append(filtered[j])

        // Clear detail if selection no longer visible
        var found = false
        for (var k = 0; k < chartModel.count; k++) {
            if (chartModel.get(k).collection_name === reportRoot.selectedCollection)
                { found = true; break }
        }
        if (!found) { reportRoot.selectedCollection = ""; detailModel.clear() }
    }

    function rebuildDeviceList() {
        var seen = {}
        var devices = []
        for (var i = 0; i < allData.length; i++) {
            var d = allData[i].device
            if (d && !seen[d]) { seen[d] = true; devices.push(d) }
        }
        devices.sort()
        deviceModel.clear()
        deviceModel.append({ text: "All Devices" })
        for (var j = 0; j < devices.length; j++)
            deviceModel.append({ text: devices[j] })
        deviceBox.currentIndex = 0
    }

    function loadDetail(collectionName) {
        detailModel.clear()
        var rows = mediaManagerBackend.get_collection_detail_sync(collectionName)
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i]
            detailModel.append({
                file_name:       r.file_name       || "",
                file_extension:  r.file_extension  || "",
                file_size_bytes: r.file_size_bytes  || 0,
                media_category:  r.media_category  || "",
                created_at:      r.created_at      || ""
            })
        }
    }

    // ── Backend connection ────────────────────────────────────────────────────
    Connections {
        target: mediaManagerBackend
        function onReportData(rows) {
            reportRoot.loading = false
            reportRoot.allData = rows
            rebuildDeviceList()
            applyFilters()
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // ── Title ─────────────────────────────────────────────────────────────
        Text {
            text: "Collection Report"
            color: reportRoot.accent
            font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.25) }

        // ── Controls row ──────────────────────────────────────────────────────
        RowLayout {
            width: parent.width
            spacing: 16

            // Table toggle — Media / Master
            Row {
                spacing: 0
                Repeater {
                    model: [
                        { label: "Media",  tbl: "mediafiledetail"  },
                        { label: "Master", tbl: "masterfiledetail" }
                    ]
                    delegate: Rectangle {
                        width: 90; height: 32
                        color: reportRoot.selectedTable === modelData.tbl
                               ? Qt.rgba(0,0.75,1,0.20) : "#080d14"
                        border.color: reportRoot.accent; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: reportRoot.selectedTable === modelData.tbl
                                   ? reportRoot.accent : "#445566"
                            font.pixelSize: 13; font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                reportRoot.selectedTable = modelData.tbl
                                reportRoot.selectedCollection = ""
                                detailModel.clear()
                            }
                        }
                    }
                }
            }

            // Category filter
            Row {
                spacing: 6
                Text {
                    text: "Category:"; color: "#445566"; font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
                ComboBox {
                    id: categoryBox
                    width: 110; height: 32
                    model: ["All", "Video", "Music", "Images"]
                    font.pixelSize: 13
                    onCurrentIndexChanged: if (reportRoot.allData.length) applyFilters()
                    contentItem: Text {
                        leftPadding: 8; text: categoryBox.displayText
                        color: "white"; font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "#0a1a2a"
                        border.color: categoryBox.activeFocus ? reportRoot.accent : "#1e3050"
                        border.width: 1; radius: 4
                    }
                    popup: Popup {
                        y: categoryBox.height; width: categoryBox.width
                        implicitHeight: contentItem.implicitHeight; padding: 1
                        contentItem: ListView {
                            clip: true; implicitHeight: contentHeight
                            model: categoryBox.popup.visible ? categoryBox.delegateModel : null
                        }
                        background: Rectangle {
                            color: "#0a1a2a"; border.color: reportRoot.accent
                            border.width: 1; radius: 4
                        }
                    }
                    delegate: ItemDelegate {
                        width: categoryBox.width
                        contentItem: Text {
                            text: modelData; color: "white"; font.pixelSize: 12
                            leftPadding: 8; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: highlighted ? "#003355" : "transparent" }
                        highlighted: categoryBox.highlightedIndex === index
                    }
                }
            }

            // Device filter
            Row {
                spacing: 6
                Text {
                    text: "Device:"; color: "#445566"; font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
                ComboBox {
                    id: deviceBox
                    width: 150; height: 32
                    model: deviceModel
                    textRole: "text"
                    font.pixelSize: 13
                    onCurrentIndexChanged: if (reportRoot.allData.length) applyFilters()
                    contentItem: Text {
                        leftPadding: 8; text: deviceBox.displayText
                        color: "white"; font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "#0a1a2a"
                        border.color: deviceBox.activeFocus ? reportRoot.accent : "#1e3050"
                        border.width: 1; radius: 4
                    }
                    popup: Popup {
                        y: deviceBox.height; width: deviceBox.width
                        implicitHeight: contentItem.implicitHeight; padding: 1
                        contentItem: ListView {
                            clip: true; implicitHeight: contentHeight
                            model: deviceBox.popup.visible ? deviceBox.delegateModel : null
                        }
                        background: Rectangle {
                            color: "#0a1a2a"; border.color: reportRoot.accent
                            border.width: 1; radius: 4
                        }
                    }
                    delegate: ItemDelegate {
                        width: deviceBox.width
                        contentItem: Text {
                            text: model.text; color: "white"; font.pixelSize: 12
                            leftPadding: 8; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: highlighted ? "#003355" : "transparent" }
                        highlighted: deviceBox.highlightedIndex === index
                    }
                }
            }

            // Expanding spacer
            Item { Layout.fillWidth: true }

            // Load button
            Rectangle {
                width: 110; height: 32; radius: 5
                color: loadMa.pressed ? "#003344" : (loadMa.containsMouse ? "#005566" : "#004455")
                border.color: reportRoot.accent; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: reportRoot.loading ? "Loading…" : "⟳  Load"
                    color: reportRoot.accent; font.pixelSize: 13; font.bold: true
                }
                MouseArea {
                    id: loadMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        reportRoot.loading = true
                        reportRoot.selectedCollection = ""
                        detailModel.clear()
                        mediaManagerBackend.load_report(reportRoot.selectedTable, false)
                    }
                }
            }
        }

        // ── Summary strip ─────────────────────────────────────────────────────
        Text {
            visible: chartModel.count > 0
            text: chartModel.count + " collection" + (chartModel.count === 1 ? "" : "s")
                  + (reportRoot.selectedCollection !== ""
                     ? "   ·   Selected: " + reportRoot.selectedCollection : "")
            color: "#445566"; font.pixelSize: 12
        }

        // ── Main body: chart left | detail right ──────────────────────────────
        Row {
            width: parent.width
            height: reportRoot.height - y - 20
            spacing: 10

            // ── LEFT: bar chart ───────────────────────────────────────────────
            Rectangle {
                width: parent.width * 0.55
                height: parent.height
                color: reportRoot.bgDark
                border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1
                radius: 4; clip: true

                Text {
                    anchors.centerIn: parent
                    visible: chartModel.count === 0 && !reportRoot.loading
                    text: "Press  ⟳ Load  to fetch collections"
                    color: "#334455"; font.pixelSize: 15; font.italic: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: reportRoot.loading
                    text: "Loading…"
                    color: "#445566"; font.pixelSize: 15
                }

                ListView {
                    id: chartList
                    anchors.fill: parent; anchors.margins: 8
                    clip: true; model: chartModel; spacing: 5
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Item {
                        width: chartList.width
                        height: 40

                        readonly property bool isSelected:
                            model.collection_name === reportRoot.selectedCollection
                        readonly property real barFraction:
                            reportRoot.maxSize > 0
                            ? Math.max(model.total_size_mb / reportRoot.maxSize, 0.005) : 0
                        readonly property color barColor:
                            categoryColor(model.media_category)

                        // Row hover/selection background
                        Rectangle {
                            anchors.fill: parent; radius: 4
                            color: isSelected
                                   ? Qt.rgba(0, 0.75, 1, 0.12)
                                   : (rowMa.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent")
                            border.color: isSelected ? reportRoot.accent : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        // Fixed-width right column: size label
                        Text {
                            id: sizeLabel
                            width: 68
                            anchors.right: parent.right; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: formatSize(model.total_size_mb)
                            color: isSelected ? barColor : "#556677"
                            font.pixelSize: 11; font.bold: isSelected
                            horizontalAlignment: Text.AlignRight
                        }

                        // Bar track — full width minus size label
                        Item {
                            anchors.left:  parent.left;   anchors.leftMargin: 4
                            anchors.right: sizeLabel.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: 28
                            clip: true

                            // Track background
                            Rectangle {
                                anchors.fill: parent; radius: 4
                                color: "#0e1c2e"
                                border.color: Qt.rgba(0,0.75,1,0.12); border.width: 1
                            }

                            // Filled portion
                            Rectangle {
                                id: filledBar
                                width: Math.max(parent.width * barFraction, 6)
                                height: parent.height; radius: 4
                                color: barColor
                                opacity: isSelected ? 1.0 : 0.70
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                // Highlight stripe
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius
                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.22) }
                                        GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.0)  }
                                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.15) }
                                    }
                                }
                            }

                            // Collection name — dark text overlaid on bar
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 8
                                width: parent.width - 8
                                text: model.collection_name
                                color: "#0a1520"
                                font.pixelSize: 12
                                elide: Text.ElideMiddle
                                z: 1
                            }

                            // File count — shown after the filled bar (dim, small)
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 6
                                text: model.file_count + " files"
                                color: Qt.rgba(0,0,0,0.45)
                                font.pixelSize: 10
                                z: 1
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                reportRoot.selectedCollection = model.collection_name
                                loadDetail(model.collection_name)
                            }
                        }
                    }
                }
            }

            // ── RIGHT: detail panel ───────────────────────────────────────────
            Rectangle {
                width: parent.width * 0.45 - 10
                height: parent.height
                color: reportRoot.bgDark
                border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1
                radius: 4; clip: true

                Column {
                    anchors.fill: parent

                    // Header
                    Rectangle {
                        width: parent.width; height: 36
                        color: "#060d18"
                        border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            text: reportRoot.selectedCollection !== ""
                                  ? reportRoot.selectedCollection
                                  : "← Click a bar to view detail"
                            color: reportRoot.selectedCollection !== ""
                                   ? reportRoot.accent : "#334455"
                            font.pixelSize: 12; font.bold: true
                            elide: Text.ElideMiddle
                        }
                    }

                    // File count
                    Rectangle {
                        visible: detailModel.count > 0
                        width: parent.width; height: 24; color: "#080f1a"
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            text: detailModel.count + " files"
                            color: "#445566"; font.pixelSize: 11
                        }
                    }

                    // Empty state
                    Text {
                        width: parent.width
                        visible: detailModel.count === 0
                        text: reportRoot.selectedCollection === ""
                              ? "No collection selected" : "Loading…"
                        color: "#334455"; font.pixelSize: 14; font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 40
                    }

                    // File list
                    ListView {
                        id: detailList
                        width: parent.width
                        height: reportRoot.height - 36 - 24 - 80
                        clip: true; model: detailModel; spacing: 2
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: detailList.width
                            height: fileCol.implicitHeight + 8
                            color: index % 2 === 0 ? "#0a1520" : "#080d18"

                            Column {
                                id: fileCol
                                anchors {
                                    left: parent.left; leftMargin: 10
                                    right: parent.right; rightMargin: 6
                                    top: parent.top; topMargin: 4
                                }
                                spacing: 2

                                Row {
                                    spacing: 6; width: parent.width
                                    Text {
                                        text: model.file_name
                                        color: "#AABBCC"; font.pixelSize: 12
                                        width: parent.width - extTag.width - 8
                                        elide: Text.ElideMiddle
                                    }
                                    Rectangle {
                                        id: extTag
                                        width: extTagTxt.implicitWidth + 8
                                        height: 16; radius: 2
                                        color: "#0d1e30"
                                        border.color: categoryColor(model.media_category)
                                        border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            id: extTagTxt
                                            anchors.centerIn: parent
                                            text: model.file_extension
                                            color: categoryColor(model.media_category)
                                            font.pixelSize: 10; font.family: "Consolas"
                                        }
                                    }
                                }

                                Row {
                                    spacing: 14
                                    Text {
                                        text: formatSize(model.file_size_bytes / 1048576.0)
                                        color: "#445566"; font.pixelSize: 11
                                    }
                                    Text {
                                        text: model.created_at || ""
                                        color: "#334455"; font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
