import QtQuick 2.15
import QtQuick.Controls 2.15

Row {
    id: menuButtonRow
    spacing: 40
    anchors.horizontalCenter: parent.horizontalCenter

    // --- Collections button with dropdown menu ---
    StyledButton {
        id: collectionsButton
        text: "Collections"
        fixedWidth: 200
        fixedHeight: 60

        onClicked: {
            if (collectionsMenu.opened)
                collectionsMenu.close()
            else
                collectionsMenu.open()
        }

        Menu {
            id: collectionsMenu
            MenuItem { text: "Find a Collection"; onTriggered: console.log("Find a Collection triggered") }
            MenuItem { text: "Move a Collection"; onTriggered: console.log("Move a Collection triggered") }
            MenuItem { text: "Edit a Collection"; onTriggered: console.log("Edit a Collection triggered") }
            MenuItem { text: "View a Collection"; onTriggered: console.log("View a Collection triggered") }
        }
    }

    // --- Utilities button with dropdown menu ---
    StyledButton {
        id: utilitiesButton
        text: "Utilities"
        fixedWidth: 200
        fixedHeight: 60

        onClicked: {
            if (utilitiesMenu.opened)
                utilitiesMenu.close()
            else
                utilitiesMenu.open()
        }

        Menu {
            id: utilitiesMenu
            MenuItem { text: "Option A"; onTriggered: console.log("Utilities Option A triggered") }
            MenuItem { text: "Option B"; onTriggered: console.log("Utilities Option B triggered") }
        }
    }

    // --- Settings button with dropdown menu ---
    StyledButton {
        id: settingsButton
        text: "Settings"
        fixedWidth: 200
        fixedHeight: 60

        onClicked: {
            if (settingsMenu.opened)
                settingsMenu.close()
            else
                settingsMenu.open()
        }

        Menu {
            id: settingsMenu
            MenuItem { text: "Preferences"; onTriggered: console.log("Settings Preferences triggered") }
            MenuItem { text: "About"; onTriggered: console.log("Settings About triggered") }
        }
    }
}