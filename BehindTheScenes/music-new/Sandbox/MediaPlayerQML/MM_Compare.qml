import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
//  MM_Compare — Side-by-side collection comparison
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: compareRoot
    anchors.fill: parent

    readonly property string helpHint:
        "Select two collections and press Compare.\n\n" +
        "Files unique to each collection are listed\nside by side."

    readonly property color accent: "#00BFFF"
    readonly property color bgDark: "#080d14"

    // ── State ─────────────────────────────────────────────────────────────────
    property bool   comparing:  false
    property int    countA:     0
    property int    countB:     0

    // ── Models ────────────────────────────────────────────────────────────────
    ListModel { id: collNamesA  }
    ListModel { id: collNamesB  }
    ListModel { id: onlyInA     }
    ListModel { id: onlyInB     }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function tableForSide(side) {
        return side === "A"
            ? (tableToggleA.checked ? "masterfiledetail" : "mediafiledetail")
            : (tableToggleB.checked ? "masterfiledetail" : "mediafiledetail")
    }

    function loadCollectionNames(side) {
        var tbl = tableForSide(side)
        var names = mediaManagerBackend.get_collection_names(tbl)
        var mdl = side === "A" ? collNamesA : collNamesB
        mdl.clear()
        mdl.append({ text: "— select —" })
        for (var i = 0; i < names.length; i++)
            mdl.append({ text: names[i] })
        if (side === "A") collBoxA.currentIndex = 0
        else              collBoxB.currentIndex = 0
    }

    function runCompare() {
        var tblA = tableForSide("A")
        var tblB = tableForSide("B")
        var nameA = collBoxA.currentIndex > 0 ? collNamesA.get(collBoxA.currentIndex).text : ""
        var nameB = collBoxB.currentIndex > 0 ? collNamesB.get(collBoxB.currentIndex).text : ""
        if (!nameA || !nameB) return
        compareRoot.comparing = true
        onlyInA.clear(); onlyInB.clear()
        compareRoot.countA = 0; compareRoot.countB = 0
        mediaManagerBackend.compare_collections(tblA, nameA, tblB, nameB)
    }

    // ── Backend signals ───────────────────────────────────────────────────────
    Connections {
        target: mediaManagerBackend
        function onCompareResult(listA, listB) {
            compareRoot.comparing = false
            onlyInA.clear(); onlyInB.clear()
            for (var i = 0; i < listA.length; i++) {
                var fp = listA[i].file_path || ""
                onlyInA.append({ file_path: fp, file_name: fp.split(/[\\/]/).pop() })
            }
            for (var j = 0; j < listB.length; j++) {
                var fp2 = listB[j].file_path || ""
                onlyInB.append({ file_path: fp2, file_name: fp2.split(/[\\/]/).pop() })
            }
            compareRoot.countA = onlyInA.count
            compareRoot.countB = onlyInB.count
        }
    }

    Component.onCompleted: {
        loadCollectionNames("A")
        loadCollectionNames("B")
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Title
        Text {
            text: "Compare Collections"
            color: compareRoot.accent
            font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.5
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.25) }

        // ── Selector row ──────────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 0

            // ── Collection A ──────────────────────────────────────────────────
            Rectangle {
                width: (parent.width - 90) / 2
                height: 100
                color: "#060d18"
                border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1; radius: 4

                Column {
                    anchors.fill: parent; anchors.margins: 12; spacing: 8

                    Text {
                        text: "Collection A"
                        color: compareRoot.accent
                        font.pixelSize: 13; font.bold: true; font.letterSpacing: 1
                    }

                    // Table toggle
                    Row {
                        spacing: 0
                        Repeater {
                            model: ["Media", "Master"]
                            delegate: Rectangle {
                                width: 66; height: 26
                                color: (modelData === "Master") === tableToggleA.checked
                                       ? Qt.rgba(0,0.75,1,0.18) : "#080d14"
                                border.color: compareRoot.accent; border.width: 1
                                Text {
                                    anchors.centerIn: parent; text: modelData
                                    color: (modelData === "Master") === tableToggleA.checked
                                           ? compareRoot.accent : "#445566"
                                    font.pixelSize: 12; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        tableToggleA.checked = (modelData === "Master")
                                        loadCollectionNames("A")
                                    }
                                }
                            }
                        }
                    }

                    // Collection dropdown
                    ComboBox {
                        id: collBoxA
                        width: parent.width; height: 30
                        model: collNamesA; textRole: "text"
                        font.pixelSize: 12
                        contentItem: Text {
                            leftPadding: 8; text: collBoxA.displayText
                            color: collBoxA.currentIndex > 0 ? "white" : "#445566"
                            font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                        }
                        background: Rectangle {
                            color: "#0a1a2a"
                            border.color: collBoxA.activeFocus ? compareRoot.accent : "#1e3050"
                            border.width: 1; radius: 4
                        }
                        popup: Popup {
                            y: collBoxA.height; width: collBoxA.width
                            implicitHeight: Math.min(contentItem.implicitHeight, 300); padding: 1
                            contentItem: ListView {
                                clip: true; implicitHeight: contentHeight
                                model: collBoxA.popup.visible ? collBoxA.delegateModel : null
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            }
                            background: Rectangle {
                                color: "#0a1a2a"; border.color: compareRoot.accent
                                border.width: 1; radius: 4
                            }
                        }
                        delegate: ItemDelegate {
                            width: collBoxA.width
                            contentItem: Text {
                                text: model.text; color: "white"; font.pixelSize: 11
                                leftPadding: 8; verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                            }
                            background: Rectangle { color: highlighted ? "#003355" : "transparent" }
                            highlighted: collBoxA.highlightedIndex === index
                        }
                    }
                }
            }

            // Hidden toggle state holders
            CheckBox { id: tableToggleA; visible: false; checked: false }
            CheckBox { id: tableToggleB; visible: false; checked: false }

            // ── Centre: Compare button ────────────────────────────────────────
            Item {
                width: 90; height: 100

                Rectangle {
                    anchors.centerIn: parent
                    width: 70; height: 36; radius: 5
                    color: compareMa.pressed ? "#003344"
                         : (compareMa.containsMouse ? "#005566" : "#004455")
                    border.color: compareRoot.accent; border.width: 1
                    enabled: collBoxA.currentIndex > 0 && collBoxB.currentIndex > 0
                             && !compareRoot.comparing
                    opacity: enabled ? 1.0 : 0.35
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: compareRoot.comparing ? "…" : "⟳"
                        color: compareRoot.accent; font.pixelSize: 18; font.bold: true
                    }
                    MouseArea {
                        id: compareMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: compareRoot.runCompare()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                    text: "Compare"
                    color: "#445566"; font.pixelSize: 11
                }
            }

            // ── Collection B ──────────────────────────────────────────────────
            Rectangle {
                width: (parent.width - 90) / 2
                height: 100
                color: "#060d18"
                border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1; radius: 4

                Column {
                    anchors.fill: parent; anchors.margins: 12; spacing: 8

                    Text {
                        text: "Collection B"
                        color: compareRoot.accent
                        font.pixelSize: 13; font.bold: true; font.letterSpacing: 1
                    }

                    Row {
                        spacing: 0
                        Repeater {
                            model: ["Media", "Master"]
                            delegate: Rectangle {
                                width: 66; height: 26
                                color: (modelData === "Master") === tableToggleB.checked
                                       ? Qt.rgba(0,0.75,1,0.18) : "#080d14"
                                border.color: compareRoot.accent; border.width: 1
                                Text {
                                    anchors.centerIn: parent; text: modelData
                                    color: (modelData === "Master") === tableToggleB.checked
                                           ? compareRoot.accent : "#445566"
                                    font.pixelSize: 12; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        tableToggleB.checked = (modelData === "Master")
                                        loadCollectionNames("B")
                                    }
                                }
                            }
                        }
                    }

                    ComboBox {
                        id: collBoxB
                        width: parent.width; height: 30
                        model: collNamesB; textRole: "text"
                        font.pixelSize: 12
                        contentItem: Text {
                            leftPadding: 8; text: collBoxB.displayText
                            color: collBoxB.currentIndex > 0 ? "white" : "#445566"
                            font.pixelSize: 12; verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                        }
                        background: Rectangle {
                            color: "#0a1a2a"
                            border.color: collBoxB.activeFocus ? compareRoot.accent : "#1e3050"
                            border.width: 1; radius: 4
                        }
                        popup: Popup {
                            y: collBoxB.height; width: collBoxB.width
                            implicitHeight: Math.min(contentItem.implicitHeight, 300); padding: 1
                            contentItem: ListView {
                                clip: true; implicitHeight: contentHeight
                                model: collBoxB.popup.visible ? collBoxB.delegateModel : null
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            }
                            background: Rectangle {
                                color: "#0a1a2a"; border.color: compareRoot.accent
                                border.width: 1; radius: 4
                            }
                        }
                        delegate: ItemDelegate {
                            width: collBoxB.width
                            contentItem: Text {
                                text: model.text; color: "white"; font.pixelSize: 11
                                leftPadding: 8; verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                            }
                            background: Rectangle { color: highlighted ? "#003355" : "transparent" }
                            highlighted: collBoxB.highlightedIndex === index
                        }
                    }
                }
            }
        }

        // ── Summary strip ─────────────────────────────────────────────────────
        Text {
            visible: compareRoot.countA > 0 || compareRoot.countB > 0
            text: "Only in A: " + compareRoot.countA + "   ·   Only in B: " + compareRoot.countB
                  + "   ·   " + (compareRoot.countA === 0 && compareRoot.countB === 0
                                 ? "Collections are identical"
                                 : compareRoot.countA + compareRoot.countB + " differences total")
            color: "#445566"; font.pixelSize: 12
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(0,0.75,1,0.10) }

        // ── Results columns ───────────────────────────────────────────────────
        Row {
            width: parent.width
            height: compareRoot.height - y - 20
            spacing: 10

            // Only in A
            Rectangle {
                width: (parent.width - 10) / 2
                height: parent.height
                color: compareRoot.bgDark
                border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1; radius: 4; clip: true

                Column {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width; height: 32; color: "#060d18"
                        border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            text: "Only in A"
                            color: compareRoot.accent; font.pixelSize: 12; font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        visible: onlyInA.count === 0
                        text: compareRoot.comparing ? "Comparing…"
                            : (compareRoot.countA === 0 && compareRoot.countB === 0
                               && !compareRoot.comparing ? "No results yet" : "None — identical")
                        color: "#334455"; font.pixelSize: 13; font.italic: true
                        horizontalAlignment: Text.AlignHCenter; topPadding: 30
                    }

                    ListView {
                        width: parent.width
                        height: compareRoot.height - 32 - 80
                        clip: true; model: onlyInA; spacing: 1
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: fileNameA.implicitHeight + 10
                            color: index % 2 === 0 ? "#0a1520" : "#080d18"

                            Text {
                                id: fileNameA
                                anchors { left: parent.left; right: parent.right
                                          leftMargin: 10; rightMargin: 6
                                          verticalCenter: parent.verticalCenter }
                                text: model.file_name
                                color: "#AABBCC"; font.pixelSize: 11
                                elide: Text.ElideMiddle
                                ToolTip.visible: maTipA.containsMouse
                                ToolTip.text:    model.file_path
                                ToolTip.delay:   600
                            }
                            MouseArea { id: maTipA; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }

            // Only in B
            Rectangle {
                width: (parent.width - 10) / 2
                height: parent.height
                color: compareRoot.bgDark
                border.color: Qt.rgba(0,0.75,1,0.15); border.width: 1; radius: 4; clip: true

                Column {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width; height: 32; color: "#060d18"
                        border.color: Qt.rgba(0,0.75,1,0.20); border.width: 1
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            text: "Only in B"
                            color: compareRoot.accent; font.pixelSize: 12; font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        visible: onlyInB.count === 0
                        text: compareRoot.comparing ? "Comparing…"
                            : (compareRoot.countA === 0 && compareRoot.countB === 0
                               && !compareRoot.comparing ? "No results yet" : "None — identical")
                        color: "#334455"; font.pixelSize: 13; font.italic: true
                        horizontalAlignment: Text.AlignHCenter; topPadding: 30
                    }

                    ListView {
                        width: parent.width
                        height: compareRoot.height - 32 - 80
                        clip: true; model: onlyInB; spacing: 1
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: fileNameB.implicitHeight + 10
                            color: index % 2 === 0 ? "#0a1520" : "#080d18"

                            Text {
                                id: fileNameB
                                anchors { left: parent.left; right: parent.right
                                          leftMargin: 10; rightMargin: 6
                                          verticalCenter: parent.verticalCenter }
                                text: model.file_name
                                color: "#AABBCC"; font.pixelSize: 11
                                elide: Text.ElideMiddle
                                ToolTip.visible: maTipB.containsMouse
                                ToolTip.text:    model.file_path
                                ToolTip.delay:   600
                            }
                            MouseArea { id: maTipB; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }
        }
    }
}
