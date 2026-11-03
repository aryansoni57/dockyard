import QtQuick
import org.kde.kirigami as Kirigami
import "../components"

// Start tile, far left. A click opens the Lumen launcher in the dock popup; main.qml
// connects the clicked() signal.
Tile {
    id: start

    readonly property real inner: height - padding * 2

    implicitWidth: height

    Kirigami.Icon {
        anchors.centerIn: parent
        width: start.inner * 0.72
        height: width
        source: Qt.resolvedUrl("../../icons/start.svg")
        fallback: "start-here-kde-plasma"
        isMask: true
        color: Kirigami.Theme.textColor
    }
}
