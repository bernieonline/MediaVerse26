import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick
import QtQuick.Controls
//version 1.0.1 border edge added to left panel
//1.o.2 sliding video panel added
//1.0.3 centre button moved to toolbar
//1.0.4 final adjustments made before applying styling to panels
//1.0.5 Glow effects added to main window

ApplicationWindow {
    id: window
    visibility: ApplicationWindow.FullScreen
    title: "MediaVerse"

    Material.theme: Material.Dark
    Material.accent: Material.Yellow

    // The colors used in this file are standard hex color codes.
    // If your editor is highlighting them as invalid, it might be a linter configuration issue.

    Rectangle { //sets theme colour
        id: background
        anchors.fill: parent
        color: "#1e1e1e"
    }

    GlowStyling {
        target: border
    }

    Rectangle { //subdued glow
        id: border
        anchors.fill: parent
        anchors.margins: 10
        radius: 25
        color: "transparent"
        border.color: "yellow"
        border.width: 1
        z: 2
    }

    GlowStyling {
        target: sidePanel
    }

    Rectangle { //sliding panel on left
        id: sidePanel
        width: 300
        height: parent.height * 2 / 3
        anchors.verticalCenter: parent.verticalCenter
        x: -width
        z: 2
        color: "transparent"
        radius: 25
        border.color: "yellow"
        border.width: 1

        Behavior on x {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Rectangle {//background to sliding panel
            // This is the background
            anchors.fill: parent
            anchors.margins: 5
            color: "#1e1e1e"
            radius: 20
            border.width: 0

            Label {//refers to combobox
                id: chooseLocationLabel
                text: "Choose a Location"
                color: "white"
                font.pixelSize: 20
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10
                padding: 10
                background: Rectangle {
                    color: "transparent"
                    border.color: "yellow"
                    border.width: 1
                    radius: 5
                }
            }

            ComboBox {//sets up combobox for receiving data from .py
                id: categoryCombo
                anchors.top: chooseLocationLabel.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 20
                
                width: parent.width
                model: myLibraryModel
                textRole: "name"

                onModelChanged: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].name === "JRiver Library") {
                            currentIndex = i;
                            categoryCombo.activated(i)
                            break;
                        }
                    }
                }

                onActivated: function(index) {
                    if (model[index]) {
                        let selectedPath = model[index].path
                        console.log("Selected path:", selectedPath)
                        fileSystemManager.update_folders(selectedPath)
                    }
                }

                background: Rectangle {
                    color: "transparent"
                    border.color: "yellow"
                    border.width: 1
                    radius: 5
                }

                contentItem: Text {
                    text: parent.displayText
                    color: "white"
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                    elide: Text.ElideRight
                }

                indicator: Text {
                    text: "▼"
                    color: "yellow"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                }
            } // combobox

            ListView { //hopefully stores the folders to be displayed on sidepanel
                id: fileView
                anchors.top: categoryCombo.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 20
                anchors.bottomMargin: 80
                clip: true
                model: fileSystemManager.folders // Ready to accept a model from Python
                property int currentIndex: -1
                delegate: Item {
                    width: fileView.width
                    height: 40

                    Rectangle {
                        id: background
                        anchors.fill: parent
                        color: fileView.currentIndex === index ? "#555555" : "transparent" //dark grey colour
                        radius: 5
                    }

                    Image {
                        id: folderIcon
                        source: "file:///D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new/images/icons/icons8-movie-liquid-glass-color/icons8-movie-32.png"
                        width: 24 // Adjust size as needed
                        height: 24 // Adjust size as needed
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: folderNameText
                        text: modelData.folderName // Display folder name only
                        color: "white"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: folderIcon.right
                        anchors.leftMargin: 10 // Adjust margin between icon and text
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            print("i just clicked an image folder")
                            fileView.currentIndex = index
                            var folderPath = modelData.folderPath // Get full pathname when folder is clicked
                            console.log("Clicked folder:", folderPath)
                            fileSystemManager.list_image_files_in_folder(folderPath)
                            sidePanel.x = -sidePanel.width
                            // Do something with the folder path
                        }
                    }
                }
            }

            Timer {//used by sliding objects
                id: scrollTimer
                interval: 50
                repeat: true
                property int scrollStep: 0
                onTriggered: {
                    fileView.contentY += scrollStep;
                }
            }

            Row {//used for top row of buttons and icons
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 15
                spacing: 10

                Loader {//below is a Component being created which is a button in this case, it has a number of features built in
                //Loader takes a copy of it and modifies and runs it
                //its a way of creating bespoke buttons that are usable within a single file. To use it throughout the project you would create it in its own qml file
                    sourceComponent: scrollButtonComponent
                    onLoaded: {
                        item.text = "▲";
                        item.scrollAmount = -10;
                    }
                }
                Loader {
                    sourceComponent: scrollButtonComponent
                    onLoaded: {
                        item.text = "▼";
                        item.scrollAmount = 10;
                    }
                }
            }

            Component {// This creates a bespoke component, in this case a special button we use for scrolling, it is the modifies and used by Loader above
                id: scrollButtonComponent
                Rectangle {
                    property string text
                    property int scrollAmount

                    width: 80
                    height: 50
                    color: "#333"
                    radius: 8
                    border.color: "yellow"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: parent.text
                        color: "white"
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            scrollTimer.scrollStep = scrollAmount;
                            scrollTimer.start();
                        }
                        onExited: {
                            scrollTimer.stop();
                        }
                    }
                }
            }
        }
    }

    GlowStyling {
        target: videoPanel
    }

    Rectangle {
        id: videoPanel
        height: parent.height * 0.25
        width: height * 16 / 9
        anchors.horizontalCenter: parent.horizontalCenter
        y: isVideoPanelVisible ? parent.height - height : parent.height
        z: 2

        color: "transparent"
        radius: 25
        border.color: "yellow"
        border.width: 1

        Behavior on y {
            NumberAnimation { duration: 1500; easing.type: Easing.OutCubic }
        }

        Rectangle {
            // This is the background
            anchors.fill: parent
            anchors.margins: 5
            color: "#1e1e1e"
            radius: 20
            border.width: 0

            // In the future, the video player component will go here
            Text {
                anchors.centerIn: parent
                text: "Mini Video Player"
                color: "white"
                font.pixelSize: 24
            }
        }
    }

    property bool isVideoPanelVisible: false

    Row {
        id: buttonRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80
        spacing: 40

        Button {
            id: menuButton
            text: "Menu"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                sidePanel.x = (sidePanel.x === 0) ? -sidePanel.width : 0
                if (sidePanel.x === 0 && categoryCombo.currentIndex !== -1) {
                    categoryCombo.activated(categoryCombo.currentIndex)
                }
                contentLoader.source = ""
            }
        }

        Button {
            id: videoButton
            text: "Video"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                isVideoPanelVisible = !isVideoPanelVisible
                contentLoader.source = ""
            }
        }

        Button {
            id: carouselButton
            text: "Carousel"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                console.log("Carousel button clicked")
                contentLoader.source = "" 
            }
        }

        Button {
            id: gridViewButton
            text: "Grid View"
            width: 320
            height: 120
            background: Rectangle {
                implicitWidth: 320
                implicitHeight: 120
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: {
                console.log("Grid View button clicked")
                contentLoader.source = "ImageGridView.qml"
            }
        }

        Button {
            text: "Close"
            width: 320
            height: 120

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8
                color: "#333"
                border.color: "yellow"
                border.width: 1
            }
            onClicked: Qt.quit()
        }
    }

    Rectangle {
    id: contentContainer
    anchors.top: buttonRow.bottom
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 100

    radius: 25
    color: "transparent"
    border.color: "#2566c2"
    border.width: 1

    // Loader for dynamically loading content like the GridView
    Loader {
        id: contentLoader
        anchors.fill: parent
    }
}
}