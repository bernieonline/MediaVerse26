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
    property int currentDelay: 8000 // Total time per slide

    function deactivate() {
        rotateTimer.stop()
        fadeOutMain.start()
    }

    // Smooth fade in for the whole component at startup
    NumberAnimation { id: fadeInMain; target: splashRoot; property: "opacity"; to: 1.0; duration: 2000 }
    NumberAnimation { id: fadeOutMain; target: splashRoot; property: "opacity"; to: 0.0; duration: 1000; onStopped: splashRoot.visible = false }

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
        rotateTimer.interval = (splashData[index].delay * 1000)
    }

    // ---------------------------------------------------------
    // Background with Radial Vignette + Minimal Overscan Crop
    // ---------------------------------------------------------
    Rectangle {
        id: splashMask
        anchors.fill: parent
        anchors.margins: 8        // reveal blue border
        radius: 20
        color: "black"            // ensures clipping works
        clip: true

        // Base image with tiny overscan crop
        Image {
            id: bg
            anchors.fill: parent
            anchors.margins: -12      // <--- minimal crop to hide square corners
            source: currentImage
            fillMode: Image.PreserveAspectCrop
            visible: false            // used only as mask source
        }

        // Radial vignette mask (aggressive fade)
        OpacityMask {
            id: vignetteEffect
            anchors.fill: parent
            source: bg

            maskSource: RadialGradient {
                width: splashMask.width
                height: splashMask.height

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 0.35; color: "white" }       // center clear
                    GradientStop { position: 0.65; color: "transparent" } // strong fade
                }
            }
        }
    }

    // ---------------------------------------------------------
    // Rotation Animation
    // ---------------------------------------------------------
    SequentialAnimation {
        id: crossFadeAnim

        // 1. Fade OUT
        NumberAnimation { target: splashRoot; property: "opacity"; to: 0.0; duration: 2500; easing.type: Easing.InOutQuad }

        // 2. Change Data while invisible
        PropertyAction { target: splashRoot; property: "index"; value: (index + 1) % splashData.length }
        ScriptAction { script: updateData() }

        // 3. Fade IN
        NumberAnimation { target: splashRoot; property: "opacity"; to: 1.0; duration: 2500; easing.type: Easing.InOutQuad }
    }

    Timer {
        id: rotateTimer
        running: true
        repeat: true
        onTriggered: crossFadeAnim.start()
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
}