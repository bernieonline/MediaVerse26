import QtQuick 2.15
import QtMultimedia 5.15

/*
    PlaybackController.qml
    -----------------------
    A small, self-contained module that wraps the Video element
    and exposes a clean API for controlling playback.

    This lets your PlayerPanel stay simple and focused on layout,
    while all playback logic lives here in one safe place.
*/

Item {
    id: controller

    // ------------------------------------------------------------
    // PUBLIC PROPERTIES (these are what PlayerPanel will use)
    // ------------------------------------------------------------

    // The video file path (QML alias to the Video element's source)
    property alias source: videoPlayer.source

    // Whether the video is currently playing
    property bool isPlaying: false

    // Duration and position are read-only from the Video element
    property real duration: videoPlayer.duration
    property real position: videoPlayer.position

    // Volume (0.0 to 1.0)
    property real volume: videoPlayer.volume


    // ------------------------------------------------------------
    // PUBLIC SIGNALS (PlayerPanel can connect to these)
    // ------------------------------------------------------------

    signal started()          // Fired when playback begins
    signal paused()           // Fired when playback pauses
    signal stopped()          // Fired when playback stops
    signal finished()         // Fired when video reaches the end
    signal positionChanged(real pos)   // Fired when playback position updates
    signal durationChanged(real dur)   // Fired when duration becomes known


    // ------------------------------------------------------------
    // INTERNAL VIDEO ENGINE
    // ------------------------------------------------------------
    // This is the actual QtMultimedia Video element.
    // It handles decoding, playback, and timing.
    // We do NOT expose it directly to PlayerPanel.
    // PlayerPanel interacts ONLY with the controller API above.
    // ------------------------------------------------------------

    Video {
        id: videoPlayer
        autoPlay: false
        muted: false
        volume: 1.0

        // Emit controller-level signals when internal state changes
        onPositionChanged: controller.positionChanged(position)
        onDurationChanged: controller.durationChanged(duration)
        onStopped: controller.stopped()
        onPlaying: controller.started()
        onPaused: controller.paused()

        // Detect when the video reaches the end
        onPlaybackStateChanged: {
            if (playbackState === Video.EndOfMedia)
                controller.finished()
        }
    }


    // ------------------------------------------------------------
    // PUBLIC METHODS (safe API for PlayerPanel)
    // ------------------------------------------------------------

    // Start playback
    function play() {
        videoPlayer.play()
        controller.isPlaying = true
    }

    // Pause playback
    function pause() {
        videoPlayer.pause()
        controller.isPlaying = false
    }

    // Stop playback completely
    function stop() {
        videoPlayer.stop()
        controller.isPlaying = false
    }

    // Seek to a specific time (in milliseconds)
    function seek(ms) {
        videoPlayer.seek(ms)
    }

    // Adjust volume safely (clamped between 0 and 1)
    function setVolume(v) {
        videoPlayer.volume = Math.max(0, Math.min(1, v))
    }
}