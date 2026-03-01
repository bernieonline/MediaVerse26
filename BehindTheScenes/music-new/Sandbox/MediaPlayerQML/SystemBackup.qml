import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects 1.15

Rectangle {
    id: backupOverlay
    anchors.fill: parent
    color: "#F8121214" 
    visible: false
    z: 10001 

    property string currentTab: "Home"
    property bool isProcessing: false 

    Connections {
        target: backupManager
        function onBackupFinished(message, success) {
            backupOverlay.isProcessing = false 
        }
        function onProgressChanged() {}
    }

    Rectangle {
        id: mainPanel
        anchors.centerIn: parent
        width: 850; height: 600 
        color: "#1A1A1C"
        border.color: "gold"; border.width: 3 
        radius: 12
        clip: true

        Text {
            id: titleText
            text: "SYSTEM BACKUP"
            color: "gold"
            font.pixelSize: 32; font.bold: true 
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 30
        }

        Row {
            id: headerRow
            anchors.top: titleText.bottom; anchors.topMargin: 35
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Repeater {
                model: ["JSON", "Code", "Movie Assets", "Sync"]
                Rectangle {
                    width: 160; height: 55 
                    color: currentTab === modelData ? "gold" : (btnMouse.containsMouse ? "#33FFFFFF" : "#11FFFFFF")
                    border.color: "gold"; border.width: 2; radius: 6
                    Text {
                        text: modelData
                        anchors.centerIn: parent
                        color: currentTab === modelData ? "black" : "white"
                        font.pixelSize: 18; font.bold: true
                    }
                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: if(!backupOverlay.isProcessing) currentTab = modelData
                    }
                }
            }
        }

        Rectangle {
            id: controlContent
            anchors.top: headerRow.bottom; anchors.topMargin: 30
            anchors.bottom: statusBar.top; anchors.bottomMargin: 20 
            anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 40
            color: "#0D0D0F"
            border.color: "#333"; radius: 8

            // --- Home View ---
            Column {
                anchors.fill: parent; anchors.margins: 30
                visible: currentTab === "Home"
                spacing: 25
                Text {
                    text: "Protect your system data and metadata."
                    color: "gold"; font.pixelSize: 22; font.bold: true; width: parent.width
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: "white"
                    font.pixelSize: 18; lineHeight: 1.4 
                    text: "• <b>JSON:</b> Databases, configs, and manifests.<br>" +
                          "• <b>Code:</b> Development source protection.<br>" +
                          "• <b>Movie Assets:</b> Covers, backdrops, and XML data.<br>" +
                          "• <b>Sync:</b> Real-time mirrored backup of assets."
                }
                // --- Simple Path Label (Home) ---
                Text {
                    text: "BACKUP ROOT: <b>U:\\Movie System Backup\\</b>"
                    color: "#666"; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter
                    textFormat: Text.RichText
                }
            }

            // --- JSON Panel ---
            Column {
                anchors.fill: parent; anchors.margins: 30
                visible: currentTab === "JSON"
                spacing: 25
                Text { text: "DATABASE & MANIFEST PROTECTION"; color: "gold"; font.pixelSize: 22; font.bold: true }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: "white"
                    font.pixelSize: 17; lineHeight: 1.3
                    text: "Captures movie records, collection logic, and configuration files."
                }
                Row {
                    spacing: 30; anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        width: 220; height: 60; radius: 8
                        color: backupOverlay.isProcessing ? "#444" : (jsonBtnMouse.containsMouse ? "#FFD700" : "gold")
                        Text { text: "BACKUP JSON"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 18; color: "black" }
                        MouseArea {
                            id: jsonBtnMouse; anchors.fill: parent; hoverEnabled: true; enabled: !backupOverlay.isProcessing
                            onClicked: { backupOverlay.isProcessing = true; backupManager.run_json_backup() }
                        }
                    }
                }
                // --- Simple Path Label (JSON) ---
                Text {
                    text: "DESTINATION: <b>U:\\Movie System Backup\\JSON\\</b>"
                    color: "#888"; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter
                    textFormat: Text.RichText
                }
            }

            // --- Code Panel ---
            Column {
                anchors.fill: parent; anchors.margins: 30
                visible: currentTab === "Code"
                spacing: 25
                Text { text: "CODE PROTECTION"; color: "gold"; font.pixelSize: 22; font.bold: true }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap; color: "white"
                    font.pixelSize: 17; lineHeight: 1.3
                    text: "Secures development files as defined in <b>BackupSystem.py</b>."
                }
                Row {
                    spacing: 30; anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        width: 220; height: 60; radius: 8
                        color: backupOverlay.isProcessing ? "#444" : (backupMouse.containsMouse ? "#FFD700" : "gold")
                        Text { text: "BACKUP NOW"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 18; color: "black" }
                        MouseArea {
                            id: backupMouse; anchors.fill: parent; hoverEnabled: true; enabled: !backupOverlay.isProcessing
                            onClicked: { backupOverlay.isProcessing = true; backupManager.run_code_backup() }
                        }
                    }
                }
                // --- Simple Path Label (Code) ---
                Text {
                    text: "DESTINATION: <b>U:\\Movie System Backup\\Code\\</b>"
                    color: "#888"; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter
                    textFormat: Text.RichText
                }
            }

            // --- RUNNING OVERLAY ---
            Rectangle {
                anchors.fill: parent
                color: "#F20D0D0F"
                visible: backupOverlay.isProcessing
                radius: 8
                z: 100 
                Column {
                    anchors.centerIn: parent; spacing: 20
                    Text {
                        text: "BACKUP IS RUNNING..."
                        color: "gold"; font.pixelSize: 24; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.4; duration: 1000 }
                            NumberAnimation { from: 0.4; to: 1.0; duration: 1000 }
                        }
                    }
                    Text {
                        text: "Your data is being secured to the U: drive.\nYou can safely close this panel."
                        color: "white"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.4; anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        width: 350; height: 4; color: "#33FFFFFF"; radius: 2; anchors.horizontalCenter: parent.horizontalCenter
                        Rectangle {
                            width: parent.width * (backupManager ? backupManager.progress : 0)
                            height: parent.height; color: "gold"; radius: 2
                            Behavior on width { NumberAnimation { duration: 500 } }
                        }
                    }
                }
            }
        }

        // --- Status Bar ---
        Rectangle {
            id: statusBar
            width: parent.width - 80; height: 50
            color: "#11FFFFFF"; radius: 6
            anchors.bottom: parent.bottom; anchors.bottomMargin: 25
            anchors.horizontalCenter: parent.horizontalCenter
            border.color: "#22FFFFFF"
            Row {
                anchors.centerIn: parent; spacing: 15
                Rectangle {
                    width: 14; height: 14; radius: 7; color: "gold"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 1200; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                    }
                }
                Text {
                    text: backupOverlay.isProcessing ? "THREAD ACTIVE - DO NOT SHUTDOWN" : "LAST SUCCESSFUL BACKUP: " + (backupManager ? backupManager.lastBackupTime : "CONNECTING...")
                    color: backupOverlay.isProcessing ? "gold" : "#AAA"
                    font.pixelSize: 15; font.bold: true; font.letterSpacing: 1 
                }
            }
        }
        
        Rectangle {
            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 20
            width: 55; height: 55; color: closeMouse.containsMouse ? "#44FFFFFF" : "transparent"; radius: 28
            Text { text: "✕"; color: "white"; font.pixelSize: 28; anchors.centerIn: parent }
            MouseArea {
                id: closeMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { backupOverlay.visible = false; currentTab = "Home" }
            }
        }
    }
}