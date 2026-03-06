import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: filmRoot

    // ── Public interface ─────────────────────────────────────────────────────
    signal openDetail(var movie)
    signal playMovie(var movie)

    property var movieModel   // accepts a ListModel from parent

    // ── Layout — all derived from height so it scales automatically ──────────
    readonly property real sprocH: Math.round(height * 0.145)   // sprocket zone height each side
    readonly property real imgH:   height - sprocH * 2          // poster image height
    readonly property real frameW: Math.round(imgH * 0.667)     // 2:3 portrait frame width
    readonly property real holeW:  Math.round(frameW * 0.165)   // sprocket hole width
    readonly property real holeH:  Math.round(sprocH  * 0.62)   // sprocket hole height
    readonly property real divW:   3                             // dark frame divider

    // ── Hover state ──────────────────────────────────────────────────────────
    property var  hoveredMovie:   null
    property real hoveredCenterX: filmRoot.width / 2

    Timer {
        id: showTimer; interval: 380; repeat: false
        property var  pendingMd: null
        property real pendingX:  0
        onTriggered: {
            filmRoot.hoveredMovie   = pendingMd
            filmRoot.hoveredCenterX = pendingX
        }
    }
    Timer { id: hideTimer; interval: 200; repeat: false; onTriggered: filmRoot.hoveredMovie = null }

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

                // Blue bottom accent on hover
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 2
                    color: "#2566c2"
                    opacity: fMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // ── Click / dwell / double-click ──────────────────────────────
                MouseArea {
                    id: fMouse
                    anchors.fill:    parent
                    hoverEnabled:    true
                    acceptedButtons: Qt.LeftButton
                    property bool dblActive: false
                    property var  singleTimer: null

                    onEntered: {
                        hideTimer.stop()
                        if (del.imgUri !== "") {
                            showTimer.pendingMd = {
                                imageUri: del.imgUri,
                                title:    del.titleStr,
                                year:     del.yearStr,
                                display:  del.dispStr
                            }
                            // Centre of this frame in filmRoot viewport coords
                            showTimer.pendingX = del.x - frameList.contentX + filmRoot.frameW / 2
                            showTimer.restart()
                        }
                    }
                    onExited: {
                        showTimer.stop()
                        showTimer.pendingMd = null
                        hideTimer.restart()
                    }

                    onClicked: {
                        if (del.imgUri === "") return
                        if (singleTimer) singleTimer.stop()
                        var cap = { imageUri: del.imgUri, title: del.titleStr,
                                    year: del.yearStr, display: del.dispStr }
                        singleTimer = Qt.createQmlObject(
                            'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                            filmRoot)
                        singleTimer.triggered.connect(function() {
                            if (!dblActive) filmRoot.openDetail(cap)
                            dblActive = false
                        })
                        singleTimer.start()
                    }

                    onDoubleClicked: {
                        if (del.imgUri === "") return
                        dblActive = true
                        if (singleTimer) singleTimer.stop()
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

    // ── Dwell preview — portrait card floating above the strip ───────────────
    Item {
        id: dwellPreview
        z: 10

        readonly property real pvW: Math.round(filmRoot.height * 0.88)   // ~88% of strip height
        readonly property real pvH: Math.round(pvW * 1.50)               // 2:3 portrait

        width:  pvW
        height: pvH + 11   // card + pointer triangle

        // Sits above the strip; slides left/right to track hovered frame
        y: -(pvH + 11 + 18)
        x: Math.max(4, Math.min(filmRoot.width - pvW - 4,
               filmRoot.hoveredCenterX - pvW / 2))

        opacity: filmRoot.hoveredMovie !== null ? 1.0 : 0.0
        visible: true   // always in render tree; opacity drives show/hide so animation works both ways
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        Behavior on x       { NumberAnimation { duration: 160; easing.type: Easing.OutCubic  } }

        // ── Card ─────────────────────────────────────────────────────────────
        Rectangle {
            id: pvCard
            width:  parent.pvW
            height: parent.pvH
            radius: 9; color: "#111"; clip: true

            layer.enabled: true
            layer.effect: DropShadow {
                verticalOffset: 0; horizontalOffset: 0
                radius: 24; samples: 33
                color: Qt.rgba(0, 0, 0, 0.92)
            }

            Image {
                anchors.fill: parent
                source:       filmRoot.hoveredMovie ? filmRoot.hoveredMovie.imageUri : ""
                fillMode:     Image.PreserveAspectCrop
                smooth: true; asynchronous: true
            }

            // Top sheen
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: Qt.rgba(1,1,1, 0.08) }
                    GradientStop { position: 0.35; color: "transparent"         }
                }
            }

            // Year badge
            Rectangle {
                visible: filmRoot.hoveredMovie !== null && filmRoot.hoveredMovie.year !== ""
                anchors.top:     parent.top
                anchors.right:   parent.right
                anchors.margins: 8
                width: pvYrTxt.implicitWidth + 14; height: 24; radius: 4
                color: Qt.rgba(0, 0, 0, 0.76)
                Text {
                    id: pvYrTxt; anchors.centerIn: parent
                    text:  filmRoot.hoveredMovie ? filmRoot.hoveredMovie.year : ""
                    color: "#e0e0e0"; font.pixelSize: 13; font.bold: true
                }
            }

            // Title bar
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: 50; color: Qt.rgba(0, 0, 0, 0.78)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 10
                    text:  filmRoot.hoveredMovie ? filmRoot.hoveredMovie.title : ""
                    color: "white"; font.pixelSize: 16; font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight; maximumLineCount: 1
                }
            }

            // Blue accent line
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 3; color: "#2566c2"
            }
        }

        // ── Downward pointer triangle ─────────────────────────────────────────
        Canvas {
            anchors.top:              pvCard.bottom
            anchors.horizontalCenter: pvCard.horizontalCenter
            width: 18; height: 11
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "#2566c2"
                ctx.beginPath()
                ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width / 2, height)
                ctx.closePath(); ctx.fill()
            }
        }

        // ── Click / double-click on the dwell preview ─────────────────────────
        MouseArea {
            anchors.fill:    pvCard
            hoverEnabled:    true
            acceptedButtons: Qt.LeftButton
            property bool dblActive: false
            property var  singleTimer: null

            onEntered: hideTimer.stop()
            onExited:  hideTimer.restart()

            onClicked: {
                if (!filmRoot.hoveredMovie) return
                if (singleTimer) singleTimer.stop()
                var cap = filmRoot.hoveredMovie
                singleTimer = Qt.createQmlObject(
                    'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                    filmRoot)
                singleTimer.triggered.connect(function() {
                    if (!dblActive) filmRoot.openDetail(cap)
                    dblActive = false
                })
                singleTimer.start()
            }
            onDoubleClicked: {
                if (!filmRoot.hoveredMovie) return
                dblActive = true
                if (singleTimer) singleTimer.stop()
                filmRoot.playMovie(filmRoot.hoveredMovie)
            }
        }
    }
}
