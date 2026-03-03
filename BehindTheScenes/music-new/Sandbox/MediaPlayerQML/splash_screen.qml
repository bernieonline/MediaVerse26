// splash_screen.qml
// Scattered-photo gallery with cinematic blur/darkness hero transition.
//
// Requires context property: splashLayout (list produced by splash_layout.py)
// Each item: { x, y, width, height, rotation, z, path, title }
//
// x, y      — fractions of root.width / root.height for scattered position.
// width     — fraction of root.width.  QML derives height as width * 1.48.
// The hero card always snaps to the exact centre of the left 75 % of the
// display area; its Python x/y are used only when it returns to background.

import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    property int heroIndex:     0   // which card is currently the hero
    property int revealedCount: 0   // drives the stagger reveal

    // ── Dark stage ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#0d0d0d"
    }

    // ── Photo cards ───────────────────────────────────────────────────────────
    Repeater {
        id: cardRepeater
        model: splashLayout

        delegate: Item {
            id: card

            property int  cardIndex: index
            property bool isHero:   cardIndex === root.heroIndex

            // ── Sizing ───────────────────────────────────────────────────────
            // Width is a fraction of the component width.
            // Height is always width × 1.48 in pixels — consistent portrait
            // ratio regardless of screen aspect, not affected by root.height.
            width:    modelData.width * root.width
            height:   width * 1.48
            rotation: modelData.rotation
            z:        isHero ? 999 : modelData.z

            // ── Position ─────────────────────────────────────────────────────
            // Hero: pinned to the exact centre of the left 75 % of the area.
            // Others: use the Python-provided scattered coordinates.
            x: card.isHero
                ? root.width  * 0.375 - width  * 0.5
                : modelData.x * root.width
            y: card.isHero
                ? root.height * 0.5   - height * 0.5
                : modelData.y * root.height

            // Stagger reveal — hidden until staggerTimer counts up to this index.
            opacity: cardIndex < root.revealedCount ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on x       { NumberAnimation { duration: 1500; easing.type: Easing.InOutCubic } }
            Behavior on y       { NumberAnimation { duration: 1500; easing.type: Easing.InOutCubic } }

            // ── Image ────────────────────────────────────────────────────────
            Image {
                id: cardImage
                anchors.fill:  parent
                source:        modelData.path
                fillMode:      Image.PreserveAspectCrop
                smooth:        true
                asynchronous:  true
                layer.enabled: true     // required for FastBlur source
            }

            // ── Blur (Qt5Compat) ──────────────────────────────────────────────
            FastBlur {
                anchors.fill:      parent
                source:            cardImage
                radius:            card.isHero ? 0 : 48
                transparentBorder: false

                Behavior on radius { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
            }

            // ── Darkness overlay ─────────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                color:        "black"
                opacity:      card.isHero ? 0.0 : 0.55
                z:            1

                Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
            }

            // ── Photo-border frame ────────────────────────────────────────────
            Rectangle {
                anchors.fill:    parent
                anchors.margins: -2
                color:           "transparent"
                border.color:    "white"
                border.width:    2
                opacity:         card.isHero ? 0.55 : 0.10
                z:               2

                Behavior on opacity { NumberAnimation { duration: 1200 } }
            }

            // ── Title bar — delayed fade-in on hero only ──────────────────────
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height:         titleLabel.implicitHeight + 22
                color:          Qt.rgba(0, 0, 0, 0.65)
                opacity:        card.isHero ? 1.0 : 0.0
                z:              3

                Behavior on opacity {
                    SequentialAnimation {
                        // Pause on the way in so the blur clears first;
                        // instant on the way out.
                        PauseAnimation  { duration: card.isHero ? 900 : 0 }
                        NumberAnimation { duration: 700; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    id: titleLabel
                    anchors.left:    parent.left
                    anchors.bottom:  parent.bottom
                    anchors.margins: 12
                    width:           parent.width - 24
                    text:            modelData.title
                    color:           "white"
                    font.pixelSize:  Math.max(14, card.width * 0.07)
                    font.bold:       true
                    font.letterSpacing: 3.0
                    wrapMode:        Text.WordWrap
                }
            }
        }
    }

    // ── Hero cycle — every 5 s, started after stagger completes ──────────────
    Timer {
        id: heroTimer
        interval: 5000
        repeat:   true
        running:  false
        onTriggered: root.heroIndex = (root.heroIndex + 1) % splashLayout.length
    }

    // ── Stagger reveal — one card every 150 ms ────────────────────────────────
    Timer {
        id: staggerTimer
        interval: 150
        repeat:   true
        running:  false
        onTriggered: {
            if (root.revealedCount < splashLayout.length) {
                root.revealedCount++
            } else {
                stop()
                heroTimer.start()
            }
        }
    }

    Component.onCompleted: {
        if (splashLayout && splashLayout.length > 0) {
            staggerTimer.start()
        }
    }
}
