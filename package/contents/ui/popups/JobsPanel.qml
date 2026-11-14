pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.notificationmanager as NotificationManager

// Jobs popup: one row per running job with its app, title, progress bar,
// and pause/resume and stop buttons.
ColumnLayout {
    id: panel

    property var applet
    readonly property var service: applet.notificationService
    readonly property var jobs: service.jobs

    spacing: 0
    implicitHeight: header.implicitHeight + Kirigami.Units.largeSpacing * 2
        + (service.jobCount > 0
            ? Math.min(list.contentHeight, Kirigami.Units.gridUnit * 18)
            : placeholder.implicitHeight + Kirigami.Units.largeSpacing * 2)

    RowLayout {
        id: header
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "folder-download-symbolic"
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: i18n("Jobs")
            font.weight: Font.DemiBold
        }
        PlasmaComponents.Label {
            visible: panel.service.activeJobCount > 0
            text: panel.service.jobsPercent + "%"
            opacity: 0.6
            font.features: { "tnum": 1 }
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: panel.service.jobCount > 0
        clip: true
        interactive: contentHeight > height
        spacing: Kirigami.Units.smallSpacing
        leftMargin: Kirigami.Units.largeSpacing
        rightMargin: Kirigami.Units.largeSpacing
        model: panel.jobs

        delegate: ColumnLayout {
            id: job

            required property int index
            required property var model
            readonly property var m: job.model ? job.model : ({})
            readonly property int jobState: m?.jobState ?? NotificationManager.Notifications.JobStateRunning
            readonly property bool running: jobState === NotificationManager.Notifications.JobStateRunning
            readonly property bool suspended: jobState === NotificationManager.Notifications.JobStateSuspended
            readonly property bool stopped: jobState === NotificationManager.Notifications.JobStateStopped

            width: list.width - list.leftMargin - list.rightMargin
            spacing: Kirigami.Units.smallSpacing / 2

            // Details the sender reports: sizes, speed, file counts and the two description lines.
            readonly property var d: m?.jobDetails ?? null
            readonly property real speed: d?.speed ?? 0
            readonly property real doneBytes: d?.processedBytes ?? 0
            readonly property real allBytes: d?.totalBytes ?? 0
            readonly property string sizeText: allBytes > 0
                ? i18n("%1 of %2", KCoreAddons.Format.formatByteSize(doneBytes), KCoreAddons.Format.formatByteSize(allBytes))
                : (doneBytes > 0 ? KCoreAddons.Format.formatByteSize(doneBytes) : "")
            readonly property string speedText: running && speed > 0 ? i18n("%1/s", KCoreAddons.Format.formatByteSize(speed)) : ""
            readonly property string filesText: (d?.totalFiles ?? 0) > 0
                ? i18n("%1 of %2 files", d.processedFiles, d.totalFiles)
                : ((d?.totalItems ?? 0) > 0 ? i18n("%1 of %2 items", d.processedItems, d.totalItems) : "")
            readonly property string leftText: running && speed > 0 && allBytes > doneBytes
                ? i18n("%1 left", KCoreAddons.Format.formatDuration(Math.round((allBytes - doneBytes) / speed * 1000)))
                : ""
            readonly property string statsText: [sizeText, speedText, filesText, leftText].filter(t => t !== "").join("  ·  ")

            // Tapping the app icon or title opens the job's destination folder.
            function openApp() {
                const dest = job.d?.effectiveDestUrl || job.d?.destUrl;
                panel.applet.openJob(dest ? dest.toString() : "", job.m?.desktopEntry);
                panel.applet.dockItem.hide();
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: job.m?.applicationIconName || "document-save"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    TapHandler {
                        onTapped: job.openApp()
                    }
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: job.m?.summary || job.m?.applicationName || ""
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                    TapHandler {
                        onTapped: job.openApp()
                    }
                }
                PlasmaComponents.ToolButton {
                    visible: !job.stopped && (job.m?.suspendable ?? false)
                    icon.name: job.suspended ? "media-playback-start-symbolic" : "media-playback-pause-symbolic"
                    text: job.suspended ? i18n("Resume") : i18n("Pause")
                    display: QQC2.AbstractButton.IconOnly
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: {
                        const idx = panel.jobs.index(job.index, 0);
                        if (job.suspended)
                            panel.jobs.resumeJob(idx);
                        else
                            panel.jobs.suspendJob(idx);
                    }
                }
                PlasmaComponents.ToolButton {
                    visible: job.stopped
                    icon.name: "window-close-symbolic"
                    text: i18n("Dismiss")
                    display: QQC2.AbstractButton.IconOnly
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: panel.jobs.close(panel.jobs.index(job.index, 0))
                }
                PlasmaComponents.ToolButton {
                    visible: !job.stopped && (job.m?.killable ?? false)
                    icon.name: "process-stop-symbolic"
                    text: i18n("Stop")
                    display: QQC2.AbstractButton.IconOnly
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: panel.jobs.killJob(panel.jobs.index(job.index, 0))
                }
            }

            PlasmaComponents.ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: job.stopped ? 100 : (job.m?.percentage ?? 0)
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: job.stopped ? i18n("Finished")
                    : job.suspended ? i18n("Paused at %1%", job.m?.percentage ?? 0)
                    : i18n("%1%", job.m?.percentage ?? 0)
                opacity: 0.6
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: job.statsText !== ""
                text: job.statsText
                opacity: 0.6
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.features: { "tnum": 1 }
                wrapMode: Text.Wrap
            }
            // The sender's own lines, usually From and To.
            Repeater {
                model: [
                    { label: job.d?.descriptionLabel1 ?? "", value: job.d?.descriptionValue1 ?? "" },
                    { label: job.d?.descriptionLabel2 ?? "", value: job.d?.descriptionValue2 ?? "" }
                ].filter(r => r.value !== "")

                delegate: PlasmaComponents.Label {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.label !== "" ? i18n("%1: %2", modelData.label, modelData.value) : modelData.value
                    elide: Text.ElideMiddle
                    opacity: 0.6
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
        }
    }

    Kirigami.PlaceholderMessage {
        id: placeholder
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        visible: panel.service.jobCount === 0
        icon.name: "folder-download-symbolic"
        text: i18n("No jobs running")
    }
}
