import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    width: 900
    height: 700
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape

    // ── Local state ────────────────────────────────────────────────
    property var    settings:       ({})
    property string recoveryStatus: ""
    property int    recoveryStatusTimer: 0
    property string videoProcPath:  ""

    function refreshToolPaths() {
        var tp = root.settings["ToolPaths"] || {}
        root.videoProcPath = tp["VideoProc"] || ""
    }

    // ── Load settings when panel opens ─────────────────────────────
    onOpened: {
        settings = SettingsManager.get_settings()
        nameField.text = settings["name"] || ""
        recoveryStatus = ""
        buildPlayerModel()
        refreshToolPaths()
    }

    // ── Reload if settings change externally ───────────────────────
    Connections {
        target: SettingsManager
        function onSettingsChanged() {
            if (root.visible) {
                settings = SettingsManager.get_settings()
                nameField.text = settings["name"] || ""
                buildPlayerModel()
                refreshToolPaths()
            }
        }
    }

    // ── Player model ───────────────────────────────────────────────
    ListModel { id: playerModel }

    property int preferredIndex: 0

    function buildPlayerModel() {
        playerModel.clear()
        var s = SettingsManager.get_settings()
        var playerPaths = s["PlayerPaths"] || {}
        var preferred = s["Preferred Player"] || 0
        preferredIndex = preferred
        var keys = Object.keys(playerPaths)
        for (var i = 0; i < keys.length; i++) {
            playerModel.append({ "playerName": keys[i], "playerPath": playerPaths[keys[i]] })
        }
    }

    // ── Recovery helper ────────────────────────────────────────────
    function runRecovery(label, fn) {
        recoveryStatus = label + " — Running..."
        fn()
        recoveryStatusTimer = 3000
        statusClearTimer.restart()
    }

    Timer {
        id: statusClearTimer
        interval: 3000
        repeat: false
        onTriggered: recoveryStatus = ""
    }

    // ── Background ─────────────────────────────────────────────────
    background: Rectangle {
        color: "#1a1a1a"
        radius: 12
        border.color: "#FFD700"
        border.width: 1
    }

    // ── Content ────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "transparent"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                text: "SETTINGS"
                color: "#FFD700"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 3
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 20
                text: "✕"
                color: "#FFD700"
                font.pixelSize: 22
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#333"
            }
        }

        // Tab bar (Updated to 5 items)
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            height: 48
            background: Rectangle { color: "#111" }

            Repeater {
                model: ["Profile", "Player", "Library", "Startup", "Recovery", "Tools"]
                TabButton {
                    text: modelData
                    font.pixelSize: 18
                    font.bold: tabBar.currentIndex === index
                    width: root.width / 6

                    background: Rectangle {
                        color: tabBar.currentIndex === index ? "#2566c2" : "#1a1a1a"
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: tabBar.currentIndex === index ? "#2566c2" : "#333"
                        }
                    }
                    contentItem: Text {
                        text: modelData
                        color: tabBar.currentIndex === index ? "white" : "#888"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Tab pages
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // ── Tab 1: Profile ─────────────────────────────────────
            Item {
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 20

                    Text {
                        text: "USER PROFILE"
                        color: "#aaaaaa"
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

                    ColumnLayout {
                        spacing: 8
                        Text { text: "Name"; color: "#aaaaaa"; font.pixelSize: 18 }
                        Rectangle {
                            width: 400
                            height: 48
                            color: "#111"
                            radius: 6
                            border.color: nameField.activeFocus ? "#FFD700" : "#444"
                            border.width: nameField.activeFocus ? 2 : 1

                            TextField {
                                id: nameField
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                height: 36
                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 0
                                rightPadding: 0
                                background: Rectangle { color: "transparent" }
                                color: "white"
                                font.pixelSize: 22
                            }
                        }
                    }

                    Item { height: 16 }

                    Row {
                        spacing: 16
                        Rectangle {
                            width: 120; height: 44
                            color: saveNameHover ? "#FFD700" : "#2a2a2a"
                            radius: 6
                            border.color: "#FFD700"
                            border.width: 1
                            property bool saveNameHover: false

                            Text {
                                anchors.centerIn: parent
                                text: "Save"
                                color: parent.saveNameHover ? "#111" : "white"
                                font.pixelSize: 20
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.saveNameHover = true
                                onExited: parent.saveNameHover = false
                                onClicked: SettingsManager.update_setting("name", nameField.text)
                            }
                        }
                    }
                }
            }

            // ── Tab 2: Player ──────────────────────────────────────
            Item {
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 16

                    Text {
                        text: "SELECT PREFERRED PLAYER"
                        color: "#aaaaaa"
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

                    Repeater {
                        model: playerModel
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            color: root.preferredIndex === index ? "#1a2a3a" : "#222"
                            radius: 6
                            border.color: root.preferredIndex === index ? "#2566c2" : "#333"
                            border.width: root.preferredIndex === index ? 2 : 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 16

                                RadioButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: root.preferredIndex === index
                                    onClicked: root.preferredIndex = index
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Text {
                                        text: model.playerName
                                        color: root.preferredIndex === index ? "white" : "#ccc"
                                        font.pixelSize: 20
                                        font.bold: root.preferredIndex === index
                                    }
                                    Text {
                                        text: model.playerPath || "(not configured)"
                                        color: "#666"
                                        font.pixelSize: 14
                                        elide: Text.ElideMiddle
                                        width: 600
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.preferredIndex = index
                            }
                        }
                    }

                    Item { height: 8 }

                    Row {
                        spacing: 16

                        Rectangle {
                            width: 160; height: 44
                            color: savePlyHover ? "#FFD700" : "#2a2a2a"
                            radius: 6
                            border.color: "#FFD700"
                            border.width: 1
                            property bool savePlyHover: false
                            Text {
                                anchors.centerIn: parent
                                text: "Save"
                                color: parent.savePlyHover ? "#111" : "white"
                                font.pixelSize: 20
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.savePlyHover = true
                                onExited: parent.savePlyHover = false
                                onClicked: SettingsManager.update_setting("Preferred Player", root.preferredIndex)
                            }
                        }

                        Rectangle {
                            width: 200; height: 44
                            color: mngHover ? "#333" : "#222"
                            radius: 6
                            border.color: "#555"
                            border.width: 1
                            property bool mngHover: false
                            Text {
                                anchors.centerIn: parent
                                text: "Manage Players..."
                                color: "white"
                                font.pixelSize: 18
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.mngHover = true
                                onExited: parent.mngHover = false
                                onClicked: {
                                    root.close()
                                    playerExeBrowser.open()
                                }
                            }
                        }
                    }
                }
            }

            // ── Tab 3: Library ─────────────────────────────────────
            Item {
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 20

                    Text {
                        text: "LIBRARY CONFIGURATION"
                        color: "#aaaaaa"
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

                    Text {
                        text: "These values are read-only. Edit Config.json directly to change them."
                        color: "#666"
                        font.pixelSize: 15
                        font.italic: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: [
                            { label: "Library Root",  key: "LibraryRoot" },
                            { label: "JRiver Port",   key: "JRiverPort"  }
                        ]
                        delegate: ColumnLayout {
                            spacing: 6
                            Text {
                                text: modelData.label
                                color: "#aaaaaa"
                                font.pixelSize: 18
                            }
                            Rectangle {
                                width: 600
                                height: 48
                                color: "#111"
                                radius: 6
                                border.color: "#333"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.right: parent.right
                                    anchors.rightMargin: 14
                                    text: root.settings[modelData.key] || "(not set)"
                                    color: "#ccc"
                                    font.pixelSize: 20
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // ── Tab 4: Startup (The Addition) ───────────────────────
            Item {
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 30

                    Text {
                        text: "STARTUP BEHAVIOR"
                        color: "#aaaaaa"
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

                    // Splash Toggle
                    RowLayout {
                        spacing: 20
                        Switch {
                            checked: root.settings["StartUp"] ? root.settings["StartUp"]["Splash"] : true
                            onToggled: {
                                var current = root.settings["StartUp"] || {}
                                current["Splash"] = checked
                                SettingsManager.update_setting("StartUp", current)
                            }
                        }
                        Column {
                            Text { text: "Show Splash Screen"; color: "white"; font.pixelSize: 18 }
                            Text { text: "Enable the intro animation on launch"; color: "#666"; font.pixelSize: 14 }
                        }
                    }

                    // Tiles Toggle
                    RowLayout {
                        spacing: 20
                        Switch {
                            checked: root.settings["StartUp"] ? root.settings["StartUp"]["Tiles"] : false
                            onToggled: {
                                var current = root.settings["StartUp"] || {}
                                current["Tiles"] = checked
                                SettingsManager.update_setting("StartUp", current)
                            }
                        }
                        Column {
                            Text { text: "Start in Grid Mode"; color: "white"; font.pixelSize: 18 }
                            Text { text: "Launch directly into the movie wall"; color: "#666"; font.pixelSize: 14 }
                        }
                    }
                }
            }

            // ── Tab 5: Recovery (RESTORED FULL LOGIC) ────────────────
            Item {
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 12

                    Text {
                        text: "RECOVERY TOOLS"
                        color: "#aaaaaa"
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

                    Repeater {
                        model: [
                            { label: "Restore Collections Backup",  sub: "Replaces Movies_Collections_v2.json from backup",  action: "collections_bak"  },
                            { label: "Restore XML Data Backup",        sub: "Replaces xml_collection_data.json from backup",    action: "xml_bak"          },
                            { label: "Restore Config Backup",          sub: "Replaces Config.json from backup",                 action: "config_bak"       },
                            { label: "Rebuild XML Collection Data",    sub: "Re-scans all JRiver XML sidecar files",            action: "rebuild_xml"      },
                            { label: "Rebuild Manifest",               sub: "Forces full library manifest rebuild from scratch", action: "rebuild_manifest" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            color: btnHover ? "#2a2a2a" : "#1e1e1e"
                            radius: 6
                            border.color: btnHover ? "#FFD700" : "#333"
                            border.width: 1
                            property bool btnHover: false

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                spacing: 3
                                Text {
                                    text: modelData.label
                                    color: "white"
                                    font.pixelSize: 20
                                }
                                Text {
                                    text: modelData.sub
                                    color: "#777"
                                    font.pixelSize: 14
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.btnHover = true
                                onExited: parent.btnHover = false
                                onClicked: {
                                    var a = modelData.action
                                    if      (a === "collections_bak")  root.runRecovery(modelData.label, function() { collectionLogic.restore_from_backup("collections") })
                                    else if (a === "xml_bak")          root.runRecovery(modelData.label, function() { collectionLogic.restore_from_backup("xml_collection_data") })
                                    else if (a === "config_bak")       root.runRecovery(modelData.label, function() { collectionLogic.restore_from_backup("config") })
                                    else if (a === "rebuild_xml")      root.runRecovery(modelData.label, function() { collectionLogic.force_rebuild_xml_collection_data() })
                                    else if (a === "rebuild_manifest") root.runRecovery(modelData.label, function() { manifestUpdater.force_rebuild_manifest() })
                                }
                            }
                        }
                    }

                    Text {
                        text: root.recoveryStatus
                        color: "#FFD700"
                        font.pixelSize: 16
                        font.italic: true
                        visible: root.recoveryStatus !== ""
                    }
                }
            }

            // ── Tab 6: Tools ───────────────────────────────────────────
            Item {
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 24

                    Text {
                        text: "EXTERNAL TOOLS"
                        color: "#aaaaaa"
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333" }

                    // ── VideoProc row ──────────────────────────────────
                    ColumnLayout {
                        spacing: 10

                        Text {
                            text: "VideoProc Converter AI"
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            text: "AI upscaling and video conversion. Path to VideoProcConverterAI.exe"
                            color: "#888"
                            font.pixelSize: 15
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Path display box
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            color: "#111"
                            radius: 6
                            border.color: "#333"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                text: root.videoProcPath !== "" ? root.videoProcPath : "(not configured)"
                                color: root.videoProcPath !== "" ? "#ccc" : "#555"
                                font.pixelSize: 15
                                elide: Text.ElideLeft
                            }
                        }

                        // Browse button
                        Row {
                            spacing: 12

                            Rectangle {
                                width: 160; height: 44
                                color: browseVpHover ? "#39FF14" : "#2a2a2a"
                                radius: 6
                                border.color: "#39FF14"
                                border.width: 1
                                property bool browseVpHover: false

                                Text {
                                    anchors.centerIn: parent
                                    text: "Browse..."
                                    color: parent.browseVpHover ? "#111" : "white"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.browseVpHover = true
                                    onExited:  parent.browseVpHover = false
                                    onClicked: SettingsManager.browse_and_save_tool_path("VideoProc")
                                }
                            }

                            Rectangle {
                                width: 160; height: 44
                                color: launchVpHover ? "#333" : "#222"
                                radius: 6
                                border.color: "#555"
                                border.width: 1
                                property bool launchVpHover: false
                                visible: root.videoProcPath !== ""

                                Text {
                                    anchors.centerIn: parent
                                    text: "Launch"
                                    color: "white"
                                    font.pixelSize: 18
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.launchVpHover = true
                                    onExited:  parent.launchVpHover = false
                                    onClicked: SettingsManager.launch_tool("VideoProc")
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "transparent"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#333"
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 24
                width: 120; height: 40
                color: closeHover ? "#333" : "transparent"
                radius: 6
                border.color: "#555"
                border.width: 1
                property bool closeHover: false

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: "white"
                    font.pixelSize: 18
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.closeHover = true
                    onExited: parent.closeHover = false
                    onClicked: root.close()
                }
            }
        }
    }
}