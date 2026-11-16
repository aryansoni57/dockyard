import QtQuick
import Qt5Compat.GraphicalEffects

// Frosted glass pane: samples a pre-blurred copy of the wallpaper behind it,
// clips it to a rounded shape, then adds tint, sheen, edge light and an outer-only shadow.
Item {
    id: g

    // Pre-blurred full-screen item shared by every pane.
    property Item backdrop
    property real radius: height / 2
    property color tint: Qt.rgba(1, 1, 1, 0.10)
    property color borderColor: Qt.rgba(1, 1, 1, 0.30)
    property real borderWidth: 1
    property real sheen: 0.20

    // Keeps the sampled region aligned while the pane slides in.
    property rect region: Qt.rect(0, 0, width, height)
    function sync() {
        if (!backdrop) return;
        const p = g.mapToItem(backdrop, 0, 0);
        region = Qt.rect(p.x, p.y, width, height);
    }
    Component.onCompleted: sync()
    onWidthChanged: sync()
    onHeightChanged: sync()
    Timer { interval: 16; repeat: true; running: g.visible && g.opacity > 0; onTriggered: g.sync() }

    Rectangle { id: shape; anchors.fill: parent; radius: g.radius; visible: false }

    // Shadow, cut out under the glass so it doesn't darken the blur.
    readonly property int pad: 60
    ShaderEffectSource {
        id: shapeSrc
        x: -g.pad; y: -g.pad
        width: g.width + g.pad * 2; height: g.height + g.pad * 2
        sourceItem: shape
        sourceRect: Qt.rect(-g.pad, -g.pad, width, height)
        live: true
        visible: false
    }
    DropShadow {
        id: shadow
        x: -g.pad; y: -g.pad
        width: shapeSrc.width; height: shapeSrc.height
        source: shapeSrc
        visible: false
        verticalOffset: 14
        radius: 36
        samples: 41
        color: "#66000000"
    }
    OpacityMask {
        x: -g.pad; y: -g.pad
        width: shapeSrc.width; height: shapeSrc.height
        source: shadow
        maskSource: shapeSrc
        invert: true
    }

    ShaderEffectSource {
        id: sample
        anchors.fill: parent
        sourceItem: g.backdrop
        sourceRect: g.region
        live: true
        visible: false
    }
    OpacityMask {
        anchors.fill: parent
        source: sample
        maskSource: shape
    }

    // Tint.
    Rectangle { anchors.fill: parent; radius: g.radius; color: g.tint }

    // Sheen: light falls off from the top edge.
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, g.sheen) }
            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.02) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.07) }
        }
    }

    // Edge light.
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        color: "transparent"
        border.width: g.borderWidth
        border.color: g.borderColor
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }
    // Specular line along the top curve.
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: g.radius * 0.6; rightMargin: g.radius * 0.6 }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.45)
    }
}
