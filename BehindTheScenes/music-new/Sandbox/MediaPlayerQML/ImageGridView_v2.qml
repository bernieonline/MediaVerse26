import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: gridRoot
    width: parent ? parent.width : 1000
    height: parent ? parent.height : 800
    color: "transparent"

    // ----------------------------------------------------------------
    // 1. PROPERTIES & LOGIC
    // ----------------------------------------------------------------
    property var externalImageList: []
    property int currentPage: 0
    property int itemsPerPage: 12
    property bool showLabels: true
    property string sortMode: "oldest"

    MetadataTools { id: metadata }

    // Re-sorts whenever sortMode or list changes
    property var sortedList: metadata.sortList(externalImageList, sortMode)

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

    // ----------------------------------------------------------------
    // 2. MAIN LAYOUT
    // ----------------------------------------------------------------
    Row {
        anchors.fill: parent
        spacing: 0
        z: 1

        // LEFT NAV
        Rectangle {
            width: 80; height: parent.height; color: "transparent"
            Text {
                anchors.centerIn: parent
                text: "❮"; color: "white"; font.pixelSize: 45
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

                            // POSTER WRAPPER (Allows Badge to float over clipped Image)
                            Item {
                                width: parent.width
                                height: gridRoot.posterHeight

                                Rectangle {
                                    id: posterRect
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#111"
                                    border.color: "white"
                                    border.width: 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.filePath || ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                // YEAR BADGE
                                Rectangle {
                                    id: yearBadge
                                    width: 38
                                    height: 20
                                    radius: 4
                                    color: "#CC000000" // 80% opacity black
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 6
                                    anchors.rightMargin: 6
                                    z: 10 // Force visibility over the image

                                    // Safely extract year
                                    property int yearVal: metadata.extractYear(modelData.filePath)
                                    visible: yearVal !== 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.yearVal
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
            width: 80; height: parent.height; color: "transparent"
            Text {
                anchors.centerIn: parent
                text: "❯"; color: "white"; font.pixelSize: 45
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

    // ----------------------------------------------------------------
    // 3. SORT DRAWER
    // ----------------------------------------------------------------
    Rectangle {
        id: sortDrawer
        z: 100
        width: 110
        height: drawerOpen ? 160 : 35
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 16
        anchors.rightMargin: 16
        color: drawerOpen ? "#222" : "#44000000"
        border.color: drawerOpen ? "white" : "transparent"
        border.width: 1
        radius: 8
        property bool drawerOpen: false

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        MouseArea {
            anchors.fill: parent
            onClicked: sortDrawer.drawerOpen = !sortDrawer.drawerOpen
            
            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 10
                anchors.topMargin: 12
                spacing: 3
                Rectangle { width: 16; height: 2; color: "white" }
                Rectangle { width: 16; height: 2; color: "white" }
                Rectangle { width: 16; height: 2; color: "white" }
            }
        }

        Column {
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 12
            visible: sortDrawer.drawerOpen

            Repeater {
                model: [
                    { name: "Oldest First", mode: "oldest" },
                    { name: "Recent First", mode: "recent" },
                    { name: "Recently Added", mode: "added" },
                    { name: "Alphabetical", mode: "alpha" }
                ]
                delegate: Text {
                    text: modelData.name
                    color: gridRoot.sortMode === modelData.mode ? "yellow" : "white"
                    font.pixelSize: 11
                    font.bold: gridRoot.sortMode === modelData.mode
                    width: parent.width
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gridRoot.sortMode = modelData.mode
                            sortDrawer.drawerOpen = false
                        }
                    }
                }
            }
        }
    }
}