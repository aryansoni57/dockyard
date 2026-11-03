import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../components"

// Pinned and running apps (docs/STYLE.md): app icons sit loose between tiles,
// with no tile behind them. A small accent dot marks a running app.
// The tasks model is created in main.qml and passed in; this module is a view.
Item {
    id: apps

    property var tasks: null

    // Emitted when an icon was dragged to a new place, after the model has moved.
    signal moved()

    SlideOnMove {}

    readonly property real iconSize: Math.round(height * 0.72)

    implicitWidth: row.implicitWidth

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: apps.tasks

            // Invisible delegates are skipped by Row, so Row is used instead of RowLayout.
            Item {
                id: app

                required property int index
                required property var model

                width: apps.iconSize
                height: apps.height

                Rectangle {
                    anchors.fill: parent
                    radius: width * 0.24
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
                    visible: hover.hovered
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: apps.iconSize
                    height: apps.iconSize
                    source: app.model.decoration
                    scale: reorder.active ? 1.12 : tap.pressed ? 0.94 : 1
                    opacity: reorder.active ? 0.8 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: Kirigami.Theme.highlightColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height - (parent.height - apps.iconSize) / 4 - 2)
                    visible: !app.model.IsLauncher
                }

                SlideOnMove {}

                HoverHandler {
                    id: hover
                }

                // Drag one icon sideways to reorder it. It swaps with a neighbour once the
                // pointer crosses that neighbour's midpoint. This handler is exclusive, so
                // the dock-level tile reorder never sees a press that starts on an icon.
                DragHandler {
                    id: reorder
                    target: null
                    acceptedButtons: Qt.LeftButton
                    dragThreshold: Kirigami.Units.gridUnit * 0.6

                    onActiveChanged: {
                        if (!active)
                            apps.moved();
                    }
                    onCentroidChanged: {
                        if (!active)
                            return;
                        const p = app.mapToItem(row, centroid.position.x, centroid.position.y);
                        const other = row.childAt(p.x, p.y);
                        if (!other || other === app || other.index === undefined)
                            return;
                        const mid = other.x + other.width / 2;
                        const forward = other.x > app.x;
                        if (forward ? p.x <= mid : p.x >= mid)
                            return;
                        apps.tasks.move(app.index, other.index);
                    }
                }

                TapHandler {
                    id: tap
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onTapped: (eventPoint, button) => {
                        const idx = apps.tasks.makeModelIndex(app.index);
                        if (button === Qt.MiddleButton || app.model.IsLauncher)
                            apps.tasks.requestNewInstance(idx);
                        else
                            apps.tasks.requestActivate(idx);
                    }
                }

                QQC2.ToolTip.visible: hover.hovered
                QQC2.ToolTip.text: app.model.AppName || app.model.display || ""
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
