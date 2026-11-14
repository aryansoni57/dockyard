pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons as KQCAddons
import org.kde.notificationmanager as NotificationManager

// Notification server for setups with no stock Notifications applet (the dock replaces
// the panel that held it). Plasma only owns org.freedesktop.Notifications while a
// Notifications model exists in plasmashell; creating one here registers the server.
// Shows toast popups near the dock and keeps the history the Notifications tile reads.
Item {
    id: service

    // Popups off still keeps the server and history, so apps never lose notifications.
    property bool popupsEnabled: true
    // Accent for the unread dot and buttons.
    property color accent: Kirigami.Theme.highlightColor

    readonly property alias settings: notifSettings
    readonly property alias history: historyModel
    // True when another program (dunst, mako, another shell) owns the D-Bus name.
    readonly property bool serverValid: NotificationManager.Server.valid
    readonly property int unreadCount: historyModel.unreadNotificationsCount
    readonly property int count: historyModel.count

    // File copies and other KDE jobs, from their own model (the history skips jobs).
    readonly property alias jobs: jobsModel
    // Rows in the jobs model, finished ones included until they are swept away.
    readonly property int jobCount: jobsModel.count
    // Jobs still running or paused. The dock pill follows this one.
    property int activeJobCount: 0
    // Average progress of the running jobs, 0..100.
    readonly property int jobsPercent: jobsModel.jobsPercentage
    // App icon and title of the first live job, for the dock pill.
    property string jobIcon: ""
    property string jobTitle: ""
    property string jobDesktopEntry: ""
    // Where the first job puts its files (the folder of a copy), "" when it has none.
    property string jobDestUrl: ""
    // True when every job in the model has ended: the pill stays up for a while, saying so.
    property bool jobsDone: false

    // Destination folder a job reports, as a URL string, or "".
    function destOf(idx) {
        const det = jobsModel.data(idx, NotificationManager.Notifications.JobDetailsRole);
        const u = det ? (det.effectiveDestUrl || det.destUrl) : "";
        return u ? u.toString() : "";
    }

    function refreshJobs() {
        const N = NotificationManager.Notifications;
        let active = 0;
        let finished = 0;
        let icon = "";
        let title = "";
        let entry = "";
        let dest = "";
        // Fall back to the first finished job when none is running, so the pill keeps its look.
        let fallbackIdx = null;
        for (let i = 0; i < jobsModel.count; ++i) {
            const idx = jobsModel.index(i, 0);
            if (jobsModel.data(idx, N.JobStateRole) === N.JobStateStopped) {
                ++finished;
                if (fallbackIdx === null)
                    fallbackIdx = idx;
                continue;
            }
            if (active === 0) {
                icon = String(jobsModel.data(idx, N.ApplicationIconNameRole) || "") || "document-save";
                title = String(jobsModel.data(idx, N.SummaryRole) || jobsModel.data(idx, N.ApplicationNameRole) || "");
                entry = String(jobsModel.data(idx, N.DesktopEntryRole) || "");
                dest = destOf(idx);
            }
            ++active;
        }
        if (active === 0 && fallbackIdx !== null) {
            icon = String(jobsModel.data(fallbackIdx, N.ApplicationIconNameRole) || "") || "document-save";
            title = String(jobsModel.data(fallbackIdx, N.SummaryRole) || jobsModel.data(fallbackIdx, N.ApplicationNameRole) || "");
            entry = String(jobsModel.data(fallbackIdx, N.DesktopEntryRole) || "");
            dest = destOf(fallbackIdx);
        }
        activeJobCount = active;
        jobsDone = active === 0 && finished > 0;
        jobIcon = icon;
        jobTitle = title;
        jobDesktopEntry = entry;
        jobDestUrl = dest;
        // A finished job stays in the model until somebody closes it. Leave it up long
        // enough to click through to the app, then close it so nothing piles up.
        // Not restarted on each update, so a busy model cannot postpone it forever.
        if (finished > 0 && !sweepJobs.running)
            sweepJobs.start();
    }
    function sweepFinishedJobs() {
        const N = NotificationManager.Notifications;
        for (let i = jobsModel.count - 1; i >= 0; --i) {
            const idx = jobsModel.index(i, 0);
            if (jobsModel.data(idx, N.JobStateRole) === N.JobStateStopped)
                jobsModel.close(idx);
        }
    }
    Timer {
        id: sweepJobs
        interval: 15000
        onTriggered: service.sweepFinishedJobs()
    }
    Component.onCompleted: refreshJobs()
    Connections {
        target: jobsModel
        function onCountChanged() { service.refreshJobs(); }
        function onDataChanged() { service.refreshJobs(); }
        function onModelReset() { service.refreshJobs(); }
    }

    property date clock: new Date()
    readonly property bool inhibitedByTime: notifSettings.notificationsInhibitedUntil !== undefined
        && !isNaN(notifSettings.notificationsInhibitedUntil) && notifSettings.notificationsInhibitedUntil > clock
    readonly property bool inhibited: inhibitedByTime || notifSettings.notificationsInhibitedByApplication
        || (notifSettings.inhibitNotificationsWhenScreensMirrored && notifSettings.screensMirrored)
        || (notifSettings.inhibitNotificationsWhenFullscreen && notifSettings.fullscreenFocused)

    // Do Not Disturb until a given time; Plasma ends it by itself then.
    function doNotDisturbUntil(date) {
        notifSettings.notificationsInhibitedUntil = date;
        notifSettings.save();
        clock = new Date();
    }
    function setDoNotDisturb(on) {
        if (on) {
            const d = new Date();
            d.setFullYear(d.getFullYear() + 1);
            notifSettings.notificationsInhibitedUntil = d;
        } else {
            notifSettings.notificationsInhibitedUntil = undefined;
            notifSettings.revokeApplicationInhibitions();
        }
        notifSettings.save();
        clock = new Date();
    }

    // Opening the history counts as reading everything in it.
    function markAllRead() {
        historyModel.lastRead = new Date();
    }
    function clearAll() {
        historyModel.clear(NotificationManager.Notifications.ClearExpired);
        // Unexpired ones still on screen go too.
        for (let i = historyModel.count - 1; i >= 0; --i) {
            const idx = historyModel.index(i, 0);
            if (historyModel.data(idx, NotificationManager.Notifications.ClosableRole))
                historyModel.close(idx);
        }
    }

    Timer {
        // Re-check a timed Do Not Disturb once a minute while one is set.
        running: notifSettings.notificationsInhibitedUntil !== undefined
        interval: 60000
        repeat: true
        onTriggered: service.clock = new Date()
    }

    NotificationManager.Settings {
        id: notifSettings
        live: true
    }

    // The server marks notifications that arrive during Do Not Disturb, so they skip popups later.
    Binding {
        target: NotificationManager.Server
        property: "inhibited"
        value: service.inhibited
        restoreMode: Binding.RestoreNone
    }

    NotificationManager.Notifications {
        id: historyModel
        showExpired: true
        showDismissed: true
        showJobs: false
        showNotifications: true
        sortMode: NotificationManager.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
        blacklistedDesktopEntries: notifSettings.historyBlacklistedApplications
        blacklistedNotifyRcNames: notifSettings.historyBlacklistedServices
        urgencies: notifSettings.lowPriorityHistory
            ? NotificationManager.Notifications.LowUrgency | NotificationManager.Notifications.NormalUrgency | NotificationManager.Notifications.CriticalUrgency
            : NotificationManager.Notifications.NormalUrgency | NotificationManager.Notifications.CriticalUrgency
    }

    // Jobs only, as Plasma's own notification applet reads them.
    NotificationManager.Notifications {
        id: jobsModel
        showExpired: false
        showDismissed: true
        showJobs: true
        showNotifications: false
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
    }

    NotificationManager.Notifications {
        id: popupModel
        limit: 3
        showExpired: false
        showDismissed: false
        showJobs: false
        showNotifications: true
        showAddedDuringInhibition: false
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
        blacklistedDesktopEntries: notifSettings.popupBlacklistedApplications
        blacklistedNotifyRcNames: notifSettings.popupBlacklistedServices
        whitelistedDesktopEntries: service.inhibited ? notifSettings.doNotDisturbPopupWhitelistedApplications : []
        whitelistedNotifyRcNames: service.inhibited ? notifSettings.doNotDisturbPopupWhitelistedServices : []
        urgencies: {
            const N = NotificationManager.Notifications;
            if (service.inhibited)
                return notifSettings.criticalPopupsInDoNotDisturbMode ? N.CriticalUrgency : 0;
            return notifSettings.lowPriorityPopups
                ? N.LowUrgency | N.NormalUrgency | N.CriticalUrgency
                : N.NormalUrgency | N.CriticalUrgency;
        }
    }

    // Toasts stack in one window at the screen corner on the dock's side.
    PlasmaCore.Dialog {
        id: toastWindow

        readonly property rect screen: Plasmoid.containment.screenGeometry
        readonly property rect avail: Plasmoid.containment.availableScreenRect
        readonly property bool dockOnTop: Plasmoid.location === PlasmaCore.Types.TopEdge
        readonly property int gap: Kirigami.Units.largeSpacing

        type: PlasmaCore.Dialog.Notification
        flags: Qt.WindowDoesNotAcceptFocus
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: false
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        visible: service.popupsEnabled && popupModel.count > 0

        x: screen.x + avail.x + avail.width - width - gap
        y: dockOnTop ? screen.y + avail.y + gap
            : screen.y + avail.y + avail.height - height - gap

        mainItem: Item {
            width: Kirigami.Units.gridUnit * 20
            // Layouts only settle once the window shows, so start from a minimum
            // height: Plasma refuses to show an empty (zero-height) dialog.
            height: Math.max(stack.implicitHeight, Kirigami.Units.gridUnit * 3)
            Kirigami.Theme.highlightColor: service.accent

            ColumnLayout {
                id: stack
                width: parent.width
                spacing: 0

                Repeater {
                    model: popupModel
                    delegate: ColumnLayout {
                        id: toastRow
                        required property var model
                        required property int index
                        Layout.fillWidth: true
                        spacing: 0

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            visible: toastRow.index > 0
                            opacity: 0.5
                        }
                        NotificationCard {
                            Layout.fillWidth: true
                            model: toastRow.model
                            notifications: popupModel
                            row: toastRow.index
                            popup: true
                            accent: service.accent
                            defaultTimeout: notifSettings.popupTimeout
                        }
                    }
                }
            }
        }
    }
}
