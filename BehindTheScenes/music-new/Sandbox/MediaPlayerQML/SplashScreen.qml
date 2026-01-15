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
        // Subtract animation times from the delay to keep rotation timing consistent
        rotateTimer.interval = (splashData[index].delay * 1000)
    }

    // --- Background with Radial Vignette ---
    Rectangle {
        id: splashMask
        anchors.fill: parent
        anchors.margins: 8
        radius: 20
        color: "black" // Background behind the image

        Image {
            id: bg
            anchors.fill: parent
            source: currentImage
            fillMode: Image.PreserveAspectCrop
            visible: false
        }

        OpacityMask {
            id: vignetteEffect
            anchors.fill: parent
            source: bg
            maskSource: RadialGradient {
                width: splashMask.width
                height: splashMask.height
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 0.4; color: "white" } // Center clear
                    GradientStop { position: 0.7; color: "transparent" } // Soft fade out
                }
            }
        }
    }

    // --- Rotation Animation ---
    SequentialAnimation {
        id: crossFadeAnim
        
        // 1. Fade OUT
        NumberAnimation { target: splashRoot; property: "opacity"; to: 0.0; duration: 2500; easing.type: Easing.InOutQuad }
        
        // 2. Change Data while invisible
        PropertyAction { 
            target: splashRoot; 
            property: "index"; 
            value: (index + 1) % splashData.length 
        }
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

    // --- Quote Block ---
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
                style: Text.Outline; styleColor: "black"
            }
        }
    }
}