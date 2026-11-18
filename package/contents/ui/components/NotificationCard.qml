pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons as KQCAddons
import org.kde.notificationmanager as NotificationManager
import "accent"

// One notification: app line with time and close, icon or image, summary, body and
// action buttons. Used by the toast popups and the history panel. `model` is the
// delegate's role object; `notifications` and `row` address it for actions.
Item {
    id: card

    required property var model
    // Empty while the row is being removed, so bindings do not throw during teardown.
    readonly property var m: card.model ? card.model : ({})
    property var notifications
    property int row: 0
    property bool popup: false
    property color accent: DockAccent.color
    // Milliseconds a popup stays when the sender leaves the timeout to the server.
    property int defaultTimeout: 5000

    readonly property bool critical: m?.urgency === NotificationManager.Notifications.CriticalUrgency
    // History only: rows newer than this get the unread dot.
    property var unreadSince: null
    readonly property bool unread: !popup && !!unreadSince && !!m?.created && m.created > unreadSince
    readonly property var actionNames: m?.actionNames ?? []
    readonly property var actionLabels: m?.actionLabels ?? []
    readonly property string bigIcon: m?.iconName && m?.iconName !== m?.applicationIconName ? m?.iconName : ""

    function timeText(when) {
        if (!when || isNaN(when))
            return "";
        const secs = Math.max(0, (Date.now() - when.getTime()) / 1000);
        if (secs < 60)
            return i18n("now");
        if (secs < 3600)
            return i18n("%1 min", Math.floor(secs / 60));
        if (secs < 86400)
            return i18n("%1 h", Math.floor(secs / 3600));
        return Qt.formatDate(when, "d MMM");
    }
    // Raises or starts the sending app (set by the owner; false when it cannot).
    property var openApp: null
    signal activated()
    // The default action wins when the app has one. Otherwise the sending app is raised,
    // or started when it has no window, as the dock's app icons do.
    function activate() {
        if (!notifications)
            return;
        const idx = notifications.index(row, 0);
        if (m?.hasDefaultAction && (popup || !m?.expired)) {
            notifications.invokeDefaultAction(idx, NotificationManager.Notifications.Close);
        } else {
            const entry = String(m?.desktopEntry ?? "");
            if (entry !== "" && card.openApp)
                card.openApp(entry);
            if (popup)
                notifications.expire(idx);
        }
        card.activated();
    }

    // The popup window already pads its edges, so toasts sit tighter than history rows.
    implicitHeight: content.implicitHeight + Kirigami.Units.smallSpacing * (popup ? 2 : 3)

    function currentIdx() {
        return notifications.index(row, 0);
    }
    // Summary and body as plain text, for Copy.
    function plainText() {
        const body = String(m?.body ?? "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]*>/g, "")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'").replace(/&amp;/g, "&");
        return [m?.summary ?? "", body].filter(t => t !== "").join("\n");
    }

    HoverHandler { id: hover }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: card.activate()
    }
    // A MouseArea accepts the right press, so the dock's applet menu stays shut.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            menu.visualParent = card;
            menu.open(mouse.x, mouse.y);
        }
    }

    // Hidden editor: the simplest way to put text on the clipboard from QML.
    TextEdit {
        id: copier
        visible: false
    }

    // Right-click menu, like Plasma's: open or run an action, copy the text,
    // the app's notification settings, and close.
    PlasmaExtras.Menu {
        id: menu

        PlasmaExtras.MenuItem {
            id: openItem
            visible: !!card.m?.hasDefaultAction
            text: card.m?.defaultActionLabel || i18n("Open")
            icon: "quickopen"
            onClicked: card.activate()
        }
        PlasmaExtras.MenuItem {
            id: actionsEnd
            separator: true
            visible: openItem.visible || card.actionNames.length > 0
        }
        PlasmaExtras.MenuItem {
            text: i18n("Copy")
            icon: "edit-copy"
            onClicked: {
                copier.text = card.plainText();
                copier.selectAll();
                copier.copy();
            }
        }
        PlasmaExtras.MenuItem {
            visible: card.m?.configurable !== false
            text: card.m?.applicationName ? i18n("Configure %1 Notifications…", card.m.applicationName) : i18n("Configure Notifications…")
            icon: "configure"
            onClicked: card.notifications.configure(card.currentIdx())
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            visible: card.m?.closable !== false
            text: card.popup ? i18n("Dismiss") : i18n("Remove from History")
            icon: "window-close"
            onClicked: card.notifications.close(card.currentIdx())
        }
    }
    // The app's own actions go between Open and Copy.
    Instantiator {
        model: card.actionNames.length
        delegate: PlasmaExtras.MenuItem {
            required property int index
            text: card.actionLabels[index] ?? card.actionNames[index]
            onClicked: card.notifications.invokeAction(card.currentIdx(), card.actionNames[index],
                NotificationManager.Notifications.Close)
        }
        onObjectAdded: (index, object) => menu.addMenuItem(object, actionsEnd)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        visible: !card.popup
        color: Qt.alpha(Kirigami.Theme.textColor, hover.hovered ? 0.06 : 0)
    }

    // Popups dismiss themselves unless critical; hovering or an open menu holds them.
    // Resident only means "stay after an action is tapped" (freedesktop spec),
    // not "never expire", so it must not block the timeout.
    // The deadline counts from when the server created the notification, so a
    // replaced or re-sorted toast cannot extend its own life by restarting this timer.
    readonly property int dismissAfter: card?.m?.timeout > 0 ? card?.m?.timeout : card.defaultTimeout
    // Time spent hovered or in the menu; it is added to the deadline so the countdown
    // pauses and resumes from where it stopped.
    property real heldMs: 0
    property real lastTick: Date.now()
    function dismissIn() {
        const c = card?.m?.created;
        const age = c instanceof Date && !isNaN(c) ? Date.now() - c.getTime() : 0;
        return Math.max(0, card.dismissAfter + card.heldMs - age);
    }
    readonly property bool counting: card.popup && !hover.hovered && menu.status === PlasmaExtras.Menu.Closed && !card.critical
    // Share of the popup's time still left, for the countdown line.
    property real timeLeft: 1
    // Space the toast window leaves above the first card; the line runs through it to the window edge.
    property real topInset: 0
    Timer {
        interval: 33
        repeat: true
        running: card.popup && !card.critical
        onTriggered: {
            const now = Date.now();
            if (!card.counting)
                card.heldMs += now - card.lastTick;
            card.lastTick = now;
            const left = card.dismissIn();
            card.timeLeft = Math.max(0, Math.min(1, left / card.dismissAfter));
            if (left <= 0)
                card.notifications.expire(card.notifications.index(card.row, 0));
        }
        onRunningChanged: if (running) card.lastTick = Date.now()
    }

    // Countdown line along the top of a toast; shrinks to the left as it closes.
    Rectangle {
        visible: card.popup && !card.critical
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: -card.topInset
        anchors.leftMargin: card.topInset > 0 ? Kirigami.Units.cornerRadius : 0
        height: 3
        radius: 1.5
        width: (parent.width - anchors.leftMargin * 2) * card.timeLeft
        color: card.accent
        opacity: 0.85
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                visible: card.unread
                Layout.preferredWidth: Kirigami.Units.smallSpacing * 1.5
                Layout.preferredHeight: width
                radius: width / 2
                color: card.accent
            }
            Kirigami.Icon {
                source: card?.m?.applicationIconName || "preferences-desktop-notification"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: card?.m?.applicationName || i18n("Notification")
                elide: Text.ElideRight
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }
            PlasmaComponents.Label {
                text: card.timeText(card?.m?.updated || card?.m?.created)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.features: { "tnum": 1 }
                opacity: 0.78
            }
            PlasmaComponents.ToolButton {
                visible: card?.m?.closable !== false
                icon.name: "window-close-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Close")
                Layout.preferredWidth: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                Layout.preferredHeight: Layout.preferredWidth
                opacity: hover.hovered || card.popup ? 1 : 0.5
                onClicked: card.notifications.close(card.notifications.index(card.row, 0))
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Kirigami.Units.smallSpacing / 2

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card?.m?.summary ?? ""
                    font.weight: Font.DemiBold
                    color: card.critical ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card?.m?.body ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: card.popup ? 4 : 3
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    opacity: 0.8
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            // The image role is empty for most notifications; a QImage cannot take that.
            Loader {
                id: image
                active: !!card?.m?.image
                visible: active
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                sourceComponent: KQCAddons.QImageItem {
                    image: card?.m?.image
                    fillMode: KQCAddons.QImageItem.PreserveAspectFit
                }
            }
            Kirigami.Icon {
                visible: !image.active && card.bigIcon !== ""
                source: card.bigIcon
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: card.actionNames.length > 0
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: card.actionNames.length
                delegate: PlasmaComponents.Button {
                    required property int index
                    text: card.actionLabels[index] ?? card.actionNames[index]
                    onClicked: card.notifications.invokeAction(card.notifications.index(card.row, 0),
                        card.actionNames[index], NotificationManager.Notifications.Close)
                }
            }
        }
    }
}
