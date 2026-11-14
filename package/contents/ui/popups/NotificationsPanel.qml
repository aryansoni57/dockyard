pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/motion.js" as Motion

// Notifications popup: header with Do Not Disturb and Clear all, then the history,
// newest first. Opening it marks everything read.
ColumnLayout {
    id: panel

    property var applet
    readonly property var service: applet.notificationService

    spacing: 0
    // Grows with the list up to a cap, so a short or empty history leaves no gap.
    implicitHeight: header.implicitHeight + Kirigami.Units.largeSpacing * 2
        + (warning.visible ? warning.implicitHeight : 0)
        + (panel.service.count > 0
            ? Math.min(list.contentHeight, Kirigami.Units.gridUnit * 22)
            : placeholder.implicitHeight + Kirigami.Units.largeSpacing * 2)

    // Rows that arrived since the last look keep their dot while this stays open.
    property var seenBefore: null
    // True just after opening: only rows created then are staggered, not ones scrolled into view.
    property bool intro: true
    Timer {
        interval: 800
        running: true
        onTriggered: panel.intro = false
    }
    Component.onCompleted: {
        seenBefore = service.history.lastRead;
        service.markAllRead();
    }

    RowLayout {
        id: header
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: Qt.resolvedUrl("../../icons/bell.svg")
            isMask: true
            color: Kirigami.Theme.textColor
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: i18n("Notifications")
            font.weight: Font.DemiBold
        }
        PlasmaComponents.ToolButton {
            checkable: true
            checked: panel.service.inhibited
            icon.source: Qt.resolvedUrl("../../icons/moon-dnd.svg")
            text: i18n("Do Not Disturb")
            display: QQC2.AbstractButton.IconOnly
            PlasmaComponents.ToolTip.text: text
            PlasmaComponents.ToolTip.visible: hovered
            onClicked: panel.service.setDoNotDisturb(!panel.service.inhibited)
        }
        PlasmaComponents.ToolButton {
            enabled: panel.service.count > 0
            icon.name: "edit-clear-history-symbolic"
            text: i18n("Clear all")
            onClicked: panel.service.clearAll()
        }
        PlasmaComponents.ToolButton {
            icon.name: "configure-symbolic"
            display: QQC2.AbstractButton.IconOnly
            text: i18n("Notification settings")
            PlasmaComponents.ToolTip.text: text
            PlasmaComponents.ToolTip.visible: hovered
            onClicked: panel.applet.launch("systemsettings kcm_notifications")
        }
    }

    Kirigami.InlineMessage {
        id: warning
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing
        Layout.rightMargin: Kirigami.Units.largeSpacing
        visible: !panel.service.serverValid
        type: Kirigami.MessageType.Warning
        text: i18n("Another program owns the notification server, so notifications go there instead.")
    }

    PlasmaComponents.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: panel.service.count > 0
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ListView {
            id: list
            clip: true
            spacing: Kirigami.Units.smallSpacing / 2
            leftMargin: Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
            model: panel.service.history
            delegate: NotificationCard {
                id: card
                required property int index
                width: list.width - list.leftMargin - list.rightMargin
                notifications: panel.service.history
                row: index
                accent: panel.applet.accent
                unreadSince: panel.seenBefore

                // The first rows rise one after another when the popup opens.
                readonly property bool staggered: panel.intro && index < Motion.staggerRows
                opacity: staggered ? 0 : 1
                Component.onCompleted: if (staggered) rowIn.start()
                SequentialAnimation {
                    id: rowIn
                    PauseAnimation { duration: Motion.ms(index * Motion.staggerMs, Kirigami.Units.longDuration) }
                    NumberAnimation {
                        target: card
                        property: "opacity"
                        to: 1
                        duration: Motion.ms(Motion.enterMs, Kirigami.Units.longDuration)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.enter
                    }
                }
            }
        }
    }

    Kirigami.PlaceholderMessage {
        id: placeholder
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        visible: panel.service.count === 0
        icon.source: Qt.resolvedUrl("../../icons/" + (panel.service.inhibited ? "bell-off" : "bell") + ".svg")
        text: i18n("No notifications")
        explanation: panel.service.inhibited ? i18n("Do Not Disturb is on") : ""
    }
}
