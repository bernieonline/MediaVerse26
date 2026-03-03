import QtQuick 2.15

Item {
    id: heroRoot
    anchors.fill: parent
    property var imageSources: []
    property int currentIndex: 0

    // --- The Two Buffers (For Crossfading) ---
    Image {
        id: imageBufferA
        anchors.fill: parent
        source: imageSources.length > 0 ? imageSources[currentIndex] : ""
        fillMode: Image.PreserveAspectCrop
        opacity: 1
        scale: 1.0

        Behavior on opacity { NumberAnimation { duration: 2500; easing.type: Easing.InOutQuad } }
    }

    Image {
        id: imageBufferB
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0
        scale: 1.0

        Behavior on opacity { NumberAnimation { duration: 2500; easing.type: Easing.InOutQuad } }
    }

    // --- The Ken Burns Animation Logic ---
    Timer {
        id: transitionTimer
        interval: 8000 // Change image every 8 seconds
        running: imageSources.length > 0
        repeat: true
        onTriggered: {
            currentIndex = (currentIndex + 1) % imageSources.length
            
            if (imageBufferA.opacity === 1) {
                imageBufferB.source = imageSources[currentIndex]
                imageBufferB.opacity = 1
                imageBufferA.opacity = 0
                // Reset A for next time
                zoomAnimB.restart()
            } else {
                imageBufferA.source = imageSources[currentIndex]
                imageBufferA.opacity = 1
                imageBufferB.opacity = 0
                zoomAnimA.restart()
            }
        }
    }

    PropertyAnimation {
        id: zoomAnimA
        target: imageBufferA
        property: "scale"
        from: 1.0; to: 1.05
        duration: 10000
    }

    PropertyAnimation {
        id: zoomAnimB
        target: imageBufferB
        property: "scale"
        from: 1.0; to: 1.05
        duration: 10000
    }
}