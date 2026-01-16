import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import Qt5Compat.GraphicalEffects 1.0

Item {
    id: playerRoot
    anchors.fill: parent

    property bool isVideoPanelVisible: false
    property bool isPlaying: false
    property string videoPath: ""

    // --- 1. THEATER DIMMER ---
    Rectangle {
        id: theaterDimmer
        anchors.fill: parent
        color: "black"
        opacity: playerRoot.isVideoPanelVisible ? 0.92 : 0.0
        z: 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        MouseArea {
            anchors.fill: parent
            onClicked: playerRoot.isVideoPanelVisible = false
        }
    }

    // --- 2. PLAYER PANEL ---
    Rectangle {
        id: playerPanel
        width: parent.width * 0.7
        height: width * 0.75
        anchors.horizontalCenter: parent.horizontalCenter
        z: 2

        y: isVideoPanelVisible ? (parent.height - height) / 2 : parent.height + 100

        color: "#1e1e1e"
        radius: 25
        border.color: "gold"
        border.width: 2
        clip: true

        Behavior on y { NumberAnimation { duration: 400 } }

        // --- VIDEO SCREEN ---
        Rectangle {
            id: videoScreen
            anchors {
                top: parent.top; topMargin: 15
                left: parent.left; right: parent.right
                leftMargin: 15; rightMargin: 15
                bottom: buttonArea.top; bottomMargin: 15
            }
            radius: 16
            color: "black"
            clip: true

            Video {
                id: videoPlayer
                anchors.fill: parent
                source: playerRoot.formatPath(playerRoot.videoPath)
                autoPlay: false
                fillMode: Video.PreserveAspectFit
            }

            FastBlur {
                anchors.fill: parent
                source: videoPlayer
                radius: 4
                visible: playerRoot.isVideoPanelVisible
            }

            Rectangle {
                anchors.fill: parent
                color: "#CC000000"
                visible: !playerRoot.isPlaying
                radius: 16

                Text {
                    anchors.centerIn: parent
                    text: "FOOTBALL: 1965 ARSENAL v MAN UTD"
                    color: "gold"
                    font.pixelSize: 20
                    font.bold: true
                }
            }
        }

        // --- BUTTON AREA ---
        Rectangle {
            id: buttonArea
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 15 }
            height: 100
            radius: 10
            color: "#33FFFFFF"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 20

                Button {
                    text: playerRoot.isPlaying ? "PAUSE" : "PLAY MATCH"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onClicked: {
                        if (playerRoot.isPlaying) {
                            videoPlayer.pause()
                            playerRoot.isPlaying = false
                        } else {
                            videoPlayer.source = playerRoot.formatPath(playerRoot.videoPath)
                            videoPlayer.play()
                            playerRoot.isPlaying = true
                        }
                    }
                }

                Button {
                    text: "CLOSE"
                    Layout.preferredWidth: 120
                    Layout.fillHeight: true

                    onClicked: {
                        videoPlayer.stop()
                        playerRoot.isPlaying = false
                        playerRoot.isVideoPanelVisible = false
                    }
                }
            }
        }
    }

    function formatPath(path) {
        if (!path || path === "") return ""
        var p = path.replace(/\\/g, "/")
        if (!p.startsWith("file:///")) p = "file:///" + p
        return p
    }
}