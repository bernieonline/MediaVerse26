import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: gridRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    // ----------------------------------------------------------------
    // INLINE TITLE EXTRACTOR (URL-safe)
    // ----------------------------------------------------------------
    function cleanTitle(path) {
        if (!path) return "";

        // Remove file:/// prefix
        let clean = path.replace(/^file:\/{3}/, "");

        // Decode URL encoding
        clean = decodeURIComponent(clean);

        // Extract filename
        let name = clean.split("/").pop().split("\\").pop();

        // Remove extension
        return name.replace(/\.[^/.]+$/, "");
    }

    signal v2OpenDetail(var movie)
    signal v2PlayMovie(string videoPath)

    property var externalImageList: []
    property int currentPage: 0
    property int itemsPerPage: 12
    property bool showLabels: true
    property string sortMode: "oldest"

    property var sortedList: {
        if (!externalImageList) return [];
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

        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text {
                anchors.centerIn: parent; text: "❮"; color: "white"; font.pixelSize: 45
                opacity: currentPage > 0 ? 1.0 : 0.1
            }
            MouseArea { anchors.fill: parent; onClicked: if (currentPage > 0) currentPage-- }
        }

        Item {
            id: gridContainer
            width: parent.width - 160; height: parent.height; clip: true

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

                            // POSTER
                            Item {
                                width: parent.width
                                height: gridRoot.posterHeight

                                Rectangle {
                                    id: posterRect
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#111"
                                    border.color: modelData.sourceType === "RAW" ? "#555" : "white"
                                    border.width: 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.filePath || ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }

                                    // ⭐ YEAR BADGE (restored)
                                    Rectangle {
                                        id: yearBadge
                                        visible: modelData.year && modelData.year !== 0
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: 6
                                        anchors.rightMargin: 6
                                        radius: 4
                                        color: "#CC000000"   // translucent black
                                        border.color: "white"
                                        border.width: 1
                                        width: 38
                                        height: 20
                                        z: 10

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.year
                                            color: "white"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
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
                                            let cleanPath = decodeURIComponent(rawPath.replace(/^(file:\/{3})/, ""));
                                            cleanPath = cleanPath.replace(/\//g, "\\");
                                            console.log("🚀 Playing Video:", cleanPath);
                                            playbackRouter.playVideo(cleanPath, false)
                                            gridRoot.v2PlayMovie(cleanPath);
                                        }
                                    }
                                }
                            }

                            // TITLE
                            Text {
                                width: parent.width
                                text: cleanTitle(modelData.filePath)
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