import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
//import "./MetadataTools.qml" as MetadataTools

Rectangle {
    id: gridRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    property var externalImageList: []
    property int currentPage: 0
    property int itemsPerPage: 12
    property bool showLabels: true


    MetadataTools {
        id: metadata
    }   

    // -------------------------------
    // HEIGHT-DRIVEN GEOMETRY ENGINE
    // -------------------------------

    readonly property real labelHeight: showLabels ? 45 : 0
    readonly property real rowSpacing: 20

    readonly property real maxHeightPerRow: (gridRoot.height / 2) - rowSpacing
    readonly property real posterHeight: Math.max(50, maxHeightPerRow - labelHeight)
    readonly property real posterWidth: posterHeight / 1.5

    // -------------------------------
    // PAGE SLICE (unchanged for now)
    // -------------------------------
    property var pageItems: {
        if (!externalImageList || externalImageList.length === 0) return [];
        let start = currentPage * itemsPerPage;
        return externalImageList.slice(start, start + itemsPerPage);
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

                            Rectangle {
                                width: parent.width
                                height: gridRoot.posterHeight
                                radius: 8
                                color: "#111"
                                border.color: "white"
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: modelData.filePath || ""
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }

                            Text {
                                width: parent.width
                                //text: MetadataTools.extractCleanTitle(modelData.filePath)   // ⭐ NEW
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