import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: gridRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    signal v2OpenDetail(var movie)
    signal v2PlayMovie(string videoPath)

    property var externalImageList: []
    property int currentPage: 0
    property int itemsPerPage: 12
    property bool showLabels: true
    property string sortMode: "oldest"

    // Logic for sorting and paging
    property var sortedList: {
        if (!externalImageList) return [];
        // Note: Using a simple sort if MetadataTools isn't available
        return externalImageList; 
    }

    readonly property real labelHeight: showLabels ? 45 : 0
    readonly property real rowSpacing: 20
    readonly property real maxHeightPerRow: (gridRoot.height / 2) - rowSpacing
    readonly property real posterHeight: Math.max(50, maxHeightPerRow - labelHeight)
    readonly property real posterWidth: posterHeight / 1.5

    property var pageItems: {
        if (!sortedList || sortedList.length === 0) return [];
        let start = currentPage * itemsPerPage;
        return sortedList.slice(start, start + itemsPerPage);
    }

    // CLICK DE-BOUNCER
    property var currentClickData: null
    Timer {
        id: clickTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (gridRoot.currentClickData) {
                gridRoot.v2OpenDetail(gridRoot.currentClickData)
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // Navigation Left
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text {
                anchors.centerIn: parent; text: "❮"; color: "white"; font.pixelSize: 45
                opacity: currentPage > 0 ? 1.0 : 0.1
            }
            MouseArea { anchors.fill: parent; onClicked: if (currentPage > 0) currentPage-- }
        }

        // Main Grid
        Item {
            id: gridContainer
            width: parent.width - 160; height: parent.height; clip: true
            Grid {
                id: imageGrid; anchors.centerIn: parent; columns: 6; columnSpacing: 40; rowSpacing: gridRoot.rowSpacing
                Repeater {
                    model: gridRoot.pageItems
                    delegate: Item {
                        width: gridRoot.posterWidth; height: gridRoot.posterHeight + gridRoot.labelHeight
                        Column {
                            anchors.fill: parent; spacing: 5
                            Item {
                                width: parent.width; height: gridRoot.posterHeight
                                Rectangle {
                                    id: posterRect; anchors.fill: parent; radius: 8; color: "#111"
                                    border.color: modelData.sourceType === "RAW" ? "#555" : "white"
                                    border.width: 1; clip: true
                                    Image {
                                        anchors.fill: parent; source: modelData.filePath || ""
                                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        clickTimer.stop()
                                        gridRoot.currentClickData = modelData
                                        clickTimer.start()
                                    }
                                    onDoubleClicked: {
                                        clickTimer.stop()
                                        gridRoot.currentClickData = null
                                        if (modelData.originalPath) {
                                            let rawPath = modelData.originalPath.toString();
                                            // CLEAN THE PATH: remove file:/// and decode URL characters
                                            let cleanPath = decodeURIComponent(rawPath.replace(/^(file:\/{3})/, ""));
                                            // Flip slashes for Windows if needed
                                            cleanPath = cleanPath.replace(/\//g, "\\");
                                            
                                            console.log("🚀 Playing Video:", cleanPath);
                                            playbackBridge.playVideo(cleanPath);
                                            gridRoot.v2PlayMovie(cleanPath);
                                        }
                                    }
                                }
                            }
                            Text {
                                width: parent.width; text: modelData.title || ""
                                color: "white"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
                                visible: gridRoot.showLabels
                            }
                        }
                    }
                }
            }
        }

        // Navigation Right
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text {
                anchors.centerIn: parent; text: "❯"; color: "white"; font.pixelSize: 45
                opacity: (currentPage < Math.ceil(sortedList.length / itemsPerPage) - 1) ? 1.0 : 0.1
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let totalPages = Math.ceil(sortedList.length / itemsPerPage)
                    if (currentPage < totalPages - 1) currentPage++
                }
            }
        }
    }
}