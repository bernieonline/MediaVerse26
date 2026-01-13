import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: triageRoot
    anchors.fill: parent
    color: "#080808"

    property string targetPath: ""
    property var videoData: []

    function refreshData() {
        if (typeof driveManager !== "undefined" && driveManager) {
            videoData = driveManager.get_video_triage_data(targetPath);
        }
    }

    onTargetPathChanged: refreshData()
    Component.onCompleted: refreshData()

    // --- TOP BAR ---
    Rectangle {
        id: topBar
        width: parent.width; height: 60
        color: "#121212"; z: 210
        
        Text {
            anchors.left: parent.left; anchors.leftMargin: 30
            anchors.verticalCenter: parent.verticalCenter
            text: "TECHNICAL TRIAGE • " + targetPath.toUpperCase()
            color: "gold"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1
        }
        
        Button {
            anchors.right: parent.right; anchors.rightMargin: 30
            anchors.verticalCenter: parent.verticalCenter
            text: "BACK TO FOLDERS"
            onClicked: freestyleRoot.activeMode = "PANELS"
            background: Rectangle { color: "transparent"; border.color: "gold"; radius: 2 }
            contentItem: Text { text: parent.text; color: "gold"; font.pixelSize: 10; font.bold: true }
        }
    }

    // --- THE CAROUSEL ---
    ListView {
        id: carousel
        anchors.fill: parent
        anchors.topMargin: 60
        // Padding for the large side-buttons
        leftMargin: 60; rightMargin: 60 
        orientation: ListView.Horizontal
        spacing: 10
        model: triageRoot.videoData
        clip: true
        snapMode: ListView.SnapToItem
        highlightFollowsCurrentItem: true
        
        // FIX SCROLLING: Explicitly allow horizontal only
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        
        // MATH: (Total Width - Side Margins - Spacing Gaps) / 7
        delegate: Rectangle {
            width: (carousel.width - 120 - (carousel.spacing * 6)) / 7
            height: carousel.height - 40
            anchors.verticalCenter: parent.verticalCenter
            color: "#151515"; radius: 4
            border.color: modelData.isStandard ? "#33D4AF37" : "#66FF3333"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 8; spacing: 8

                // POSTER
                Rectangle {
                    width: parent.width; height: parent.height * 0.50
                    color: "black"; radius: 3; clip: true
                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        source: modelData.thumb || "assets/mediaverse2.png"
                    }
                }

                // TEXT AREA
                Column {
                    width: parent.width; spacing: 8
                    
                    Text { 
                        text: modelData.filename
                        color: "white"; font.bold: true; font.pixelSize: 9 
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter // CENTRALIZED
                        elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WrapAnywhere
                    }

                    // DATA PILLS (Centralized)
                    Flow {
                        width: parent.width
                        spacing: 4
                        // Use an Item wrapper to center the Flow content
                        leftPadding: (parent.width - 98) / 2 // Rough center for 2 badges
                        
                        Rectangle {
                            width: 45; height: 16; color: "gold"; radius: 2
                            Text { text: modelData.size; color: "black"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 8 }
                        }
                        Rectangle {
                            width: 45; height: 16; color: "#222"; radius: 2; border.color: "gold"
                            Text { text: modelData.filename.split('.').pop().toUpperCase(); color: "gold"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 8 }
                        }
                    }

                    Text { 
                        text: modelData.folder
                        color: "#444"; font.pixelSize: 7; width: parent.width
                        horizontalAlignment: Text.AlignHCenter // CENTRALIZED
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }

    // --- LARGE NAVIGATION BUTTONS ---
    // Left Button
    Rectangle {
        anchors.left: parent.left; width: 60; height: parent.height; z: 300
        color: leftMA.pressed ? "#22D4AF37" : "#111"
        border.color: "#33D4AF37"; border.width: 1
        
        Text { text: "❮"; color: "gold"; font.pixelSize: 40; anchors.centerIn: parent }
        
        MouseArea {
            id: leftMA
            anchors.fill: parent
            onClicked: carousel.contentX = Math.max(0, carousel.contentX - carousel.width + 120)
        }
    }

    // Right Button
    Rectangle {
        anchors.right: parent.right; width: 60; height: parent.height; z: 300
        color: rightMA.pressed ? "#22D4AF37" : "#111"
        border.color: "#33D4AF37"; border.width: 1

        Text { text: "❯"; color: "gold"; font.pixelSize: 40; anchors.centerIn: parent }

        MouseArea {
            id: rightMA
            anchors.fill: parent
            onClicked: carousel.contentX = Math.min(carousel.contentWidth - carousel.width, carousel.contentX + carousel.width - 120)
        }
    }
}