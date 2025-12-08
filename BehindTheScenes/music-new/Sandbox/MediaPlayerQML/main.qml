import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects 6.0

ApplicationWindow {
    id: mainWindow
    visible: true
    visibility: Window.FullScreen
    color: "#1e1e1e"
    title: "Ultra Diffuse Glow Test"

    // Simple helper for mm → px conversion
    function mmToPx(mm) { return mm * 3.78 }

    Item {
        id: imageContainer
        anchors.centerIn: parent

        width: imageSource.implicitWidth
        height: imageSource.implicitHeight

        //--------------------------------------------------------------------
        // 1. The original IMAGE
        //--------------------------------------------------------------------
        Image {
            //console.log("✅ Connected imageClicked")
            id: imageSource
            //source: "file:///D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new/cache/display/2000s/The Last Samurai (2003).jpg"
            //source: "file:///C:/Users/berna/pythonproject2026/BehindTheScenes/BehindTheScenes/music-new/cache/display/1960s 70s 80s/BEN_HUR_DISC_2 (1959).jpg"
            
            source:  "File:///J:/MediaVerse 1.0/BehindTheScenes/music-new/images/mediaverse.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
        }

        //--------------------------------------------------------------------
        // 2. OUTER BLOOM (very diffuse halo)
        //--------------------------------------------------------------------

        // High-resolution offscreen buffer (bigger → stronger diffusion)
        ShaderEffectSource {
            id: srcOuter
            visible: false
            sourceItem: imageSource
            smooth: true
            hideSource: false
            mipmap: true

            // Scale up 1.8× for extreme blur spread
            width: imageSource.width * 1.8
            height: imageSource.height * 1.8

            // Center scaling correctly
            sourceRect: Qt.rect(
                -imageSource.width * 0.4,
                -imageSource.height * 0.4,
                imageSource.width * 1.8,
                imageSource.height * 1.8
            )
        }

        // Golden colour layer behind blur (needed because GaussianBlur cannot tint)
        Rectangle {
            id: goldenLayer
            anchors.fill: imageSource
            color: "#FFD700"
            opacity: 0.35    // adjust for stronger or weaker golden wash
            z: -4
        }

        // First heavy blur pass (large radius)
        GaussianBlur {
            id: blur1
            anchors.fill: imageSource
            source: srcOuter
            radius: 60       // wide blur
            samples: 32      // high quality
            opacity: 0.85
            z: -3
        }

        // Second blur pass (softens even more)
        GaussianBlur {
            id: blur2
            anchors.fill: imageSource
            source: blur1
            radius: 45       // softening layer
            samples: 32
            opacity: 0.75
            z: -2
        }

        //--------------------------------------------------------------------
        // 3. INNER GLOW (rim light close to the image)
        //--------------------------------------------------------------------
        Glow {
            id: innerGlow
            source: imageSource
            anchors.fill: imageSource

            radius: mainWindow.mmToPx(4)
            spread: 0.25
            color: "#ffdd55"
            opacity: 0.8

            z: -1
        }

        //--------------------------------------------------------------------
        // 4. SHADOW — helps lift image from background
        //--------------------------------------------------------------------
        DropShadow {
            id: shadow
            source: imageSource
            anchors.fill: imageSource

            radius: 18
            samples: 16
            horizontalOffset: 4
            verticalOffset: 4
            color: "#40000000"

            z: -5
        }
    }
}
