import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: gridRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    property var externalImageList: []
    property int currentPage: 0
    property int itemsPerPage: 12
    property bool showLabels: true
    property string sortMode: "oldest"   // ⭐ default sort order

     
    MetadataTools {
        id: metadata
    }
    property var sortedList: metadata.sortList(externalImageList, sortMode)

    // -------------------------------
    // HEIGHT-DRIVEN GEOMETRY ENGINE
    // -------------------------------
    readonly property real labelHeight: showLabels ? 45 : 0
    readonly property real rowSpacing: 20

    readonly property real maxHeightPerRow: (gridRoot.height / 2) - rowSpacing
    readonly property real posterHeight: Math.max(50, maxHeightPerRow - labelHeight)
    readonly property real posterWidth: posterHeight / 1.5

    // -------------------------------
    // PAGE SLICE
    // -------------------------------
    property var pageItems: {
        if (!sortedList || sortedList.length === 0) return [];
        let start = currentPage * itemsPerPage;
        return sortedList.slice(start, start + itemsPerPage);
    }
    Rectangle {
        id: sortControl
        width: 140
        height: 40
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        radius: 6
        color: "#333333"
        border.color: "white"
        border.width: 1


        Text {
            anchors.centerIn: parent
            text: "Sort: " + gridRoot.sortMode
            color: "white"
            font.pixelSize: 14
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (gridRoot.sortMode === "oldest")      gridRoot.sortMode = "recent"
                else if (gridRoot.sortMode === "recent") gridRoot.sortMode = "added"
                else if (gridRoot.sortMode === "added")  gridRoot.sortMode = "alpha"
                else                                      gridRoot.sortMode = "oldest"
            }
        }
    }

   
    // -------------------------------
    // MAIN LAYOUT
    // -------------------------------
    Row {
        anchors.fill: parent
        spacing: 0

        // LEFT NAV
        Rectangle {
            width: 80
            height: parent.height
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "❮"
                color: "white"
                font.pixelSize: 45
                opacity: currentPage > 0 ? 1.0 : 0.1
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (currentPage > 0) currentPage--
            }
        }

        // GRID CONTAINER
        Item {
            id: gridContainer
            width: parent.width - 160
            height: parent.height
            clip: true

            Grid {
                id: imageGrid
                anchors.centerIn: parent
                columns: 6
                columnSpacing: 40
                rowSpacing: gridRoot.rowSpacing

                Repeater {
                    model: gridRoot.pageItems

                    delegate: Item {
                        width: gridRoot.posterWidth
                        height: gridRoot.posterHeight + gridRoot.labelHeight

                        Column {
                            anchors.fill: parent
                            spacing: 5

                            // POSTER CONTAINER
                            Rectangle {
                                id: posterContainer
                                width: parent.width
                                height: gridRoot.posterHeight
                                radius: 8
                                color: "#111"
                                border.color: "white"
                                border.width: 1
                                clip: true

                                Image {
                                    id: posterImage
                                    anchors.fill: parent
                                    source: modelData.filePath || ""
                                    fillMode: Image.PreserveAspectCrop
                                }

                                // ⭐ YEAR BADGE
                                Rectangle {
                                    id: yearBadge
                                    width: 36
                                    height: 20
                                    radius: 4
                                    color: "#66000000"
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 4
                                    anchors.rightMargin: 4
                                    visible: metadata.extractYear(modelData.filePath) > 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: metadata.extractYear(modelData.filePath)
                                        color: "white"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            // TITLE LABEL
                            Text {
                                width: parent.width
                                text: metadata.extractCleanTitle(modelData.filePath)
                                color: "white"
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                                visible: gridRoot.showLabels
                            }
                        }
                    }
                }
            }
        }

        // RIGHT NAV
        Rectangle {
            width: 80
            height: parent.height
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "❯"
                color: "white"
                font.pixelSize: 45
                opacity: (currentPage < Math.ceil(externalImageList.length / itemsPerPage) - 1) ? 1.0 : 0.1
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let totalPages = Math.ceil(externalImageList.length / itemsPerPage)
                    if (currentPage < totalPages - 1) currentPage++
                }
            }
        }
    }
}