import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Backlight Effect")

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1e1e1e"

        Rectangle {
            id: target
            width: parent.width / 2
            height: parent.height / 2
            anchors.centerIn: parent
            color: "#1e1e1e"
            border.color: "yellow"
            border.width: 1
            radius: 16
            z: 2
        }

        Item {
            id: backlight
            width: target.width
            height: target.height
            anchors.centerIn: target
            z: 1

            Repeater {
                model: 20
                delegate: Rectangle {
                    width: target.width + index * 4
                    height: target.height + index * 4
                    anchors.centerIn: parent
                    radius: target.radius + index * 0.5
                    color: "transparent"
                    border.width: 1
                    border.color: {
                        function smoothstep(edge0, edge1, x) {
                            var t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
                            return t * t * (3 - 2 * t);
                        }

                        var color1 = Qt.color("#B18737");
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

                        var a = 0.7 * (1 - index/20.0);
                        return Qt.rgba(r, g, b, a);
                    }
                }
            }
        }
    }
}
