import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "motion.js" as Motion
import "accent"

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

    // Accent glass: a top-lit accent wash and an accent-leaning rim. Off when the dock option
    // "Tint dock with the accent" is unticked; fixed-color tiles (docs/STYLE.md) turn it off too.
    property bool accentTint: DockAccent.tint
    readonly property color accent: DockAccent.color

    radius: height * 0.24
    color: Qt.alpha(Kirigami.Theme.textColor, hover.hovered ? 0.095 : 0.055)
    border.width: 1
    border.color: accentTint
        ? Qt.alpha(Qt.tint(Kirigami.Theme.textColor, Qt.alpha(accent, 0.55)), darkTheme ? 0.24 : 0.18)
        : Qt.alpha(Kirigami.Theme.textColor, darkTheme ? 0.13 : 0.09)

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

    // Accent wash: strongest along the top, fading out by the bottom, so the glass
    // looks lit by the accent instead of painted with it. Sits under the content;
    // hover brightens it via opacity (no new colors per frame).
    Rectangle {
        visible: tile.accentTint
        z: -1
        anchors.fill: parent
        anchors.margins: 1
        radius: tile.radius - 1
        opacity: hover.hovered ? 1 : 0.75
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(tile.accent, tile.darkTheme ? 0.36 : 0.24) }
            GradientStop { position: 0.6; color: Qt.alpha(tile.accent, 0.08) }
            GradientStop { position: 1; color: Qt.alpha(tile.accent, 0.04) }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    // Top highlight: brighter rim along the flat part of the top edge, accent-lit when tinted.
    Rectangle {
        visible: tile.darkTheme || tile.accentTint
        x: tile.radius
        y: 1
        width: tile.width - tile.radius * 2
        height: 1
        color: tile.accentTint
            ? Qt.alpha(Qt.tint("white", Qt.alpha(tile.accent, 0.7)), tile.darkTheme ? 0.3 : 0.45)
            : Qt.alpha("white", 0.08)
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
