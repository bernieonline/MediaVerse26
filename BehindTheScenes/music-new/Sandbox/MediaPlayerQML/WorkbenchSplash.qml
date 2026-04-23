import QtQuick 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  WorkbenchSplash — cinematic rotating backdrop for all Workbench views.
//
//  Loads Assets/Splash.json (title, multi-line quote, delay, offsets).
//  Images live in Assets/Splash/.  Two Image items crossfade with Ken Burns
//  zoom.  Quote text sits in the bottom strip below the glass panels.
//
//  Anchor this inside the display area at z:0 behind the centred panels.
//  Set  layer.enabled: true  in the parent to allow ShaderEffectSource capture.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root
    anchors.fill: parent

    // ── Data — supplied as a context property from Python ────────────────────
    //  workbenchSplashData: list of { image, title, quote[], delay, uri }
    //  uri is pre-built by Framework.py using Path.as_uri()
    property var  entries:    (typeof workbenchSplashData !== "undefined") ? workbenchSplashData : []
    property int  currentIdx: 0
    property bool aIsActive:  true   // which Image is currently showing

    // ── Helpers ──────────────────────────────────────────────────────────────
    function imageUrl(idx) {
        if (entries.length === 0) return ""
        return entries[idx % entries.length].uri || ""
    }

    function currentEntry() {
        return entries.length > 0 ? entries[currentIdx % entries.length] : null
    }

    function quoteText(entry) {
        if (!entry) return ""
        if (entry.quote && entry.quote.length > 0)
            return entry.quote.join("\n")
        return ""
    }

    // Called when a new image becomes fully visible
    function showEntry(entry) {
        if (!entry) return
        titleText.text     = entry.title || ""
        quoteTextItem.text = quoteText(entry)

        // Use delay from json; clamp to 7-20 s
        var ms = Math.min(20000, Math.max(7000, (entry.delay || 10) * 1000))
        holdTimer.interval = ms
        holdTimer.restart()

        // Fade caption in
        captionFader.stop()
        captionArea.opacity = 0
        captionFaderIn.start()
    }

    // ── Bootstrap ─────────────────────────────────────────────────────────────
    Component.onCompleted: {
        if (entries.length === 0) return

        imgA.source = imageUrl(0)
        kbAnimA.restart()

        if (entries.length > 1)
            imgB.source = imageUrl(1)

        showEntry(currentEntry())
    }

    // ── Dark base ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#030810"
    }

    // ── Image A ───────────────────────────────────────────────────────────────
    Image {
        id: imgA
        anchors.fill: parent
        fillMode:     Image.PreserveAspectCrop
        asynchronous: true
        cache:        true
        opacity:      1.0

        property real zoom: 1.0
        transform: Scale {
            xScale: imgA.zoom;    yScale: imgA.zoom
            origin.x: imgA.width  / 2
            origin.y: imgA.height / 2
        }
    }
    NumberAnimation {
        id: kbAnimA
        target: imgA; property: "zoom"
        from: 1.0; to: 1.10
        duration: 22000
        easing.type: Easing.InOutSine
        running: false
    }

    // ── Image B ───────────────────────────────────────────────────────────────
    Image {
        id: imgB
        anchors.fill: parent
        fillMode:     Image.PreserveAspectCrop
        asynchronous: true
        cache:        true
        opacity:      0.0

        property real zoom: 1.0
        transform: Scale {
            xScale: imgB.zoom;    yScale: imgB.zoom
            origin.x: imgB.width  / 2
            origin.y: imgB.height / 2
        }
    }
    NumberAnimation {
        id: kbAnimB
        target: imgB; property: "zoom"
        from: 1.0; to: 1.10
        duration: 22000
        easing.type: Easing.InOutSine
        running: false
    }

    // ── Crossfade animations ──────────────────────────────────────────────────
    NumberAnimation {
        id: fadeInB; target: imgB; property: "opacity"
        from: 0; to: 1; duration: 1800; easing.type: Easing.InOutSine
        onFinished: {
            root.aIsActive  = false
            root.currentIdx = (root.currentIdx + 1) % root.entries.length
            // Pre-load next frame into A
            var nxtIdx = (root.currentIdx + 1) % root.entries.length
            imgA.source = root.imageUrl(nxtIdx)
            showEntry(root.currentEntry())
        }
    }
    NumberAnimation {
        id: fadeOutA; target: imgA; property: "opacity"
        from: 1; to: 0; duration: 1800; easing.type: Easing.InOutSine
    }

    NumberAnimation {
        id: fadeInA; target: imgA; property: "opacity"
        from: 0; to: 1; duration: 1800; easing.type: Easing.InOutSine
        onFinished: {
            root.aIsActive  = true
            root.currentIdx = (root.currentIdx + 1) % root.entries.length
            var nxtIdx = (root.currentIdx + 1) % root.entries.length
            imgB.source = root.imageUrl(nxtIdx)
            showEntry(root.currentEntry())
        }
    }
    NumberAnimation {
        id: fadeOutB; target: imgB; property: "opacity"
        from: 1; to: 0; duration: 1800; easing.type: Easing.InOutSine
    }

    // ── Hold timer — switches to next image ───────────────────────────────────
    Timer {
        id: holdTimer
        interval: 10000
        repeat:   false
        running:  false
        onTriggered: {
            if (root.entries.length < 2) return
            // Fade caption out first, then crossfade images
            captionFaderIn.stop()
            captionFader.start()

            if (root.aIsActive) {
                imgB.zoom = 1.0
                kbAnimB.restart()
                fadeInB.start()
                fadeOutA.start()
            } else {
                imgA.zoom = 1.0
                kbAnimA.restart()
                fadeInA.start()
                fadeOutB.start()
            }
        }
    }

    // ── Caption fade animations ───────────────────────────────────────────────
    NumberAnimation {
        id: captionFaderIn; target: captionArea; property: "opacity"
        from: 0; to: 1; duration: 1200; easing.type: Easing.InOutSine
    }
    NumberAnimation {
        id: captionFader; target: captionArea; property: "opacity"
        from: 1; to: 0; duration: 900; easing.type: Easing.InOutSine
    }

    // ── Left + right edge vignette ─────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.80) }
            GradientStop { position: 0.18; color: "transparent" }
            GradientStop { position: 0.82; color: "transparent" }
            GradientStop { position: 1.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.80) }
        }
    }

    // ── Top + bottom vignette ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.70) }
            GradientStop { position: 0.10; color: "transparent" }
            GradientStop { position: 0.80; color: "transparent" }
            GradientStop { position: 1.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.92) }
        }
    }

    // ── Caption strip — bottom of screen, outside panel footprint ─────────────
    //  The centred glass panel is 84% tall → bottom strip is 8% of height.
    //  We give the caption slightly more room: bottom 16% so quotes are visible.
    Item {
        id: captionArea
        anchors.left:         parent.left
        anchors.right:        parent.right
        anchors.bottom:       parent.bottom
        height:               parent.height * 0.16
        opacity:              0

        Column {
            anchors.left:         parent.left
            anchors.leftMargin:   parent.width * 0.06
            anchors.right:        parent.right
            anchors.rightMargin:  parent.width * 0.32   // clear the right side WorkButtons column
            anchors.bottom:       parent.bottom
            anchors.bottomMargin: parent.height * 0.18
            spacing:              8

            Text {
                id: titleText
                text:  ""
                font.family:        "Segoe UI"
                font.pixelSize:     28
                font.bold:          true
                font.letterSpacing: 3
                color:              "#d8f0e0"
                style:              Text.Raised
                styleColor:         Qt.rgba(0, 0, 0, 0.90)
            }

            Text {
                id: quoteTextItem
                width:     parent.width
                text:      ""
                wrapMode:  Text.WordWrap
                font.family:        "Segoe UI"
                font.pixelSize:     22
                font.italic:        true
                color:              Qt.rgba(0.85, 0.95, 0.88, 0.78)
                lineHeight:         1.45
                style:              Text.Raised
                styleColor:         Qt.rgba(0, 0, 0, 0.85)
            }
        }
    }
}
