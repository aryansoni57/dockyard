import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// One widget in a list of widgets: a colored icon badge, the name with a short
// description, and a switch. The whole row toggles. The badge goes gray while off,
// so the list reads at a glance. Shared by the Widgets settings page and the gallery popup.
QQC2.AbstractButton {
    id: row

    property string iconName
    property string description
    property color accent: Kirigami.Theme.highlightColor

    checkable: true
    hoverEnabled: true
    Layout.fillWidth: true
    Layout.preferredWidth: 1 // equal columns in a GridLayout
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 2.8, content.implicitHeight + Kirigami.Units.smallSpacing * 2)
    Accessible.role: Accessible.CheckBox
    Accessible.description: description

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius * 1.5
        color: Qt.alpha(Kirigami.Theme.textColor, row.down ? 0.1 : row.hovered ? 0.06 : 0)
        border.width: row.visualFocus ? 2 : 0
        border.color: Kirigami.Theme.highlightColor
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }

    contentItem: RowLayout {
        id: content
        spacing: Kirigami.Units.largeSpacing

        Rectangle {
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            radius: width * 0.28
            color: row.checked ? row.accent : Qt.alpha(Kirigami.Theme.textColor, 0.12)
            Behavior on color { ColorAnimation { duration: Kirigami.Units.longDuration } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.small
                height: width
                source: row.iconName
                isMask: true
                color: row.checked ? "white" : Qt.alpha(Kirigami.Theme.textColor, 0.6)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            QQC2.Label {
                text: row.text
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            QQC2.Label {
                visible: row.description !== ""
                text: row.description
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.55
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        QQC2.Switch {
            id: toggle
            Layout.rightMargin: Kirigami.Units.smallSpacing
            checked: row.checked
            focusPolicy: Qt.NoFocus
            Accessible.ignored: true
            // The row owns the state; a tap on the switch counts as a tap on the row.
            MouseArea {
                anchors.fill: parent
                onClicked: row.click()
            }
        }
    }
}
