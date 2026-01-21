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
    property string manifestKey: ""

    signal v2PlayMovie(var movie)

    function getSearchTitle() {
        var path = manifestKey !== "" ? manifestKey : imagePath
        var decoded = decodeURIComponent(path)
        var filename = decoded.split("/").pop().split("\\").pop()
        return filename.replace(/\.[^/.]+$/, "")
    }

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
            // Only update text if we aren't on the AiQ tab
            if (tabBar.currentItem && tabBar.currentItem.text !== "AiQ") {
                xmlTextArea.text = lines.join("\n\n")
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // LEFT PANEL (Poster)
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
                    onDoubleClicked: {
                        let resolved = xmlController.resolve_paths(detailViewRoot.manifestKey)
                        if (resolved && resolved.video) {
                            let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                            playbackRouter.playVideo(cleanPath, false)
                            detailViewRoot.v2PlayMovie(cleanPath)
                        }
                    }
                }
            }
        }

        // RIGHT PANEL
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                
                // 1. Dynamic Tabs from XML
                Repeater {
                    model: xmlController.getCategories()
                    TabButton {
                        text: modelData
                        onClicked: xmlController.requestCategoryContent(modelData)
                    }
                }

                // 2. ⭐ NEW: Static AiQ Tab
                TabButton {
                    text: "AiQ"
                    onClicked: {
                        xmlTextArea.text = "AI Analysis for " + getSearchTitle() + "...\n\n(Waiting for AI metadata...)"
                        // You can trigger a python call here later for your AI analysis
                    }
                }
            }

            Rectangle {
                color: "#151515"
                radius: 10
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
                        color: "white"
                        font.pixelSize: detailViewRoot.tenFootMode ? 48 : 16
                        padding: 20
                    }
                }
            }

            // WEB LINKS ROW
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    function openWeb(url) {
                        var fullUrl = url + encodeURIComponent(getSearchTitle())
                        Qt.openUrlExternally(fullUrl)
                    }

                    component WebLinkButton : Button {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentItem: Text {
                            text: parent.text
                            font.bold: true
                            color: parent.down ? "gold" : "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#333" : "#222"
                            border.color: parent.hovered ? "gold" : "#444"
                            border.width: 1
                            radius: 8
                        }
                    }

                    WebLinkButton { text: "IMDb"; onClicked: parent.openWeb("https://www.imdb.com/find?q=") }
                    WebLinkButton { text: "Rotten"; onClicked: parent.openWeb("https://www.rottentomatoes.com/search?search=") }
                    WebLinkButton { text: "TMDB"; onClicked: parent.openWeb("https://www.themoviedb.org/search?query=") }
                    WebLinkButton { text: "Wiki"; onClicked: parent.openWeb("https://en.wikipedia.org/wiki/Special:Search?search=") }
                    WebLinkButton { text: "Blu-ray"; onClicked: parent.openWeb("https://www.blu-ray.com/search/?action=search&keyword=") }
                }
            }
        }
    }
}