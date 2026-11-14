import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "motion.js" as Motion

// Glass tile (docs/STYLE.md, "Glass material"): faint fill, hairline border,
// top-lit edge on dark themes. Children go straight inside; size them yourself.
Rectangle {
    id: tile

    readonly property bool darkTheme: Kirigami.Theme.textColor.hslLightness > 0.5
    readonly property real padding: Math.round(height * 0.14)

    // Shown as a tooltip while hovered (and not being dragged).
    property string hoverName

    // Passes the tile itself, so a handler can anchor a popup to it.
    signal clicked(Item source)

    // True when the point (in tile coordinates) sits on a button or slider inside
    // the tile, so a tap there does that control's job and not the tile's.
    function controlAt(x, y) {
        let item = tile;
        let px = x;
        let py = y;
        while (true) {
            const c = item.childAt(px, py);
            if (!c)
                return false;
            if (c.pressed !== undefined && c.hovered !== undefined)
                return true;
            const p = c.mapFromItem(item, px, py);
            px = p.x;
            py = p.y;
            item = c;
        }
    }

    radius: height * 0.24
    color: Qt.alpha(Kirigami.Theme.textColor, hover.hovered ? 0.095 : 0.055)
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.13 : 0.09)

    scale: tap.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    // Pressing dips fast; letting go springs back past 1 and settles (elastic curve).
    Behavior on scale {
        NumberAnimation {
            duration: Motion.ms(tap.pressed ? 80 : Motion.elasticMs, Kirigami.Units.longDuration)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: tap.pressed ? Motion.snap : Motion.elastic
        }
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

    SlideOnMove {}

    PlasmaComponents.ToolTip {
        visible: hover.hovered && tile.hoverName !== "" && tile.opacity === 1
        text: tile.hoverName
        delay: Kirigami.Units.toolTipDelay
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        onTapped: eventPoint => {
            if (!tile.controlAt(eventPoint.position.x, eventPoint.position.y))
                tile.clicked(tile);
        }
    }
}
