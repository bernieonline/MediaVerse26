// PlayerPanel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15   // or just QtMultimedia if using Qt 6

Rectangle {
    id: playerPanel
    property bool isVisible: true
    property bool isPlaying: false
    property string videoPath: ""   // ✅ dynamic, set by detail_view

    width: parent ? parent.width * 0.5 : 640
    height: parent ? parent.height * 0.5 : 360

    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    y: isVisible ? (parent ? parent.height - height : 0) : (parent ? parent.height : 0)
    z: 2

    color: "#1e1e1e80"
    radius: 25
    border.color: "gold"
    border.width: 2

    Behavior on y {
        NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }

    function filenameFromVideoPath(path) {
        if (!path || path === "") return ""
        var decoded = decodeURIComponent(path)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var parts = decoded.split("/")
        return parts[parts.length - 1]   // just the filename
    }


    Rectangle {
        id: videoScreen
        anchors {
            top: parent.top; topMargin: 15
            left: parent.left; leftMargin: 15
            right: parent.right; rightMargin: 15
            bottom: timelineSlider.top; bottomMargin: 15
        }
        radius: 16
        color: "#000000"
        clip: true

        Video {
            id: videoPlayer
            anchors.fill: parent
            source: playerPanel.videoPath
            autoPlay: false
            muted: false
            volume: 1.0
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !playerPanel.isPlaying
            color: "#00000040"
        }

        Text {
            anchors.centerIn: parent
            text: playerPanel.videoPath === "" ? "No movie selected"
                                                : (videoPlayer.hasAudio ? "Ready: " + filenameFromVideoPath(playerPanel.videoPath)
                                                                       : "No audio track detected")
            color: "white"
            font.pixelSize: 20
            visible: !playerPanel.isPlaying
        }
    }

    // --- Timeline slider ---
    Slider {
        id: timelineSlider
        anchors {
            left: parent.left; right: parent.right
            bottom: buttonArea.top; bottomMargin: 10
            leftMargin: 15; rightMargin: 15
        }
        from: 0
        to: videoPlayer.duration
        value: videoPlayer.position

        onMoved: videoPlayer.seek(value)

        // ✅ Modern Connections syntax
        Connections {
            target: videoPlayer
            function onPositionChanged() {
                timelineSlider.value = videoPlayer.position
            }
        }
    }

    // --- Button bar ---
    Rectangle {
        id: buttonArea
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 15; rightMargin: 15; bottomMargin: 15
        }
        height: 100
        radius: 10
        color: "#1e1e1e80"
        border.color: "gold"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Button {
                text: "Play"
                Layout.fillWidth: true
                onClicked: {
                    if (playerPanel.videoPath !== "") {
                        videoPlayer.play()
                        playerPanel.isPlaying = true
                    }
                }
            }
            Button { text: "Pause"; Layout.fillWidth: true; onClicked: videoPlayer.pause() }
            Button { text: "Stop"; Layout.fillWidth: true; onClicked: { videoPlayer.stop(); playerPanel.isPlaying = false } }
            Button { text: "Full Screen"; Layout.fillWidth: true; onClicked: console.log("Full screen requested") }

            Button {
                text: "Volume +"
                Layout.fillWidth: true
                onClicked: {
                    if (videoPlayer.volume < 1.0) {
                        videoPlayer.volume += 0.1
                        console.log("Volume:", videoPlayer.volume)
                    }
                }
            }
            Button {
                text: "Volume -"
                Layout.fillWidth: true
                onClicked: {
                    if (videoPlayer.volume > 0.0) {
                        videoPlayer.volume -= 0.1
                        console.log("Volume:", videoPlayer.volume)
                    }
                }
            }
        }
    }
}