import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import Qt5Compat.GraphicalEffects

Item {
    id: playerRoot
    anchors.fill: parent 

    property bool isVideoPanelVisible: false
    property bool startupComplete: false
    property bool isPlaying: false
    property string videoPath: ""

    // --- THE THEATER DIMMER ---
    Rectangle {
        id: theaterDimmer
        anchors.fill: parent
        color: "black"
        opacity: playerRoot.isVideoPanelVisible ? 0.92 : 0.0 // Slightly darker for SD content
        z: 1 
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            enabled: playerRoot.isVideoPanelVisible
            onClicked: playerRoot.isVideoPanelVisible = false
        }
    }

    // --- THE PLAYER BOX ---
    Rectangle {
        id: playerPanel
        
        // SD Capping: 1280px is the "Sweet Spot" for 480p on a 4K monitor
        width: Math.min(parent.width * 0.66, 1280)
    
        height: width * 0.75 
        
        anchors.horizontalCenter: parent.horizontalCenter
        z: 2 

        y: {
            if (!startupComplete) return parent.height + 150;
            return isVideoPanelVisible ? (parent.height - height) / 2 : parent.height + 150
        }

        Behavior on y {
            enabled: startupComplete
            NumberAnimation { duration: 600; easing.type: Easing.OutQuart }
        }

        color: "#1A1A1A" 
        radius: 20
        border.color: "gold"
        border.width: 2
        clip: true

        Component.onCompleted: playerRoot.startupComplete = true

        // --- Video Screen with Effects ---
        Rectangle {
            id: videoContainer
            anchors {
                top: parent.top; topMargin: 10
                left: parent.left; leftMargin: 10
                right: parent.right; rightMargin: 10
                bottom: timelineSlider.top; bottomMargin: 10
            }
            color: "black"; radius: 10; clip: true

            Video {
                id: videoPlayer
                anchors.fill: parent
                source: playerRoot.formatPath(playerRoot.videoPath)
                autoPlay: false
                fillMode: 1 // Fixed: Uses integer for PreserveAspectFit
                
                smooth: true
                antialiasing: true
            }

            // ⭐ Qt5Compat Effect: Softens 4K magnification noise
            FastBlur {
                anchors.fill: videoPlayer
                source: videoPlayer
                radius: 8 // Very subtle blur to blend pixelated edges
                transparentBorder: true
                visible: playerRoot.isVideoPanelVisible // Only process when visible
            }
        }

        // --- Controls ---
        Slider {
            id: timelineSlider
            anchors {
                left: parent.left; right: parent.right
                bottom: buttonArea.top; bottomMargin: 10
                leftMargin: 20; rightMargin: 20
            }
            from: 0; to: Math.max(1, videoPlayer.duration)
            value: videoPlayer.position
            onMoved: videoPlayer.seek(value)
        }

        Rectangle {
            id: buttonArea
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
            height: 60; radius: 10; color: "#22FFFFFF"

            RowLayout {
                anchors.fill: parent; anchors.margins: 10
                Button { 
                    text: playerRoot.isPlaying ? "PAUSE" : "PLAY"
                    Layout.fillWidth: true
                    onClicked: {
                        if (playerRoot.isPlaying) videoPlayer.pause()
                        else videoPlayer.play()
                        playerRoot.isPlaying = !playerRoot.isPlaying
                    }
                }
                Button { 
                    text: "EXIT THEATER"
                    Layout.fillWidth: true
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
        if (!path) return ""
        var p = path.replace(/\\/g, "/")
        if (!p.startsWith("file:///")) p = "file:///" + p
        return p
    }

    function filenameFromVideoPath(path) {
        if (!path) return ""
        var parts = path.split(/[\\/]/)
        return parts[parts.length - 1]
    }
}