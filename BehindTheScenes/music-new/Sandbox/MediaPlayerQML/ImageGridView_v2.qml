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
    property string sortMode: "oldest"

    // Component from your MetadataTools.qml
    MetadataTools { id: metadata }

    // This triggers a re-sort whenever sortMode or externalImageList changes
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

    // ============================================================
    // MAIN LAYOUT (Moved up so it's behind the drawer)
    // ============================================================
    Row {
        anchors.fill: parent
        spacing: 0
        z: 1 // Base layer

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
                            Rectangle {
                                width: parent.width; height: gridRoot.posterHeight
                                radius: 8; color: "#111"; border.color: "white"; border.width: 1; clip: true
                                Image {
                                    anchors.fill: parent
                                    source: modelData.filePath || ""
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Text {
                                width: parent.width
                                text: metadata.extractCleanTitle(modelData.filePath)
                                color: "white"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
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

    // ============================================================
    // SLIDE-UP SORT DRAWER (Placed LAST and with Z: 100)
    // ============================================================
    Rectangle {
        id: sortDrawer
        z: 100 // FORCES IT TO BE ON TOP OF THE GRID
        width: 110
        height: drawerOpen ? 160 : 30 // Slightly taller for easier clicking

        anchors.bottom: gridRoot.bottom
        anchors.right: gridRoot.right
        anchors.bottomMargin: 16
        anchors.rightMargin: 16

        visible: sortedList && sortedList.length > 0
        color: drawerOpen ? "#222222" : "#33000000" // Subtle tint when closed
        border.color: drawerOpen ? "white" : "transparent"
        border.width: 1
        radius: 8

        property bool drawerOpen: false

        // Animation for smoothness
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        MouseArea {
            id: toggleArea
            anchors.fill: parent // Fill entire drawer area
            // We only want to toggle if the drawer is closed OR if clicking the top bar
            onClicked: {
                sortDrawer.drawerOpen = !sortDrawer.drawerOpen
            }

            // HAMBURGER ICON
            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 10
                anchors.topMargin: 10
                spacing: 3

                Rectangle { width: 18; height: 2; radius: 1; color: "white" }
                Rectangle { width: 18; height: 2; radius: 1; color: "white" }
                Rectangle { width: 18; height: 2; radius: 1; color: "white" }
            }
        }

        // STACKED OPTIONS
        Column {
            anchors.top: parent.top
            anchors.topMargin: 40 // Push down below hamburger
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 12
            visible: sortDrawer.drawerOpen

            // Helper component for sort buttons
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
                    font.pixelSize: 12
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