import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// Power & Battery flyout: power profile, charge bar, battery health. Stands in for
// Plasma's own battery popup, which only exists inside the system tray. Profile and
// health come from powerprofilesctl and upower; the charge comes from the dock.
PlasmaCore.Dialog {
    id: fly

    property real percent: 0
    property bool charging: false

    signal settingsRequested()

    readonly property real unit: Kirigami.Units.gridUnit
    readonly property color accent: "#0A84FF"
    readonly property real panelWidth: Math.round(unit * 20)

    // Profiles in slider order, filtered to what the machine offers.
    property var profiles: ["power-saver", "balanced", "performance"]
    property string profile: "balanced"
    property string health: ""
    property string state: ""
    property string timeLeft: ""

    readonly property var profileLabels: ({
        "power-saver": i18n("Power Save"),
        "balanced": i18n("Balanced"),
        "performance": i18n("Performance")
    })
    readonly property string statusText: {
        const base = charging ? i18n("Charging") : (state === "fully-charged" || percent >= 100 ? i18n("Fully Charged") : i18n("Discharging"));
        return timeLeft !== "" ? base + " · " + timeLeft : base;
    }

    hideOnWindowDeactivate: true
    flags: Qt.Popup

    onVisibleChanged: if (visible) refresh()

    function refresh() {
        shell.run("p=$(upower -e | grep -m1 -i battery); powerprofilesctl get; echo '--'; "
                  + "powerprofilesctl list | grep -oE '^[ *]+[a-z-]+:' | tr -d ' *:'; echo '--'; "
                  + "upower -i \"$p\" | grep -E 'state:|capacity:|time to'");
    }

    function setProfile(name) {
        profile = name;
        shell.run("powerprofilesctl set " + name);
    }

    ShellRunner {
        id: shell
        onFinished: (cmd, out) => {
            if (cmd.indexOf("powerprofilesctl set") === 0)
                return;
            const parts = out.split("--\n");
            if (parts.length < 3)
                return;
            fly.profile = parts[0].trim() || fly.profile;
            const names = parts[1].split("\n").map(s => s.trim()).filter(s => s !== "");
            const order = ["power-saver", "balanced", "performance"].filter(n => names.indexOf(n) >= 0);
            if (order.length > 0)
                fly.profiles = order;
            const get = re => { const m = parts[2].match(re); return m ? m[1].trim() : ""; };
            fly.state = get(/state:\s*(.+)/);
            const cap = get(/capacity:\s*(\S+)/);
            fly.health = cap;
            fly.timeLeft = get(/time to (?:empty|full):\s*(.+)/);
        }
    }

    mainItem: Item {
        id: panel
        implicitWidth: fly.panelWidth
        implicitHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight

        Keys.onEscapePressed: fly.visible = false
        focus: fly.visible

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // ---- power profile ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: i18n("Power Profile")
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    QQC2.Label {
                        text: fly.profileLabels[fly.profile] ?? fly.profile
                        opacity: 0.8
                    }
                }

                QQC2.Slider {
                    id: profileSlider
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, fly.profiles.length - 1)
                    stepSize: 1
                    snapMode: QQC2.Slider.SnapAlways
                    value: Math.max(0, fly.profiles.indexOf(fly.profile))
                    onMoved: fly.setProfile(fly.profiles[Math.round(value)])

                    background: Rectangle {
                        x: profileSlider.leftPadding
                        y: profileSlider.topPadding + profileSlider.availableHeight / 2 - height / 2
                        width: profileSlider.availableWidth
                        height: Math.round(fly.unit * 0.4)
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                    }
                    handle: Rectangle {
                        x: profileSlider.leftPadding + profileSlider.visualPosition * (profileSlider.availableWidth - width)
                        y: profileSlider.topPadding + profileSlider.availableHeight / 2 - height / 2
                        width: Math.round(fly.unit * 1.1)
                        height: width
                        radius: width / 2
                        color: "white"
                        border.width: 1
                        border.color: Qt.alpha("black", 0.15)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: fly.profiles
                        delegate: QQC2.Label {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            horizontalAlignment: index === 0 ? Text.AlignLeft
                                : index === fly.profiles.length - 1 ? Text.AlignRight : Text.AlignHCenter
                            text: fly.profileLabels[modelData] ?? modelData
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            opacity: modelData === fly.profile ? 1 : 0.55
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: fly.setProfile(modelData)
                            }
                        }
                    }
                }
            }

            // ---- battery ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: i18n("Battery")
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    QQC2.Label {
                        text: fly.statusText
                        opacity: 0.8
                    }
                    QQC2.Label {
                        text: Math.round(fly.percent) + "%"
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(fly.unit * 0.4)
                    radius: height / 2
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, fly.percent)) / 100
                        height: parent.height
                        radius: height / 2
                        color: fly.charging ? Kirigami.Theme.positiveTextColor
                            : fly.percent < 20 ? Kirigami.Theme.negativeTextColor : fly.accent
                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: fly.health !== ""
                    QQC2.Label {
                        text: i18n("Battery Health:")
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
                    }
                    Item { Layout.fillWidth: true }
                    QQC2.Label {
                        text: fly.health
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
                    }
                }
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignRight
                icon.name: "configure"
                text: i18n("Configure…")
                flat: true
                onClicked: {
                    fly.visible = false;
                    fly.settingsRequested();
                }
            }
        }
    }
}
