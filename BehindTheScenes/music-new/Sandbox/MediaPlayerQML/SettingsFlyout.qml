import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: settingsSidebar
    width: 320
    height: parent ? parent.height : 800

    // Park off-screen until opened — no anchors override this
    x: parent ? parent.width : 5000
    visible: x < (parent ? parent.width : 5000)

    color: "#0F0F0F"
    border.color: "#333333"
    border.width: 1
    z: 9999

    signal menuItemClicked(string item)

    Behavior on x {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function open() {
        playerSubPanel.shown = false
        settingsSidebar.x = parent.width - width
    }

    function close() {
        playerSubPanel.shown = false
        settingsSidebar.x = parent.width
    }

    // ── Dismissal shield — covers screen area left of this panel ───────
    // Child of settingsSidebar so it moves with it; only active when visible
    MouseArea {
        x: -5000
        y: 0
        width: 5000
        height: settingsSidebar.height
        z: -1
        enabled: settingsSidebar.visible
        onClicked: settingsSidebar.close()
    }

    // ── Sub-panel dismissal — clicking the main settings body closes sub-panel
    MouseArea {
        anchors.fill: parent
        z: 5
        enabled: playerSubPanel.shown
        onClicked: playerSubPanel.shown = false
    }

    // ── Player sub-panel (slides left from behind main panel) ──────────
    Rectangle {
        id: playerSubPanel
        width: 300
        height: settingsSidebar.height

        // Parked behind main panel (x = settingsSidebar.width) when hidden,
        // slides to the left of main panel when shown
        x: shown ? -width : settingsSidebar.width
        y: 0

        property bool shown: false
        property string preferredName: ""
        property string pendingName: ""

        Behavior on x {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        color: "#0F0F0F"
        border.color: "#333333"
        border.width: 1

        ListModel { id: playerModel }

        function load() {
            playerModel.clear()
            var s = SettingsManager.get_settings()
            var paths = s["PlayerPaths"] || {}
            var keys = Object.keys(paths)

            // Support legacy integer value in config — resolve to name
            var saved = s["Preferred Player"]
            var legacyMap = ["MiniPlayer", "JRiver", "PowerDVD", "vlc"]
            if (typeof saved === "number") {
                saved = legacyMap[saved] || keys[0] || ""
            }
            preferredName = saved || ""
            pendingName = preferredName

            for (var i = 0; i < keys.length; i++) {
                playerModel.append({ playerName: keys[i], playerPath: paths[keys[i]] })
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header
            Row {
                width: parent.width
                height: 40
                Text {
                    text: "MEDIA PLAYER"
                    color: "#FFD700"
                    font.pixelSize: 20
                    font.bold: true
                    font.letterSpacing: 1
                    width: parent.width - 30
                }
                Text {
                    text: "✕"
                    color: "#888888"
                    font.pixelSize: 22
                    verticalAlignment: Text.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playerSubPanel.shown = false
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#222222" }

            Text {
                text: "Select preferred player"
                color: "#888888"
                font.pixelSize: 13
                font.letterSpacing: 1
            }

            // Player list
            ListView {
                width: parent.width
                height: parent.height - 200
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: playerModel

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 56
                    color: playerSubPanel.pendingName === model.playerName ? "#1a2a3a" : "#161616"
                    radius: 6
                    border.color: playerSubPanel.pendingName === model.playerName ? "#2566c2" : "#2a2a2a"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RadioButton {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: playerSubPanel.pendingName === model.playerName
                            onClicked: playerSubPanel.pendingName = model.playerName
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: model.playerName
                                color: playerSubPanel.pendingName === model.playerName ? "white" : "#aaaaaa"
                                font.pixelSize: 16
                                font.bold: playerSubPanel.pendingName === model.playerName
                            }
                            Text {
                                text: model.playerPath || "(not configured)"
                                color: "#555555"
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                                width: 200
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: playerSubPanel.pendingName = model.playerName
                    }
                }
            }

            // Save button
            Rectangle {
                width: 120
                height: 40
                radius: 6
                color: saveHover ? "#FFD700" : "#2a2a2a"
                border.color: "#FFD700"
                border.width: 1
                property bool saveHover: false

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: parent.saveHover ? "#111111" : "white"
                    font.pixelSize: 16
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.saveHover = true
                    onExited:  parent.saveHover = false
                    onClicked: {
                        SettingsManager.update_setting("Preferred Player", playerSubPanel.pendingName)
                        playerSubPanel.preferredName = playerSubPanel.pendingName
                        playerSubPanel.shown = false
                    }
                }
            }
        }
    }

    // ── Main menu column ───────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header
        Row {
            width: parent.width
            height: 40
            Text {
                text: "SETTINGS"
                color: "#FFD700"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 1
                width: parent.width - 40
            }
            Text {
                text: "✕"
                color: "#888888"
                font.pixelSize: 24
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsSidebar.close()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#222222" }

        // Menu items
        Column {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { label: "Media Player",       action: "media_player"   },
                    { label: "Manage Players...",   action: "manage_players" },
                    { label: "Categories",          action: "categories"     },
                    { label: "Configuration...",    action: "configuration"  }
                ]

                delegate: Rectangle {
                    width: parent.width
                    height: 52
                    color: itemMouse.containsMouse ? "#1a2a3a" : "transparent"
                    radius: 6
                    border.color: itemMouse.containsMouse ? "#2566c2" : "#333"
                    border.width: itemMouse.containsMouse ? 1 : 0

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: itemMouse.containsMouse ? "white" : "#cccccc"
                            font.pixelSize: 18
                            font.bold: itemMouse.containsMouse
                        }

                        // Chevron hint for Media Player sub-menu
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "‹"
                            color: "#555555"
                            font.pixelSize: 20
                            visible: modelData.action === "media_player"
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.action === "media_player") {
                                playerSubPanel.load()
                                playerSubPanel.shown = true
                            } else {
                                settingsSidebar.menuItemClicked(modelData.label)
                                settingsSidebar.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
