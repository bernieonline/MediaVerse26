import QtQuick 6.5
import QtQuick.Controls 2.15
import QtQuick.Window 6.5

ApplicationWindow {
    id: window
    visible: true
    width: 1400
    height: 900
    title: "Detail_View Test"

    Loader {
        id: testLoader
        anchors.fill: parent
        source: "Detail_View.qml"

        onLoaded: {
            // pass a fake image path for testing
            if (item && item.hasOwnProperty("imagePath")) {
                // Use either escaped backslashes:
                item.imagePath = "file:///W:/Collection/1990s/Deep Impact (1998).jpg"

                // OR forward slashes (recommended):
                // item.imagePath = "W:/Collection/1990s/Deep Impact (1998).jpg"
            }
        }
    }
}
