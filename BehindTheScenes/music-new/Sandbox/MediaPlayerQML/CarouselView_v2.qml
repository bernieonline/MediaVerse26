import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: carouselRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    // --- NEW: V2 click signal ---
    signal v2OpenDetail(var movie)

    property var externalImageList: []
    property string sortMode: "year"

    // --- METADATA TOOLS ---
    MetadataTools { id: metadata }

    // If you later re-enable sort, swap this line:
    // property var sortedList: metadata.sortList(externalImageList, sortMode)
    property var sortedList: externalImageList

    // --- GEOMETRY ---
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

    // --- DERIVED PROPERTIES FOR CURRENT ITEM ---
    property string currentFilePath: {
        if (!sortedList || sortedList.length === 0)
            return ""
        let idx = carouselView.currentIndex
        if (idx < 0 || idx >= sortedList.length)
            return ""
        return sortedList[idx].filePath || ""
    }

    property string currentTitle: metadata.extractCleanTitle(currentFilePath)
    property int currentYear: metadata.extractYear(currentFilePath)

    Row {
        anchors.fill: parent

        // LEFT BUTTON
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text { anchors.centerIn: parent; text: "❮"; color: "white"; font.pixelSize: 45 }
            MouseArea { anchors.fill: parent; onClicked: carouselView.decrementCurrentIndex() }
        }

        // CENTER AREA
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

                        // --- NEW: CLICK HANDLER FOR CAROUSEL ---
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                carouselRoot.v2OpenDetail({
                                    display: modelData.filePath,   // already a display path
                                    filePath: modelData.filePath,  // optional but consistent
                                    title: metadata.extractCleanTitle(modelData.filePath),
                                    year: metadata.extractYear(modelData.filePath)
                                })
                            }
                        }
                    }
                }
            }

            // --- TITLE + YEAR FOR CURRENT (CENTER) ITEM ---
            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                anchors.horizontalCenter: parent.horizontalCenter
                z: 2000
                spacing: 4

                // TITLE
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

                // YEAR
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

        // RIGHT BUTTON
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text { anchors.centerIn: parent; text: "❯"; color: "white"; font.pixelSize: 45 }
            MouseArea { anchors.fill: parent; onClicked: carouselView.incrementCurrentIndex() }
        }
    }
}