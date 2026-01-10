import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5

Rectangle {
    id: detailViewRoot
    anchors.fill: parent
    color: "transparent"

    property string xmlPath: ""
    property string imagePath: ""
    property var movie: null
    property bool tenFootMode: false

    // Key used to look up the movie in the manifest
    property string manifestKey: ""

    signal v2PlayMovie(var movie)

    Component.onCompleted: {
        var decoded = decodeURIComponent(imagePath)
        if (decoded.startsWith("file:///"))
            decoded = decoded.substring(8)

        var marker = "cacheV2/images/display/"
        var keyPath = decoded
        var idx = decoded.indexOf(marker)
        if (idx !== -1)
            keyPath = decoded.substring(idx + marker.length)

        manifestKey = keyPath

        if (xmlPath && xmlPath.length > 0) {
            xmlController.loadXML(xmlPath)
            var cats = xmlController.getCategories()
            if (cats.length > 0) {
                tabBar.currentIndex = 0
                xmlController.requestCategoryContent(cats[0])
            }
        }
    }

    function loadMovie(m) {
        movie = m
        if (!movie) return
        posterImage.source = movie.posterPath
        if (movie.xmlPath && movie.xmlPath.length > 0) {
            xmlController.loadXML(movie.xmlPath)
            var cats = xmlController.getCategories()
            if (cats.length > 0) {
                tabBar.currentIndex = 0
                xmlController.requestCategoryContent(cats[0])
            }
        }
    }

    Connections {
        target: xmlController
        function onCategoryContentUpdated(category, lines) {
            xmlTextArea.text = lines.join("\n\n")
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // --------------------------------------------------------
        // LEFT PANEL — LARGE POSTER (Now with Playback)
        // --------------------------------------------------------
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: leftPanel.height * 2 / 3
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            radius: 15
            color: "transparent"

            Image {
                id: posterImage
                anchors.fill: parent
                source: imagePath
                fillMode: Image.PreserveAspectCrop
                smooth: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    
                    property bool doubleClickActive: false
                    property var singleClickTimer: null

                    onClicked: {
                        if (singleClickTimer) singleClickTimer.stop()
                        singleClickTimer = Qt.createQmlObject(
                            'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                            detailViewRoot
                        )
                        singleClickTimer.triggered.connect(function() {
                            if (!doubleClickActive) {
                                // Potential future single-click action (e.g. zoom)
                                console.log("DETAIL VIEW: Single click")
                            }
                            doubleClickActive = false
                        })
                        singleClickTimer.start()
                    }

                    onDoubleClicked: {
                        doubleClickActive = true
                        if (singleClickTimer) singleClickTimer.stop()

                        // 1. Resolve paths using manifestKey
                        let resolved = xmlController.resolve_paths(detailViewRoot.manifestKey)
                        
                        if (resolved && resolved.video) {
                            // 2. Clean slashes for Python
                            let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                            
                            console.log("!!! DETAIL VIEW PLAYBACK TRIGGERED !!!")
                            console.log("Path: " + cleanPath)

                            // 3. SEND TO BRIDGE
                            playbackBridge.playVideo(cleanPath)
                            
                            // 4. Emit signal
                            detailViewRoot.v2PlayMovie(cleanPath)
                        } else {
                            console.log("DETAIL ERROR: No video found for " + detailViewRoot.manifestKey)
                        }
                    }
                }
            }
        }

        // --------------------------------------------------------
        // RIGHT PANEL — TABS + XML CONTENT
        // --------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                Repeater {
                    model: xmlController.getCategories()
                    TabButton {
                        text: modelData
                        onClicked: xmlController.requestCategoryContent(modelData)
                    }
                }
            }

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.fillHeight: true

                ScrollView {
                    id: scrollArea
                    anchors.fill: parent
                    clip: true

                    TextArea {
                        id: xmlTextArea
                        width: scrollArea.width
                        readOnly: true
                        wrapMode: Text.Wrap
                        text: "No details available"
                        background: null
                        color: "white"
                        font.pixelSize: detailViewRoot.tenFootMode ? 48 : 16
                        font.bold: true
                        padding: 20
                        rightPadding: vbar.width + 10
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AlwaysOn
                        interactive: true
                        width: detailViewRoot.tenFootMode ? 30 : 14
                        anchors.right: scrollArea.right
                        anchors.top: scrollArea.top
                        anchors.bottom: scrollArea.bottom
                        z: 10
                        background: Rectangle { color: "#262626"; radius: 6 }
                        contentItem: Rectangle {
                            implicitWidth: vbar.width
                            implicitHeight: 100
                            radius: 6
                            color: "#3a3a3a"
                        }
                    }
                }
            }
        }
    }
}