import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5

Rectangle {
    id: detailViewRoot
    anchors.fill: parent
    color: "transparent"

    property string xmlPath: ""



    Component.onCompleted: {
        console.log("DEBUG: xmlController =", xmlController)
        console.log("DEBUG: xmlPath received =", xmlPath)

        // 1) Start from the QML imagePath
        var decoded = decodeURIComponent(imagePath)
        if (decoded.startsWith("file:///"))
            decoded = decoded.substring(8)

        console.log("DEBUG: raw imagePath =", decoded)

        // 2) Extract the cache-local path used as manifest key
        //    e.g. from:
        //    D:/MediaVerse1.0/.../cacheV2/images/display/Western HD/Chisum (1970).jpg
        //    to:
        //    Western HD/Chisum (1970).jpg
        var marker = "cacheV2/images/display/"
        var keyPath = decoded
        var idx = decoded.indexOf(marker)
        if (idx !== -1)
            keyPath = decoded.substring(idx + marker.length)

        console.log("DEBUG: manifest lookup key (local image path) =", keyPath)

        // 🔒 No xmlController lookup here yet — just printing what we *would* pass in


        if (xmlPath && xmlPath.length > 0) {
            xmlController.loadXML(xmlPath)

            var cats = xmlController.getCategories()
            if (cats.length > 0) {
                tabBar.currentIndex = 0
                xmlController.requestCategoryContent(cats[0])
            }
        }







    }

    // ============================================================
    //  STEP 1 TEST PATCH
    //  Accept a simple imagePath directly from the button
    // ============================================================
    property string imagePath: ""

    // ============================================================
    //  V2 MOVIE OBJECT (unused in Step 1, kept for later)
    // ============================================================
    property var movie: null
    property bool tenFootMode: false

    signal v2PlayMovie(var movie)

    // ============================================================
    //  PUBLIC API — used later when movie objects are passed
    // ============================================================
    function loadMovie(m) {
        movie = m

        if (!movie)
            return

        // Poster from V2 movie object (not used in Step 1)
        posterImage.source = movie.posterPath

        // XML loading (disabled for Step 1)
        if (movie.xmlPath && movie.xmlPath.length > 0) {
            xmlController.loadXML(movie.xmlPath)

            var cats = xmlController.getCategories()
            if (cats.length > 0) {
                tabBar.currentIndex = 0
                xmlController.requestCategoryContent(cats[0])
            }
        }
    }

    // ============================================================
    //  XML CONTENT UPDATES (inactive in Step 1)
    // ============================================================
    Connections {
        target: xmlController
        function onCategoryContentUpdated(category, lines) {
            xmlTextArea.text = lines.join("\n\n")
        }
    }

    // ============================================================
    //  LAYOUT
    // ============================================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // --------------------------------------------------------
        // LEFT PANEL — LARGE POSTER
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

                // ⭐ STEP 1: Use the direct imagePath
                source: imagePath

                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton

                onDoubleClicked: {
                    if (movie) {
                        console.log("Detail_View_v2 double-click → play:", movie.originalPath)
                        detailViewRoot.v2PlayMovie(movie)
                    }
                }
            }
        }

        // --------------------------------------------------------
        // RIGHT PANEL — TABS + XML CONTENT (inactive in Step 1)
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