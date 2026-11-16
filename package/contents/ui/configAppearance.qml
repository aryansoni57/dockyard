import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls
import "settings"
import "components"

// How the dock looks: bar or islands, glass material, accent color and the day and night look.
KCM.SimpleKCM {
    id: page

    property bool cfg_barOpaque
    property string cfg_dockLayout
    property string cfg_accentColor
    property bool cfg_syncSystemTheme
    property bool cfg_accentSurfaces
    property alias cfg_dayNightLook: dayNightLook.checked
    property string cfg_dayScheme
    property string cfg_nightScheme
    property var schemes: []

    readonly property string schemeCmd: "plasma-apply-colorscheme --list-schemes 2>/dev/null | sed -n 's/^ *\\* \\([^ ]*\\).*/\\1/p'"

    Component.onCompleted: schemeShell.run(schemeCmd)

    ShellRunner {
        id: schemeShell
        onFinished: (cmd, out) => page.schemes = out.split("\n").map(s => s.trim()).filter(s => s !== "")
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        Card {
            title: i18n("Layout")
            WidgetRow {
                text: i18n("Opaque dock bar")
                description: i18n("Solid instead of frosted glass")
                iconName: "preferences-desktop-theme-global-symbolic"
                accent: "#8E8E93"
                checked: page.cfg_barOpaque
                onToggled: page.cfg_barOpaque = checked
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Changes the dock bar when it is a desktop widget, and switches the Glass Plasma theme to Glass (opaque) if that is your theme. Run install-all.sh once to install both.")
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay * 2
            }
            FormRow {
                label: i18n("Layout")
                hint: i18n("Islands split the dock into floating pills. Right-click the dock and choose Add Separator to split a pill, drag a separator to move the gap, right-click it to remove it. In Bar mode separators show as thin dividers. Switches the Glass Plasma theme to a variant with no panel background, if Glass is your theme.")
                QQC2.RadioButton {
                    text: i18n("Bar")
                    checked: page.cfg_dockLayout !== "islands"
                    onToggled: if (checked) page.cfg_dockLayout = "bar"
                }
                QQC2.RadioButton {
                    text: i18n("Islands")
                    checked: page.cfg_dockLayout === "islands"
                    onToggled: if (checked) page.cfg_dockLayout = "islands"
                }
            }
        }

        Card {
            title: i18n("Accent")
            FormRow {
                label: i18n("Theme")
                hint: i18n("Ticked: the dock uses your system's accent color and the color picker below is locked. Unticked: pick the dock's own accent color.")
                QQC2.CheckBox {
                    text: i18n("Sync with system theme")
                    checked: page.cfg_syncSystemTheme
                    onToggled: page.cfg_syncSystemTheme = checked
                }
            }
            FormRow {
                label: i18n("Dock surfaces")
                hint: i18n("Washes the dock's tiles, bar and islands with the accent color. Unticked keeps the plain glass; buttons and highlights still use the accent.")
                QQC2.CheckBox {
                    text: i18n("Tint dock with the accent")
                    checked: page.cfg_accentSurfaces
                    onToggled: page.cfg_accentSurfaces = checked
                }
            }
            FormRow {
                label: i18n("Accent color")
                enabled: !page.cfg_syncSystemTheme
                hint: page.cfg_syncSystemTheme ? i18n("Locked while synced with the system theme.") : i18n("Colors the dock's buttons and highlights. Reset follows your Plasma theme.")
                KQuickControls.ColorButton {
                    color: /^#[0-9a-fA-F]{6}$/.test(page.cfg_accentColor) ? page.cfg_accentColor : Kirigami.Theme.highlightColor
                    showAlphaChannel: false
                    onAccepted: page.cfg_accentColor = Qt.color(color).toString().toLowerCase()
                }
                QQC2.Button {
                    text: i18n("Reset")
                    icon.name: "edit-undo"
                    enabled: page.cfg_accentColor !== ""
                    onClicked: page.cfg_accentColor = ""
                }
            }
        }

        Card {
            title: i18n("Day and night look")
            subtitle: i18n("Switches the Plasma color scheme at sunrise and sunset. The times come from the weather location, so set one in the Weather settings.")

            FormRow {
                label: i18n("Schedule:")
                QQC2.CheckBox {
                    id: dayNightLook
                    text: i18n("Follow sunrise and sunset")
                }
            }
            FormRow {
                label: i18n("Day:")
                enabled: dayNightLook.checked
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    model: page.schemes
                    currentIndex: page.schemes.indexOf(page.cfg_dayScheme)
                    displayText: currentIndex < 0 ? page.cfg_dayScheme : currentText
                    onActivated: index => page.cfg_dayScheme = page.schemes[index]
                }
            }
            FormRow {
                label: i18n("Night:")
                enabled: dayNightLook.checked
                QQC2.ComboBox {
                    Layout.fillWidth: true
                    model: page.schemes
                    currentIndex: page.schemes.indexOf(page.cfg_nightScheme)
                    displayText: currentIndex < 0 ? page.cfg_nightScheme : currentText
                    onActivated: index => page.cfg_nightScheme = page.schemes[index]
                }
            }
        }
    }
}
