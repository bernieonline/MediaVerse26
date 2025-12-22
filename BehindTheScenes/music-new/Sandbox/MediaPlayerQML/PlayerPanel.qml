// PlayerPanel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: playerPanel
    property bool isVisible: true
    property bool isPlaying: false
    property string videoPath: ""

    width: parent ? parent.width * 0.5 * 0.8 : 512
    height: parent ? parent.height * 0.5 : 360

    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    y: isVisible ? (parent ? parent.height - height : 0) : (parent ? parent.height : 0)
    z: 2

    // Set base color to transparent so the blur shows through
    color: "transparent"
    radius: 25
    border.color: "gold"
    border.width: 2

    Behavior on y {
        NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }

    // --- 1. THE FROSTED GLASS ENGINE ---
    ShaderEffectSource {
        id: glassSource
        anchors.fill: parent
        // 'root' is your main background item from Framework-1.qml
        sourceItem: root 
        // Important: This maps the blur to the panel's moving position
        sourceRect: Qt.rect(playerPanel.x, playerPanel.y, playerPanel.width, playerPanel.height)
        live: true
        visible: false
    }

    Rectangle {
        id: blurContainer
        anchors.fill: parent
        color: "transparent"
        radius: playerPanel.radius
        clip: true // Keeps the blur inside the rounded corners

        FastBlur {
            anchors.fill: parent
            source: glassSource
            radius: 100 // High radius for that "Heavy Frost" look
            transparentBorder: true
        }

        // The "Density" Darkening Layer
        Rectangle {
            anchors.fill: parent
            color: "#BF121212" 
            radius: playerPanel.radius
        }
    }

    // --- 2. VIDEO SCREEN ---
    Rectangle {
        id: videoScreen
        anchors {
            top: parent.top; topMargin: 15
            left: parent.left; leftMargin: 15
            right: parent.right; rightMargin: 15
            bottom: timelineSlider.top; bottomMargin: 15
        }
        radius: 16
        color: "#000000" // Keep screen pure black
        clip: true

        Video {
            id: videoPlayer
            anchors.fill: parent
            source: playerPanel.videoPath
            autoPlay: false
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !playerPanel.isPlaying
            color: "#66000000" // Slightly darker overlay when paused
        }

        Text {
            anchors.centerIn: parent
            text: playerPanel.videoPath === "" ? "No movie selected"
                    : (videoPlayer.hasAudio ? "Ready: " + filenameFromVideoPath(playerPanel.videoPath)
                    : "No audio track detected")
            color: "white"
            font.pixelSize: 18
            font.bold: true
            visible: !playerPanel.isPlaying
        }
    }

    // --- 3. TIMELINE SLIDER ---
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
        
        // Custom styling for a "MediaVerse" look
        background: Rectangle {
            height: 4; radius: 2; color: "#33FFFFFF"
            Rectangle {
                width: timelineSlider.visualPosition * parent.width
                height: parent.height; color: "gold"; radius: 2
            }
        }
    }

    // --- 4. BUTTON BAR (Nested Frost) ---
    Rectangle {
        id: buttonArea
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 15; rightMargin: 15; bottomMargin: 15
        }
        height: 80
        radius: 15
        color: "#22FFFFFF" // Subtle highlights on the button tray
        border.color: "#44FFD700" // Faded gold border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Using standard Buttons but the glass background will make them pop
            Button { text: "Play"; Layout.fillWidth: true; onClicked: { videoPlayer.play(); playerPanel.isPlaying = true } }
            Button { text: "Pause"; Layout.fillWidth: true; onClicked: videoPlayer.pause() }
            Button { text: "Stop"; Layout.fillWidth: true; onClicked: { videoPlayer.stop(); playerPanel.isPlaying = false } }
            Button { text: "Vol +"; Layout.fillWidth: true; onClicked: videoPlayer.volume = Math.min(1.0, videoPlayer.volume + 0.1) }
            Button { text: "Vol -"; Layout.fillWidth: true; onClicked: videoPlayer.volume = Math.max(0.0, videoPlayer.volume - 0.1) }
        }
    }

    // Helper function remains the same
    function filenameFromVideoPath(path) {
        if (!path || path === "") return ""
        var decoded = decodeURIComponent(path)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var parts = decoded.split("/")
        return parts[parts.length - 1]
    }
}