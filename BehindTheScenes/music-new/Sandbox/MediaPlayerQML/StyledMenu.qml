import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: centralMenu
    property var menuData: ({ menu: [] })
    signal menuItemTriggered(string label)
    signal playerSelected(int index)

    height: 40
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.top: parent.top

    Row {
        id: topRow
        anchors.centerIn: parent
        spacing: 20

        Repeater {
            model: (menuData && menuData.menu) ? menuData.menu : []

            delegate: Item {
                id: topItem
                width: textItem.paintedWidth + 32
                height: 34

                property var subItems: modelData.items || []

                Rectangle {
                    anchors.fill: parent
                    color: mouse.containsMouse ? "#303030" : "#2e2e2e"
                    radius: 6
                    border.width: 1
                    border.color: "gold"
                }

                Text {
                    id: textItem
                    anchors.centerIn: parent
                    text: modelData.label
                    color: mouse.containsMouse ? "gold" : "white"
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if (subItems.length > 0) {
                            dropdown.items = subItems
                            dropdown.openBelow(topItem)
                        } else {
                            centralMenu.menuItemTriggered(modelData.label)
                        }
                    }
                }

                Popup {
                    id: dropdown
                    property var items: []
                    modal: false
                    focus: true
                    parent: Overlay.overlay

                    background: Rectangle {
                        color: "#202020"
                        radius: 8
                        border.color: "gold"
                        border.width: 1
                    }

                    function openBelow(item) {
                        var pos = item.mapToGlobal(0, item.height)
                        x = pos.x
                        y = pos.y
                        open()
                    }

                    contentItem: Column {
                        id: dropColumn
                        spacing: 2
                        padding: 4

                        Repeater {
                            model: dropdown.items

                            delegate: Item {
                                id: subItem
                                width: 220 
                                height: 32
                                property var subItems: modelData.items || []

                                Rectangle {
                                    anchors.fill: parent
                                    color: subMouse.containsMouse ? "#404040" : "transparent"
                                    radius: 4
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: subMouse.containsMouse ? "gold" : "white"
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: subMouse
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: {
                                        if (subItems.length > 0) {
                                            if (modelData.label === "Media Player") {
                                                // CRITICAL: Bind items directly from modelData
                                                mediaPlayerPopup.items = modelData.items
                                                mediaPlayerPopup.openBelow(subItem)
                                            } else {
                                                submenu.items = subItems
                                                submenu.openRight(subItem)
                                            }
                                        } else {
                                            centralMenu.menuItemTriggered(modelData.label)
                                            dropdown.close()
                                        }
                                    }
                                }

                                Popup {
                                    id: submenu
                                    property var items: []
                                    modal: false
                                    focus: true
                                    parent: Overlay.overlay

                                    background: Rectangle {
                                        color: "#202020"
                                        radius: 8
                                        border.color: "gold"
                                        border.width: 1
                                    }

                                    function openRight(item) {
                                        var pos = item.mapToGlobal(item.width, 0)
                                        x = pos.x
                                        y = pos.y
                                        open()
                                    }

                                    contentItem: Column {
                                        spacing: 2
                                        padding: 4
                                        Repeater {
                                            model: submenu.items
                                            delegate: Item {
                                                width: 180
                                                height: 32
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: mouse2.containsMouse ? "#505050" : "transparent"
                                                    radius: 4
                                                }
                                                Text {
                                                    anchors.left: parent.left; anchors.leftMargin: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.label
                                                    color: mouse2.containsMouse ? "gold" : "white"
                                                    font.pixelSize: 14
                                                }
                                                MouseArea {
                                                    id: mouse2
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        centralMenu.menuItemTriggered(modelData.label)
                                                        submenu.close()
                                                        dropdown.close()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ✅ Media Player Selection Popup
    Popup {
        id: mediaPlayerPopup
        property var items: []                
        property int currentPlayerIndex: -1   

        modal: false
        focus: true
        parent: Overlay.overlay

        background: Rectangle {
            color: "#202020"
            radius: 8
            border.color: "gold"
            border.width: 1
        }

        function openBelow(item) {
            // Map to the right of the menu item
            var pos = item.mapToGlobal(item.width, 0) 
            x = pos.x
            y = pos.y
            open()
        }

        Component.onCompleted: {
            let settings = SettingsManager.get_settings()
            if (settings && settings["Preferred Player"] !== undefined) {
                currentPlayerIndex = settings["Preferred Player"]
            }
        }

        Connections {
            target: SettingsManager
            function onSettingsChanged() {
                let settings = SettingsManager.get_settings()
                if (settings && settings["Preferred Player"] !== undefined) {
                    currentPlayerIndex = settings["Preferred Player"]
                }
            }
        }

        contentItem: Column {
            id: mediaColumn
            spacing: 5
            padding: 8
            width: 180 
            // Force the column to wrap its children so the Popup has a height
            height: childrenRect.height + 16

            Repeater {
                model: mediaPlayerPopup.items

                delegate: RadioButton {
                    id: playerRadio
                    text: modelData.label
                    checked: (index === mediaPlayerPopup.currentPlayerIndex)
                    width: 160

                    contentItem: Text {
                        text: playerRadio.text
                        font.pixelSize: 14
                        color: playerRadio.checked ? "gold" : "white"
                        leftPadding: playerRadio.indicator.width + playerRadio.spacing
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        SettingsManager.update_setting("Preferred Player", index)
                    }
                }
            }
        }
    }
}