// landing_view.qml
// Scrolling mosaic tile landing view.
//
// Interaction:
//   Any click while animating  → pause (dim overlay appears)
//   Click a tile while paused  → open Detail_View_v2
//   Spacebar while paused      → resume
//   20 s of no mouse movement  → auto-resume with 1.5 s fade
//   Mouse movement while paused → reset 20 s timer + dim back to 0.35
//
// Cycle behaviour:
//   At 75% scroll progress    → prebuild_next_model() called (runs in Python)
//   At 100% scroll            → fade to black, swap model, fade back in (~850 ms)
//
// startPaused property: set true (via contentLoader.setSource properties)
//   when returning from Detail_View_v2 so the view begins paused with the
//   20 s auto-resume timer already running.

import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    // ── Public property — set via setSource to return paused from detail view
    property bool startPaused: false

    // ── Internal state ────────────────────────────────────────────────────────
    property string viewState:    "animating"   // "animating" | "paused"
    property real   scrollX:      0.0
    property var    tileModel:    []
    property real   canvasW:      4800
    property int    cycleGen:     0             // increments each new cycle → stagger
    property bool   _prebuildDone: false        // guards against duplicate prebuild calls

    // ── Initialise ────────────────────────────────────────────────────────────
    Component.onCompleted: {
        // Defer one event-loop tick so the Loader has finished propagating its
        // geometry to this item.  Without this, root.width/height can be 0 at
        // onCompleted time, producing invisible zero-size tiles and a ~20 s blank.
        Qt.callLater(_startView)
    }

    function _startView() {
        _loadModel()
        if (root.startPaused) {
            scrollAnim.stop()
            root.viewState       = "paused"
            pauseOverlay.opacity = 0.35
            pauseTimer.restart()
            progressiveDim.start()
        } else {
            scrollAnim.start()
        }
    }

    function _loadModel() {
        // Guard: if geometry still isn't ready, defer again
        if (root.width <= 0 || root.height <= 0) {
            Qt.callLater(_startView)
            return
        }
        var raw        = landingViewModel.build_tile_model(root.width, root.height)
        root.tileModel = JSON.parse(raw)
        root.canvasW   = _computeCanvasWidth(root.tileModel)
        scrollAnim.to       = root.canvasW
        scrollAnim.duration = landingViewModel.scroll_duration_ms
        root.scrollX        = 0
        root._prebuildDone  = false
        root.cycleGen++
    }

    function _computeCanvasWidth(model) {
        var m = 0
        for (var i = 0; i < model.length; i++) {
            var r = model[i].x + model[i].w
            if (r > m) m = r
        }
        return m > 0 ? m : 4800
    }

    // ── Scroll animation ──────────────────────────────────────────────────────
    NumberAnimation {
        id: scrollAnim
        target:   root
        property: "scrollX"
        from:     0
        to:       root.canvasW
        duration: landingViewModel.scroll_duration_ms
        easing.type: Easing.Linear
        running: false

        onStopped: {
            if (root.viewState === "animating") {
                // End of cycle — fade to black, swap model, fade back in
                cycleFadeAnim.start()
            }
        }
    }

    // ── Pre-build trigger at 75% of scroll ───────────────────────────────────
    onScrollXChanged: {
        if (viewState === "animating"
                && !_prebuildDone
                && canvasW > 0
                && scrollX >= canvasW * 0.75) {
            _prebuildDone = true
            landingViewModel.prebuild_next_model(root.width, root.height)
        }
    }

    // ── Cycle transition overlay (fades to black between batches) ─────────────
    Rectangle {
        id: cycleOverlay
        anchors.fill: parent
        color:   "black"
        opacity: 0.0
        z:       10
        enabled: false          // never intercepts mouse events
        visible: opacity > 0.0
    }

    // Fade to black → swap model → fade back in
    SequentialAnimation {
        id: cycleFadeAnim

        NumberAnimation {
            target: cycleOverlay; property: "opacity"
            to: 1.0; duration: 350; easing.type: Easing.InQuad
        }
        ScriptAction {
            script: {
                landingViewModel.on_cycle_complete()
                _loadModel()
                scrollAnim.start()
            }
        }
        NumberAnimation {
            target: cycleOverlay; property: "opacity"
            to: 0.0; duration: 500; easing.type: Easing.OutQuad
        }
    }

    // ── Clip area ─────────────────────────────────────────────────────────────
    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        // Back layer — heroes (slower parallax → depth effect)
        Item {
            id: backLayer
            x: -root.scrollX * 0.90
            width: root.canvasW; height: parent.height

            Repeater {
                model: root.tileModel.filter(function(t) { return t.layer === 0 })
                delegate: tileDelegate
            }
        }

        // Front layer — smalls (faster parallax → depth effect)
        Item {
            id: frontLayer
            x: -root.scrollX * 1.10
            width: root.canvasW; height: parent.height

            Repeater {
                model: root.tileModel.filter(function(t) { return t.layer === 1 })
                delegate: tileDelegate
            }
        }
    }

    // ── Pause overlay ─────────────────────────────────────────────────────────
    Rectangle {
        id: pauseOverlay
        anchors.fill: clipArea
        color: "black"
        opacity: 0.0
        z: 2
        visible: opacity > 0.0
    }

    // Animate in when pausing
    NumberAnimation {
        id: pauseFadeIn
        target: pauseOverlay; property: "opacity"
        to: 0.35; duration: 600; easing.type: Easing.InOutQuad
    }

    // Progressive dim while paused: 0.35 → 0.55 over 20 s
    NumberAnimation {
        id: progressiveDim
        target: pauseOverlay; property: "opacity"
        from: 0.35; to: 0.55; duration: 20000; easing.type: Easing.Linear
    }

    // Reset dim on mouse movement
    NumberAnimation {
        id: dimReset
        target: pauseOverlay; property: "opacity"
        to: 0.35; duration: 800
    }

    // Animate out when resuming
    SequentialAnimation {
        id: resumeAnim
        NumberAnimation {
            target: pauseOverlay; property: "opacity"
            to: 0.0; duration: 1500; easing.type: Easing.InOutQuad
        }
        ScriptAction {
            script: {
                root.viewState = "animating"
                scrollAnim.start()
            }
        }
    }

    // ── Auto-resume timer ─────────────────────────────────────────────────────
    Timer {
        id: pauseTimer
        interval: 20000
        repeat: false
        onTriggered: { if (root.viewState === "paused") resumeAnim.start() }
    }

    // ── Master mouse — movement tracking only ────────────────────────────────
    // propagateComposedEvents: true ensures ALL clicks pass through to tile
    // MouseAreas underneath regardless of z-order or item hierarchy.
    // Tile delegates handle both pause (while animating) and detail open (while paused).
    MouseArea {
        id: masterMouse
        anchors.fill: clipArea
        z: 3
        hoverEnabled: true
        propagateComposedEvents: true

        onClicked: function(mouse) { mouse.accepted = false }   // always pass through

        onPositionChanged: {
            if (root.viewState === "paused") {
                pauseTimer.restart()
                progressiveDim.stop()
                dimReset.start()
            }
        }
    }

    // ── Spacebar resume ───────────────────────────────────────────────────────
    Shortcut {
        sequence: "Space"
        enabled: root.viewState === "paused"
        onActivated: resumeAnim.start()
    }

    // ── Tile delegate ─────────────────────────────────────────────────────────
    Component {
        id: tileDelegate

        Item {
            id: tileRoot
            x: modelData.x
            y: modelData.y
            width:  modelData.w
            height: modelData.h

            opacity: 1.0
            property bool isHovered:  false
            property int  myStagger:  modelData.stagger_index
            property bool firstCycle: true

            scale: isHovered ? 1.06 : 1.0
            transformOrigin: Item.Center
            Behavior on scale { ScaleAnimator { duration: 180 } }

            // ── Stagger fade-in between cycles ────────────────────────────────
            Connections {
                target: root
                function onCycleGenChanged() {
                    if (tileRoot.firstCycle) {
                        tileRoot.opacity    = 1.0
                        tileRoot.firstCycle = false
                        return
                    }
                    tileRoot.opacity = 0.0
                    fadeDelay.interval = Math.min(tileRoot.myStagger * 25, 1200)
                    fadeDelay.start()
                }
            }

            Timer { id: fadeDelay; onTriggered: fadeIn.start() }

            OpacityAnimator {
                id: fadeIn
                target: tileRoot; from: 0; to: 1; duration: 400
            }

            // ── Poster image ───────────────────────────────────────────────────
            Image {
                id: poster
                anchors.fill: parent
                source:        modelData.poster_uri
                fillMode:      Image.PreserveAspectCrop
                asynchronous:  true
                smooth:        true
                sourceSize.width:  modelData.w
                sourceSize.height: modelData.h
            }

            // ── Fallback tile ─────────────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                color: "#12121e"
                visible: poster.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text:        modelData.title
                    color:       "#777777"
                    font.pixelSize: modelData.species === "hero" ? 16 : 12
                    wrapMode:    Text.WordWrap
                    width:       parent.width - 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // ── Hidden-gem amber border ────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                color:        "transparent"
                border.color: "#FFC107"
                border.width: 2
                opacity:      0.85
                visible:      modelData.is_hidden_gem === true
            }

            // ── Hover overlay — title + year ───────────────────────────────────
            Rectangle {
                id: hoverOverlay
                anchors.bottom: parent.bottom
                width:  parent.width
                height: parent.height * 0.30
                color:  "#CC000000"
                opacity: tileRoot.isHovered ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity { OpacityAnimator { duration: 180 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text:           modelData.title
                        color:          "white"
                        font.pixelSize: modelData.species === "hero" ? 18 : 13
                        font.bold:      true
                        width:          hoverOverlay.width - 12
                        elide:          Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        text:           modelData.year
                        color:          "#bbbbbb"
                        font.pixelSize: modelData.species === "hero" ? 15 : 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ── Tile click handler ─────────────────────────────────────────────
            // Handles both states:
            //   animating → pause the scroll
            //   paused    → open Detail_View_v2
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: tileRoot.isHovered = true
                onExited:  tileRoot.isHovered = false

                onClicked: function(mouse) {
                    if (root.viewState === "animating") {
                        root.viewState = "paused"
                        scrollAnim.stop()
                        pauseOverlay.opacity = 0.0
                        pauseFadeIn.start()
                        pauseTimer.restart()
                        Qt.callLater(function() { progressiveDim.start() })
                    } else {
                        window.previousLoaderSource = "landing_view.qml"
                        contentLoader.setSource("Detail_View_v2.qml", {
                            "imagePath": modelData.image_uri,
                            "xmlPath":   modelData.xml_path,
                            "moviePath": modelData.movie_path
                        })
                    }
                    mouse.accepted = true
                }
            }
        }
    }
}
