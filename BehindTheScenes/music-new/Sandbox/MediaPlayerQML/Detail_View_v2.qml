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
        return filename.replace(/\.[^/.]+$/, "").trim()
    }

    Connections {
        target: xmlController
        function onCategoryContentUpdated(category, lines) {
            if (tabBar.currentIndex !== (tabBar.count - 1)) {
                xmlTextArea.text = lines.join("\n\n")
            }
        }
    }

    Connections {
        target: aiController
        function onAnswerReady(answer) { xmlTextArea.text = answer }
        function onLoadingStatus(isLoading) { aiSpinner.running = isLoading }
    }

    Component.onCompleted: {
        var decoded = decodeURIComponent(imagePath)
        if (decoded.startsWith("file:///")) decoded = decoded.substring(8)
        var marker = "cacheV2/images/display/"
        var keyPath = decoded
        var idx = decoded.indexOf(marker)
        if (idx !== -1) keyPath = decoded.substring(idx + marker.length)
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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        // LEFT PANEL (Poster)
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: leftPanel.height * 2 / 3
            radius: 15
            color: "transparent"
            Image {
                id: posterImage
                anchors.fill: parent
                source: imagePath
                fillMode: Image.PreserveAspectCrop
                smooth: true
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
                Repeater {
                    model: xmlController.getCategories()
                    TabButton {
                        text: modelData
                        onClicked: xmlController.requestCategoryContent(modelData)
                    }
                }
                TabButton { 
                    text: "AiQ" 
                    onClicked: {
                        if (!xmlTextArea.text.includes("AI Analysis")) {
                             xmlTextArea.text = "AI Analysis Mode for " + getSearchTitle()
                        }
                    }
                }
            }

            // AI SHORTCUT PANEL
            Rectangle {
                id: aiqPanel
                visible: tabBar.currentIndex === (tabBar.count - 1)
                color: "#1a1a1a"
                radius: 5
                Layout.fillWidth: true
                implicitHeight: aiFlow.implicitHeight + 20

                Flow {
                    id: aiFlow
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Button { text: "Trivia"; onClicked: aiController.ask(getSearchTitle(), "Give me 3 cool trivia facts.") }
                    Button { text: "Locations"; onClicked: aiController.ask(getSearchTitle(), "Where was this filmed?") }
                    Button { text: "Actor Thoughts"; onClicked: aiController.ask(getSearchTitle(), "What did the lead actors say about filming this?") }
                    Button { text: "Director's Next"; onClicked: aiController.ask(getSearchTitle(), "What movie did the director make after this?") }
                }
            }

            // TEXT AREA WITH SCROLLING, SPINNER & TIMER
            Rectangle {
                color: "#151515"
                radius: 10
                Layout.fillWidth: true
                Layout.fillHeight: true
                border.color: aiqPanel.visible ? "cyan" : "transparent"
                border.width: 1

                ScrollView {
                    id: scrollArea
                    anchors.fill: parent
                    clip: true
                    TextArea {
                        id: xmlTextArea
                        width: scrollArea.width
                        readOnly: true
                        wrapMode: Text.WordWrap
                        color: "white"
                        opacity: aiSpinner.running ? 0.3 : 1.0
                        font.pixelSize: detailViewRoot.tenFootMode ? 32 : 16
                        padding: 20
                        background: Item {}
                    }
                }

                BusyIndicator {
                    id: aiSpinner
                    anchors.centerIn: parent
                    visible: running
                    running: false
                }

                Text {
                    anchors.top: aiSpinner.bottom
                    anchors.horizontalCenter: aiSpinner.horizontalCenter
                    anchors.topMargin: 10
                    text: "Thinking... " + aiTimer.seconds + "s"
                    color: "cyan"
                    visible: aiSpinner.running
                }

                Timer {
                    id: aiTimer
                    interval: 1000
                    running: aiSpinner.running
                    repeat: true
                    property int seconds: 0
                    onTriggered: seconds++
                    onRunningChanged: if (!running) seconds = 0
                }
            }

            // --- ⭐ STYLIZED WEB LINKS ROW ---
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "transparent"
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    function openWeb(url) { Qt.openUrlExternally(url + encodeURIComponent(getSearchTitle())) }
                    
                    // Styled component with dynamic colors
                    component WebButton : Button {
                        property color brandColor: "#222"
                        property color textColor: "white"
                        Layout.fillWidth: true; Layout.fillHeight: true
                        
                        background: Rectangle { 
                            color: parent.hovered ? Qt.lighter(parent.brandColor, 1.2) : parent.brandColor
                            radius: 4
                            border.color: parent.hovered ? "white" : "transparent"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: parent.textColor
                            font.bold: true
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    WebButton { 
                        text: "IMDb"
                        brandColor: "#f5c518" // IMDb Yellow
                        textColor: "black"    // IMDb Text is black on yellow
                        onClicked: parent.openWeb("https://www.imdb.com/find?q=") 
                    }
                    WebButton { 
                        text: "Rotten"
                        brandColor: "#fa320a" // RT Red
                        onClicked: parent.openWeb("https://www.rottentomatoes.com/search?search=") 
                    }
                    WebButton { 
                        text: "TMDB"
                        brandColor: "#01b4e4" // TMDB Blue
                        onClicked: parent.openWeb("https://www.themoviedb.org/search?query=") 
                    }
                    WebButton { 
                        text: "Wiki"
                        brandColor: "#333333" // Wiki Dark Grey
                        onClicked: parent.openWeb("https://en.wikipedia.org/wiki/Special:Search?search=") 
                    }
                    WebButton { 
                        text: "Blu-ray"
                        brandColor: "#0071bd" // Blu-ray Disc Blue
                        onClicked: parent.openWeb("https://www.blu-ray.com/search/?action=search&keyword=") 
                    }
                }
            }
        }
    }
}