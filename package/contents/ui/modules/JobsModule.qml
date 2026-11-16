import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import "../components"
import "../components/motion.js" as Motion
import "../components/accent"

// Job pill, after AvdanOS's render pill: the app's icon, the job's title over a
// thin progress bar with the percent, and a round count badge when several jobs run.
// main.qml hides it when no job is running, so it takes no room. Tap opens the list;
// right-click opens a menu whose items follow the job: stop it, or open, copy and show what it made.
Tile {
    id: pill

    property int count: 0
    property int percent: 0
    property string iconName: ""
    property string title: ""
    // Every job has ended. The pill stays up, full, saying so.
    property bool done: false

    // The notification service, for the job the menu acts on.
    property var service: null
    // Asks main.qml to open a job's folder or raise its app, and to show the full list.
    signal openRequested(string url, string entry)
    signal listRequested(Item source)

    // Snapshot of the job taken when the menu opens (see NotificationService.pillJob).
    property var mj: null
    property double menuClosedAt: 0

    function shq(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }
    function localPath(url) {
        return decodeURIComponent(String(url).replace(/^file:\/\//, ""));
    }
    function menuPlacement() {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge:
            return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        case PlasmaCore.Types.LeftEdge:
            return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        case PlasmaCore.Types.RightEdge:
            return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        default:
            return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }
    function openMenu() {
        if (!service)
            return;
        mj = service.pillJob();
        if (!mj)
            return;
        service.holdSweep = true;
        jobMenu.visualParent = pill;
        jobMenu.placement = menuPlacement();
        jobMenu.openRelative();
    }

    ShellRunner { id: runner }

    // Right-click only; the tile's own tap handler keeps the left button.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: pill.openMenu()
    }

    PlasmaExtras.Menu {
        id: jobMenu
        onStatusChanged: {
            if (status === PlasmaExtras.Menu.Closed) {
                pill.menuClosedAt = Date.now();
                if (pill.service)
                    pill.service.holdSweep = false;
            }
        }

        PlasmaExtras.MenuItem {
            text: pill.mj ? pill.mj.title : ""
            enabled: false
            visible: pill.mj !== null && pill.mj.title !== ""
        }
        PlasmaExtras.MenuItem {
            text: pill.mj ? pill.mj.errorText : ""
            icon: "dialog-error"
            enabled: false
            visible: pill.mj !== null && pill.mj.stopped && pill.mj.error !== 0 && pill.mj.errorText !== ""
        }
        PlasmaExtras.MenuItem {
            text: i18n("Open")
            icon: "document-open"
            visible: pill.mj !== null && pill.mj.stopped && pill.mj.error === 0
            onClicked: {
                if (pill.mj.file !== "")
                    runner.run("xdg-open " + pill.shq(pill.mj.file));
                else
                    pill.openRequested(pill.mj.folder, pill.mj.entry);
            }
        }
        PlasmaExtras.MenuItem {
            text: i18n("Open containing folder")
            icon: "folder-open"
            visible: pill.mj !== null && pill.mj.folder !== "" && (!pill.mj.stopped || pill.mj.error === 0)
            onClicked: {
                // Selects the file when the file manager supports it, else just opens the folder.
                if (pill.mj.file !== "")
                    runner.run("dbus-send --session --type=method_call --dest=org.freedesktop.FileManager1 "
                        + "/org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"
                        + pill.shq(pill.mj.file) + " string:'' || xdg-open " + pill.shq(pill.mj.folder));
                else
                    runner.run("xdg-open " + pill.shq(pill.mj.folder));
            }
        }
        PlasmaExtras.MenuItem { separator: true; visible: copyFile.visible }
        PlasmaExtras.MenuItem {
            id: copyFile
            text: i18n("Copy file")
            icon: "edit-copy"
            visible: pill.mj !== null && pill.mj.stopped && pill.mj.error === 0 && pill.mj.file !== ""
            // A uri-list on the clipboard pastes as a file copy in Dolphin and other file managers.
            onClicked: runner.run("printf '%s\\r\\n' " + pill.shq(pill.mj.file) + " | wl-copy --type text/uri-list")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Copy path")
            icon: "edit-copy-path"
            visible: pill.mj !== null && pill.mj.stopped && pill.mj.error === 0 && (pill.mj.file !== "" || pill.mj.folder !== "")
            onClicked: runner.run("printf %s " + pill.shq(pill.localPath(pill.mj.file !== "" ? pill.mj.file : pill.mj.folder)) + " | wl-copy")
        }
        PlasmaExtras.MenuItem { separator: true; visible: pauseItem.visible || stopItem.visible }
        PlasmaExtras.MenuItem {
            id: pauseItem
            text: pill.mj && pill.mj.suspended ? i18n("Resume") : i18n("Pause")
            icon: pill.mj && pill.mj.suspended ? "media-playback-start" : "media-playback-pause"
            visible: pill.mj !== null && !pill.mj.stopped && pill.mj.suspendable
            onClicked: pill.service.jobAction(pill.mj.id, pill.mj.suspended ? "resume" : "suspend")
        }
        PlasmaExtras.MenuItem {
            id: stopItem
            text: i18n("Cancel")
            icon: "process-stop"
            visible: pill.mj !== null && !pill.mj.stopped && pill.mj.killable
            onClicked: pill.service.jobAction(pill.mj.id, "kill")
        }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem {
            text: i18n("Show all jobs")
            icon: "view-list-details"
            onClicked: pill.listRequested(pill)
        }
        PlasmaExtras.MenuItem {
            text: i18n("Dismiss")
            icon: "window-close"
            visible: pill.mj !== null && pill.mj.stopped
            onClicked: pill.service.jobAction(pill.mj.id, "close")
        }
    }

    readonly property real inner: height - padding * 2
    readonly property real textSize: Math.max(Kirigami.Theme.smallFont.pixelSize, inner * 0.3)

    implicitWidth: row.implicitWidth + padding * 2

    RowLayout {
        id: row
        anchors.centerIn: parent
        height: pill.inner
        spacing: pill.padding

        Kirigami.Icon {
            Layout.preferredWidth: Math.round(pill.inner * 0.62)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            source: pill.iconName
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.max(1, pill.padding * 0.2)

            PlasmaComponents.Label {
                Layout.maximumWidth: Kirigami.Units.gridUnit * 7
                text: pill.title
                elide: Text.ElideRight
                font.pixelSize: pill.textSize
                font.weight: Font.DemiBold
            }
            RowLayout {
                spacing: pill.padding * 0.6

                PlasmaComponents.Label {
                    text: pill.done ? i18n("Finished") : pill.percent + "%"
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize * 0.9, pill.inner * 0.24)
                    font.features: { "tnum": 1 }
                    opacity: 0.78
                }
                Rectangle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Math.max(3, pill.inner * 0.09)
                    Layout.alignment: Qt.AlignVCenter
                    radius: height / 2
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.18)

                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        color: DockAccent.color
                        width: pill.done ? parent.width : parent.width * Math.max(0, Math.min(100, pill.percent)) / 100

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.ms(Motion.enterMs, Kirigami.Units.longDuration)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.enter
                            }
                        }
                    }
                }
            }
        }

        // Count badge, only when more than one job runs.
        Rectangle {
            visible: pill.count > 1
            Layout.preferredWidth: Math.round(pill.inner * 0.5)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

            Text {
                anchors.centerIn: parent
                text: pill.count
                color: Kirigami.Theme.textColor
                font.pixelSize: parent.height * 0.55
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }
    }
}
