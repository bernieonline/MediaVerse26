import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: splashRoot
    anchors.fill: parent
    opacity: 0.0

    property var splashData: []
    property int index: 0
    property string currentImage: ""
    property var currentQuote: []
    property string currentTitle: ""
    property int currentDelay: 8000

    function deactivate() {
        rotateTimer.stop()
        fadeOutMain.start()
    }

    // Fade in the entire splash container
    NumberAnimation {
        id: fadeInMain
        target: splashRoot
        property: "opacity"
        to: 1.0
        duration: 2000
    }

    // Fade out the entire splash container
    NumberAnimation {
        id: fadeOutMain
        target: splashRoot
        property: "opacity"
        to: 0.0
        duration: 1000
        onStopped: splashRoot.visible = false
    }

    Component.onCompleted: {
        splashData = splashModel.get_splash_data()
        if (splashData.length > 0) {
            updateData()
            fadeInMain.start()
        }
    }

    function updateData() {
        currentImage = splashModel.resolve_image(splashData[index].image)
        currentQuote = splashData[index].quote
        currentTitle = splashData[index].title
        rotateTimer.interval = splashData[index].delay * 1000
    }

    // ---------------------------------------------------------
    // Background with Radial Vignette + Minimal Overscan Crop
    // ---------------------------------------------------------
    Rectangle {
        id: splashMask
        anchors.fill: parent
        anchors.margins: 8
        radius: 20
        color: "black"
        clip: true

        Image {
            id: bg
            anchors.fill: parent
            anchors.margins: -12
            source: currentImage
            fillMode: Image.PreserveAspectCrop
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: bg

            maskSource: RadialGradient {
                width: splashMask.width
                height: splashMask.height

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 0.35; color: "white" }
                    GradientStop { position: 0.65; color: "transparent" }
                }
            }
        }
    }

    // ---------------------------------------------------------
    // Cinematic Movie Title (Top-Left, Gold + Black Edge)
    // ---------------------------------------------------------
    Text {
        id: titleText
        text: currentTitle
        font.pixelSize: 70
        font.bold: true
        color: "#FFD700"          // bright gold
        style: Text.Outline
        styleColor: "black"       // black edge
        opacity: 0.0

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 40
        anchors.topMargin: 40
    }

    // ---------------------------------------------------------
    // Quote Block
    // ---------------------------------------------------------
    Column {
        id: quoteBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: 8

        Repeater {
            model: currentQuote
            delegate: Text {
                text: modelData
                font.pixelSize: 28
                color: "white"
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
                width: splashRoot.width * 0.8
                wrapMode: Text.WordWrap
                style: Text.Outline
                styleColor: "black"
            }
        }
    }

    // ---------------------------------------------------------
    // Crossfade + Title Fade-In Animation
    // ---------------------------------------------------------
    SequentialAnimation {
        id: crossFadeAnim

        // Fade OUT whole splash
        NumberAnimation {
            target: splashRoot
            property: "opacity"
            to: 0.0
            duration: 2500
            easing.type: Easing.InOutQuad
        }

        // Reset title opacity
        PropertyAction { target: titleText; property: "opacity"; value: 0.0 }

        // Change data
        PropertyAction { target: splashRoot; property: "index"; value: (index + 1) % splashData.length }
        ScriptAction { script: updateData() }

        // Fade IN whole splash
        NumberAnimation {
            target: splashRoot
            property: "opacity"
            to: 1.0
            duration: 2500
            easing.type: Easing.InOutQuad
        }

        // ⭐ Critical fix: allow first frame to render before title fade-in
        PauseAnimation { duration: 400 }

        // ⭐ Slow title fade-in (4 seconds)
        NumberAnimation {
            target: titleText
            property: "opacity"
            to: 1.0
            duration: 4000
            easing.type: Easing.OutCubic
        }
    }

    // ---------------------------------------------------------
    // Rotation Timer (starts AFTER first slide is visible)
    // ---------------------------------------------------------
    Timer {
        id: rotateTimer
        running: false
        repeat: true
        onTriggered: crossFadeAnim.start()
    }

    // ⭐ One-time startup delay to fix first slide
    Timer {
        id: firstRunDelay
        interval: 500
        running: true
        repeat: false
        onTriggered: rotateTimer.start()
    }
}