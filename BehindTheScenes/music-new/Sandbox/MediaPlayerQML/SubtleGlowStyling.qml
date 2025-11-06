import QtQuick 2.15

// GlowStyling.qml
//
// This component provides a backlight/glow effect for a target item.
//
// To use it, create an instance of GlowStyling and set the 'target' property
// to the item you want to apply the effect to.
//
// Example:
//
// Item {
//     Rectangle {
//         id: myRect
//         width: 200
//         height: 100
//         color: "blue"
//         z: 2
//     }
//
//     GlowStyling {
//         target: myRect
//     }
// }
//
// Note: The target item should have a higher 'z' value than the GlowStyling
//       component to ensure the glow appears behind it. The default z-value
//       of this component is 1.

Item {
    id: glowRoot
    z: 1

    property Item target: null

    width: target ? target.width : 0
    height: target ? target.height : 0
    anchors.centerIn: target

    Repeater {
        model: 10
        delegate: Rectangle {
            width: glowRoot.width + index * 2
            height: glowRoot.height + index * 2
            anchors.centerIn: parent
            radius: (target && target.radius) ? target.radius + index * 0.5 : index * 0.5
            color: "transparent"
            border.width: 1
            border.color: {
                function smoothstep(edge0, edge1, x) {
                    var t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
                    return t * t * (3 - 2 * t);
                }

                var color1 = Qt.color("#FFC107");
                var color2 = Qt.color("#785c2a");
                var color3 = Qt.color("#382f1f");

                var r, g, b, t;

                if (index < 5) {
                    r = color1.r;
                    g = color1.g;
                    b = color1.b;
                } else if (index < 10) {
                    t = smoothstep(5, 10, index);
                    r = color1.r * (1 - t) + color2.r * t;
                    g = color1.g * (1 - t) + color2.g * t;
                    b = color1.b * (1 - t) + color2.b * t;
                } else {
                    t = smoothstep(10, 20, index);
                    r = color2.r * (1 - t) + color3.r * t;
                    g = color2.g * (1 - t) + color3.g * t;
                    b = color2.b * (1 - t) + color3.b * t;
                }

                var a = 0.7 * (1 - index/10.0);
                return Qt.rgba(r, g, b, a);
            }
        }
    }
}
