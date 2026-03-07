import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: filmRoot

    // ── Public interface ─────────────────────────────────────────────────────
    signal playMovie(var movie)
    // openDetail is no longer emitted by FilmStrip — detail view opens from the popup card

    property var movieModel   // accepts a ListModel from parent

    // ── Layout — all derived from height so it scales automatically ──────────
    readonly property real sprocH: Math.round(height * 0.145)   // sprocket zone height each side
    readonly property real imgH:   height - sprocH * 2          // poster image height
    readonly property real frameW: Math.round(imgH * 0.667)     // 2:3 portrait frame width
    readonly property real holeW:  Math.round(frameW * 0.165)   // sprocket hole width
    readonly property real holeH:  Math.round(sprocH  * 0.62)   // sprocket hole height
    readonly property real divW:   3                             // dark frame divider

    // ── Selection state — driven by click, not hover ─────────────────────────
    // selectedMovie: the movie the user tapped; drives the external popup in ArchitectGallery.
    // selectedCenterX: viewport-x of that frame's centre, so the popup tracks it.
    property var  selectedMovie:   null
    property real selectedCenterX: filmRoot.width / 2

    // ── Film base — upward drop-shadow makes it float ────────────────────────
    Rectangle {
        id: filmBase
        anchors.fill: parent
        color:  "#0d0d15"
        radius: 8
        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset:   -12
            horizontalOffset: 0
            radius:           28
            samples:          33
            color:            Qt.rgba(0, 0, 0, 0.90)
        }
    }

    // ── Scrolling frame strip ─────────────────────────────────────────────────
    ListView {
        id: frameList
        anchors.fill: parent
        orientation:          ListView.Horizontal
        clip:                 true
        spacing:              0
        flickDeceleration:    1800
        maximumFlickVelocity: 5500
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        model: filmRoot.movieModel
        onMovementStarted: filmRoot.selectedMovie = null   // dismiss popup when strip is scrolled

        delegate: Item {
            id: del
            width:  filmRoot.frameW + filmRoot.divW
            height: filmRoot.height

            // Capture ListModel roles into local properties so nested items can read them
            property string imgUri:   model.imageUri || ""
            property string titleStr: model.title    || ""
            property string yearStr:  model.year     || ""
            property string dispStr:  model.display  || ""

            // ── Top sprocket zone band — slightly lighter so holes are visible ──
            Rectangle {
                x: 0; y: 0
                width: filmRoot.frameW; height: filmRoot.sprocH
                color: "#1c1828"   // warm dark violet — distinct from film base #0d0d15
            }

            // ── Bottom sprocket zone band ─────────────────────────────────────
            Rectangle {
                x: 0; y: filmRoot.height - filmRoot.sprocH
                width: filmRoot.frameW; height: filmRoot.sprocH
                color: "#1c1828"
            }

            // ── Top sprocket holes (2 per frame) ──────────────────────────────
            Repeater {
                model: 2
                Rectangle {
                    x: (index === 0)
                        ? Math.round(filmRoot.frameW * 0.23 - filmRoot.holeW / 2)
                        : Math.round(filmRoot.frameW * 0.73 - filmRoot.holeW / 2)
                    y: Math.round((filmRoot.sprocH - filmRoot.holeH) / 2)
                    width:  filmRoot.holeW
                    height: filmRoot.holeH
                    radius: Math.round(filmRoot.holeH * 0.38)
                    color:  "#000000"
                    border.color: Qt.rgba(0.65, 0.62, 0.72, 0.55)
                    border.width: 1

                    // Inner top-edge highlight — punched metal rim
                    Rectangle {
                        anchors.top:   parent.top
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        height: 2; radius: parent.radius
                        color: Qt.rgba(1, 1, 1, 0.30)
                    }
                }
            }

            // ── Bottom sprocket holes ─────────────────────────────────────────
            Repeater {
                model: 2
                Rectangle {
                    x: (index === 0)
                        ? Math.round(filmRoot.frameW * 0.23 - filmRoot.holeW / 2)
                        : Math.round(filmRoot.frameW * 0.73 - filmRoot.holeW / 2)
                    y: Math.round(filmRoot.height - filmRoot.sprocH
                                  + (filmRoot.sprocH - filmRoot.holeH) / 2)
                    width:  filmRoot.holeW
                    height: filmRoot.holeH
                    radius: Math.round(filmRoot.holeH * 0.38)
                    color:  "#000000"
                    border.color: Qt.rgba(0.65, 0.62, 0.72, 0.55)
                    border.width: 1

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        anchors.margins: 1
                        height: 2; radius: parent.radius
                        color: Qt.rgba(0, 0, 0, 0.60)
                    }
                }
            }

            // ── Right-edge frame divider (black line between frames) ──────────
            Rectangle {
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.bottom: parent.bottom
                width: filmRoot.divW
                color: "#000"
            }

            // ── Poster image area ─────────────────────────────────────────────
            Rectangle {
                id: poster
                x:      0
                y:      filmRoot.sprocH
                width:  filmRoot.frameW
                height: filmRoot.imgH
                color:  "#14141e"
                clip:   true

                Image {
                    anchors.fill: parent
                    source:       del.imgUri
                    fillMode:     Image.PreserveAspectCrop
                    smooth:       true
                    asynchronous: true
                }

                // Year badge — top right
                Rectangle {
                    visible: del.yearStr !== ""
                    anchors.top:     parent.top
                    anchors.right:   parent.right
                    anchors.margins: 3
                    width:  yrTxt.implicitWidth + 8
                    height: 16; radius: 3
                    color:  Qt.rgba(0, 0, 0, 0.80)
                    Text {
                        id: yrTxt
                        anchors.centerIn: parent
                        text:  del.yearStr
                        color: "#cccccc"
                        font.pixelSize: 9; font.bold: true
                    }
                }

                // Hover tint
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(1, 1, 1, fMouse.containsMouse ? 0.10 : 0.0)
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Selected frame — blue border overlay
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color:        "transparent"
                    border.color: "#2566c2"
                    border.width: isSelected ? 3 : 0
                    property bool isSelected: filmRoot.selectedMovie !== null
                                           && filmRoot.selectedMovie.imageUri === del.imgUri
                    Behavior on border.width { NumberAnimation { duration: 120 } }
                }

                // ── Click / double-click ───────────────────────────────────────
                // Single click → select this frame (shows popup in ArchitectGallery).
                // Double click → play movie immediately.
                Timer {
                    id: delClickTimer
                    interval: 220; repeat: false
                    property bool dblGuard: false
                    onTriggered: {
                        if (!dblGuard && del.imgUri !== "") {
                            filmRoot.selectedMovie   = { imageUri: del.imgUri, title: del.titleStr,
                                                         year: del.yearStr,   display: del.dispStr }
                            filmRoot.selectedCenterX = del.x - frameList.contentX + filmRoot.frameW / 2
                        }
                        dblGuard = false
                    }
                }

                MouseArea {
                    id: fMouse
                    anchors.fill:    parent
                    hoverEnabled:    true
                    acceptedButtons: Qt.LeftButton

                    onClicked: {
                        if (del.imgUri === "") return
                        delClickTimer.dblGuard = false
                        delClickTimer.restart()
                    }

                    onDoubleClicked: {
                        if (del.imgUri === "") return
                        delClickTimer.dblGuard = true
                        delClickTimer.stop()
                        filmRoot.selectedMovie = null   // dismiss popup if open
                        filmRoot.playMovie({ imageUri: del.imgUri, title: del.titleStr,
                                             year: del.yearStr, display: del.dispStr })
                    }
                }
            }
        }
    }

    // ── Acetate sheen — no mouse events, sits above all frames ───────────────
    Item {
        anchors.fill: parent
        z: 5
        enabled: false

        // Soft multi-stop reflection — the glossy acetate look
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.20) }
                GradientStop { position: 0.10; color: Qt.rgba(1, 1, 1, 0.06) }
                GradientStop { position: 0.40; color: "transparent"           }
                GradientStop { position: 0.85; color: Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.09) }
            }
        }

        // Hard 1px glint — the signature of a glossy surface
        Rectangle {
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(1, 1, 1, 0.40)
        }

        // Soft bottom reflection
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: 1
            color: Qt.rgba(1, 1, 1, 0.14)
        }
    }

}
// NOTE: The dwell preview popup is owned by ArchitectGallery.qml (id: stripDwellPreview)
// so it renders at galleryRoot level (z:150), unconstrained by the film strip's bounds.
