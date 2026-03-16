import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15



Column {
    id: buttonColumn
    width: parent.width
    spacing: 0
    z: 9999
    signal architectClicked()
    signal snatcherClicked()


    Row {
        id: buttonRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        // --- 1. FREESTYLE ---
        Rectangle {
            id: freestyleBtn
            width: 130; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Text {
                anchors.centerIn: parent
                text: "🦅"; font.pixelSize: 24; opacity: 0.25; z: 1
            }
            Column {
                anchors.centerIn: parent; spacing: 2; z: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Freestyle"
                    color: "gold"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: freestyleBtn.opacity = 1.0
                onExited:  freestyleBtn.opacity = 0.85
                onPressed: freestyleBtn.opacity = 0.7
                onReleased: freestyleBtn.opacity = 1.0
                onClicked: {
                    if (typeof splash !== "undefined") splash.deactivate()
                    contentLoader.setSource("Freestyle.qml")
                }
            }
        }

        // --- 2. ARCHITECT CREATOR ---
        Rectangle {
            id: builderBtn
            width: 130; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Architect"
                    color: "#00F2FF"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Creator"
                    color: "#cccccc"; font.pixelSize: 13
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: builderBtn.opacity = 1.0
                onExited:  builderBtn.opacity = 0.85
                onPressed: builderBtn.opacity = 0.7
                onReleased: builderBtn.opacity = 1.0
                onClicked: {
                    if (typeof splash !== "undefined") splash.deactivate()
                    architectHUD.visible = true
                }
            }
        }

        // --- 3. ARCHITECT COLLECTIONS ---
        Rectangle {
            id: archCollBtn
            width: 130; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Architect"
                    color: "gold"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Collections"
                    color: "#cccccc"; font.pixelSize: 13
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: archCollBtn.opacity = 1.0
                onExited:  archCollBtn.opacity = 0.85
                onPressed: archCollBtn.opacity = 0.7
                onReleased: archCollBtn.opacity = 1.0
                onClicked: {
                    if (typeof splash !== "undefined") splash.deactivate()
                    console.log("📚 Launching Architect Gallery...")
                    buttonColumn.architectClicked()
                    contentLoader.setSource("ArchitectGallery.qml")
                    if (typeof utilitySidebar !== "undefined") utilitySidebar.isOpen = false
                    if (typeof architectHUD !== "undefined") architectHUD.visible = false
                }
            }
        }

        // --- 4. SNATCHER ---
        Rectangle {
            id: snatcherBtn
            width: 130; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Text {
                anchors.centerIn: parent
                text: "📷"; font.pixelSize: 22; opacity: 0.25; z: 1
            }
            Column {
                anchors.centerIn: parent; spacing: 2; z: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Snatcher"
                    color: "#FF9800"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: snatcherBtn.opacity = 1.0
                onExited:  snatcherBtn.opacity = 0.85
                onPressed: snatcherBtn.opacity = 0.7
                onReleased: snatcherBtn.opacity = 1.0
                onClicked: buttonColumn.snatcherClicked()
            }
        }

        // --- 5. QUICK GALLERY ---
        Rectangle {
            id: quickGalleryBtn
            width: 130; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Quick"
                    color: "#ffffff"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Gallery"
                    color: "#cccccc"; font.pixelSize: 13
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: quickGalleryBtn.opacity = 1.0
                onExited:  quickGalleryBtn.opacity = 0.85
                onPressed: quickGalleryBtn.opacity = 0.7
                onReleased: quickGalleryBtn.opacity = 1.0
                onClicked: {
                    if (typeof splash !== "undefined") splash.deactivate()
                    contentLoader.setSource("CategoryMenu.qml")
                }
            }
        }

        // --- 6. CREATE ---
        Rectangle {
            id: createBtn
            width: 110; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Create"
                    color: "#ffffff"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: createBtn.opacity = 1.0
                onExited:  createBtn.opacity = 0.85
                onPressed: createBtn.opacity = 0.7
                onReleased: createBtn.opacity = 1.0
                onClicked: {
                    if (typeof splash !== "undefined") splash.deactivate()
                    utilitySidebar.showCollectionCreator()
                }
            }
        }

        // --- 7. CLOSE ---
        Rectangle {
            id: closeBtn
            width: 90; height: 56
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2a" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
            border.width: 1; border.color: "#B8956A"

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Close"
                    color: "#ffffff"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: closeBtn.opacity = 1.0
                onExited:  closeBtn.opacity = 0.85
                onPressed: closeBtn.opacity = 0.7
                onReleased: closeBtn.opacity = 1.0
                onClicked: Qt.quit()
            }
        }
    }

    // Search bar moved to Framework-1.qml for independent vertical positioning
}