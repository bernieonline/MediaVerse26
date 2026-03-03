import QtQuick 2.15

Item {
    id: galleryRoot
    anchors.fill: parent

    // ── Background: scattered photo display ───────────────────────────────────
    Loader {
        anchors.fill: parent
        source: "splash_screen.qml"
    }

    // ── ARCHITECT header — top left ───────────────────────────────────────────
    Column {
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.margins: 36
        spacing: 8
        z: 100

        Text {
            text: "ARCHITECT"
            color: "white"
            font.pixelSize:    46
            font.bold:         true
            font.letterSpacing: 7
        }
        Rectangle {
            width: 64; height: 3
            color: "#2566c2"
        }
    }

    // ── Category navigation — right edge ─────────────────────────────────────
    // Tiles are narrow enough to leave the left 75 % clear for the image scatter.
    ListView {
        id: categoryList
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        anchors.topMargin:    20
        anchors.bottomMargin: 20
        anchors.rightMargin:  20
        width:   190
        clip:    true
        spacing: 8

        model: architectController.categoryModel

        delegate: Item {
            width:  190
            height: 62

            Rectangle {
                anchors.fill: parent
                radius: 7

                // Active: solid MediaVerse blue.  Inactive: dark glass.
                color: ListView.isCurrentItem
                    ? Qt.rgba(0.15, 0.40, 0.76, 0.92)
                    : Qt.rgba(0.04, 0.04, 0.04, 0.78)

                border.color: ListView.isCurrentItem
                    ? "#2566c2"
                    : Qt.rgba(1, 1, 1, 0.14)
                border.width: ListView.isCurrentItem ? 2 : 1

                Text {
                    anchors.centerIn:  parent
                    text:              modelData.label.toUpperCase()
                    color:             "white"
                    font.pixelSize:    20
                    font.bold:         true
                    font.letterSpacing: 2.0
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: categoryList.currentIndex = index
            }
        }
    }

    // ── Blue rounded border overlay ───────────────────────────────────────────
    // enabled: false so this decorative rectangle never intercepts mouse events.
    Rectangle {
        anchors.fill:  parent
        color:         "transparent"
        radius:        20
        border.color:  "#2566c2"
        border.width:  2
        antialiasing:  true
        z:             10000
        enabled:       false
    }
}
