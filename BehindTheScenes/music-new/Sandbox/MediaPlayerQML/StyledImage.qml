import QtQuick 2.15

/*
 * StyledImage.qml
 *
 * This component displays an image with a styled border and a glow effect.
 * It's designed to be a reusable component for consistent image presentation.
 *
 * Properties:
 *   - source: The URL of the image to display.
 *   - borderColor: The color of the border. Defaults to "#FFC107".
 *   - borderWidth: The width of the border. Defaults to 2.
 */
Item {
    id: root

    // The component's size is determined by the parent, allowing it to be used
    // in various layouts (e.g., grid view, carousel).
    width: 200  // Default width
    height: 300 // Default height

    property alias source: image.source
    property color borderColor: "#FFC107"
    property int borderWidth: 2

    // Apply the glow effect to the border.
    SubtleGlowStyling {
        target: border
    }

    // The border provides a visual frame for the image.
    Rectangle {
        id: border
        anchors.fill: parent
        color: "transparent"
        border.color: borderColor
        border.width: borderWidth
        radius: 8
        antialiasing: true // For smoother corners
        z: 2
    }

    // The image is clipped to the border's radius.
    Image {
        id: image
        source: ""
        anchors.fill: parent
        anchors.margins: borderWidth + 2 // Margin to keep image inside the border
        fillMode: Image.PreserveAspectCrop // Crop image to fill, maintaining aspect ratio
        clip: true // Clip the image to the item's bounds
        smooth: true // Render image with high quality
        z: 3
    }
}