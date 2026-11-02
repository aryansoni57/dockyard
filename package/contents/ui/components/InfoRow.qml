import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Popup row: label left, value right, optional 3 px bar, hairline divider below.
Item {
    id: row

    property string label
    property string value
    property bool emphasized: false
    property real progress: -1 // 0..100; negative hides the bar
    property bool divider: true

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 2 + (progress >= 0 ? Kirigami.Units.smallSpacing * 2 : 0)

    PlasmaComponents.Label {
        id: labelText
        x: Kirigami.Units.largeSpacing
        y: Kirigami.Units.largeSpacing
        text: row.label
    }
    PlasmaComponents.Label {
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.baseline: labelText.baseline
        text: row.value
        font.weight: row.emphasized ? Font.Bold : Font.Normal
        font.features: { "tnum": 1 }
        opacity: row.emphasized ? 1 : 0.6
    }

    Rectangle {
        id: track
        visible: row.progress >= 0
        anchors {
            left: parent.left
            right: parent.right
            top: labelText.bottom
            margins: Kirigami.Units.largeSpacing
            topMargin: Kirigami.Units.smallSpacing
        }
        height: 3
        radius: 1.5
        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, row.progress)) / 100
            height: parent.height
            radius: parent.radius
            color: Kirigami.Theme.positiveTextColor

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
            }
        }
    }

    Rectangle {
        visible: row.divider
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    }
}
