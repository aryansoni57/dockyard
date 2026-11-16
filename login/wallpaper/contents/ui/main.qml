import QtQuick
import org.kde.plasma.plasmoid

// Dockyard flowing liquid wallpaper.
WallpaperItem {
    id: root

    accentColor: root.configuration.Flow1

    ShaderEffect {
        anchors.fill: parent

        property vector2d res: Qt.vector2d(width, height)
        property real t: 12
        property color base: root.configuration.Base
        property color c1: root.configuration.Flow1
        property color c2: root.configuration.Flow2
        property color c3: root.configuration.Flow3

        // Time runs over a day-long range so the loop never visibly restarts.
        NumberAnimation on t {
            running: root.configuration.Animate
            from: 12; to: 12 + 86400; duration: 86400 * 1000
            loops: Animation.Infinite
        }
        // Render at 0.4x and upscale, (SCALE = 0.4): softer and about 6x cheaper.
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.max(2, Math.round(width * 0.4)), Math.max(2, Math.round(height * 0.4)))

        fragmentShader: Qt.resolvedUrl("../shaders/liquid.frag.qsb")
    }
}
