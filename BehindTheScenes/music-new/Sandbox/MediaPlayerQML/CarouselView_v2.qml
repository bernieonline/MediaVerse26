import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: carouselRoot
    anchors.fill: parent
    color: "transparent"

    //
    // --- GEOMETRY FOUNDATION ---
    //

    // Center poster = 2/3 of container height
    property real posterHeight: height * 0.66
    property real posterWidth: posterHeight * (2/3)

    // Scale rules for the 5 visible items:
    // Center = 1.0, next two = 0.5, outer two = 0.3
   
    property var scaleForIndex: function(i) {
        let dist = Math.abs(carouselView.currentIndex - i)
        if (dist === 0) return 1.1      // centre
        if (dist === 1) return 0.88     // inner (10% larger)
        if (dist === 2) return 0.75    // outer (10% smaller)
        return 0.0                      // anything beyond 2 should not be visible
    }


    // Total width of the 5 scaled posters
    //property real totalPosterWidth: posterWidth * (1.0 + 0.5 + 0.5 + 0.3 + 0.3)
    
    property real totalPosterWidth: posterWidth * 3.4

    // Perfect spacing for exactly 5 posters across
    //property real spacingValue: (width - totalPosterWidth) / 4
    property real spacingValue: ((width - totalPosterWidth) / 4) * 0.25


    //
    // --- YOUR ORIGINAL PROPERTIES ---
    //

    property var externalImageList: []
    property string sortMode: "year"
    property bool showLabels: false

    signal launchVideoRequested(string cachePath)
    signal imageClicked(string cachePath, string originalPath)

    MetadataTools { id: metadata }

    property var sortedList: metadata.sortList(externalImageList, sortMode)


    //
    // --- LISTVIEW (pure geometry, no effects) ---
    //

    ListView {
        id: carouselView
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: carouselRoot.spacingValue
        model: sortedList
        clip: true

        preferredHighlightBegin: width / 2 - (carouselRoot.posterWidth / 2)
        preferredHighlightEnd: width / 2 + (carouselRoot.posterWidth / 2)
        highlightRangeMode: ListView.StrictlyEnforceRange

        leftMargin: carouselRoot.spacingValue
        rightMargin: carouselRoot.spacingValue

        Component.onCompleted: currentIndex = Math.floor(count / 2)

        //
        // --- DELEGATE (scaled geometry only) ---
        //
        delegate: Item {
            width: carouselRoot.posterWidth * carouselRoot.scaleForIndex(index)
            height: carouselRoot.posterHeight * carouselRoot.scaleForIndex(index)

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#111"
                border.color: "white"
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    source: modelData.filePath
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: carouselRoot.imageClicked(modelData.filePath, modelData.originalPath)
                }
            }
        }
    }
}