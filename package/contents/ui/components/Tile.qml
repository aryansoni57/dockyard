import QtQuick
import org.kde.kirigami as Kirigami

// Glass tile (docs/STYLE.md, "Glass material"): faint fill, hairline border,
// top-lit edge on dark themes. Children go straight inside; size them yourself.
Rectangle {
    id: tile

    readonly property bool darkTheme: Kirigami.Theme.textColor.hslLightness > 0.5
    readonly property real padding: Math.round(height * 0.14)

    signal clicked()

    radius: height * 0.24
    color: Qt.alpha(Kirigami.Theme.textColor, hover.hovered ? 0.095 : 0.055)
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.13 : 0.09)

    scale: tap.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 80 }
    }

    // Top highlight: brighter rim along the flat part of the top edge.
    Rectangle {
        visible: tile.darkTheme
        x: tile.radius
        y: 1
        width: tile.width - tile.radius * 2
        height: 1
        color: Qt.alpha("white", 0.08)
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        onTapped: tile.clicked()
    }
}
