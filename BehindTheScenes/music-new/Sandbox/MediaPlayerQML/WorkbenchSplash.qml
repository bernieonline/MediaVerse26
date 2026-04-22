import QtQuick 2.15

// ─────────────────────────────────────────────────────────────────────────────
//  WorkbenchSplash — static movie poster backdrop for all Workbench views.
//
//  Anchor this to parent.fill at z:0 behind the centred panel.
//  Uses the splashLayout context property (list of dicts with "path" key).
// ─────────────────────────────────────────────────────────────────────────────

Item {
    anchors.fill: parent

    // ── Deep blue-black base ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#030810"
    }

    // ── Static poster grid ────────────────────────────────────────────────────
    GridView {
        anchors.fill: parent
        anchors.margins: -4          // bleed slightly to avoid bare edges
        interactive:  false          // no scrolling
        clip:         false

        cellWidth:  Math.ceil((parent.width + 8) / 7)
        cellHeight: Math.ceil(cellWidth * 1.48)

        model: splashLayout

        delegate: Image {
            width:       GridView.view.cellWidth
            height:      GridView.view.cellHeight
            source:      model.path || ""
            fillMode:    Image.PreserveAspectCrop
            opacity:     0.13
            asynchronous: true
            cache:        true
        }
    }

    // ── Left + right edge vignette ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.70) }
            GradientStop { position: 0.18; color: "transparent" }
            GradientStop { position: 0.82; color: "transparent" }
            GradientStop { position: 1.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.70) }
        }
    }

    // ── Top + bottom vignette ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.55) }
            GradientStop { position: 0.12; color: "transparent" }
            GradientStop { position: 0.88; color: "transparent" }
            GradientStop { position: 1.00; color: Qt.rgba(0.012, 0.031, 0.063, 0.55) }
        }
    }
}
