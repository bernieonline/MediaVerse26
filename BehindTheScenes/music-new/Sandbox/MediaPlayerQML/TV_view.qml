// TV_view.qml
//
// State 1 — Series Matrix:  3-column poster grid with page navigation
// State 2 — Series View:    Season fan/stack + Hero poster + Episode tiles
//
// Navigation:
//   Click a series poster  → State 2
//   Click a season card    → updates hero poster + episode list
//   Single-click episode   → description appears below hero
//   Double-click episode   → plays video via playbackRouter
//   Back button            → State 1

import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    // ── Public signal (Framework-1 wires backRequested → previous view) ──────
    signal backRequested()

    // ── State ────────────────────────────────────────────────────────────────
    property string viewState:     "matrix"   // "matrix" | "series"
    property string currentSeries: ""
    property int    currentSeason: 0

    // Data models (plain JS arrays from tvViewModel slots)
    property var seriesModel:  []
    property var seasonsModel: []
    property var episodesModel:[]

    property string episodeDesc:   ""
    property bool   showActors:    false
    property var    currentActors: []
    property var    xmlCache:      ({})

    // ── Initialise ───────────────────────────────────────────────────────────
    Component.onCompleted: {
        root.seriesModel = JSON.parse(tvViewModel.get_series_list())
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    function showSeries(name) {
        root.currentSeries = name
        root.showActors    = false
        // Preload all XML data for this series (cached after first call)
        root.xmlCache = JSON.parse(tvViewModel.preload_series_xml(name))
        var seasons = JSON.parse(tvViewModel.get_seasons(name))
        root.seasonsModel = seasons
        if (seasons.length > 0)
            selectSeason(seasons[0].season_num)
        root.viewState = "series"
    }

    function selectSeason(seasonNum) {
        root.currentSeason = seasonNum
        root.episodesModel = JSON.parse(tvViewModel.get_episodes(root.currentSeries, seasonNum))
        // Show first episode data immediately
        if (root.episodesModel.length > 0) {
            var ep0  = root.episodesModel[0]
            var data = root.xmlCache[ep0.xml_path] || {}
            root.episodeDesc   = data.description || ""
            root.currentActors = data.actors      || []
        } else {
            root.episodeDesc   = ""
            root.currentActors = []
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // STATE 1 — SERIES MATRIX  (mirrors ArchitectGallery layout exactly)
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: matrixView
        anchors.fill: parent

        // ── Grid pane ────────────────────────────────────────────────────────
        Item {
            id: gridPane
            anchors.fill: parent
            z: 2

            property int  currentPage: 0
            readonly property int totalPages: Math.max(1, Math.ceil(root.seriesModel.length / 6))

            // Same sizing formula as ArchitectGallery
            readonly property real edgeMargin: 24
            readonly property real imgGap:     12
            readonly property real posterH: (parent.height - edgeMargin * 2 - imgGap * 3) / 2 - 36
            readonly property real posterW: posterH * 2 / 3

            // ── Page-flip function + animation (verbatim from ArchitectGallery) ──
            function flipPage(target, forward) {
                flipAnim.nextTarget = target
                flipAnim.goForward  = forward
                flipAnim.restart()
            }

            SequentialAnimation {
                id: flipAnim
                property int  nextTarget: 0
                property bool goForward:  true

                NumberAnimation {
                    target: pageRotation; property: "angle"
                    to: flipAnim.goForward ? -90 : 90
                    duration: 320; easing.type: Easing.InCubic
                }
                ScriptAction { script: gridPane.currentPage = flipAnim.nextTarget }
                NumberAnimation {
                    target: pageRotation; property: "angle"
                    from: flipAnim.goForward ? 90 : -90; to: 0
                    duration: 320; easing.type: Easing.OutCubic
                }
            }

            // ── Glass panel behind grid ──────────────────────────────────────
            Rectangle {
                x:      gridPane.edgeMargin
                y:      gridPane.edgeMargin
                width:  gridContainer.width  + gridPane.imgGap * 2
                height: gridContainer.height + gridPane.imgGap * 2
                radius: 14
                color:  Qt.rgba(0.04, 0.04, 0.07, 0.55)
                border.color: Qt.rgba(0.37, 0.50, 0.76, 0.25)
                border.width: 1
            }

            // ── Grid container — page-flip target ────────────────────────────
            Item {
                id: gridContainer
                x:      gridPane.edgeMargin + gridPane.imgGap
                y:      gridPane.edgeMargin + gridPane.imgGap
                width:  3 * gridPane.posterW + 2 * gridPane.imgGap
                height: 2 * (gridPane.posterH + 36) + gridPane.imgGap
                layer.enabled: true

                transform: Rotation {
                    id: pageRotation
                    origin.x: gridContainer.width  / 2
                    origin.y: gridContainer.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: 0
                }

                Grid {
                    id: seriesGrid
                    columns:       3
                    rowSpacing:    gridPane.imgGap
                    columnSpacing: gridPane.imgGap

                    Repeater {
                        model: 6
                        delegate: Item {
                            id: cellItem
                            width:  gridPane.posterW
                            height: gridPane.posterH + 36

                            property int  absIdx:     gridPane.currentPage * 6 + index
                            property bool hasData:    absIdx < root.seriesModel.length
                            property var  seriesData: hasData
                                ? root.seriesModel[absIdx]
                                : ({ name: "", image_uri: "", season_count: 0, episode_count: 0 })

                            Rectangle {
                                id: posterRect
                                width:  gridPane.posterW
                                height: gridPane.posterH
                                radius: 6
                                color:  cellItem.hasData ? "#111" : "transparent"
                                clip:   true
                                border.color: cellItem.hasData ? "transparent" : Qt.rgba(1,1,1,0.06)
                                border.width: cellItem.hasData ? 0 : 1

                                layer.enabled: cellItem.hasData
                                layer.effect: DropShadow {
                                    horizontalOffset: 0; verticalOffset: 10
                                    radius: 16; samples: 33
                                    color:  Qt.rgba(0,0,0,0.72); spread: 0
                                }

                                Image {
                                    anchors.fill: parent
                                    source:       cellItem.seriesData.image_uri || ""
                                    fillMode:     Image.PreserveAspectCrop
                                    smooth:       true
                                    asynchronous: true
                                }

                                // Top-lit sheen
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius
                                    visible: cellItem.hasData
                                    gradient: Gradient {
                                        GradientStop { position: 0.0;  color: Qt.rgba(1,1,1,0.09) }
                                        GradientStop { position: 0.42; color: "transparent" }
                                    }
                                }

                                // Hover tint
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius
                                    visible: cellItem.hasData
                                    color: Qt.rgba(1,1,1, cellMouse.containsMouse ? 0.09 : 0)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                // Blue bottom accent on hover
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 3
                                    color: "#2566c2"
                                    visible: cellItem.hasData
                                    opacity: cellMouse.containsMouse ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: { if (cellItem.hasData) root.showSeries(cellItem.seriesData.name) }
                                }
                            }

                            // Series name below poster
                            Text {
                                anchors.top:              posterRect.bottom
                                anchors.topMargin:        6
                                anchors.horizontalCenter: parent.horizontalCenter
                                width:               gridPane.posterW
                                text:                cellItem.seriesData.name || ""
                                color:               "white"
                                font.pixelSize:      18
                                horizontalAlignment: Text.AlignHCenter
                                elide:               Text.ElideRight
                                maximumLineCount:    1
                            }
                        }
                    }
                }
            }

            // ── Nav buttons — right of grid, vertically centred ──────────────
            Column {
                id: navButtons
                x: gridContainer.x + gridContainer.width + gridPane.imgGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20
                z: 3

                Item {
                    width: 70; height: 70
                    opacity: gridPane.currentPage > 0 ? 1.0 : 0.28
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Rectangle {
                        anchors.fill: parent; radius: 35
                        color: prevHov.containsMouse
                            ? Qt.rgba(0.15,0.40,0.76,0.88)
                            : Qt.rgba(0.08,0.08,0.08,0.82)
                        border.color: "#2566c2"; border.width: 2
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "‹"; color: "white"; font.pixelSize: 42; font.bold: true }
                    MouseArea {
                        id: prevHov; anchors.fill: parent; hoverEnabled: true
                        enabled: gridPane.currentPage > 0
                        onClicked: gridPane.flipPage(gridPane.currentPage - 1, false)
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:  (gridPane.currentPage + 1) + " / " + gridPane.totalPages
                    color: Qt.rgba(1,1,1,0.55); font.pixelSize: 15
                }

                Item {
                    width: 70; height: 70
                    opacity: gridPane.currentPage < gridPane.totalPages - 1 ? 1.0 : 0.28
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Rectangle {
                        anchors.fill: parent; radius: 35
                        color: nextHov.containsMouse
                            ? Qt.rgba(0.15,0.40,0.76,0.88)
                            : Qt.rgba(0.08,0.08,0.08,0.82)
                        border.color: "#2566c2"; border.width: 2
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text { anchors.centerIn: parent; text: "›"; color: "white"; font.pixelSize: 42; font.bold: true }
                    MouseArea {
                        id: nextHov; anchors.fill: parent; hoverEnabled: true
                        enabled: gridPane.currentPage < gridPane.totalPages - 1
                        onClicked: gridPane.flipPage(gridPane.currentPage + 1, true)
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // STATE 2 — SERIES VIEW  (overlay on top of the always-visible matrix)
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: seriesView
        anchors.fill: parent
        opacity: root.viewState === "series" ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

        // Dark glass panel — covers only the area to the right of the nav buttons
        Rectangle {
            x:      navButtons.x + 90
            y:      gridPane.edgeMargin
            width:  parent.width - x - gridPane.edgeMargin
            height: parent.height - gridPane.edgeMargin * 2
            color:  Qt.rgba(0.03, 0.03, 0.08, 0.94)
        }

        // Overlay content panel
        Item {
            id: overlayPanel
            x:      navButtons.x + 90
            y:      gridPane.edgeMargin
            width:  parent.width - x - gridPane.edgeMargin
            height: parent.height - gridPane.edgeMargin * 2

            // ── Back button ──────────────────────────────────────────────────
            Rectangle {
                id: backBtn
                x: 16; y: 12
                width: 110; height: 36; radius: 18
                color: "#1a1a2e"
                border.color: "#2566c2"; border.width: 1
                z: 10
                Text {
                    anchors.centerIn: parent
                    text: "← Back"
                    color: "#2566c2"; font.pixelSize: 20; font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.viewState = "matrix"
                }
            }

            // ── Series title ─────────────────────────────────────────────────
            Text {
                id: seriesTitle
                anchors.top:              parent.top
                anchors.topMargin:        14
                anchors.horizontalCenter: parent.horizontalCenter
                text:  root.currentSeries
                color: "white"; font.pixelSize: 26; font.bold: true
            }

            // ── Content area ─────────────────────────────────────────────────
            Item {
                id: contentRow
                anchors.top:          seriesTitle.bottom
                anchors.topMargin:    14
                anchors.bottom:       parent.bottom
                anchors.bottomMargin: 16
                anchors.left:         parent.left
                anchors.leftMargin:   16
                anchors.right:        parent.right
                anchors.rightMargin:  16

                // ── RIGHT: Episode tiles ──────────────────────────────────────
                Item {
                    id: episodesColumn
                    anchors.right:  parent.right
                    anchors.top:    parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.26

                    ListView {
                        id: episodeList
                        anchors.fill: parent
                        clip:    true
                        spacing: 6
                        model:   root.episodesModel

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            id: episodeTile
                            width:  episodeList.width
                            height: 88
                            radius: 8
                            color:  epMouse.containsMouse ? "#182030" : "#0d0d18"
                            border.color: "#2566c2"; border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.left:           parent.left
                                anchors.leftMargin:     14
                                anchors.right:          progressBar.left
                                anchors.rightMargin:    10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    text: {
                                        var label = modelData.ep_end
                                            ? ("Ep " + modelData.ep_num + "–" + modelData.ep_end)
                                            : ("Ep " + modelData.ep_num)
                                        return modelData.ep_name
                                            ? label + " · " + modelData.ep_name
                                            : label
                                    }
                                    color: "white"
                                    font.pixelSize: 18; font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.last_played
                                        ? "Watched: " + modelData.last_played
                                        : "Never watched"
                                    color: modelData.last_played ? "#999" : "#555"
                                    font.pixelSize: 15
                                }
                            }

                            Item {
                                id: progressBar
                                anchors.right:          parent.right
                                anchors.rightMargin:    14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 76; height: 26

                                Rectangle {
                                    anchors.fill: parent; radius: 4
                                    color: "#1a1a1a"
                                    border.color: "#333"; border.width: 1
                                }
                                Rectangle {
                                    anchors.left:    parent.left
                                    anchors.top:     parent.top
                                    anchors.bottom:  parent.bottom
                                    anchors.margins: 2
                                    radius: 3
                                    width: Math.max(0, (parent.width - 4) * modelData.progress_pct / 100)
                                    color: modelData.progress_pct >= 100 ? "#39FF14"
                                         : modelData.progress_pct >  0   ? "#FFC107"
                                         : "transparent"
                                    Behavior on width { NumberAnimation { duration: 300 } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.progress_pct + "%"
                                    color: "#777"; font.pixelSize: 13
                                }
                            }

                            MouseArea {
                                id: epMouse
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    var data = root.xmlCache[modelData.xml_path] || {}
                                    root.episodeDesc   = data.description || ""
                                    root.currentActors = data.actors      || []
                                }

                                onDoubleClicked: {
                                    if (modelData.video_path) {
                                        var cleanPath = modelData.video_path.toString().replace(/\\/g, "/")
                                        playbackRouter.playVideo(cleanPath, false)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── CENTRE: Season posters (top) + Text area (bottom) ─────────
                Item {
                    id: centreColumn
                    anchors.left:        parent.left
                    anchors.right:       episodesColumn.left
                    anchors.rightMargin: 16
                    anchors.top:         parent.top
                    anchors.bottom:      parent.bottom

                    // ── Season poster row ─────────────────────────────────────
                    Item {
                        id: seasonPosterZone
                        anchors.top:   parent.top
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        height: parent.height * 0.55

                        // Layout calculations
                        property int   count:    root.seasonsModel.length
                        property real  availW:   width - 24
                        property real  maxPostH: Math.min(height * 0.88, 320)
                        property real  maxPostW: maxPostH * 2 / 3
                        property real  minStep:  68   // min exposed pixels for badge visibility

                        property real  step: {
                            if (count <= 1) return 0
                            var natural = (availW - maxPostW) / (count - 1)
                            return Math.max(minStep, natural)
                        }
                        property real  postW: {
                            if (count <= 0) return maxPostW
                            if (count === 1) return Math.min(maxPostW, availW * 0.5)
                            return Math.min(maxPostW, availW - step * (count - 1))
                        }
                        property real  postH:   postW * 1.5
                        property real  totalW:  count <= 1 ? postW : (count - 1) * step + postW
                        property real  startX:  Math.max(12, (availW - totalW) / 2 + 12)

                        Repeater {
                            model: root.seasonsModel

                            delegate: Item {
                                id: posterCard
                                property int  sNum: modelData.season_num
                                property bool sel:  root.currentSeason === sNum
                                property int  idx:  index

                                x: seasonPosterZone.startX + idx * seasonPosterZone.step
                                y: (seasonPosterZone.height - seasonPosterZone.postH) / 2
                                width:  seasonPosterZone.postW
                                height: seasonPosterZone.postH
                                // Season 1 on top — each subsequent season peeks out to the right,
                                // keeping its top-right badge in the exposed area
                                z: sel ? 99 : (seasonPosterZone.count - 1 - idx)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#111"
                                    border.color: posterCard.sel ? "#39FF14" : Qt.rgba(1,1,1,0.25)
                                    border.width: posterCard.sel ? 3 : 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source:       modelData.image_uri || ""
                                        fillMode:     Image.PreserveAspectCrop
                                        asynchronous: true
                                        smooth:       true
                                    }

                                    // Top-right season badge (right edge always exposed)
                                    Rectangle {
                                        anchors.top:         parent.top
                                        anchors.right:       parent.right
                                        anchors.topMargin:   8
                                        anchors.rightMargin: 8
                                        width: 48; height: 26; radius: 13
                                        color:        posterCard.sel ? "#39FF14" : Qt.rgba(0.05,0.05,0.15,0.88)
                                        border.color: posterCard.sel ? "#39FF14" : "#2566c2"
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "S" + modelData.season_num
                                            color: posterCard.sel ? "black" : "white"
                                            font.pixelSize: 15; font.bold: true
                                        }
                                    }

                                    // Hover tint
                                    Rectangle {
                                        anchors.fill: parent; radius: parent.radius
                                        color: Qt.rgba(1,1,1, cardMouse.containsMouse && !posterCard.sel ? 0.08 : 0)
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.selectSeason(posterCard.sNum)
                                }
                            }
                        }
                    }

                    // ── Text area (description / actors) ─────────────────────
                    Item {
                        id: textZone
                        anchors.top:         seasonPosterZone.bottom
                        anchors.topMargin:   10
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.bottom:      parent.bottom

                        Row {
                            id: toggleBar
                            anchors.top:              parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 0

                            Rectangle {
                                width: 150; height: 34; radius: 17
                                color:  !root.showActors ? "#2566c2" : Qt.rgba(0.06,0.06,0.14,0.9)
                                border.color: "#2566c2"; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Description"; color: "white"
                                    font.pixelSize: 17; font.bold: !root.showActors
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.showActors = false }
                            }

                            Rectangle {
                                width: 110; height: 34; radius: 17
                                color:  root.showActors ? "#2566c2" : Qt.rgba(0.06,0.06,0.14,0.9)
                                border.color: "#2566c2"; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Actors"; color: "white"
                                    font.pixelSize: 17; font.bold: root.showActors
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.showActors = true }
                            }
                        }

                        Rectangle {
                            anchors.top:         toggleBar.bottom
                            anchors.topMargin:   8
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.bottom:      parent.bottom
                            color:  "#CC0d0d18"
                            radius: 10
                            border.color: "#2566c2"; border.width: 1
                            clip: true

                            Flickable {
                                anchors.fill:    parent
                                anchors.margins: 14
                                contentWidth:    width
                                contentHeight:   textContent.implicitHeight
                                clip:            true
                                flickableDirection: Flickable.VerticalFlick
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                Text {
                                    id: textContent
                                    width: parent.width
                                    text: root.showActors
                                          ? (root.currentActors.length > 0
                                             ? root.currentActors.join(",  ")
                                             : "No cast information available")
                                          : (root.episodeDesc.length > 0
                                             ? root.episodeDesc
                                             : root.currentSeries + "  —  Season " + root.currentSeason)
                                    color: "#cccccc"; font.pixelSize: 18
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignTop
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
