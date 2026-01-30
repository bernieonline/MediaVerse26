import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5

Rectangle {
    id: detailViewRoot
    anchors.fill: parent
    color: "transparent"

    // --- PROPERTIES ---
    property string xmlPath: ""
    property string imagePath: ""
    property var movie: null
    property bool tenFootMode: false
    property string manifestKey: ""

    signal v2PlayMovie(var movie)

    // --- HELPER FUNCTIONS ---
    function getSearchTitle() {
        var path = manifestKey !== "" ? manifestKey : imagePath
        var decoded = decodeURIComponent(path)
        var filename = decoded.split("/").pop().split("\\").pop()
        return filename.replace(/\.[^/.]+$/, "").trim()
    }

    // --- LOGIC & CONNECTIONS ---
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

        // --- LEFT PANEL (Poster with Double-Click Play) ---
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: leftPanel.height * 2 / 3
            radius: 15
            color: "#111"
            clip: true

            Image {
                id: posterImage
                anchors.fill: parent
                source: imagePath
                fillMode: Image.PreserveAspectCrop
                smooth: true

                MouseArea {
                    id: posterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    property bool clickPending: false

                    onClicked: {
                        if (clickPending) {
                            doubleClickTimer.stop()
                            clickPending = false
                            let resolved = xmlController.resolve_paths(imagePath)
                            if (resolved && resolved.video) {
                                let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                                playbackRouter.playVideo(cleanPath, false)
                                detailViewRoot.v2PlayMovie(cleanPath)
                            }
                        } else {
                            clickPending = true
                            doubleClickTimer.start()
                        }
                    }
                }

                Timer {
                    id: doubleClickTimer
                    interval: 350
                    onTriggered: posterMouse.clickPending = false
                }
            }
        }

        // --- RIGHT PANEL ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                background: Rectangle { color: "transparent" }
                Repeater {
                    model: xmlController.getCategories()
                    TabButton {
                        text: modelData
                        onClicked: xmlController.requestCategoryContent(modelData)
                    }
                }
                TabButton { 
                    text: "AiQ" 
                    onClicked: xmlTextArea.text = "AI Analysis Mode for " + getSearchTitle()
                }
            }

            // --- AI SHORTCUT PANEL (WITH CONTEXT & CLEAR) ---
            Rectangle {
                id: aiqPanel
                visible: tabBar.currentIndex === (tabBar.count - 1)
                color: "#1a1a1a"
                radius: 10
                Layout.fillWidth: true
                implicitHeight: aiColumn.implicitHeight + 25

                ColumnLayout {
                    id: aiColumn
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    Text {
                        text: "ASKING ABOUT: " + getSearchTitle().toUpperCase()
                        color: "cyan"
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        font.bold: true
                        opacity: 0.8
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        TextField {
                            id: customQuestionInput
                            Layout.fillWidth: true
                            placeholderText: "Ask a specific question..."
                            color: "white"
                            font.pixelSize: 18
                            leftPadding: 12
                            background: Rectangle { 
                                color: "#000" 
                                radius: 4 
                                border.color: parent.activeFocus ? "cyan" : "#333" 
                            }
                            onAccepted: runAiButton.clicked()
                        }

                        Button {
                            id: clearAiButton
                            text: "X"
                            implicitWidth: 40
                            onClicked: customQuestionInput.clear()
                            contentItem: Text { text: "X"; color: "#888"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: "#222"; radius: 4; border.color: parent.hovered ? "#444" : "transparent" }
                        }

                        Button {
                            id: runAiButton
                            text: "RUN"
                            implicitWidth: 80
                            contentItem: Text { text: "RUN"; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: "white"; radius: 4 }
                            onClicked: {
                                if (customQuestionInput.text.trim() !== "") {
                                    var q = "I have a question about " + getSearchTitle() + ": " + customQuestionInput.text
                                    aiController.ask(getSearchTitle(), q)
                                }
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10
                        component QuickButton : Button {
                            contentItem: Text { text: parent.text; color: "#bbb"; font.pixelSize: 12 }
                            background: Rectangle { color: "#2a2a2a"; radius: 4; border.color: parent.hovered ? "cyan" : "#444" }
                        }
                        QuickButton { text: "Trivia"; onClicked: aiController.ask(getSearchTitle(), "Give me 3 cool trivia facts.") }
                        QuickButton { text: "Locations"; onClicked: aiController.ask(getSearchTitle(), "Where was this filmed?") }
                        QuickButton { text: "Cast Info"; onClicked: aiController.ask(getSearchTitle(), "Tell me about the cast.") }
                    }
                }
            }

            // --- TEXT AREA ---
            Rectangle {
                color: "#151515"
                radius: 10
                Layout.fillWidth: true
                Layout.fillHeight: true
                border.color: aiqPanel.visible ? "cyan" : "transparent"

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
                        font.pixelSize: detailViewRoot.tenFootMode ? 32 : 16
                        padding: 20
                        background: Item {}
                    }
                }

                BusyIndicator { id: aiSpinner; anchors.centerIn: parent; running: false }
                
                Timer {
                    id: aiTimer
                    interval: 1000; running: aiSpinner.running; repeat: true
                    property int seconds: 0
                    onTriggered: seconds++
                    onRunningChanged: if (!running) seconds = 0
                }
            }

            // --- BRANDED WEB LINKS ---
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "transparent"
                RowLayout {
                    id: brandedLinks
                    anchors.fill: parent
                    spacing: 8
                    function openWeb(url) { Qt.openUrlExternally(url + encodeURIComponent(getSearchTitle())) }
                    
                    Repeater {
                        model: [
                            { n: "IMDb", u: "https://www.imdb.com/find?q=", b: "#F5C518", t: "black" },
                            { n: "TMDB", u: "https://www.themoviedb.org/search?query=", b: "#01b4e4", t: "white" },
                            { n: "Blu-Ray", u: "https://www.blu-ray.com/search/?action=search&keyword=", b: "#0046be", t: "white" },
                            { n: "Rotten", u: "https://www.rottentomatoes.com/search?search=", b: "#FA320A", t: "white" },
                            { n: "Wiki", u: "https://en.wikipedia.org/wiki/Special:Search?search=", b: "#e6e6e6", t: "black" }
                        ]
                        Button {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentItem: Text {
                                text: modelData.n
                                color: parent.hovered ? "white" : modelData.t
                                font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle { 
                                color: parent.hovered ? Qt.lighter(modelData.b, 1.1) : modelData.b
                                radius: 4
                                border.color: parent.hovered ? "white" : "transparent"
                                border.width: 1
                            }
                            onClicked: brandedLinks.openWeb(modelData.u)
                        }
                    }
                }
            }
        }
    }
}