import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

Rectangle {
    id: playerPanel

    // --- THE THEATER DIMMER ---
    Rectangle {
        id: theaterDimmer
        // Use a massive size to ensure it covers the entire application window
        width: 5000; height: 5000
        anchors.centerIn: parent
        
        color: "black"
        // Fade in when visible, fade out when hidden
        opacity: playerPanel.isVisible ? 0.85 : 0.0
        z: -1 // Sits behind the gold-bordered player
        
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }

        // Clicking the darkened area closes the player
        MouseArea {
            anchors.fill: parent
            onClicked: playerPanel.isVisible = false
        }
    }

    // REVERSED 2: We keep isVisible, but add an ALIAS so the runButton doesn't crash the app
    property alias isVideoPanelVisible: playerPanel.isVisible 
    
    property bool isVisible: false // Set to false so it starts hidden
    property bool isPlaying: false
    property string videoPath: ""

   
    height: parent ? parent.height * 1.20 : 1000
    width: height * 1.333
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    
    // REVERSED 3: Kept your original y logic exactly as written
    
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
        return parts[parts.length - 1]
    }

    onIsPlayingChanged: {
        if (isPlaying && videoPath !== "") {
            console.log("🎥 Auto‑playing video:", videoPath)
            videoPlayer.play()
        } else {
            videoPlayer.pause()
        }
    }

    onVideoPathChanged: {
        console.log("🎥 PlayerPanel received videoPath:", videoPath)
    }

    Rectangle {
        id: videoScreen
        anchors {
            top: parent.top; topMargin: 15
            left: parent.left; leftMargin: 15
            right: parent.right; rightMargin: 15
            bottom: timelineSlider.top; bottomMargin: 15
            //bottom: timelineSlider.top; bottomMargin: -50


        }
        radius: 16
        color: "#000000"
        clip: true

        // REVERSED 4: Put your original Video element back exactly as it was
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

    Slider {
        id: timelineSlider
        anchors {
            left: parent.left; right: parent.right
            bottom: buttonArea.top; bottomMargin: -50
            leftMargin: 15; rightMargin: 15
        }
        from: 0
        to: videoPlayer.duration
        value: videoPlayer.position
        onMoved: videoPlayer.seek(value)

        Connections {
            target: videoPlayer
            function onPositionChanged() {
                timelineSlider.value = videoPlayer.position
            }
        }
    }

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
                    }
                }
            }
            Button {
                text: "Volume -"
                Layout.fillWidth: true
                onClicked: {
                    if (videoPlayer.volume > 0.0) {
                        videoPlayer.volume -= 0.1
                    }
                }
            }
        }
    }
}