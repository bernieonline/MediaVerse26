import QtQuick 2.15
import QtQuick.Controls 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  MM_DbSearch — Search both mediafiledetail and masterfiledetail
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: searchRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Search both collection tables\nby file name, path or\ncollection name.\n\n" +
        "Enter a partial name and\npress Search or hit Enter."

    readonly property color accent:  "#00BFFF"
    readonly property color bgDark:  "#080d14"
    readonly property color bgCard:  "#0a1520"

    property int resultCount: 0

    // ── Results model ─────────────────────────────────────────────────────────
    ListModel { id: resultsModel }

    // ── Backend connection ────────────────────────────────────────────────────
    Connections {
        target: mediaManagerBackend

        function onSearchResults(rows) {
            resultsModel.clear()
            for (var i = 0; i < rows.length; i++) {
                var r = rows[i]
                resultsModel.append({
                    source_table:        r.source_table        || "",
                    file_path:           r.file_path           || "",
                    file_name:           r.file_name           || "",
                    file_extension:      r.file_extension      || "",
                    file_creation_date:  r.file_creation_date  || "",
                    collection_name:     r.collection_name     || "",
                    media_category:      r.media_category      || "",
                    device:              r.device              || "",
                    location:            r.location            || "",
                    created_at:          r.created_at          || ""
                })
            }
            searchRoot.resultCount = resultsModel.count
            searchBtn.searching = false
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ── Section title ─────────────────────────────────────────────────────
        Text {
            text: "Database Search"
            color: searchRoot.accent
            font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.25) }

        // ── Search bar ────────────────────────────────────────────────────────
        Row {
            width: parent.width; spacing: 8

            TextField {
                id: queryField
                width: parent.width - searchBtn.width - clearBtn.width - 24
                height: 38
                placeholderText: "Enter file name, path or collection name…"
                font.pixelSize: 14; color: "white"
                background: Rectangle {
                    color: "#111c2e"
                    border.color: queryField.activeFocus ? searchRoot.accent : "#1e3050"
                    border.width: queryField.activeFocus ? 2 : 1; radius: 5
                }
                Keys.onReturnPressed: doSearch()
                Keys.onEnterPressed:  doSearch()
            }

            // Search button
            Rectangle {
                id: searchBtn
                property bool searching: false
                width: 100; height: 38; radius: 5
                enabled: queryField.text.trim() !== "" && !searching
                opacity: enabled ? 1.0 : 0.45
                color: sMa.pressed ? "#003344" : (sMa.containsMouse ? "#005566" : "#004455")
                border.color: searchRoot.accent; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: searchBtn.searching ? "…" : "Search"
                    color: searchRoot.accent; font.pixelSize: 14; font.bold: true
                }
                MouseArea {
                    id: sMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: doSearch()
                }
            }

            // Clear button
            Rectangle {
                id: clearBtn
                width: 70; height: 38; radius: 5
                enabled: resultsModel.count > 0 || queryField.text !== ""
                opacity: enabled ? 1.0 : 0.35
                color: cMa.pressed ? "#220000" : (cMa.containsMouse ? "#330000" : "#200000")
                border.color: "#FF5555"; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "Clear"
                    color: "#FF5555"; font.pixelSize: 14; font.bold: true
                }
                MouseArea {
                    id: cMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        queryField.text = ""
                        resultsModel.clear()
                        searchRoot.resultCount = 0
                        searchBtn.searching = false
                    }
                }
            }
        }

        // ── Result count bar ──────────────────────────────────────────────────
        Row {
            visible: searchRoot.resultCount > 0 || searchBtn.searching
            spacing: 8

            Text {
                text: searchBtn.searching
                      ? "Searching…"
                      : (searchRoot.resultCount + " result" + (searchRoot.resultCount === 1 ? "" : "s") + " found")
                color: searchRoot.resultCount > 0 ? "#00CC88" : "#888888"
                font.pixelSize: 13
            }

            Text {
                visible: searchRoot.resultCount === 200
                text: "  (limit reached — refine your query)"
                color: "#FFB300"; font.pixelSize: 12; font.italic: true
            }
        }

        // ── Results list ──────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: searchRoot.height - y - 20
            color: searchRoot.bgDark
            border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1
            radius: 4
            clip: true

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: resultsModel.count === 0 && !searchBtn.searching
                text: queryField.text === ""
                      ? "Enter a search term above"
                      : "No results found"
                color: "#334455"; font.pixelSize: 16; font.italic: true
            }

            ListView {
                id: resultsList
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                model: resultsModel
                spacing: 6

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    width: resultsList.width
                    height: cardContent.implicitHeight + 16
                    radius: 6
                    color: "#0d1a28"
                    border.color: Qt.rgba(0, 0.75, 1, 0.18)
                    border.width: 1

                    // Table badge (left edge colour bar)
                    Rectangle {
                        width: 4; height: parent.height; radius: 2
                        color: model.source_table === "masterfiledetail" ? "#FFB300" : searchRoot.accent
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        id: cardContent
                        anchors {
                            left: parent.left; leftMargin: 14
                            right: parent.right; rightMargin: 10
                            top: parent.top; topMargin: 8
                        }
                        spacing: 4

                        // ── Row 1: file name + extension badge + table badge ──
                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: model.file_name
                                color: "white"
                                font.pixelSize: 15; font.bold: true
                                elide: Text.ElideMiddle
                                width: parent.width - extBadge.width - tblBadge.width - 24
                            }

                            // Extension badge
                            Rectangle {
                                id: extBadge
                                width: extText.implicitWidth + 10
                                height: 20; radius: 3
                                color: "#112233"
                                border.color: searchRoot.accent; border.width: 1
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    id: extText
                                    anchors.centerIn: parent
                                    text: model.file_extension
                                    color: searchRoot.accent
                                    font.pixelSize: 11; font.family: "Consolas"
                                }
                            }

                            // Table badge
                            Rectangle {
                                id: tblBadge
                                width: tblText.implicitWidth + 10
                                height: 20; radius: 3
                                color: model.source_table === "masterfiledetail"
                                       ? "#1a1200" : "#001122"
                                border.color: model.source_table === "masterfiledetail"
                                              ? "#FFB300" : searchRoot.accent
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    id: tblText
                                    anchors.centerIn: parent
                                    text: model.source_table === "masterfiledetail"
                                          ? "MASTER" : "MEDIA"
                                    color: model.source_table === "masterfiledetail"
                                           ? "#FFB300" : searchRoot.accent
                                    font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                                }
                            }
                        }

                        // ── Row 2: collection name ────────────────────────────
                        Row {
                            spacing: 6
                            Text {
                                text: "Collection:"
                                color: "#445566"; font.pixelSize: 12
                                width: 70
                            }
                            Text {
                                text: model.collection_name
                                color: "#88AACC"; font.pixelSize: 12
                                width: cardContent.width - 76
                                elide: Text.ElideMiddle
                            }
                        }

                        // ── Row 3: full path ──────────────────────────────────
                        Row {
                            spacing: 6
                            Text {
                                text: "Path:"
                                color: "#445566"; font.pixelSize: 12
                                width: 70
                            }
                            Text {
                                text: model.file_path
                                color: "#667788"; font.pixelSize: 12
                                width: cardContent.width - 76
                                elide: Text.ElideMiddle
                            }
                        }

                        // ── Row 4: meta strip ─────────────────────────────────
                        Row {
                            spacing: 18
                            width: parent.width

                            MetaChip { label: "Type";     value: model.media_category }
                            MetaChip { label: "Device";   value: model.device }
                            MetaChip { label: "Created";  value: model.file_creation_date }
                            MetaChip { label: "Recorded"; value: model.created_at }
                        }

                        // ── Row 5: location ───────────────────────────────────
                        Row {
                            spacing: 6
                            visible: model.location !== ""
                            Text {
                                text: "Location:"
                                color: "#445566"; font.pixelSize: 11
                                width: 70
                            }
                            Text {
                                text: model.location
                                color: "#556677"; font.pixelSize: 11
                                width: cardContent.width - 76
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Inline component: small label+value chip ──────────────────────────────
    component MetaChip: Row {
        property string label: ""
        property string value: ""
        spacing: 4
        visible: value !== ""
        Text {
            text: label + ":"
            color: "#445566"; font.pixelSize: 11
        }
        Text {
            text: value
            color: "#8899AA"; font.pixelSize: 11
        }
    }

    // ── Search trigger ────────────────────────────────────────────────────────
    function doSearch() {
        var q = queryField.text.trim()
        if (q === "") return
        resultsModel.clear()
        searchRoot.resultCount = 0
        searchBtn.searching = true
        mediaManagerBackend.search_collections(q)
    }
}
