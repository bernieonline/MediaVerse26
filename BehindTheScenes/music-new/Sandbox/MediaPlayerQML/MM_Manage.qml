import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  MM_Manage — Collection management actions (Remove / Delete / Move / Transfer)
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: manageRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Select a collection, then choose an action.\n\n" +
        "Remove  — clears DB records, files stay on disk.\n" +
        "Delete  — removes DB records AND disk files.\n" +
        "Move    — relocates files and updates DB paths.\n" +
        "Transfer — copies records to the other table."

    readonly property color accent:   "#00BFFF"
    readonly property color bgDark:   "#080d14"
    readonly property color dangerC:  "#FF4444"

    // ── State ─────────────────────────────────────────────────────────────────
    property bool   busy:            false
    property string lastResult:      ""
    property bool   lastOk:          true

    // ── Models ────────────────────────────────────────────────────────────────
    ListModel { id: collNames   }
    ListModel { id: activityLog }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function currentTable() {
        return tableMaster.checked ? "masterfiledetail" : "mediafiledetail"
    }

    function otherTable() {
        return tableMaster.checked ? "mediafiledetail" : "masterfiledetail"
    }

    function selectedCollection() {
        return collBox.currentIndex > 0 ? collNames.get(collBox.currentIndex).text : ""
    }

    function loadCollectionNames() {
        var names = mediaManagerBackend.get_collection_names(currentTable())
        collNames.clear()
        collNames.append({ text: "— select collection —" })
        for (var i = 0; i < names.length; i++)
            collNames.append({ text: names[i] })
        collBox.currentIndex = 0
    }

    function logActivity(msg, ok) {
        var ts = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss")
        activityLog.insert(0, { message: "[" + ts + "]  " + msg, success: ok })
        if (activityLog.count > 50) activityLog.remove(activityLog.count - 1)
    }

    // ── Backend signals ───────────────────────────────────────────────────────
    Connections {
        target: mediaManagerBackend

        function onOperationDone(opName, ok) {
            manageRoot.busy = false
            manageRoot.lastOk = ok
            var label = ({ remove: "Remove", delete: "Delete",
                           move: "Move", transfer: "Transfer" })[opName] || opName
            manageRoot.lastResult = label + (ok ? " completed successfully." : " failed — check log.")
            logActivity(label + " — " + (ok ? "OK" : "FAILED"), ok)
            if (ok) loadCollectionNames()
        }

        function onStatusMessage(msg) {
            logActivity(msg, true)
        }
    }

    Component.onCompleted: loadCollectionNames()

    // ── Confirm popup (shared) ────────────────────────────────────────────────
    Popup {
        id: confirmPopup
        anchors.centerIn: parent
        width: 460; height: confirmCol.implicitHeight + 48
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape

        property string title:   ""
        property string body:    ""
        property bool   danger:  false
        property var    action:  null

        background: Rectangle {
            color: "#0a1520"; radius: 8
            border.color: confirmPopup.danger ? manageRoot.dangerC : manageRoot.accent
            border.width: 2
        }

        Column {
            id: confirmCol
            anchors { left: parent.left; right: parent.right
                      top: parent.top; margins: 24 }
            spacing: 16

            Text {
                text: confirmPopup.title
                color: confirmPopup.danger ? manageRoot.dangerC : manageRoot.accent
                font.pixelSize: 16; font.bold: true
                width: parent.width; wrapMode: Text.WordWrap
            }

            Text {
                text: confirmPopup.body
                color: "#AABBCC"; font.pixelSize: 13
                width: parent.width; wrapMode: Text.WordWrap
            }

            Row {
                spacing: 12; anchors.right: parent.right

                Rectangle {
                    width: 90; height: 34; radius: 5
                    color: cancelMa.containsMouse ? "#1a2a3a" : "#0f1e2e"
                    border.color: "#334455"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Cancel"
                           color: "#667788"; font.pixelSize: 13 }
                    MouseArea {
                        id: cancelMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: confirmPopup.close()
                    }
                }

                Rectangle {
                    width: 110; height: 34; radius: 5
                    color: confirmPopup.danger
                           ? (proceedMa.containsMouse ? "#8b0000" : "#660000")
                           : (proceedMa.containsMouse ? "#005566" : "#004455")
                    border.color: confirmPopup.danger ? manageRoot.dangerC : manageRoot.accent
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "Confirm"
                           color: confirmPopup.danger ? manageRoot.dangerC : manageRoot.accent
                           font.pixelSize: 13; font.bold: true }
                    MouseArea {
                        id: proceedMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            confirmPopup.close()
                            if (confirmPopup.action) confirmPopup.action()
                        }
                    }
                }
            }
        }
    }

    // ── Move — folder path popup ──────────────────────────────────────────────
    Popup {
        id: movePopup
        anchors.centerIn: parent
        width: 500; height: moveCol.implicitHeight + 48
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: "#0a1520"; radius: 8
            border.color: manageRoot.accent; border.width: 2
        }

        Column {
            id: moveCol
            anchors { left: parent.left; right: parent.right
                      top: parent.top; margins: 24 }
            spacing: 16

            Text {
                text: "Move Collection"
                color: manageRoot.accent; font.pixelSize: 16; font.bold: true
            }

            Text {
                text: "Enter the destination folder path.\nFiles will be moved on disk and DB paths updated."
                color: "#AABBCC"; font.pixelSize: 13
                width: parent.width; wrapMode: Text.WordWrap
            }

            TextField {
                id: pathField
                width: parent.width; height: 36
                color: "white"; font.pixelSize: 13; font.family: "Consolas"
                placeholderText: "e.g.  T:\\NewLocation\\Movies"
                selectByMouse: true; leftPadding: 10
                background: Rectangle {
                    color: "#060f1a"; radius: 4
                    border.color: pathField.activeFocus ? manageRoot.accent : "#1e3050"
                    border.width: 1
                }
                Keys.onReturnPressed: doMove()
            }

            Row {
                spacing: 12; anchors.right: parent.right

                Rectangle {
                    width: 90; height: 34; radius: 5
                    color: moveCancelMa.containsMouse ? "#1a2a3a" : "#0f1e2e"
                    border.color: "#334455"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Cancel"
                           color: "#667788"; font.pixelSize: 13 }
                    MouseArea {
                        id: moveCancelMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: movePopup.close()
                    }
                }

                Rectangle {
                    width: 110; height: 34; radius: 5
                    color: moveProceedMa.containsMouse ? "#005566" : "#004455"
                    border.color: manageRoot.accent; border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "Move"
                           color: manageRoot.accent; font.pixelSize: 13; font.bold: true }
                    MouseArea {
                        id: moveProceedMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: doMove()
                    }
                }
            }
        }

        function doMove() {
            var dest = pathField.text.trim()
            if (!dest) return
            movePopup.close()
            manageRoot.busy = true
            mediaManagerBackend.move_collection(currentTable(), manageRoot.selectedCollection(), dest)
            pathField.text = ""
        }
    }

    // ── Main layout ───────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Title
        Text {
            text: "Manage Collections"
            color: manageRoot.accent
            font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.25) }

        // ── Collection selector ───────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 90
            color: "#060d18"
            border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1; radius: 4

            Column {
                anchors.fill: parent; anchors.margins: 12; spacing: 8

                // Table toggle
                Row {
                    spacing: 0
                    Repeater {
                        model: ["Media", "Master"]
                        delegate: Rectangle {
                            width: 80; height: 26
                            color: (modelData === "Master") === tableMaster.checked
                                   ? Qt.rgba(0,0.75,1,0.18) : "#080d14"
                            border.color: manageRoot.accent; border.width: 1
                            Text {
                                anchors.centerIn: parent; text: modelData
                                color: (modelData === "Master") === tableMaster.checked
                                       ? manageRoot.accent : "#445566"
                                font.pixelSize: 12; font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    tableMaster.checked = (modelData === "Master")
                                    loadCollectionNames()
                                }
                            }
                        }
                    }
                }

                // Collection dropdown
                ComboBox {
                    id: collBox
                    width: parent.width; height: 32
                    model: collNames; textRole: "text"
                    font.pixelSize: 12
                    contentItem: Text {
                        leftPadding: 8; text: collBox.displayText
                        color: collBox.currentIndex > 0 ? "white" : "#445566"
                        font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideMiddle
                    }
                    background: Rectangle {
                        color: "#0a1a2a"
                        border.color: collBox.activeFocus ? manageRoot.accent : "#1e3050"
                        border.width: 1; radius: 4
                    }
                    popup: Popup {
                        y: collBox.height; width: collBox.width
                        implicitHeight: Math.min(contentItem.implicitHeight, 300); padding: 1
                        contentItem: ListView {
                            clip: true; implicitHeight: contentHeight
                            model: collBox.popup.visible ? collBox.delegateModel : null
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        }
                        background: Rectangle {
                            color: "#0a1a2a"; border.color: manageRoot.accent
                            border.width: 1; radius: 4
                        }
                    }
                    delegate: ItemDelegate {
                        width: collBox.width
                        contentItem: Text {
                            text: model.text; color: "white"; font.pixelSize: 11
                            leftPadding: 8; verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                        }
                        background: Rectangle { color: highlighted ? "#003355" : "transparent" }
                        highlighted: collBox.highlightedIndex === index
                    }
                }
            }
        }

        // Hidden state
        CheckBox { id: tableMaster; visible: false; checked: false }

        // ── Action buttons ────────────────────────────────────────────────────
        Row {
            spacing: 12
            enabled: manageRoot.selectedCollection() !== "" && !manageRoot.busy

            // REMOVE
            Rectangle {
                width: 140; height: 70; radius: 6
                color: removeMa.containsMouse ? "#0d2035" : "#080d14"
                border.color: manageRoot.accent; border.width: 1
                opacity: parent.enabled ? 1.0 : 0.35
                Behavior on color { ColorAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "⊖"; color: manageRoot.accent; font.pixelSize: 22 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "Remove"; color: manageRoot.accent
                           font.pixelSize: 13; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "DB records only"; color: "#445566"; font.pixelSize: 10 }
                }
                MouseArea {
                    id: removeMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var coll = manageRoot.selectedCollection()
                        confirmPopup.title  = "Remove Collection"
                        confirmPopup.body   = "Remove all DB records for:\n\n\"" + coll + "\"\n\nFiles on disk will NOT be deleted."
                        confirmPopup.danger = false
                        confirmPopup.action = function() {
                            manageRoot.busy = true
                            mediaManagerBackend.remove_collection(currentTable(), coll)
                        }
                        confirmPopup.open()
                    }
                }
            }

            // DELETE
            Rectangle {
                width: 140; height: 70; radius: 6
                color: deleteMa.containsMouse ? "#2a0808" : "#080d14"
                border.color: manageRoot.dangerC; border.width: 1
                opacity: parent.enabled ? 1.0 : 0.35
                Behavior on color { ColorAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "⊗"; color: manageRoot.dangerC; font.pixelSize: 22 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "Delete"; color: manageRoot.dangerC
                           font.pixelSize: 13; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "DB + disk files"; color: "#664444"; font.pixelSize: 10 }
                }
                MouseArea {
                    id: deleteMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var coll = manageRoot.selectedCollection()
                        confirmPopup.title  = "⚠  Delete Collection"
                        confirmPopup.body   = "This will permanently delete DB records AND all files on disk for:\n\n\"" + coll + "\"\n\nThis cannot be undone."
                        confirmPopup.danger = true
                        confirmPopup.action = function() {
                            manageRoot.busy = true
                            mediaManagerBackend.delete_collection(currentTable(), coll)
                        }
                        confirmPopup.open()
                    }
                }
            }

            // MOVE
            Rectangle {
                width: 140; height: 70; radius: 6
                color: moveMa.containsMouse ? "#0d2035" : "#080d14"
                border.color: manageRoot.accent; border.width: 1
                opacity: parent.enabled ? 1.0 : 0.35
                Behavior on color { ColorAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "⇄"; color: manageRoot.accent; font.pixelSize: 22 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "Move"; color: manageRoot.accent
                           font.pixelSize: 13; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "Relocate on disk"; color: "#445566"; font.pixelSize: 10 }
                }
                MouseArea {
                    id: moveMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: movePopup.open()
                }
            }

            // TRANSFER
            Rectangle {
                width: 140; height: 70; radius: 6
                color: transferMa.containsMouse ? "#0d2035" : "#080d14"
                border.color: manageRoot.accent; border.width: 1
                opacity: parent.enabled ? 1.0 : 0.35
                Behavior on color { ColorAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "⇅"; color: manageRoot.accent; font.pixelSize: 22 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: "Transfer"; color: manageRoot.accent
                           font.pixelSize: 13; font.bold: true }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tableMaster.checked ? "Master → Media" : "Media → Master"
                        color: "#445566"; font.pixelSize: 10
                    }
                }
                MouseArea {
                    id: transferMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var coll  = manageRoot.selectedCollection()
                        var fromT = currentTable()
                        var toT   = otherTable()
                        var label = tableMaster.checked ? "Master → Media" : "Media → Master"
                        confirmPopup.title  = "Transfer Collection"
                        confirmPopup.body   = "Copy records for:\n\n\"" + coll + "\"\n\nfrom " + fromT + " \u2192 " + toT + ".\n\nOriginal records remain in source table."
                        confirmPopup.danger = false
                        confirmPopup.action = function() {
                            manageRoot.busy = true
                            mediaManagerBackend.transfer_collection(fromT, toT, coll)
                        }
                        confirmPopup.open()
                    }
                }
            }
        }

        // ── Status bar ────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 34; radius: 4
            color: "#060d18"
            border.color: Qt.rgba(0,0.75,1,0.12); border.width: 1
            visible: manageRoot.lastResult !== "" || manageRoot.busy

            Row {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: manageRoot.busy
                    text: "Working…"
                    color: manageRoot.accent; font.pixelSize: 13; font.italic: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !manageRoot.busy && manageRoot.lastResult !== ""
                    text: manageRoot.lastResult
                    color: manageRoot.lastOk ? "#44CC88" : manageRoot.dangerC
                    font.pixelSize: 13
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.10) }

        // ── Activity log ──────────────────────────────────────────────────────
        Text {
            text: "Activity Log"
            color: "#445566"; font.pixelSize: 12; font.bold: true
        }

        Rectangle {
            width: parent.width
            height: manageRoot.height - y - 20
            color: manageRoot.bgDark
            border.color: Qt.rgba(0,0.75,1,0.12); border.width: 1; radius: 4; clip: true

            Text {
                anchors.centerIn: parent
                visible: activityLog.count === 0
                text: "No activity yet"
                color: "#223344"; font.pixelSize: 13; font.italic: true
            }

            ListView {
                anchors.fill: parent; anchors.margins: 8
                clip: true; model: activityLog; spacing: 3
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Text {
                    width: ListView.view.width
                    text: model.message
                    color: model.success ? "#667788" : manageRoot.dangerC
                    font.pixelSize: 11; font.family: "Consolas"
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
