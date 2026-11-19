import QtQuick
import org.kde.kirigami as Kirigami
import "../components"

// Do Not Disturb tile (website "Do Not Disturb"): a round moon button. Click turns
// Do Not Disturb on until you turn it off, or off again. The state comes from the
// dock's NotificationService.
Tile {
    id: tile

    property bool doNotDisturb: false
    property var service: null

    readonly property real inner: height - padding * 2

    implicitWidth: height

    onClicked: if (service) service.setDoNotDisturb(!doNotDisturb)

    Rectangle {
        anchors.centerIn: parent
        width: tile.inner * 0.72
        height: width
        radius: width / 2
        color: tile.doNotDisturb ? Qt.alpha("#BF5AF2", 0.3) : Qt.alpha(Kirigami.Theme.textColor, 0.12)

        Kirigami.Icon {
            anchors.centerIn: parent
            width: tile.inner * 0.4
            height: width
            source: Qt.resolvedUrl("../../icons/moon-dnd.svg")
            isMask: true
            color: tile.doNotDisturb ? "#BF5AF2" : Kirigami.Theme.textColor
        }
    }
}
