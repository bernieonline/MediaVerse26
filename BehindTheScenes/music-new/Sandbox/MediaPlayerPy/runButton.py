import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 6.5

Rectangle {
    id: buttonPanel
    width: parent.width
    height: 120
    color: "#222222"
    radius: 6

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ============================================================
        //  TEST BUTTON -- LOAD DETAIL VIEW WITH IMAGE + XML
        // ============================================================
        Button {
            id: testDetailButton
            text: "Test Detail View"
            Layout.preferredWidth: 200
            Layout.preferredHeight: 60

            onClicked: {
                console.log(" [Button] Test Detail View clicked")

                // --------------------------------------------------------
                // 1. Test image (DISPLAY tier -- correct 2:3 ratio)
                // --------------------------------------------------------
                let testImagePath =  _paths.local_display_v2 + "/Chisum (1970).jpg"
                    //"file:///D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/cacheV2/images/display/Chisum (1970).jpg"

                // --------------------------------------------------------
                // 2. Test XML path (server path)
                // --------------------------------------------------------
                let testXmlPath =
                    "file:///W:/Movies/John Wayne/Chisum (1970).xml"

                console.log(" [Button] imagePath =", testImagePath)
                console.log(" [Button] xmlPath   =", testXmlPath)
                console.log(" [Button] xmlController =", xmlController)

                // --------------------------------------------------------
                // 3. Load Detail_View_v2.qml with all required properties
                // --------------------------------------------------------
                contentLoader.setSource("Detail_View_v2.qml", {
                    imagePath: testImagePath,
                    xmlPath: testXmlPath,
                    xmlController: xmlController
                })
            }
        }

        // ============================================================
        //  CLOSE DETAIL VIEW (optional)
        // ============================================================
        Button {
            id: closeButton
            text: "Close Detail View"
            Layout.preferredWidth: 200
            Layout.preferredHeight: 60

            onClicked: {
                console.log(" [Button] Closing detail view")
                contentLoader.source = ""
            }
        }
    }
}