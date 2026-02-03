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

    // --- Component Lifecycle ---
    Component.onCompleted: {
        splashData = splashModel.get_splash_data()

        // --- Shuffle the splashData array (Fisher–Yates) ---
        for (var i = splashData.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var temp = splashData[i]
            splashData[i] = splashData[j]
            splashData[j] = temp
        }

        if (splashData.length > 0) {
            updateData()
            // Start the initial entry sequence
            fadeInMain.start()
        }
    }

    function updateData() {
        if (!splashData[index]) return;
        currentImage = splashModel.resolve_image(splashData[index].image)
        currentQuote = splashData[index].quote
        currentTitle = splashData[index].title
        rotateTimer.interval = splashData[index].delay * 1000
    }

    // --- Initial Entry Animations ---
    NumberAnimation {
        id: fadeInMain
        target: splashRoot
        property: "opacity"
        to: 1.0
        duration: 2000
        easing.type: Easing.InOutQuad
        onStopped: firstTitleFade.start() // Trigger title after splash is visible
    }

    NumberAnimation {
        id: firstTitleFade
        target: titleText
        property: "opacity"
        to: 1.0
        duration: 4000
        easing.type: Easing.OutCubic
        onStopped: rotateTimer.start() // Start the loop ONLY after first title shows
    }

    NumberAnimation {
        id: fadeOutMain
        target: splashRoot
        property: "opacity"
        to: 0.0
        duration: 1000
        onStopped: splashRoot.visible = false
    }

    // --- Background Layer (Vignette + Image) ---
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
            anchors.margins: -12 // Slight overscan for cinematic feel
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

    // --- Cinematic Title (Top-Left) ---
    Text {
        id: titleText
        text: currentTitle
        font.pixelSize: 70
        font.bold: true
        color: "#FFD700" // Gold
        style: Text.Outline
        styleColor: "black"
        opacity: 0.0 // Starts invisible, controlled by firstTitleFade or crossFadeAnim

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 40
        anchors.topMargin: 40
    }

    // --- Quote Block (Bottom) ---
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
                wrapMode: Text.WrapAnywhere
                style: Text.Outline
                styleColor: "black"
            }
        }
    }

    // --- Main Rotation Animation Loop ---
    SequentialAnimation {
        id: crossFadeAnim

        // 1. Fade OUT everything
        NumberAnimation {
            target: splashRoot
            property: "opacity"
            to: 0.0
            duration: 2500
            easing.type: Easing.InOutQuad
        }

        // 2. Prepare next slide while invisible
        PropertyAction { target: titleText; property: "opacity"; value: 0.0 }
        PropertyAction { target: splashRoot; property: "index"; value: (index + 1) % splashData.length }
        ScriptAction { script: updateData() }

        // 3. Fade IN background/quotes
        NumberAnimation {
            target: splashRoot
            property: "opacity"
            to: 1.0
            duration: 2500
            easing.type: Easing.InOutQuad
        }

        // 4. Slight pause then fade IN title slowly
        PauseAnimation { duration: 400 }
        NumberAnimation {
            target: titleText
            property: "opacity"
            to: 1.0
            duration: 4000
            easing.type: Easing.OutCubic
        }
    }

    // --- Timer Logic ---
    Timer {
        id: rotateTimer
        running: false // Controlled by firstTitleFade.onStopped
        repeat: true
        onTriggered: crossFadeAnim.start()
    }
}