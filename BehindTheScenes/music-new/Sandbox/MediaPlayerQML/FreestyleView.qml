import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: triageRoot
    anchors.fill: parent
    color: "#080808"

    property string targetPath: ""
    property var videoData: []

    function getFolderName(path) {
        if (!path) return "";
        var parts = path.split(/[/\\]/);
        return parts.filter(function(p) { return p.length > 0; }).pop() || "";
    }

    function refreshData() {
        if (typeof driveManager !== "undefined" && driveManager) {
            videoData = driveManager.get_video_triage_data(targetPath);
            console.log("FreestyleView: Loaded " + videoData.length + " items.");
        }
    }

    onTargetPathChanged: refreshData()
    Component.onCompleted: refreshData()

    // --- TOP BAR ---
    Rectangle {
        id: topBar
        width: parent.width; height: 60; color: "#121212"; z: 500
        Text {
            anchors.left: parent.left; anchors.leftMargin: 80
            anchors.verticalCenter: parent.verticalCenter
            text: "TRIAGE: " + getFolderName(targetPath).toUpperCase()
            color: "gold"; font.pixelSize: 14; font.bold: true
        }
        Button {
            anchors.right: parent.right; anchors.rightMargin: 100
            anchors.verticalCenter: parent.verticalCenter
            text: "BACK TO FOLDERS"
            onClicked: freestyleRoot.activeMode = "PANELS"
            background: Rectangle { implicitWidth: 140; implicitHeight: 30; color: "transparent"; border.color: "gold"; radius: 4 }
            contentItem: Text { text: parent.text; color: "gold"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignHCenter }
        }
    }

    // --- THE CAROUSEL ---
    ListView {
        id: carousel
        anchors.fill: parent
        anchors.topMargin: 80
        anchors.bottomMargin: 20
        leftMargin: 70; rightMargin: 70 
        orientation: ListView.Horizontal
        spacing: 15
        model: triageRoot.videoData
        clip: true
        
        // Disable internal snapping to allow manual smooth scrolling
        snapMode: ListView.NoSnap 
        highlightRangeMode: ListView.NoHighlightRange
        
        // Essential for smooth movement
        Behavior on contentX { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        delegate: Rectangle {
            // Force the width calculation
            width: (carousel.width - 140 - (15 * 6)) / 7
            height: carousel.height - 20
            color: "#151515"; radius: 6
            border.color: modelData.isStandard ? "#33D4AF37" : "#55FF3333"

            Column {
                anchors.fill: parent; anchors.margins: 10; spacing: 8

                Rectangle {
                    width: parent.width; height: parent.height * 0.50
                    color: "black"; radius: 4; clip: true
                    Image {
                        anchors.fill: parent; anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        source: modelData.thumb || ""
                    }
                }

                Text { 
                    text: modelData.filename; color: "white"; font.bold: true; font.pixelSize: 10
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WrapAnywhere
                }

                Flow {
                    width: parent.width; spacing: 6
                    leftPadding: (parent.width - 102) / 2
                    Rectangle {
                        width: 48; height: 18; color: "gold"; radius: 3
                        Text { text: modelData.size; color: "black"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 9 }
                    }
                    Rectangle {
                        width: 48; height: 18; color: "#222"; radius: 3; border.color: "gold"
                        Text { text: modelData.filename.split('.').pop().toUpperCase(); color: "gold"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 9 }
                    }
                }
            }
        }
    }

    // --- NAVIGATION BUTTONS (The Fixed Scrolling Logic) ---
    Rectangle {
        anchors.left: parent.left; width: 65; height: parent.height; z: 600
        color: leftMA.pressed ? "#44D4AF37" : "#111"; border.color: "#33D4AF37"
        Text { text: "❮"; color: "gold"; font.pixelSize: 45; anchors.centerIn: parent }
        MouseArea {
            id: leftMA; anchors.fill: parent
            onClicked: {
                // Move back exactly 7 items' worth of width
                var step = (carousel.width - 140) + carousel.spacing;
                carousel.contentX = Math.max(-carousel.leftMargin, carousel.contentX - step);
            }
        }
    }

    Rectangle {
        anchors.right: parent.right; width: 65; height: parent.height; z: 600
        color: rightMA.pressed ? "#44D4AF37" : "#111"; border.color: "#33D4AF37"
        Text { text: "❯"; color: "gold"; font.pixelSize: 45; anchors.centerIn: parent }
        MouseArea {
            id: rightMA; anchors.fill: parent
            onClicked: {
                // Move forward exactly 7 items' worth of width
                var step = (carousel.width - 140) + carousel.spacing;
                var maxScroll = carousel.contentWidth - carousel.width + carousel.rightMargin;
                carousel.contentX = Math.min(maxScroll, carousel.contentX + step);
            }
        }
    }
}