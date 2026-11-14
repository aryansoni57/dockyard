import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "../components"

// Notifications tile: a bell with a red unread badge; a crossed-out bell while
// Do Not Disturb is on. Click opens the history popup; right-click has Do Not
// Disturb durations, Clear All and the notification settings, like Plasma's own.
Tile {
    id: tile

    property int unread: 0
    property bool doNotDisturb: false
    // The NotificationService, for the right-click menu.
    property var service: null

    signal configureRequested()

    function hoursFromNow(h) {
        const d = new Date();
        d.setTime(d.getTime() + h * 3600000);
        return d;
    }
    function tomorrowMorning() {
        const d = new Date();
        d.setDate(d.getDate() + 1);
        d.setHours(8, 0, 0, 0);
        return d;
    }
    function untilForever() {
        const d = new Date();
        d.setFullYear(d.getFullYear() + 1);
        return d;
    }

    // Plasma opens the dock's own applet menu on every right click. Opening this menu
    // a beat later closes that one, as the app icons' menu does.
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: openLater.restart()
    }
    Timer {
        id: openLater
        interval: 80
        onTriggered: {
            menu.placement = Plasmoid.location === PlasmaCore.Types.TopEdge
                ? PlasmaExtras.Menu.BottomPosedLeftAlignedPopup : PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
            menu.openRelative();
        }
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: tile

        PlasmaExtras.MenuItem {
            visible: tile.doNotDisturb
            text: i18n("Turn Off Do Not Disturb")
            icon: "notifications"
            onClicked: tile.service.setDoNotDisturb(false)
        }
        PlasmaExtras.MenuItem {
            id: dndItem
            visible: !tile.doNotDisturb
            text: i18n("Do Not Disturb")
            icon: "notifications-disabled"
            readonly property PlasmaExtras.Menu sub: PlasmaExtras.Menu {
                visualParent: dndItem.action
                PlasmaExtras.MenuItem {
                    text: i18n("For 1 Hour")
                    onClicked: tile.service.doNotDisturbUntil(tile.hoursFromNow(1))
                }
                PlasmaExtras.MenuItem {
                    text: i18n("For 4 Hours")
                    onClicked: tile.service.doNotDisturbUntil(tile.hoursFromNow(4))
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Until Tomorrow")
                    onClicked: tile.service.doNotDisturbUntil(tile.tomorrowMorning())
                }
                PlasmaExtras.MenuItem {
                    text: i18n("Until Turned Off")
                    onClicked: tile.service.doNotDisturbUntil(tile.untilForever())
                }
            }
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Clear All Notifications")
            icon: "edit-clear-history"
            enabled: !!tile.service && tile.service.count > 0
            onClicked: tile.service.clearAll()
        }
        PlasmaExtras.MenuItem {
            text: i18n("Configure Notifications…")
            icon: "configure"
            onClicked: tile.configureRequested()
        }
    }

    readonly property real inner: height - padding * 2

    implicitWidth: height

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(tile.inner * 0.6)
        height: width
        source: Qt.resolvedUrl("../../icons/" + (tile.doNotDisturb ? "bell-off" : "bell") + ".svg")
        isMask: true
        color: Kirigami.Theme.textColor
        opacity: tile.doNotDisturb ? 0.5 : 0.9
    }

    Rectangle {
        visible: tile.unread > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: tile.padding * 0.5
        width: Math.max(height, badgeText.implicitWidth + height * 0.5)
        height: tile.inner * 0.42
        radius: height / 2
        color: "#FF3B30"

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: tile.unread > 99 ? "99+" : tile.unread
            color: "white"
            font.pixelSize: parent.height * 0.62
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
    }
}
