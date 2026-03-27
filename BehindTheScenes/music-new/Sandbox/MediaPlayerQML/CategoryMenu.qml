import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: menuRoot
    anchors.fill: parent

    // Signal to send the category back to the main framework
    signal categorySelected(string categoryKey)
    signal backRequested

    // Back button — top-left corner
    Rectangle {
        id: backBtn
        width: 46; height: 46
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
        z: 10
        color: backMa.containsMouse ? "#2a2a2a" : "transparent"
        radius: 8
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "❮"
            font.pixelSize: 26
            color: backMa.containsMouse ? "white" : "#888888"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: backMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: menuRoot.backRequested()
        }
    }

    // Full-panel background image — dimmed so category cards remain primary focus
    Image {
        anchors.fill: parent
        source: "file:///" + _paths["splash"] + "/dvds.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    // Dark veil to subdue the background without hiding it
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
    }

    // The Grid Container (Occupies 2/3 width of a 4k screen)
    GridView {
        id: grid
        width: parent.width * 0.66
        height: parent.height * 0.8
        anchors.centerIn: parent
        
        cellWidth: width / 3
        cellHeight: height / 2
        interactive: false // Keep it a static 2x3 grid

        model: [
            { key: "Actors",   label: "ACTORS" },
            { key: "Decade",   label: "DECADES" },
            { key: "Director", label: "DIRECTORS" },
            { key: "Series",   label: "SERIES" },
            { key: "Genre",    label: "GENRE" },
            { key: "Keywords", label: "CURATIONS" } // "Keywords" data, but "Curations" label
        ]

        delegate: Item {
            width: grid.cellWidth - 30
            height: grid.cellHeight - 30

            Image {
                id: cardImage
                anchors.fill: parent
                // Pulls from project_paths.py "collection_bg"
                // Use the variable from your project_paths.py, but wrapped for QML
                source: "file:///" + _paths["collection_bg"]
                //source: Qt.resolvedUrl(_paths["collection_bg"])
                fillMode: Image.PreserveAspectCrop
                //source: "file:///" + _paths.collection_bg
                //fillMode: Image.PreserveAspectCrop
                layer.enabled: true

                // Overlay Rectangle for the 'Movie Screen' effect
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "gold"
                    border.width: ma.containsMouse ? 4 : 1
                    radius: 10
                }

                // THE LABEL (25% down from top edge)
                Text {
                    text: modelData.label
                    color: "white"
                    font.pixelSize: parent.width * 0.09
                    font.bold: true
                    font.letterSpacing: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: parent.height * 0.25
                    
                    // High-end theatrical text styling
                    style: Text.Outline
                    styleColor: "black"
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // 1. Identify which card was clicked
                        console.log("-----------------------------------------")
                        console.log("MENU TRIGGER: User selected " + modelData.label)
                        
                        // 2. See the EXACT string being sent to the backend
                        // This is the "Key" that Python must match (e.g., "Decade")
                        console.log("SENT KEY: '" + modelData.key + "'")
                        console.log("-----------------------------------------")

                        // 3. Emit the original signal
                        menuRoot.categorySelected(modelData.key)
                    }
                }

                // Animation on hover
                scale: ma.containsMouse ? 1.04 : 1.0
                Behavior on scale { NumberAnimation { duration: 150 } }
            }
        }
    }
}