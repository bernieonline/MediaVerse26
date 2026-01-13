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
        width: parent.width; height: 60
        color: "#121212"; z: 1000 // Ensure it stays on top
        
        Text {
            anchors.left: parent.left; anchors.leftMargin: 85
            anchors.verticalCenter: parent.verticalCenter
            text: "TRIAGE: " + getFolderName(targetPath).toUpperCase()
            color: "gold"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 1
        }
        
        Button {
            id: backBtn
            anchors.right: parent.right; anchors.rightMargin: 100
            anchors.verticalCenter: parent.verticalCenter
            text: "BACK TO FOLDERS"
            onClicked: freestyleRoot.activeMode = "PANELS"
            
            background: Rectangle { 
                implicitWidth: 140; implicitHeight: 30
                color: backBtn.hovered ? "#33D4AF37" : "transparent"
                border.color: "gold"; radius: 4 
            }
            contentItem: Text { 
                text: parent.text; color: "gold"; font.pixelSize: 10; font.bold: true
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // --- NAVIGATION CONTROLS (Defined first to provide anchor points) ---
    Rectangle {
        id: navLeft
        anchors.left: parent.left; width: 65; height: parent.height; z: 800
        color: leftMA.pressed ? "#44D4AF37" : "#080808"
        border.color: "#33D4AF37"; border.width: 1
        Text { text: "❮"; color: "gold"; font.pixelSize: 45; anchors.centerIn: parent }
        MouseArea {
            id: leftMA; anchors.fill: parent
            onClicked: {
                var step = carousel.width + carousel.spacing;
                carousel.contentX = Math.max(0, carousel.contentX - step);
            }
        }
    }

    Rectangle {
        id: navRight
        anchors.right: parent.right; width: 65; height: parent.height; z: 800
        color: rightMA.pressed ? "#44D4AF37" : "#080808"
        border.color: "#33D4AF37"; border.width: 1
        Text { text: "❯"; color: "gold"; font.pixelSize: 45; anchors.centerIn: parent }
        MouseArea {
            id: rightMA; anchors.fill: parent
            onClicked: {
                var step = carousel.width + carousel.spacing;
                var maxScroll = carousel.contentWidth - carousel.width;
                carousel.contentX = Math.min(maxScroll, carousel.contentX + step);
            }
        }
    }

    // --- THE CAROUSEL (Now anchored strictly BETWEEN the buttons) ---
    ListView {
        id: carousel
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: navLeft.right
        anchors.right: navRight.left
        anchors.topMargin: 15
        anchors.bottomMargin: 15
        
        orientation: ListView.Horizontal
        spacing: 15
        model: triageRoot.videoData
        clip: true // This property now strictly shears pixels at the navLeft/navRight boundaries
        
        snapMode: ListView.NoSnap 
        boundsBehavior: Flickable.StopAtBounds
        
        Behavior on contentX { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        delegate: Rectangle {
            // Width is now a clean division of the gap between the buttons
            width: Math.floor((carousel.width - (carousel.spacing * 6)) / 7)
            height: carousel.height - 10
            anchors.verticalCenter: parent.verticalCenter
            color: "#151515"; radius: 6
            border.color: modelData.isStandard ? "#33D4AF37" : "#55FF3333"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 10; spacing: 8

                Rectangle {
                    width: parent.width; height: parent.height * 0.52
                    color: "black"; radius: 4; clip: true
                    Image {
                        anchors.fill: parent; anchors.margins: 2
                        fillMode: Image.PreserveAspectFit; asynchronous: true
                        source: modelData.thumb || ""
                        onStatusChanged: if (status === Image.Error) source = "assets/mediaverse2.png"
                    }
                }

                Column {
                    width: parent.width; spacing: 8
                    
                    Text { 
                        text: modelData.filename 
                        color: "white"; font.bold: true; font.pixelSize: 10
                        width: parent.width; horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WrapAnywhere
                    }

                    Flow {
                        width: parent.width; spacing: 6
                        leftPadding: Math.max(0, (parent.width - 102) / 2)
                        
                        Rectangle {
                            width: 48; height: 18; color: "gold"; radius: 3
                            Text { text: modelData.size; color: "black"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 9 }
                        }
                        Rectangle {
                            width: 48; height: 18; color: "#222"; radius: 3; border.color: "gold"
                            Text { text: modelData.extension; color: "gold"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 9 }
                        }
                    }

                    Text { 
                        text: modelData.folder; color: "#444"; font.pixelSize: 8; width: parent.width
                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle
                    }
                }
            }
        }
    }
}