import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: carouselRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    // ------------------------------------------------------------
    // 1. DATA & TOOLS
    // ------------------------------------------------------------
    property var externalImageList: []
    property string sortMode: "year"
    property bool showLabels: false
    signal imageClicked(string cachePath, string originalPath)

    MetadataTools { id: metadata }
    property var sortedList: metadata.sortList(externalImageList, sortMode)

    // ------------------------------------------------------------
    // 2. GEOMETRY
    // ------------------------------------------------------------
    // Use most of the height for the posters
    readonly property real posterAreaHeight: height * 0.8
    property real posterHeight: posterAreaHeight * 0.75
    property real posterWidth: posterHeight * (2/3)

    property var scaleForIndex: function(i) {
        let dist = Math.abs(carouselView.currentIndex - i)
        if (dist === 0) return 1.1      // centre
        if (dist === 1) return 0.88     // inner
        if (dist === 2) return 0.75     // outer
        return 0.0
    }

    // Total width of 5 scaled posters
    property real totalPosterWidth: posterWidth * 3.5

    // Spacing between posters
    property real spacingValue: ((carouselCenter.width - totalPosterWidth) / 4) * 0.25


    // ============================================================
    // 3. MAIN LAYOUT (SIDE NAV + CAROUSEL + SIDE NAV)
    //    Mirrors the structure of ImageGridView_v2
    // ============================================================
    Row {
        anchors.fill: parent
        spacing: 0
        z: 1

        // ---------------- LEFT NAV ----------------
        Rectangle {
            id: leftNav
            width: 80
            height: parent.height
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "❮"
                color: "white"
                font.pixelSize: 45
                // Always visible for now (no opacity gating)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    carouselView.decrementCurrentIndex()
                }
            }
        }

        // ---------------- CAROUSEL CENTER AREA ----------------
        Item {
            id: carouselCenter
            width: parent.width - 160    // leave 80px for each side nav
            height: parent.height
            clip: true

            ListView {
                id: carouselView
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: sortedList
                clip: true
                spacing: carouselRoot.spacingValue

                preferredHighlightBegin: width / 2 - (carouselRoot.posterWidth / 2)
                preferredHighlightEnd: width / 2 + (carouselRoot.posterWidth / 2)
                highlightRangeMode: ListView.StrictlyEnforceRange

                leftMargin: carouselRoot.spacingValue
                rightMargin: carouselRoot.spacingValue

                Component.onCompleted: currentIndex = Math.floor(count / 2)

                delegate: Item {
                    width: carouselRoot.posterWidth * carouselRoot.scaleForIndex(index)
                    height: carouselRoot.posterHeight * carouselRoot.scaleForIndex(index)
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "#222"
                        border.color: "white"
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.filePath || ""
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: carouselView.currentIndex = index
                        }
                    }
                }
            }
        }

        // ---------------- RIGHT NAV ----------------
        Rectangle {
            id: rightNav
            width: 80
            height: parent.height
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "❯"
                color: "white"
                font.pixelSize: 45
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    carouselView.incrementCurrentIndex()
                }
            }
        }
    }
}