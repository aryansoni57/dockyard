import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Popup section header: uppercase, tracked, 50% opacity, on a slightly darker band.
Rectangle {
    property alias text: label.text

    Layout.fillWidth: true
    implicitHeight: label.implicitHeight + Kirigami.Units.smallSpacing * 2
    color: Qt.alpha(Kirigami.Theme.textColor, 0.04)

    PlasmaComponents.Label {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: Kirigami.Units.largeSpacing
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
        opacity: 0.5
    }
}
