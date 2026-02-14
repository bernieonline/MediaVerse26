import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Item {
    id: panelRoot

    // --- SIGNALS ---
    signal commitRequested(int panelIndex)
    signal finishRequested(int panelIndex)
    signal shelfRequested(int panelIndex)
    signal listRequested(int panelIndex)

    property int panelIndex: 0
    property int hitCount: 0
    property bool filterEnabled: false
    property string currentMode: "selection"
    property var stagingResults: []

    // Track whether this panel has been committed
    property bool isCommitted: false

    // --- NEW: rule state for this panel ---
    property string panelMode: ""
    property var panelData: null
    property var panelListData: []

    width: 360
    height: 600

    RectangularGlow {
        id: effect
        anchors.fill: cardFrame
        glowRadius: 18
        spread: 0.18
        color: "#99FFD700"
        cornerRadius: 12
        z: 0
    }

    Rectangle {
        id: cardFrame
        anchors.fill: parent
        anchors.margins: 15

        color: "#1A1A1A"
        radius: 12
        border.color: "#FFFFFF"
        border.width: 1
        clip: true
        z: 1

        Rectangle {
            id: toolbar
            width: parent.width - 20; height: 48; color: "#2C2C2C"; radius: 8
            anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
            z: 100
            border.color: "#22FFFFFF"; border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "#" + (panelIndex + 1)
                    color: "white"; font.bold: true; opacity: 0.5; font.pixelSize: 12
                }

                CheckBox {
                    id: filterCheckbox
                    text: "FILTER"
                    visible: currentMode !== "selection" && panelRoot.filterEnabled
                    contentItem: Text {
                        text: filterCheckbox.text
                        font.pixelSize: 10; font.bold: true
                        color: filterCheckbox.checked ? "#00F2FF" : "#88FFFFFF"
                        leftPadding: filterCheckbox.indicator.width + 4
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: helpBtn
                    width: 26; height: 26; radius: 13
                    color: helpMouse.containsMouse ? "#3300F2FF" : "transparent"
                    border.color: "#00F2FF"; border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "H"; color: "white"; font.bold: true; font.pixelSize: 13
                    }

                    MouseArea {
                        id: helpMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: console.log("❓ Help requested for panel: " + panelIndex)
                    }
                    ToolTip.visible: helpMouse.containsMouse
                    ToolTip.text: "View logic documentation"
                    ToolTip.delay: 400
                }

                Text {
                    text: "M"; font.pixelSize: 22; font.bold: true; color: "gold"
                    opacity: menuMouse.containsMouse ? 1.0 : 0.8
                    MouseArea {
                        id: menuMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: currentMode = "selection"
                    }
                }

                Text {
                    text: panelRoot.hitCount
                    color: "#00F2FF"; font.pixelSize: 18; font.bold: true
                    Layout.preferredWidth: 35; horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: "×"; font.pixelSize: 26; color: "#FF4444"
                    opacity: closeMouse.containsMouse ? 1.0 : 0.7
                    MouseArea {
                        id: closeMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (typeof architectRoot !== "undefined") architectRoot.removePanel(panelIndex)
                    }
                }
            }
        }

        Loader {
            id: toolLoader
            anchors.top: toolbar.bottom; anchors.bottom: footerArea.top
            anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 5
            z: 5
            source: {
                if (currentMode === "folder") return "ArchitectFolderNav.qml";
                if (currentMode === "search") return "ArchitectSearchNav.qml";
                if (currentMode === "category") return "ArchitectCategoryNav.qml";
                return "";
            }
            onLoaded: if (item) {
                item.parentPanel = panelRoot
                console.log("🛠️ Tool Loaded: " + currentMode + " linked to Panel " + panelIndex)
            }
        }

        Column {
            visible: currentMode === "selection"
            anchors.centerIn: parent; spacing: 15
            z: 10
            Text {
                text: "SELECT LOGIC"; color: "white"; font.pixelSize: 18;
                font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.6
            }
            Button { text: "🔍 SEARCH"; width: 180; height: 45; onClicked: currentMode = "search" }
            Button { text: "📁 FOLDER"; width: 180; height: 45; onClicked: currentMode = "folder" }
            Button { text: "🏷️ CATEGORY"; width: 180; height: 45; onClicked: currentMode = "category" }
        }

        // --- FOOTER AREA ---
        Rectangle {
            id: footerArea
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 1
            height: 85
            color: "#111111"
            visible: currentMode !== "selection"
            z: 100
            radius: 12

            Rectangle { width: parent.width; height: 1; color: "#22FFFFFF"; anchors.top: parent.top }

            GridLayout {
                anchors.fill: parent
                anchors.margins: 8
                columns: 2
                rowSpacing: 6
                columnSpacing: 6

                // ⭐ COMMIT
                Button {
                    id: commitBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32

                    enabled: hitCount > 0 && !panelRoot.isCommitted
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: commitBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: commitBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "COMMIT"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                    }
                    onClicked: {
                        // Guard: only commit if we have a valid mode + data
                        if (panelRoot.panelMode === "" || panelRoot.panelData === null) {
                            console.log("⚠️ Cannot commit panel", panelRoot.panelIndex, "- no selection state.")
                            return
                        }

                        var rule = {
                            panelIndex: panelRoot.panelIndex,
                            mode: panelRoot.panelMode,
                            data: panelRoot.panelData,
                            list: panelRoot.panelListData
                        }

                        if (typeof architectController !== "undefined") {
                            // Match existing pattern: send an array of rules
                            architectController.update_live_preview(JSON.stringify([rule]))
                        }

                        panelRoot.isCommitted = true
                        panelRoot.commitRequested(panelRoot.panelIndex)
                    }
                }

                // ⭐ FINISH
                Button {
                    id: finishBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32

                    enabled: panelRoot.isCommitted
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: finishBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: finishBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "FINISH"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                    }
                    onClicked: panelRoot.finishRequested(panelRoot.panelIndex)
                }

                // ⭐ SHELF
                Button {
                    id: shelfBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32

                    enabled: panelRoot.isCommitted
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: shelfBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: shelfBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "SHELF"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                    }
                    onClicked: panelRoot.shelfRequested(panelRoot.panelIndex)
                }

                // ⭐ THIS LIST
                Button {
                    id: listBtn
                    Layout.fillWidth: true; Layout.preferredHeight: 32

                    enabled: hitCount > 0
                    opacity: enabled ? 1.0 : 0.35

                    background: Rectangle {
                        color: listBtn.pressed ? "#000" : "#222"
                        radius: 6; border.width: 1
                        border.color: listBtn.hovered ? "#FFD700" : "#555"
                    }
                    contentItem: Text {
                        text: "THIS LIST"; color: "gold"; font.bold: true; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                    }
                    onClicked: panelRoot.listRequested(panelRoot.panelIndex)
                }
            }
        }
    }

    // Listen to architectController for hit counts
    Connections {
        target: (typeof architectController !== "undefined") ? architectController : null
        ignoreUnknownSignals: true

        function onResultsCounted(pIndex, pCount) {
            if (panelRoot.panelIndex === pIndex) {
                panelRoot.hitCount = pCount
            }
        }
    }

    // NEW: listen to the currently loaded tool (Folder / Category / Search)
    Connections {
        target: toolLoader.item
        ignoreUnknownSignals: true

        function onFolderSelected(folderName, panelList) {
            panelRoot.panelMode = "folder"
            panelRoot.panelData = folderName
            panelRoot.panelListData = panelList || []
            panelRoot.stagingResults = panelRoot.panelListData
            console.log("📁 Panel", panelRoot.panelIndex, "folderSelected →", folderName)
        }

        function onCategorySelected(key, value, panelList) {
            panelRoot.panelMode = "category"
            panelRoot.panelData = { key: key, value: value }
            panelRoot.panelListData = panelList || []
            panelRoot.stagingResults = panelRoot.panelListData
            console.log("🏷️ Panel", panelRoot.panelIndex, "categorySelected →", key, "=", value)
        }

        function onSearchSelected(query, panelList) {
            panelRoot.panelMode = "search"
            panelRoot.panelData = { query: query }
            panelRoot.panelListData = panelList || []
            panelRoot.stagingResults = panelRoot.panelListData
            console.log("🔍 Panel", panelRoot.panelIndex, "searchSelected →", query)
        }
    }
}