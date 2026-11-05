import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.ksysguard.sensors as Sensors
import "settings"
import "components"

// Sensor tiles, the battery source and the quick toggles.
KCM.SimpleKCM {
    id: page

    property int cfg_statsInterval
    property alias cfg_batteryDevice: batteryDevice.text
    property string cfg_toggleItems
    property string cfg_toggleStyle
    property alias cfg_scriptCommand: scriptCommand.text
    property alias cfg_scriptLabel: scriptLabel.text
    property alias cfg_scriptIcon: scriptIcon.text
    property alias cfg_scriptClickCommand: scriptClickCommand.text
    property int cfg_scriptInterval

    readonly property var intervals: [
        { ms: 1000, text: i18n("Every second") },
        { ms: 2000, text: i18n("Every 2 seconds (default)") },
        { ms: 5000, text: i18n("Every 5 seconds") },
        { ms: 10000, text: i18n("Every 10 seconds") },
        { ms: 30000, text: i18n("Every 30 seconds") }
    ]
    readonly property var scriptIntervals: [
        { seconds: 10, text: i18n("Every 10 seconds") },
        { seconds: 30, text: i18n("Every 30 seconds") },
        { seconds: 60, text: i18n("Every minute (default)") },
        { seconds: 300, text: i18n("Every 5 minutes") },
        { seconds: 900, text: i18n("Every 15 minutes") },
        { seconds: 3600, text: i18n("Every hour") }
    ]
    property string scriptResult
    readonly property var toggleKeys: [
        { key: "wifi", label: i18n("Wi-Fi"), icon: "network-wireless" },
        { key: "bluetooth", label: i18n("Bluetooth"), icon: "network-bluetooth" },
        { key: "dnd", label: i18n("Do Not Disturb"), icon: "notifications-disabled" },
        { key: "nightlight", label: i18n("Night Light"), icon: "redshift-status-on" },
        { key: "mute", label: i18n("Mute"), icon: "audio-volume-muted" },
        { key: "quickshare", label: i18n("Quick Share"), icon: "document-share" }
    ]
    property var batteries: []
    property bool scanned: false

    function toggleOn(key) {
        return cfg_toggleItems.split(",").map(k => k.trim()).indexOf(key) >= 0;
    }
    function setToggle(key, on) {
        const have = cfg_toggleItems.split(",").map(k => k.trim()).filter(k => k !== "");
        const next = toggleKeys.map(t => t.key).filter(k => k === key ? on : have.indexOf(k) >= 0);
        cfg_toggleItems = next.join(",");
    }

    readonly property string batteryCmd: "kstatsviewer --list 2>/dev/null | sed -n 's#^power/\\([^/ ]*\\)/chargePercentage .*#\\1#p'"

    Component.onCompleted: shell.run(batteryCmd)

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            page.batteries = out.split("\n").map(s => s.trim()).filter(s => s !== "");
            page.scanned = true;
        }
    }

    ShellRunner {
        id: scriptShell
        onFinished: (cmd, out, code, err) => {
            page.scriptResult = code === 124 ? i18n("Timed out after 30 seconds")
                : code !== 0 ? i18n("Exit code %1: %2", code, (err || out).trim())
                : (out.trim() || i18n("No output"));
        }
    }

    Sensors.Sensor {
        id: chargeSensor
        sensorId: batteryDevice.text.trim() !== "" ? "power/" + batteryDevice.text.trim() + "/chargePercentage" : ""
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        Card {
            title: i18n("Sensors")
            subtitle: i18n("How often the CPU, temperature, network and battery tiles update. Slower uses less power.")

            FormRow {
                label: i18n("Refresh:")
                QQC2.ComboBox {
                    id: intervalBox
                    // Keep a hand-set value from an older config selectable.
                    readonly property var options: page.intervals.some(o => o.ms === page.cfg_statsInterval)
                        ? page.intervals
                        : page.intervals.concat([{ ms: page.cfg_statsInterval, text: i18n("Every %1 ms", page.cfg_statsInterval) }])
                    model: options.map(o => o.text)
                    currentIndex: options.findIndex(o => o.ms === page.cfg_statsInterval)
                    onActivated: index => page.cfg_statsInterval = options[index].ms
                    Layout.fillWidth: true
                }
            }
        }

        Card {
            title: i18n("Battery")

            FormRow {
                label: i18n("Battery:")
                hint: page.scanned && page.batteries.length === 0
                    ? i18n("No battery found. Desktops without one can turn the Battery tile off.")
                    : ""
                QQC2.ComboBox {
                    visible: page.batteries.length > 0
                    model: page.batteries
                    currentIndex: page.batteries.indexOf(batteryDevice.text.trim())
                    displayText: currentIndex < 0 ? i18n("Custom") : currentText
                    onActivated: index => batteryDevice.text = page.batteries[index]
                    Layout.fillWidth: true
                }
                QQC2.TextField {
                    id: batteryDevice
                    visible: page.batteries.length === 0 || page.batteries.indexOf(text.trim()) < 0
                    placeholderText: "SerialNumber"
                    Layout.fillWidth: true
                }
                QQC2.ToolButton {
                    icon.name: "view-refresh"
                    onClicked: shell.run(page.batteryCmd)
                    QQC2.ToolTip.text: i18n("Scan again")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
            FormRow {
                label: i18n("Reading:")
                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        source: chargeSensor.value !== undefined ? "dialog-ok-apply" : "dialog-warning"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    QQC2.Label {
                        text: chargeSensor.value !== undefined
                            ? i18n("%1% charged", Math.round(chargeSensor.value))
                            : i18n("No reading from this device")
                        opacity: 0.8
                    }
                }
            }
        }

        Card {
            title: i18n("Script output")
            subtitle: i18n("The tile runs a shell command as your user. It shows the first line of the output big and the second line small. Commands stop after 30 seconds.")

            FormRow {
                label: i18n("Command:")
                hint: i18n("Example: checkupdates | wc -l")
                QQC2.TextField {
                    id: scriptCommand
                    font.family: "monospace"
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    text: i18n("Test")
                    icon.name: "media-playback-start"
                    enabled: scriptCommand.text.trim() !== ""
                    onClicked: {
                        page.scriptResult = "";
                        scriptShell.run("timeout -k 2 30 sh -c '" + scriptCommand.text.trim().replace(/'/g, "'\\''") + "'");
                    }
                }
            }
            FormRow {
                visible: page.scriptResult !== ""
                label: i18n("Result:")
                QQC2.Label {
                    text: page.scriptResult
                    font.family: "monospace"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            FormRow {
                label: i18n("Label:")
                QQC2.TextField {
                    id: scriptLabel
                    placeholderText: i18n("Script")
                    Layout.fillWidth: true
                }
            }
            FormRow {
                label: i18n("Icon name:")
                QQC2.TextField {
                    id: scriptIcon
                    Layout.fillWidth: true
                }
                Kirigami.Icon {
                    source: scriptIcon.text || "utilities-terminal"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
            }
            FormRow {
                label: i18n("Refresh:")
                QQC2.ComboBox {
                    // Keep a hand-set value from the config file selectable.
                    readonly property var options: page.scriptIntervals.some(o => o.seconds === page.cfg_scriptInterval)
                        ? page.scriptIntervals
                        : page.scriptIntervals.concat([{ seconds: page.cfg_scriptInterval, text: i18n("Every %1 seconds", page.cfg_scriptInterval) }])
                    model: options.map(o => o.text)
                    currentIndex: options.findIndex(o => o.seconds === page.cfg_scriptInterval)
                    onActivated: index => page.cfg_scriptInterval = options[index].seconds
                    Layout.fillWidth: true
                }
            }
            FormRow {
                label: i18n("On click:")
                hint: i18n("Leave empty to run the command again on click.")
                QQC2.TextField {
                    id: scriptClickCommand
                    font.family: "monospace"
                    Layout.fillWidth: true
                }
            }
        }

        Card {
            title: i18n("Quick toggles")
            subtitle: i18n("The Quick toggles tile.")

            FormRow {
                label: i18n("Style:")
                ColumnLayout {
                    spacing: 0
                    QQC2.RadioButton {
                        text: i18n("Status strip: icons only, click opens Quick Settings")
                        checked: page.cfg_toggleStyle !== "toggles"
                        onToggled: if (checked) page.cfg_toggleStyle = "strip"
                    }
                    QQC2.RadioButton {
                        text: i18n("Toggle row: each icon switches its setting")
                        checked: page.cfg_toggleStyle === "toggles"
                        onToggled: if (checked) page.cfg_toggleStyle = "toggles"
                    }
                }
            }
            FormRow {
                label: i18n("Show:")
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Repeater {
                        model: page.toggleKeys
                        QQC2.CheckBox {
                            required property var modelData
                            text: modelData.label
                            icon.name: modelData.icon
                            checked: page.toggleOn(modelData.key)
                            onToggled: page.setToggle(modelData.key, checked)
                        }
                    }
                }
            }
        }
    }
}
