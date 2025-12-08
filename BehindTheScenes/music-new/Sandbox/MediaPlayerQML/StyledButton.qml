// StyledButton.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: styledButton

    // --- Standardized properties ---
    property int fixedWidth: 150
    property int fixedHeight: 60
    property color normalColor: "#333"
    property color hoverColor: "#444"
    property color pressedColor: "#222"
    property color borderColor: "yellow"
    property int borderThickness: 2

    width: fixedWidth
    height: fixedHeight

    // --- Background styling ---
    background: Rectangle {
        radius: 8
        color: styledButton.down ? styledButton.pressedColor
                                 : styledButton.hovered ? styledButton.hoverColor
                                                        : styledButton.normalColor
        border.color: styledButton.borderColor
        border.width: styledButton.borderThickness
    }

    // --- Text styling ---
    contentItem: Text {
        text: styledButton.text
        font: styledButton.font
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}