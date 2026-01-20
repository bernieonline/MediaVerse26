import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: carouselRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    // --- Signals ---
    signal v2OpenDetail(var movie)
    signal v2PlayMovie(var movie)

    property var externalImageList: []
    property string sortMode: "year"

    // --- Metadata Tools ---
    MetadataTools { id: metadata }

    property var sortedList: externalImageList

    // --- Geometry & Scaling ---
    readonly property real posterAreaHeight: height * 0.8
    property real posterHeight: posterAreaHeight * 0.75
    property real posterWidth: posterHeight * (2/3)

    property var scaleForIndex: function(i) {
        let dist = Math.abs(carouselView.currentIndex - i)
        if (dist === 0) return 1.1
        if (dist === 1) return 0.88
        if (dist === 2) return 0.75
        return 0.0
    }

    property real totalPosterWidth: posterWidth * 3.5
    property real spacingValue: ((carouselCenter.width - totalPosterWidth) / 4) * 0.25

    // --- Derived Properties for Center Item ---
    property string currentFilePath: {
        if (!sortedList || sortedList.length === 0) return ""
        let idx = carouselView.currentIndex
        if (idx < 0 || idx >= sortedList.length) return ""
        return sortedList[idx].filePath || ""
    }

    property string currentTitle: metadata.extractCleanTitle(currentFilePath)
    property int currentYear: metadata.extractYear(currentFilePath)

    Row {
        anchors.fill: parent

        // Left Navigation
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text { anchors.centerIn: parent; text: "❮"; color: "white"; font.pixelSize: 45 }
            MouseArea { anchors.fill: parent; onClicked: carouselView.decrementCurrentIndex() }
        }

        // Carousel Container
        Item {
            id: carouselCenter
            width: parent.width - 160
            height: parent.height
            clip: true

            ListView {
                id: carouselView
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: sortedList
                spacing: carouselRoot.spacingValue
                preferredHighlightBegin: width / 2 - (carouselRoot.posterWidth / 2)
                preferredHighlightEnd: width / 2 + (carouselRoot.posterWidth / 2)
                highlightRangeMode: ListView.StrictlyEnforceRange

                delegate: Item {
                    width: carouselRoot.posterWidth * carouselRoot.scaleForIndex(index)
                    height: carouselRoot.posterHeight * carouselRoot.scaleForIndex(index)
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        color: "#222"
                        border.color: "white"
                        border.width: 1
                        radius: 12
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.filePath || ""
                            fillMode: Image.PreserveAspectFit
                        }

                        // --- FINAL PLAYBACK CLICK HANDLER ---
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            property bool doubleClickActive: false
                            property var singleClickTimer: null

                            onClicked: {
                                if (singleClickTimer) singleClickTimer.stop()
                                
                                singleClickTimer = Qt.createQmlObject(
                                    'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                                    carouselRoot
                                )
                                
                                singleClickTimer.triggered.connect(function() {
                                    if (!doubleClickActive) {
                                        carouselRoot.v2OpenDetail({
                                            display: modelData.filePath,
                                            filePath: modelData.filePath,
                                            title: metadata.extractCleanTitle(modelData.filePath),
                                            year: metadata.extractYear(modelData.filePath)
                                        })
                                    }
                                    doubleClickActive = false
                                })
                                singleClickTimer.start()
                            }

                            onDoubleClicked: {
                                doubleClickActive = true
                                if (singleClickTimer) singleClickTimer.stop()

                                // 1. Resolve full V2 paths
                                let resolved = _xmlController.resolve_paths(modelData.filePath)
                                
                                if (resolved && resolved.video) {
                                    // 2. Clean slashes for the Python Bridge
                                    let cleanPath = resolved.video.toString().replace(/\\/g, "/")
                                    
                                    console.log("!!! CAROUSEL PLAYBACK TRIGGERED !!!")
                                    console.log("Target: " + cleanPath)

                                    // 3. EXECUTE PLAYBACK
                                    //playbackBridge.playVideo(cleanPath)
                                    playbackRouter.playVideo(cleanPath, false)
                                    
                                    
                                    
                                    // 4. Signal UI (optional)
                                    carouselRoot.v2PlayMovie(cleanPath)
                                } else {
                                    console.log("CAROUSEL ERROR: No video found for " + modelData.filePath)
                                }
                            }
                        }
                    }
                }
            }

            // Labels
            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                anchors.horizontalCenter: parent.horizontalCenter
                z: 2000
                spacing: 4

                Text {
                    width: carouselCenter.width * 0.6
                    text: carouselRoot.currentTitle
                    color: "#FFD86B"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    visible: carouselRoot.currentTitle !== ""
                }

                Text {
                    width: carouselCenter.width * 0.6
                    text: carouselRoot.currentYear === 0 ? "" : carouselRoot.currentYear
                    color: "#FFD86B"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    visible: carouselRoot.currentYear !== 0
                }
            }
        }

        // Right Navigation
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text { anchors.centerIn: parent; text: "❯"; color: "white"; font.pixelSize: 45 }
            MouseArea { anchors.fill: parent; onClicked: carouselView.incrementCurrentIndex() }
        }
    }
}