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

    property string heroImageUri: ""
    property string episodeDesc:  ""

    // ── Initialise ───────────────────────────────────────────────────────────
    Component.onCompleted: {
        root.seriesModel = JSON.parse(tvViewModel.get_series_list())
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    function showSeries(name) {
        root.currentSeries = name
        var seasons = JSON.parse(tvViewModel.get_seasons(name))
        root.seasonsModel  = seasons
        if (seasons.length > 0)
            selectSeason(seasons[0].season_num)
        root.viewState = "series"
    }

    function selectSeason(seasonNum) {
        root.currentSeason = seasonNum
        root.episodeDesc   = ""
        for (var i = 0; i < root.seasonsModel.length; i++) {
            if (root.seasonsModel[i].season_num === seasonNum) {
                root.heroImageUri = root.seasonsModel[i].image_uri
                break
            }
        }
        root.episodesModel = JSON.parse(tvViewModel.get_episodes(root.currentSeries, seasonNum))
    }

    // ════════════════════════════════════════════════════════════════════════
    // STATE 1 — SERIES MATRIX  (mirrors ArchitectGallery layout exactly)
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: matrixView
        anchors.fill: parent
        opacity: root.viewState === "matrix" ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

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
    // STATE 2 — SERIES VIEW
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: seriesView
        anchors.fill: parent
        opacity: root.viewState === "series" ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

        // ── Back button ──────────────────────────────────────────────────────
        Rectangle {
            id: backBtn
            x: 20; y: 10
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

        // ── Series title ─────────────────────────────────────────────────────
        Text {
            id: seriesTitle
            anchors.top:              parent.top
            anchors.topMargin:        12
            anchors.horizontalCenter: parent.horizontalCenter
            text:  root.currentSeries
            color: "white"; font.pixelSize: 26; font.bold: true
        }

        // ── Three-column layout ──────────────────────────────────────────────
        Row {
            id: contentRow
            anchors.top:         seriesTitle.bottom
            anchors.topMargin:   16
            anchors.bottom:      parent.bottom
            anchors.bottomMargin:20
            anchors.left:        parent.left
            anchors.leftMargin:  30
            anchors.right:       parent.right
            anchors.rightMargin: 30
            spacing: 24

            // ── LEFT: Season fan — pivot at column centre, cards radiate upward ─
            Item {
                id: seasonColumn
                width:  contentRow.width * 0.50
                height: parent.height

                // Cards — portrait 2:3
                property real cardW: Math.min(210, width * 0.38)
                property real cardH: cardW * 1.5

                // Pivot at vertical centre — fan radiates symmetrically upward
                Item {
                    id: fanPivot
                    anchors.horizontalCenter:       parent.horizontalCenter
                    anchors.verticalCenter:         parent.verticalCenter
                    anchors.verticalCenterOffset:   100

                    Repeater {
                        model: root.seasonsModel

                        delegate: Item {
                            id: fanCard
                            property int  sNum:     modelData.season_num
                            property bool selected: root.currentSeason === sNum
                            property bool hovered:  false
                            property int  idx:      index
                            property int  total:    root.seasonsModel.length

                            // Spread widens with more seasons (30°–80° total)
                            property real spread: Math.min(80, Math.max(30, total * 12))
                            property real angle:  total > 1
                                ? -spread / 2 + idx * (spread / (total - 1))
                                : 0

                            width:  seasonColumn.cardW
                            height: seasonColumn.cardH

                            // All cards share pivot at their bottom-centre
                            x: -seasonColumn.cardW / 2
                            // Hover slides card outward (upward in its own axis)
                            y: -seasonColumn.cardH - (hovered ? seasonColumn.cardH * 0.08 : 0)

                            transformOrigin: Item.Bottom
                            rotation: angle
                            z: hovered ? total + 5 : (total - 1 - idx)
                            scale: selected ? 1.10 : 1.0

                            Behavior on scale { ScaleAnimator   { duration: 200 } }
                            Behavior on y     { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                            // Poster with rounded clip
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: "#000"
                                border.color: fanCard.selected ? "#39FF14"
                                            : fanCard.hovered  ? "white"
                                            : Qt.rgba(1,1,1,0.4)
                                border.width: fanCard.selected ? 3 : 1
                                clip: true

                                Image {
                                    id: fanImg
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: modelData.image_uri || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    smooth: true
                                    visible: false
                                }
                                Rectangle { id: fanMask; anchors.fill: parent; radius: 6; visible: false }
                                OpacityMask {
                                    anchors.fill: parent
                                    source:     fanImg
                                    maskSource: fanMask
                                }

                                // Fallback
                                Text {
                                    anchors.centerIn: parent
                                    text: "S" + String(fanCard.sNum).padStart(2, "0")
                                    color: "#555"; font.pixelSize: 28; font.bold: true
                                    visible: fanImg.status !== Image.Ready
                                }
                            }

                            // Season label tag — top-right corner
                            Rectangle {
                                anchors.top:         parent.top
                                anchors.right:       parent.right
                                anchors.topMargin:   8
                                anchors.rightMargin: 8
                                width: 64; height: 28; radius: 14
                                color:        fanCard.selected ? "#39FF14" : "#1a1a2e"
                                border.color: fanCard.selected ? "#39FF14" : "#2566c2"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "S" + String(fanCard.sNum).padStart(2, "0")
                                    color: fanCard.selected ? "black" : "white"
                                    font.pixelSize: 16; font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered:  fanCard.hovered = true
                                onExited:   fanCard.hovered = false
                                onClicked:  root.selectSeason(fanCard.sNum)
                            }
                        }
                    }
                }
            }

            // ── CENTRE: Hero poster + description ────────────────────────────
            Column {
                width:   contentRow.width * 0.27
                height:  parent.height
                spacing: 14

                Image {
                    id: heroPoster
                    width:  parent.width
                    height: Math.min(width * 1.5, parent.height * 0.65)
                    source: root.heroImageUri
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true

                    Behavior on source { PropertyAnimation { duration: 0 } }

                    Rectangle {
                        anchors.fill: parent
                        color: "#12121e"
                        visible: heroPoster.status !== Image.Ready
                        Text {
                            anchors.centerIn: parent
                            text: root.currentSeries
                            color: "#444"; font.pixelSize: 20
                            wrapMode: Text.WordWrap
                            width: parent.width - 20
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Episode / series description
                Rectangle {
                    width:  parent.width
                    height: parent.height - heroPoster.height - parent.spacing
                    color:  "#CC0d0d18"
                    radius: 10
                    border.color: "#2566c2"; border.width: 1
                    clip: true

                    Text {
                        anchors.fill:    parent
                        anchors.margins: 14
                        text: root.episodeDesc.length > 0
                              ? root.episodeDesc
                              : (root.currentSeries + "\nSeason " + root.currentSeason)
                        color: "#cccccc"; font.pixelSize: 18
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignTop
                    }
                }
            }

            // ── RIGHT: Episode tiles — narrower, anchored right ──────────────
            Item {
                width:  contentRow.width * 0.20
                height: parent.height

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

                        // Episode label + last-played
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

                        // Gold progress bar
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
                                anchors.left:   parent.left
                                anchors.top:    parent.top
                                anchors.bottom: parent.bottom
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

                            // Single click — fetch and show episode description
                            onClicked: {
                                var detail = JSON.parse(
                                    tvViewModel.get_episode_detail(modelData.xml_path))
                                var desc = detail.description || ""
                                if (!desc && detail.genre)
                                    desc = detail.genre
                                        + (detail.year ? " · " + detail.year : "")
                                if (!desc)
                                    desc = root.currentSeries
                                        + " — S" + String(root.currentSeason).padStart(2,"0")
                                        + "E" + String(modelData.ep_num).padStart(2,"0")
                                root.episodeDesc = desc
                            }

                            // Double click — play via playback router
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
        }
    }
}
