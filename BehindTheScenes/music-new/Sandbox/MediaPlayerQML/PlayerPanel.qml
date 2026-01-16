import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

Rectangle {
    id: playerPanel

    // ⭐ PROPERTY SYNC: Changed from panelVisible to isVideoPanelVisible to match Framework-1
    property bool isVideoPanelVisible: false
    property bool startupComplete: false
    property bool isPlaying: false
    property string videoPath: ""

    // ⭐ GEOMETRY: Centered 2/3 width
    width: parent ? parent.width * 0.66 : 800
    height: parent ? parent.height * 0.5 : 450
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    // Safe Y logic
    y: {
        if (!parent || !startupComplete) return 5000;
        return isVideoPanelVisible ? parent.height - height - 20 : parent.height + 50
    }
    
    z: 100 

    Component.onCompleted: {
        if (parent) playerPanel.y = parent.height
        // Simple internal timer to enable movement
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 300; repeat: false; running: true; onTriggered: playerPanel.startupComplete = true }', playerPanel);
    }

    Behavior on y {
        enabled: startupComplete
        NumberAnimation { duration: 600; easing.type: Easing.OutQuart }
    }

    color: "#F21A1A1A" 
    radius: 25
    border.color: "gold"
    border.width: 2

    // --- Video Screen ---
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
            // ⭐ PATH SAFETY: Format the path for Windows W:/ compatibility
            source: playerPanel.formatPath(playerPanel.videoPath)
            autoPlay: false
            fillMode: 1 
        }

        // Overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !playerPanel.isPlaying
            color: "#AA000000"
            
            ColumnLayout {
                anchors.centerIn: parent
                Text {
                    text: playerPanel.videoPath === "" ? "No movie selected" : "Ready to Play"
                    color: "gold"
                    font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: filenameFromVideoPath(playerPanel.videoPath)
                    color: "white"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- Timeline Slider ---
    Slider {
        id: timelineSlider
        anchors {
            left: parent.left; right: parent.right
            bottom: buttonArea.top; bottomMargin: 10
            leftMargin: 25; rightMargin: 25
        }
        from: 0
        to: Math.max(1, videoPlayer.duration)
        value: videoPlayer.position
        onMoved: videoPlayer.seek(value)
    }

    // --- Button Bar ---
    Rectangle {
        id: buttonArea
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 15; rightMargin: 15; bottomMargin: 15
        }
        height: 70
        radius: 15
        color: "#22FFFFFF"

        RowLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 20

            Button { 
                text: playerPanel.isPlaying ? "PAUSE" : "PLAY"
                Layout.fillWidth: true
                onClicked: {
                    if (playerPanel.isPlaying) {
                        videoPlayer.pause()
                    } else {
                        videoPlayer.play()
                    }
                    playerPanel.isPlaying = !playerPanel.isPlaying
                }
            }
            
            Button { 
                text: "CLOSE"
                Layout.fillWidth: true
                onClicked: {
                    videoPlayer.stop()
                    playerPanel.isPlaying = false
                    playerPanel.isVideoPanelVisible = false // Toggle off
                }
            }

            Button { text: "Vol +"; Layout.preferredWidth: 60; onClicked: videoPlayer.volume = Math.min(1.0, videoPlayer.volume + 0.1) }
            Button { text: "Vol -"; Layout.preferredWidth: 60; onClicked: videoPlayer.volume = Math.max(0.0, videoPlayer.volume - 0.1) }
        }
    }

    // ⭐ NEW: Ensures Windows paths like W:\Collection work in QML
    function formatPath(path) {
        if (!path) return ""
        var p = path.replace(/\\/g, "/")
        if (!p.startsWith("file:///")) p = "file:///" + p
        return p
    }

    function filenameFromVideoPath(path) {
        if (!path || path === "") return ""
        var decoded = decodeURIComponent(path)
        var parts = decoded.split(/[\\/]/)
        return parts[parts.length - 1]
    }
}