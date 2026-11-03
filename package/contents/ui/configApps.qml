import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "settings"

// The application launcher and the dock's pinned apps.
KCM.SimpleKCM {
    id: page

    property bool cfg_launcherGridView
    property bool cfg_appsFromTaskManager
    property string cfg_appLaunchers
    property string cfg_launcherFavorites

    readonly property var preferred: ({
        "preferred://browser": { name: i18n("Default web browser"), icon: "internet-web-browser" },
        "preferred://filemanager": { name: i18n("Default file manager"), icon: "system-file-manager" },
        "preferred://mailer": { name: i18n("Default email client"), icon: "internet-mail" }
    })

    function split(s) {
        return s.split(",").map(x => x.trim()).filter(x => x !== "");
    }
    // "applications:org.kde.dolphin.desktop" -> "org.kde.dolphin"
    function desktopBase(id) {
        return id.replace(/^applications:/, "").replace(/^file:\/\/.*\//, "").replace(/\.desktop$/, "");
    }
    function appName(id) {
        if (preferred[id])
            return preferred[id].name;
        const last = desktopBase(id).split(".").pop().replace(/[-_]/g, " ");
        return last.charAt(0).toUpperCase() + last.slice(1);
    }
    function appIcon(id) {
        return preferred[id] ? preferred[id].icon : desktopBase(id);
    }
    // "firefox" or "firefox.desktop" -> "applications:firefox.desktop"
    function normalizeLauncher(t) {
        if (/^(preferred|file):\/\//.test(t) || t.startsWith("applications:"))
            return t;
        return "applications:" + (t.endsWith(".desktop") ? t : t + ".desktop");
    }
    // Same rule as the dock's drag-reorder: dock order first in the launcher's pins,
    // other pins kept after; an app removed from the dock is unpinned in the launcher too.
    function setDockApps(value) {
        const before = split(cfg_appLaunchers), docked = split(value);
        const removed = before.filter(id => docked.indexOf(id) < 0);
        const rest = split(cfg_launcherFavorites).filter(id => docked.indexOf(id) < 0 && removed.indexOf(id) < 0);
        cfg_appLaunchers = docked.join(",");
        cfg_launcherFavorites = docked.concat(rest).join(",");
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        Card {
            title: i18n("Application launcher")
            subtitle: i18n("Opens from the Start tile or the Meta key.")

            FormRow {
                label: i18n("Show apps as:")
                QQC2.RadioButton {
                    text: i18n("Grid")
                    checked: page.cfg_launcherGridView
                    onToggled: if (checked) page.cfg_launcherGridView = true
                }
                QQC2.RadioButton {
                    text: i18n("List")
                    checked: !page.cfg_launcherGridView
                    onToggled: if (checked) page.cfg_launcherGridView = false
                }
            }
        }

        Card {
            title: i18n("Pinned apps")
            subtitle: i18n("Apps on the dock. Running apps get a dot underneath. Pins stay in step with the launcher's pinned apps.")

            QQC2.RadioButton {
                text: i18n("Follow the Task Manager's pinned apps")
                checked: page.cfg_appsFromTaskManager
                onToggled: if (checked) page.cfg_appsFromTaskManager = true
            }
            QQC2.Label {
                text: i18n("Uses the first Task Manager in your panels. Falls back to your own list when there is none.")
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 1.5
            }
            QQC2.RadioButton {
                text: i18n("Use my own list")
                checked: !page.cfg_appsFromTaskManager
                onToggled: if (checked) page.cfg_appsFromTaskManager = false
            }
            StringListEditor {
                Layout.leftMargin: Kirigami.Units.gridUnit * 1.5
                enabled: !page.cfg_appsFromTaskManager
                opacity: enabled ? 1 : 0.5
                value: page.cfg_appLaunchers
                onEdited: v => page.setDockApps(v)
                iconFor: id => page.appIcon(id)
                labelFor: id => page.appName(id)
                normalize: t => page.normalizeLauncher(t)
                placeholder: i18n("Desktop file name, e.g. firefox or org.kde.kate")
                emptyText: i18n("No pinned apps. Pin apps from the launcher or add one below.")
            }
        }

        Card {
            title: i18n("Keyboard")

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: "input-keyboard"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: i18n("Meta+1 to Meta+9 open or switch to the pinned apps, in dock order.")
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    QQC2.Label {
                        text: i18n("Provided by the Dockyard Shortcuts KWin script. Meta alone opens the launcher.")
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                QQC2.Button {
                    icon.name: "preferences-desktop-keyboard-shortcut"
                    text: i18n("Shortcuts…")
                    onClicked: KCM.KCMLauncher.openSystemSettings("kcm_keys")
                }
            }
        }
    }
}
