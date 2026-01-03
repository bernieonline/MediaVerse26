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

    // -------------------------------
    // HEIGHT-DRIVEN GEOMETRY ENGINE
    // -------------------------------

    readonly property real labelHeight: showLabels ? 45 : 0
    readonly property real rowSpacing: 20

    // Each row gets half the available height
    readonly property real maxHeightPerRow: (gridRoot.height / 2) - rowSpacing

    // Poster height is limited by available vertical space
    readonly property real posterHeight: Math.max(50, maxHeightPerRow - labelHeight)

    // Width is derived from height (aspect ratio 2:3)
    readonly property real posterWidth: posterHeight / 1.5

    // -------------------------------
    // PAGE SLICE
    // -------------------------------
    property var pageItems: {
        if (!externalImageList || externalImageList.length === 0) return [];
        let start = currentPage * itemsPerPage;
        return externalImageList.slice(start, start + itemsPerPage);
    }

    // -------------------------------
    // MAIN LAYOUT: LEFT ARROW | GRID | RIGHT ARROW
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
                columnSpacing: 15
                rowSpacing: gridRoot.rowSpacing

                Repeater {
                    model: gridRoot.pageItems

                    delegate: Item {
                        width: gridRoot.posterWidth
                        height: gridRoot.posterHeight + gridRoot.labelHeight

                        // 🔍 DEBUG
                        Component.onCompleted: {
                            console.log("MODEL ENTRY:", JSON.stringify(modelData))
                        }

                        // ------------------------------------
                        // TITLE EXTRACTION FROM FILEPATH
                        // ------------------------------------
                        readonly property string titleFromPath: {
                            if (!modelData.filePath) return "Unknown"

                            // Remove file:/// prefix
                            let url = modelData.filePath.replace("file:///", "")

                            // Split into path segments
                            let parts = url.split(/[\\/]/)
                            let file = parts[parts.length - 1]

                            // Remove extension
                            file = file.replace(/\.[^/.]+$/, "")

                            // Decode %20 etc....
                            try { file = decodeURIComponent(file) } catch(e) {}

                            return file
                        }

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
                                text: titleFromPath
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