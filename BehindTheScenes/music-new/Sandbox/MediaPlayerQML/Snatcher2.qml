import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ─────────────────────────────────────────────────────────────────────────────
// Snatcher 2  —  clipboard image crop tool
// Instantiated in Framework-1.qml:  Snatcher2 { id: snatcher2Panel; anchors.fill: parent }
// Shown/hidden by RowButton snatcherClicked signal.
// Python backend: snatcher2Backend context property (Snatcher2Backend instance).
// ─────────────────────────────────────────────────────────────────────────────
Rectangle {
    id: snatcher2Root
    color: Qt.rgba(0, 0, 0, 0.78)
    visible: false
    z: 900

    // ── Panel-level state ─────────────────────────────────────────────────────
    property string currentImageUri: ""
    property int    srcW: 0
    property int    srcH: 0
    property string destChoice: "Splash"

    // ── Click-blocker for backdrop ────────────────────────────────────────────
    MouseArea { anchors.fill: parent; onClicked: {} }

    // ── Python signal wiring ──────────────────────────────────────────────────
    Connections {
        target: snatcher2Backend

        function onClipboardImageReady(uri, w, h) {
            snatcher2Root.currentImageUri = uri
            snatcher2Root.srcW = w
            snatcher2Root.srcH = h
            // Clear previous selection
            imgDisplay.selX = 0; imgDisplay.selY = 0
            imgDisplay.selW = 0; imgDisplay.selH = 0
        }

        function onStatusMessage(msg) {
            feedbackText.text  = msg
            feedbackText.color = msg.startsWith("✓") ? "#00FF7F" : "#FF6060"
            feedbackTimer.restart()
        }
    }

    Timer {
        id: feedbackTimer
        interval: 3500
        onTriggered: feedbackText.text = ""
    }

    onVisibleChanged: {
        if (visible) snatcher2Backend.startMonitoring()
        else         snatcher2Backend.stopMonitoring()
    }

    // ── Main Panel ────────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        width:  Math.round(parent.width  * 0.667)
        height: Math.round(parent.height * 0.667)
        anchors.centerIn: parent
        color:   "#0D0D0D"
        radius:  8
        border.color: "gold"
        border.width: 2

        // Gold left accent stripe
        Rectangle {
            width: 3
            anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: 8; anchors.bottomMargin: 8
            color: "gold"; radius: 1
        }

        // ── Header bar ────────────────────────────────────────────────────────
        Item {
            id: headerBar
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.margins: 18
            height: 38

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text:  "SNATCHER  2"
                color: "gold"; font.pixelSize: 22; font.bold: true; font.letterSpacing: 3
            }

            // Source pixel dimensions (centre)
            Text {
                anchors.centerIn: parent
                text: snatcher2Root.srcW > 0
                      ? "SRC  " + snatcher2Root.srcW + " × " + snatcher2Root.srcH
                      : "Copy an image to clipboard…"
                color: snatcher2Root.srcW > 0 ? "#00E676" : "#555"
                font.pixelSize: 14; font.family: "monospace"
            }

            // Close button (top-right)
            Item {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32; height: 32

                Rectangle {
                    anchors.fill: parent; radius: 16
                    color: closeHov.containsMouse ? "#B8860B" : "transparent"
                    border.color: "gold"; border.width: 1
                }
                Text {
                    anchors.centerIn: parent
                    text: "✕"; color: "gold"; font.pixelSize: 16; font.bold: true
                }
                MouseArea {
                    id: closeHov; anchors.fill: parent; hoverEnabled: true
                    onClicked: snatcher2Root.visible = false
                }
            }
        }

        // ── Controls row: name | dest toggle | Google search ─────────────────
        Item {
            id: controlsBar
            anchors.top:       headerBar.bottom
            anchors.left:      parent.left
            anchors.right:     parent.right
            anchors.topMargin: 10
            anchors.leftMargin:  20
            anchors.rightMargin: 18
            height: 46

            RowLayout {
                anchors.fill: parent
                spacing: 10

                TextField {
                    id: nameInput
                    Layout.fillWidth: true
                    placeholderText: "Film / collection name…"
                    color: "white"; font.pixelSize: 15
                    background: Rectangle {
                        color: "#252525"; radius: 4
                        border.color: nameInput.activeFocus ? "gold" : "#444"
                        border.width: 2
                    }
                }

                // Destination toggle buttons
                Repeater {
                    model: ["Splash", "Temp"]
                    delegate: Rectangle {
                        width: 68; height: 40
                        color:  snatcher2Root.destChoice === modelData ? "gold" : "#252525"
                        border.color: "gold"; border.width: 1; radius: 4
                        Text {
                            anchors.centerIn: parent; text: modelData
                            color: snatcher2Root.destChoice === modelData ? "black" : "gold"
                            font.pixelSize: 13; font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: snatcher2Root.destChoice = modelData
                        }
                    }
                }

                // Google 4K search
                Rectangle {
                    width: 124; height: 40
                    color:  googleHov.containsMouse ? "#B8860B" : "#1A1A1A"
                    border.color: "gold"; border.width: 1; radius: 4
                    Text {
                        anchors.centerIn: parent; text: "🔍 Google 4K"
                        color: "gold"; font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        id: googleHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: snatcher2Backend.openGoogleSearch(nameInput.text)
                    }
                }
            }
        }

        // ── Image display area with rubber-band crop ──────────────────────────
        Rectangle {
            id: imgDisplay
            anchors.top:    controlsBar.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: footerBar.top
            anchors.topMargin:    10
            anchors.leftMargin:   20
            anchors.rightMargin:  18
            anchors.bottomMargin: 10
            color: "#080808"
            border.color: "#333"; border.width: 1

            // Placeholder when no image loaded
            Text {
                anchors.centerIn: parent
                visible: imgItem.status !== Image.Ready
                text: "Copy an image to clipboard to load it here\n\nThen drag to draw your crop area"
                color: "#444"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }

            Image {
                id: imgItem
                anchors.fill: parent
                source:       snatcher2Root.currentImageUri
                fillMode:     Image.PreserveAspectFit
                smooth:       true
                asynchronous: true
            }

            // ── Rendered image geometry (for coordinate mapping) ───────────
            property real _srcW:  snatcher2Root.srcW || 1
            property real _srcH:  snatcher2Root.srcH || 1
            property real _scale: imgItem.status === Image.Ready
                                  ? Math.min(width / _srcW, height / _srcH)
                                  : 1
            property real _rendW: _srcW * _scale
            property real _rendH: _srcH * _scale
            property real _offX:  (width  - _rendW) / 2
            property real _offY:  (height - _rendH) / 2

            // ── Crop selection state ───────────────────────────────────────
            property real selX: 0; property real selY: 0
            property real selW: 0; property real selH: 0
            property bool hasSelection: selW > 6 && selH > 6

            // Selection rectangle (drawn before MouseArea so mouse events pass through)
            Rectangle {
                x: imgDisplay.selX; y: imgDisplay.selY
                width:  imgDisplay.selW; height: imgDisplay.selH
                visible: imgDisplay.hasSelection
                color:   Qt.rgba(1, 0.84, 0, 0.07)
                border.color: "gold"; border.width: 2

                // Crop pixel dimensions — top-right corner inside selection
                Text {
                    anchors.top:   parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 5; anchors.rightMargin: 6
                    visible: imgDisplay.selW > 70
                    text: Math.round(imgDisplay.selW / imgDisplay._scale)
                          + " × "
                          + Math.round(imgDisplay.selH / imgDisplay._scale)
                          + " px"
                    color: "gold"; font.pixelSize: 12; font.bold: true
                    style: Text.Outline; styleColor: "#111"
                }
            }

            // ── Rubber-band drag MouseArea (declared last → on top) ────────
            MouseArea {
                id: cropMouse
                anchors.fill: parent
                enabled: imgItem.status === Image.Ready
                property real px: 0; property real py: 0

                onPressed: function(mouse) {
                    px = mouse.x; py = mouse.y
                    imgDisplay.selX = mouse.x
                    imgDisplay.selY = mouse.y
                    imgDisplay.selW = 0
                    imgDisplay.selH = 0
                }
                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    imgDisplay.selX = Math.min(mouse.x, px)
                    imgDisplay.selY = Math.min(mouse.y, py)
                    imgDisplay.selW = Math.abs(mouse.x - px)
                    imgDisplay.selH = Math.abs(mouse.y - py)
                }
            }
        }

        // ── Footer: feedback + save button ───────────────────────────────────
        Item {
            id: footerBar
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.margins: 18
            height: 52

            Text {
                id: feedbackText
                anchors.left:            parent.left
                anchors.verticalCenter:  parent.verticalCenter
                width: parent.width * 0.65
                elide: Text.ElideRight
                text:  ""
                color: "#00FF7F"; font.pixelSize: 13; font.bold: true
            }

            Rectangle {
                anchors.right:           parent.right
                anchors.verticalCenter:  parent.verticalCenter
                width: 148; height: 44; radius: 22
                color: saveBtnHov.containsMouse ? "#B8860B" : "gold"

                Text {
                    anchors.centerIn: parent
                    text: "💾  SAVE CROP"; color: "black"
                    font.pixelSize: 15; font.bold: true
                }
                MouseArea {
                    id: saveBtnHov
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (!imgDisplay.hasSelection) {
                            feedbackText.text  = "⚠ Draw a crop area first"
                            feedbackText.color = "#FF6060"
                            feedbackTimer.restart()
                            return
                        }
                        var n = nameInput.text.trim()
                        if (n === "") {
                            feedbackText.text  = "⚠ Name required"
                            feedbackText.color = "#FF6060"
                            feedbackTimer.restart()
                            return
                        }
                        // Normalised ratios relative to source image
                        var xr = Math.max(0, (imgDisplay.selX - imgDisplay._offX) / imgDisplay._rendW)
                        var yr = Math.max(0, (imgDisplay.selY - imgDisplay._offY) / imgDisplay._rendH)
                        var wr = Math.min(imgDisplay.selW / imgDisplay._rendW, 1.0 - xr)
                        var hr = Math.min(imgDisplay.selH / imgDisplay._rendH, 1.0 - yr)
                        snatcher2Backend.saveCrop(xr, yr, wr, hr, n, snatcher2Root.destChoice)
                    }
                }
            }
        }
    }
}
