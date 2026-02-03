import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5

Rectangle {
    id: detailViewRoot
    anchors.fill: parent
    color: "transparent"

    property string imagePath: ""
    property var xmlDetails
    property bool tenFootMode: false

    signal launchVideoRequested(string cachePath)

    Component.onCompleted: {
        if (xmlDetails && imagePath) {
            xmlDetails.loadXML(imagePath)
        }
        if (imagePath && imagePath.length > 0) {
            xmlController.loadXML(imagePath)
            var cats = xmlController.getCategories()
            if (cats.length > 0) {
                tabBar.currentIndex = 0
                xmlController.requestCategoryContent(cats[0])
            }
        }
    }

    Connections {
        target: xmlController
        function onCategoryContentUpdated(category, lines) {
            xmlTextArea.text = lines.join("\n\n")
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 50
        spacing: 50

        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: leftPanel.height * 2 / 3
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            radius: 15
            color: "transparent"

            Image {
                id: posterImage
                anchors.fill: parent
                source: detailViewRoot.imagePath
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                property bool doubleClickActive: false
                property var singleClickTimer: null

                onClicked: {
                    if (singleClickTimer) singleClickTimer.stop()
                    singleClickTimer = Qt.createQmlObject(
                        'import QtQuick 2.15; Timer { interval: 250; repeat: false }',
                        detailViewRoot
                    )
                    singleClickTimer.triggered.connect(function() {
                        if (!doubleClickActive) {
                            console.log("✅ Single click confirmed in Detail_View")
                            // optional: could emit imageClicked here if needed
                        }
                        doubleClickActive = false
                    })
                    singleClickTimer.start()
                }

                onDoubleClicked: {
                    console.log("🎯 Double‑clicked in Detail_View:", detailViewRoot.imagePath)
                    doubleClickActive = true
                    if (singleClickTimer) singleClickTimer.stop()

                    
                    
                    detailViewRoot.launchVideoRequested(detailViewRoot.imagePath)
                    //playbackRouter.playVideo(rawPath, isMaster)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                Repeater {
                    model: xmlController.getCategories()
                    TabButton {
                        text: modelData
                        onClicked: xmlController.requestCategoryContent(modelData)
                    }
                }
            }

            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.fillHeight: true

                ScrollView {
                    id: scrollArea
                    anchors.fill: parent
                    clip: true

                    LayoutMirroring.enabled: false

                    TextArea {
                        id: xmlTextArea
                        width: scrollArea.width
                        readOnly: true
                        wrapMode: Text.Wrap
                        text: "No details available"
                        background: null
                        color: "white"
                        font.pixelSize: detailViewRoot.tenFootMode ? 48 : 16
                        font.bold: true
                        padding: 20
                        rightPadding: vbar.width + 10
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AlwaysOn
                        interactive: true
                        width: detailViewRoot.tenFootMode ? 30 : 14
                        anchors.right: scrollArea.right
                        anchors.top: scrollArea.top
                        anchors.bottom: scrollArea.bottom
                        z: 10
                        background: Rectangle { color: "#262626"; radius: 6 }
                        contentItem: Rectangle {
                            implicitWidth: vbar.width
                            implicitHeight: 100
                            radius: 6
                            color: "#3a3a3a"
                        }
                    }
                }
            }
        }
    }
}