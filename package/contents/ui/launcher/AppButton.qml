import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// One app: icon over name in the grid, icon beside name in the list.
// Focusable, so arrow keys and Enter work; right-click asks for its menu.
QQC2.AbstractButton {
    id: app

    property var iconSource: ""
    property string label
    property string note
    property bool listMode: false
    readonly property real iconSize: listMode ? Kirigami.Units.iconSizes.smallMedium : Math.round(Kirigami.Units.gridUnit * 1.9)
    // The icon sits on a faint rounded-square tile, so theme icons of any shape read as one set.
    readonly property real tileSize: listMode ? Math.round(Kirigami.Units.gridUnit * 1.75) : Math.round(iconSize * 1.25)
    property color accent: "#0A84FF"
    // Set by the launcher on the first search match, so Enter launches it.
    property bool searchHit: false
    readonly property bool selected: app.visualFocus || app.activeFocus || app.searchHit

    signal launched()
    signal menuRequested(real x, real y)

    activeFocusOnTab: true
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    implicitWidth: listMode ? 200 : Kirigami.Units.gridUnit * 5
    implicitHeight: listMode ? Kirigami.Units.gridUnit * 2.4 : Kirigami.Units.gridUnit * 4.6
    Layout.fillWidth: listMode
    padding: listMode ? Kirigami.Units.smallSpacing : Kirigami.Units.smallSpacing * 2
    leftPadding: listMode ? Kirigami.Units.smallSpacing * 1.5 : padding
    rightPadding: listMode ? Kirigami.Units.largeSpacing * 1.5 : padding

    onClicked: app.launched()
    Keys.onReturnPressed: app.launched()
    Keys.onEnterPressed: app.launched()
    Keys.onRightPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onLeftPressed: nextItemInFocusChain(false).forceActiveFocus()
    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()

    scale: down ? 0.97 : 1
    Behavior on scale {
        NumberAnimation { duration: 80 }
    }

    background: Rectangle {
        radius: app.listMode ? Math.round(Kirigami.Units.gridUnit * 0.55) : Math.round(Kirigami.Units.gridUnit * 0.78)
        color: app.selected ? Qt.alpha(app.accent, 0.18)
             : app.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.06) : "transparent"
        border.width: app.selected ? 1 : 0
        border.color: Qt.alpha(app.accent, 0.85)

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    contentItem: GridLayout {
        columns: app.listMode ? 3 : 1
        rowSpacing: Kirigami.Units.smallSpacing * 1.5
        columnSpacing: Kirigami.Units.largeSpacing * 1.25

        Rectangle {
            Layout.preferredWidth: app.tileSize
            Layout.preferredHeight: app.tileSize
            Layout.alignment: app.listMode ? Qt.AlignVCenter : Qt.AlignHCenter
            radius: app.listMode ? Math.round(app.tileSize * 0.28) : Math.round(Kirigami.Units.gridUnit * 0.78)
            color: Qt.alpha(Kirigami.Theme.textColor, 0.06)

            Kirigami.Icon {
                anchors.centerIn: parent
                width: app.iconSize
                height: app.iconSize
                source: app.iconSource
            }
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.alignment: app.listMode ? Qt.AlignVCenter : Qt.AlignHCenter
            horizontalAlignment: app.listMode ? Text.AlignLeft : Text.AlignHCenter
            text: app.label
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pixelSize: app.listMode ? Math.round(Kirigami.Units.gridUnit * 0.72) : Math.round(Kirigami.Units.gridUnit * 0.67)
        }
        PlasmaComponents.Label {
            visible: app.listMode && app.note !== ""
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 11
            text: app.note
            opacity: 0.45
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => app.menuRequested(eventPoint.scenePosition.x, eventPoint.scenePosition.y)
    }
}
