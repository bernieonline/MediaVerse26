import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: splashRoot
    anchors.fill: parent
    visible: true
    opacity: 0.0     // start invisible so fade-in works

    // Fade animation for the entire splash screen
    Behavior on opacity {
        NumberAnimation { duration: 5000; easing.type: Easing.InOutQuad }
    }

    property var splashData: []
    property int index: 0
    property string currentImage: ""
    property var currentQuote: []
    property int currentDelay: 3000

    // ---------------------------------------------------------
    // Shutdown function (Option 3 core)
    // ---------------------------------------------------------
    function deactivate() {
        rotateTimer.stop()
        splashRoot.opacity = 0.0
        Qt.callLater(() => splashRoot.visible = false)
    }

    Component.onCompleted: {
        splashData = splashModel.get_splash_data()

        if (splashData.length > 0) {
            currentImage = splashModel.resolve_image(splashData[index].image)
            currentQuote = splashData[index].quote
            currentDelay = splashData[index].delay * 1000

            // Fade-in AFTER component is ready
            Qt.callLater(() => splashRoot.opacity = 1.0)

        } else {
            console.log("SplashScreen: No splash entries found")
        }
    }

    // ---------------------------------------------------------
    // Background image
    // ---------------------------------------------------------
    Image {
        id: bg
        anchors.fill: parent
        source: currentImage
        opacity: 1.0
        fillMode: Image.Stretch

        // Slow fade for crossfades
        Behavior on opacity {
            NumberAnimation { duration: 5000; easing.type: Easing.InOutQuad }
        }
    }

    // ---------------------------------------------------------
    // Soft gradient overlay
    // ---------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#80000000" }
        }
    }

    // ---------------------------------------------------------
    // Quote text block
    // ---------------------------------------------------------
    Column {
        id: quoteBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: 8

        Repeater {
            model: currentQuote.length
            delegate: Text {
                text: currentQuote[index]
                font.pixelSize: 28
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 5000 }
                }
            }
        }
    }

    // ---------------------------------------------------------
    // Timer to rotate splash entries
    // ---------------------------------------------------------
    Timer {
        id: rotateTimer
        interval: currentDelay
        running: true
        repeat: true

        onTriggered: {

            // Step 1: fade OUT current image
            bg.opacity = 0.0

            // Step 2: after fade-out completes, change image + fade IN
            Qt.callLater(() => {
                index = (index + 1) % splashData.length
                currentImage = splashModel.resolve_image(splashData[index].image)
                currentQuote = splashData[index].quote
                currentDelay = splashData[index].delay * 1000

                // Step 3: fade IN new image
                bg.opacity = 1.0
            })
        }
    }
}