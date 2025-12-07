// UltraGlowFrame.qml
import QtQuick 2.15
import Qt5Compat.GraphicalEffects 6.0   // use this if you’re on Qt 6
// import QtGraphicalEffects 1.15       // use this if you’re on Qt 5

Item {
    id: root
    property Item target        // the item to style
    property real glowRadius: 12
    property color glowColor: "gold"
    property real glowOpacity: 0.6

    Glow {
        anchors.fill: target
        source: target
        radius: root.glowRadius
        color: root.glowColor
        opacity: root.glowOpacity
    }
}