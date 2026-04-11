import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  MM_DbEdit — 4 editable list panels side-by-side
//
//  Panels:
//    1. Media Types    (mediatypename)
//    2. Excluded Folders (excluded_folders)
//    3. Master Types   (mastertype)
//    4. Extensions     (mediatypes — extension + category)
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: dbEditRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Edit lookup lists stored in\nMediaManager2.\n\n" +
        "Make changes then press Save\nfor each panel."

    readonly property color accent:   "#00BFFF"
    readonly property color bgPanel:  "#0d1420"
    readonly property color bgRow:    "#111827"
    readonly property color bgRowAlt: "#0f1622"

    // ── Load all 4 lists when panel appears ───────────────────────────────────
    Component.onCompleted: {
        mediaManagerBackend.load_list("media_types")
        mediaManagerBackend.load_list("excluded_folders")
        mediaManagerBackend.load_list("master_types")
        mediaManagerBackend.load_list("extensions")
    }

    // ── Receive loaded data ───────────────────────────────────────────────────
    Connections {
        target: mediaManagerBackend

        function onListLoaded(listName, items) {
            if (listName === "media_types") {
                mediaTypesModel.clear()
                for (var i = 0; i < items.length; i++)
                    mediaTypesModel.append({ display: items[i]["media_type_name"] || items[i] })
            } else if (listName === "excluded_folders") {
                excludedModel.clear()
                for (var j = 0; j < items.length; j++)
                    excludedModel.append({ display: items[j] })
            } else if (listName === "master_types") {
                masterTypesModel.clear()
                for (var k = 0; k < items.length; k++)
                    masterTypesModel.append({ display: items[k]["master_type_name"] || items[k] })
            } else if (listName === "extensions") {
                extensionsModel.clear()
                for (var m = 0; m < items.length; m++)
                    extensionsModel.append({
                        ext:      items[m]["file_extension"] || "",
                        category: items[m]["media_category"]  || ""
                    })
            }
        }

        function onListSaved(listName, success) {
            // statusMessage is already emitted by the backend — nothing to do here
        }
    }

    // ── Data models ───────────────────────────────────────────────────────────
    ListModel { id: mediaTypesModel  }
    ListModel { id: excludedModel    }
    ListModel { id: masterTypesModel }
    ListModel { id: extensionsModel  }

    // ─────────────────────────────────────────────────────────────────────────
    //  Reusable single-column list edit panel
    // ─────────────────────────────────────────────────────────────────────────
    component ListPanel: Item {
        id: lp
        property string title:      ""
        property string listName:   ""
        property alias  model:      listView.model
        property string fieldHint:  "New entry…"
        property int    selectedIdx: -1

        function doAdd() {
            var v = addField.text.trim()
            if (v !== "") {
                lp.model.append({ display: v })
                addField.text = ""
                lp.selectedIdx = -1
            }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // Title bar
            Rectangle {
                width: parent.width; height: 38
                color: Qt.rgba(0, 0.75, 1.0, 0.10)
                border.color: Qt.rgba(0, 0.75, 1.0, 0.25); border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: lp.title
                    color: dbEditRoot.accent
                    font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.8
                    font.capitalization: Font.AllUppercase
                }
            }

            // List
            Rectangle {
                width: parent.width
                height: lp.height - 38 - 80
                color: dbEditRoot.bgPanel
                border.color: Qt.rgba(0, 0.75, 1.0, 0.12); border.width: 1
                clip: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    delegate: Rectangle {
                        width: listView.width; height: 32
                        color: lp.selectedIdx === index
                               ? Qt.rgba(0, 0.75, 1.0, 0.18)
                               : (index % 2 === 0 ? dbEditRoot.bgRow : dbEditRoot.bgRowAlt)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 10
                            text: model.display
                            color: lp.selectedIdx === index ? dbEditRoot.accent : "#CCCCCC"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: lp.selectedIdx = index
                        }
                    }

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }

            // Add / Remove / Save controls
            Rectangle {
                width: parent.width; height: 80
                color: "#0a0f18"
                border.color: Qt.rgba(0, 0.75, 1.0, 0.12); border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Text field + Add button
                    Row {
                        width: parent.width; spacing: 6
                        TextField {
                            id: addField
                            width: parent.width - 64
                            height: 30
                            placeholderText: lp.fieldHint
                            font.pixelSize: 13
                            color: "white"
                            background: Rectangle {
                                color: "#1a2233"
                                border.color: addField.activeFocus
                                              ? dbEditRoot.accent : "#334455"
                                border.width: 1; radius: 4
                            }
                            onAccepted: lp.doAdd()
                        }
                        Rectangle {
                            id: addBtn
                            width: 58; height: 30; radius: 4
                            color: addMa.pressed ? "#003355"
                                 : (addMa.containsMouse ? "#005577" : "#004466")
                            border.color: dbEditRoot.accent; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "+ Add"; color: dbEditRoot.accent; font.pixelSize: 13
                            }
                            MouseArea {
                                id: addMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: doAdd()
                            }
                        }
                    }

                    // Remove + Save buttons
                    Row {
                        width: parent.width; spacing: 6
                        Rectangle {
                            width: (parent.width - 6) / 2; height: 28; radius: 4
                            color: remMa.pressed ? "#330000"
                                 : (remMa.containsMouse ? "#550000" : "#3a0000")
                            border.color: "#FF5555"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Remove"; color: "#FF5555"; font.pixelSize: 13
                            }
                            MouseArea {
                                id: remMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (lp.selectedIdx >= 0 && lp.selectedIdx < lp.model.count) {
                                        lp.model.remove(lp.selectedIdx)
                                        lp.selectedIdx = -1
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: (parent.width - 6) / 2; height: 28; radius: 4
                            color: saveMa.pressed ? "#003322"
                                 : (saveMa.containsMouse ? "#005533" : "#003322")
                            border.color: "#00FF7F"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Save"; color: "#00FF7F"; font.pixelSize: 13
                            }
                            MouseArea {
                                id: saveMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    var arr = []
                                    for (var i = 0; i < lp.model.count; i++)
                                        arr.push(lp.model.get(i).display)
                                    mediaManagerBackend.save_list(lp.listName, arr)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Extensions panel (two-column: extension + category)
    // ─────────────────────────────────────────────────────────────────────────
    component ExtPanel: Item {
        id: ep
        property int selectedIdx: -1

        Column {
            anchors.fill: parent
            spacing: 0

            // Title bar
            Rectangle {
                width: parent.width; height: 38
                color: Qt.rgba(0, 0.75, 1.0, 0.10)
                border.color: Qt.rgba(0, 0.75, 1.0, 0.25); border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Extensions"
                    color: dbEditRoot.accent
                    font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.8
                    font.capitalization: Font.AllUppercase
                }
            }

            // Column headers
            Rectangle {
                width: parent.width; height: 26
                color: "#0a1020"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10
                    Text { width: parent.width * 0.4; text: "Extension"; color: "#667788"; font.pixelSize: 12 }
                    Text { width: parent.width * 0.6; text: "Category";  color: "#667788"; font.pixelSize: 12 }
                }
            }

            // List
            Rectangle {
                width: parent.width
                height: ep.height - 38 - 26 - 28 - 112
                color: dbEditRoot.bgPanel
                border.color: Qt.rgba(0, 0.75, 1.0, 0.12); border.width: 1
                clip: true

                ListView {
                    id: extListView
                    anchors.fill: parent
                    model: extensionsModel
                    delegate: Rectangle {
                        width: extListView.width; height: 30
                        color: ep.selectedIdx === index
                               ? Qt.rgba(0, 0.75, 1.0, 0.18)
                               : (index % 2 === 0 ? dbEditRoot.bgRow : dbEditRoot.bgRowAlt)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 10
                            Text {
                                width: parent.width * 0.4
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.ext
                                color: ep.selectedIdx === index ? dbEditRoot.accent : "#CCCCCC"
                                font.pixelSize: 13
                            }
                            Text {
                                width: parent.width * 0.6
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.category
                                color: ep.selectedIdx === index ? "#88DDFF" : "#999999"
                                font.pixelSize: 13
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: ep.selectedIdx = index
                        }
                    }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
            }

            // ── ADD NEW section header — clear break from the list above ────
            Rectangle {
                width: parent.width; height: 28
                color: "#060d18"
                border.color: Qt.rgba(0, 0.75, 1.0, 0.30); border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8

                    // Left rule
                    Rectangle {
                        width: 24; height: 1; color: Qt.rgba(0,0.75,1,0.35)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ADD NEW"
                        color: dbEditRoot.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.5
                        opacity: 0.75
                    }

                    Rectangle {
                        width: 24; height: 1; color: Qt.rgba(0,0.75,1,0.35)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Controls
            Rectangle {
                width: parent.width; height: 112
                color: "#080e1a"
                border.color: Qt.rgba(0, 0.75, 1.0, 0.12); border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Extension field with label
                    Row {
                        width: parent.width; spacing: 8
                        Text {
                            width: 42; anchors.verticalCenter: parent.verticalCenter
                            text: "Ext"; color: dbEditRoot.accent; font.pixelSize: 12
                            font.bold: true; opacity: 0.80
                            horizontalAlignment: Text.AlignRight
                        }
                        TextField {
                            id: extField
                            width: parent.width - 50
                            height: 28
                            placeholderText: ".mkv"
                            font.pixelSize: 13; color: "white"
                            background: Rectangle {
                                color: "#111c2e"
                                border.color: extField.activeFocus ? dbEditRoot.accent : "#1e3050"
                                border.width: extField.activeFocus ? 2 : 1; radius: 4
                            }
                        }
                    }

                    // Category field with label
                    Row {
                        width: parent.width; spacing: 8
                        Text {
                            width: 42; anchors.verticalCenter: parent.verticalCenter
                            text: "Type"; color: dbEditRoot.accent; font.pixelSize: 12
                            font.bold: true; opacity: 0.80
                            horizontalAlignment: Text.AlignRight
                        }
                        TextField {
                            id: catField
                            width: parent.width - 50
                            height: 28
                            placeholderText: "Video / Music / Images"
                            font.pixelSize: 13; color: "white"
                            background: Rectangle {
                                color: "#111c2e"
                                border.color: catField.activeFocus ? dbEditRoot.accent : "#1e3050"
                                border.width: catField.activeFocus ? 2 : 1; radius: 4
                            }
                        }
                    }

                    // Add / Remove / Save
                    Row {
                        width: parent.width; spacing: 6
                        Rectangle {
                            width: (parent.width - 12) / 3; height: 28; radius: 4
                            color: eAddMa.containsMouse ? "#005577" : "#004466"
                            border.color: dbEditRoot.accent; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: "+ Add"; color: dbEditRoot.accent; font.pixelSize: 13 }
                            MouseArea {
                                id: eAddMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    var e = extField.text.trim()
                                    var c = catField.text.trim()
                                    if (e !== "" && c !== "") {
                                        extensionsModel.append({ ext: e, category: c })
                                        extField.text = ""; catField.text = ""
                                        ep.selectedIdx = -1
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: (parent.width - 12) / 3; height: 28; radius: 4
                            color: eRemMa.containsMouse ? "#550000" : "#3a0000"
                            border.color: "#FF5555"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: "Remove"; color: "#FF5555"; font.pixelSize: 13 }
                            MouseArea {
                                id: eRemMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (ep.selectedIdx >= 0 && ep.selectedIdx < extensionsModel.count) {
                                        extensionsModel.remove(ep.selectedIdx)
                                        ep.selectedIdx = -1
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: (parent.width - 12) / 3; height: 28; radius: 4
                            color: eSaveMa.containsMouse ? "#005533" : "#003322"
                            border.color: "#00FF7F"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: "Save"; color: "#00FF7F"; font.pixelSize: 13 }
                            MouseArea {
                                id: eSaveMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    var arr = []
                                    for (var i = 0; i < extensionsModel.count; i++) {
                                        var r = extensionsModel.get(i)
                                        arr.push({ file_extension: r.ext, media_category: r.category })
                                    }
                                    mediaManagerBackend.save_list("extensions", arr)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  4-column layout
    // ─────────────────────────────────────────────────────────────────────────
    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        ListPanel {
            width:    (parent.width - 32) / 4
            height:   parent.height
            title:    "Media Types"
            listName: "media_types"
            model:    mediaTypesModel
            fieldHint: "e.g. Video"
        }

        ListPanel {
            width:    (parent.width - 32) / 4
            height:   parent.height
            title:    "Excluded Folders"
            listName: "excluded_folders"
            model:    excludedModel
            fieldHint: "e.g. @eaDir"
        }

        ListPanel {
            width:    (parent.width - 32) / 4
            height:   parent.height
            title:    "Master Types"
            listName: "master_types"
            model:    masterTypesModel
            fieldHint: "e.g. Clone"
        }

        ExtPanel {
            width:  (parent.width - 32) / 4
            height: parent.height
        }
    }
}
