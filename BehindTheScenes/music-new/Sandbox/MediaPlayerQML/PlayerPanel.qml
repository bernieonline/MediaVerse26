import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

Rectangle {
    id: playerPanel

    // ----------------------------------------------------
    // Properties & Connections
    // ----------------------------------------------------
    property var rootWindow                  // Linked to 'window' in Framework-1.qml
    property bool isPlaying: false
    property string videoPath: ""
    property alias videoPlayer: videoPlayer  // Allows Framework-1 to control the engine

    // Helper to check the source of truth in the main window
    readonly property bool isActuallyVisible: rootWindow ? rootWindow.isVideoPanelVisible : false

    // ----------------------------------------------------
    // Panel Dimensions & Positioning
    // ----------------------------------------------------
    width: parent ? parent.width * 0.70 : 800
    height: parent ? parent.height * 0.85 : 600
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    
    // Y Position: Slides up when visible, slides off-screen when hidden
    y: isActuallyVisible ? (parent.height - height - 20) : (parent.height + 100)
    z: 1000

    color: "#1e1e1e"
    radius: 25
    border.color: "gold"
    border.width: 2

    // Smooth movement for the slide effect
    Behavior on y {
        NumberAnimation { duration: 500; easing.type: Easing.OutQuart }
    }

    // ----------------------------------------------------
    // Internal Logic Functions
    // ----------------------------------------------------
    function closePlayer() {
        console.log("🛑 PlayerPanel: Stopping video and closing")
        videoPlayer.stop()
        playerPanel.isPlaying = false
        
        // Tells Framework-1.qml to update window.isVideoPanelVisible
        if (rootWindow) {
            rootWindow.isVideoPanelVisible = false
        }
    }

    function filenameFromVideoPath(path) {
        if (!path || path === "") return ""
        var decoded = decodeURIComponent(path)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var parts = decoded.split("/")
        return parts[parts.length - 1]
    }

    // Auto-play/pause based on the isPlaying property
    onIsPlayingChanged: {
        if (isPlaying && videoPath !== "") {
            videoPlayer.play()
        } else {
            videoPlayer.pause()
        }
    }

    // ----------------------------------------------------
    // UI Elements
    // ----------------------------------------------------

    // --- 1. THE THEATER DIMMER (Background) ---
    Rectangle {
        id: theaterDimmer
        width: 5000; height: 5000
        anchors.centerIn: parent
        color: "black"
        // Fades in/out based on the panel's visibility
        opacity: playerPanel.isActuallyVisible ? 0.85 : 0.0
        z: -1 
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }

        // Clicking the dark area also closes the player
        MouseArea {
            anchors.fill: parent
            onClicked: playerPanel.closePlayer()
        }
    }

    // --- 2. THE VIDEO SCREEN ---
    Rectangle {
        id: videoScreen
        anchors {
            top: parent.top; topMargin: 20
            left: parent.left; leftMargin: 20
            right: parent.right; rightMargin: 20
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
            volume: volumeSlider.value // Linked to the volume slider below
        }

        // Dark overlay and text when no video is playing
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !playerPanel.isPlaying
            color: "#00000090"
            
            Text {
                anchors.centerIn: parent
                text: playerPanel.videoPath === "" ? "No movie selected" : "Ready: " + filenameFromVideoPath(playerPanel.videoPath)
                color: "white"
                font.pixelSize: 22
                font.bold: true
            }
        }
    }

    // --- 3. THE TIMELINE SLIDER (Scrubbing) ---
    Slider {
        id: timelineSlider
        anchors.bottom: buttonArea.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        
        from: 0
        to: videoPlayer.duration
        value: videoPlayer.position
        
        // Allows the user to seek through the movie
        onMoved: videoPlayer.seek(value)
    }

    // --- 4. THE CONTROL BUTTON AREA ---
    Rectangle {
        id: buttonArea
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 20
        width: parent.width - 40
        height: 100
        color: "#2a2a2a"
        radius: 15
        border.color: "#3d3d3d"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 30

            // Standard Play/Pause Button
            Button {
                text: playerPanel.isPlaying ? "Pause" : "Play"
                Layout.preferredWidth: 120
                onClicked: {
                    if (playerPanel.isPlaying) {
                        videoPlayer.pause()
                        playerPanel.isPlaying = false
                    } else if (playerPanel.videoPath !== "") {
                        videoPlayer.play()
                        playerPanel.isPlaying = true
                    }
                }
            }

            // Audio Volume Control
            RowLayout {
                spacing: 15
                Text { text: "VOL"; color: "white"; font.pixelSize: 14; font.bold: true }
                Slider {
                    id: volumeSlider
                    from: 0.0
                    to: 1.0
                    value: 0.8 // Starts at 80% volume
                    Layout.preferredWidth: 150
                }
                Text { 
                    text: Math.round(volumeSlider.value * 100) + "%"
                    color: "white"; font.pixelSize: 14 
                }
            }

            // Pushes the Close button to the far right
            Item { Layout.fillWidth: true } 

            // Standard Close Button (Matched Style)
            Button {
                text: "Close"
                Layout.preferredWidth: 120
                onClicked: playerPanel.closePlayer()
            }
        }
    }
}