import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Quick settings flyout (docs/mockups/quick-settings.html): a 2x2 grid of toggle
// cards, brightness and volume sliders, and Wi-Fi / Bluetooth detail views that
// slide in over the main view. A dumb view over ToggleSource (`source`); the
// anchoring tile sets `visualParent` and `location`.
PlasmaCore.Dialog {
    id: fly

    property var source: null
    // "main", "wifi" or "bluetooth"
    property string view: "main"

    signal settingsRequested()

    readonly property real unit: Kirigami.Units.gridUnit
    // Set by the host tile to follow the dock accent.
    property color accent: "#0A84FF"
    readonly property color cardColor: Qt.alpha(Kirigami.Theme.textColor, 0.07)
    readonly property real panelWidth: Math.round(unit * 20)

    hideOnWindowDeactivate: true
    flags: Qt.Popup

    onVisibleChanged: {
        if (!visible) {
            view = "main";
            if (source)
                source.dragging = false;
        }
    }
    onViewChanged: {
        if (!source)
            return;
        if (view === "wifi")
            source.scanNetworks();
        else if (view === "bluetooth")
            source.scanDevices();
    }

    function iconUrl(name) {
        return Qt.resolvedUrl("../../icons/" + name + ".svg");
    }

    function item(key) {
        const list = source ? source.items : [];
        for (let i = 0; i < list.length; i++)
            if (list[i].key === key)
                return list[i];
        return ({});
    }

    // Always the four cards, whatever the tile row is configured to show, plus
    // Quick Share when rquickshare is installed.
    readonly property var cards: baseCards.concat(source && source.qsAvailable ? [
        { key: "quickshare", label: "Quick Share", icon: "share", on: source.qsOn,
          sub: source.qsOn ? i18n("Open, nearby devices can find you") : i18n("Off"), detail: "" }
    ] : [])
    readonly property var baseCards: [
        { key: "wifi", label: "Wi-Fi", icon: source && source.wifiOn ? "wifi" : "wifi-off", on: !!source && source.wifiOn,
          sub: !source ? "" : !source.wifiOn ? i18n("Off") : source.ssid !== "" ? source.ssid : i18n("Not connected"), detail: "wifi" },
        { key: "bluetooth", label: "Bluetooth", icon: source && source.btOn ? "bluetooth" : "bluetooth-off", on: !!source && source.btOn,
          sub: !source ? "" : !source.btOn ? i18n("Off") : source.btDevice !== "" ? source.btDevice : i18n("On"), detail: "bluetooth" },
        { key: "dnd", label: i18n("Do Not Disturb"), icon: "moon-dnd", on: !!source && source.dndOn,
          sub: source && source.dndOn ? i18n("On") : i18n("Off"), detail: "" },
        { key: "nightlight", label: i18n("Night Light"), icon: "night-light", on: !!source && source.nightOn,
          sub: !source ? "" : !source.nightAvailable ? i18n("Unavailable") : source.nightOn ? i18n("On") : i18n("Off"), detail: "" }
    ]

    mainItem: Item {
        id: panel
        // Set at once (no animation): the dialog refuses to show a zero-sized item.
        implicitWidth: fly.panelWidth
        implicitHeight: fly.view === "main" ? mainView.implicitHeight : detailView.implicitHeight
        // The dialog follows these as the content changes size.
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        clip: true

        Keys.onEscapePressed: {
            if (fly.view !== "main")
                fly.view = "main";
            else
                fly.visible = false;
        }
        focus: fly.visible

        // ---- main view ----
        ColumnLayout {
            id: mainView
            width: panel.width
            x: fly.view === "main" ? 0 : -panel.width * 0.3
            opacity: fly.view === "main" ? 1 : 0
            visible: opacity > 0
            spacing: Kirigami.Units.smallSpacing * 2

            Behavior on x {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 2
                columnSpacing: Kirigami.Units.smallSpacing * 1.5
                rowSpacing: Kirigami.Units.smallSpacing * 1.5

                Repeater {
                    model: fly.cards

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        // An odd last card takes the whole row.
                        Layout.columnSpan: index === fly.cards.length - 1 && fly.cards.length % 2 === 1 ? 2 : 1
                        Layout.preferredWidth: 1
                        implicitHeight: Math.round(fly.unit * 3.3)
                        radius: Math.round(fly.unit * 0.7)
                        color: cardHover.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.11) : fly.cardColor

                        Behavior on color {
                            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        HoverHandler {
                            id: cardHover
                        }

                        // Icon circle: toggles. Label area: opens the list when there is one.
                        Rectangle {
                            id: circle
                            x: Kirigami.Units.smallSpacing * 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(fly.unit * 1.9)
                            height: width
                            radius: width / 2
                            color: card.modelData.on ? fly.accent : Qt.alpha(Kirigami.Theme.textColor, 0.12)
                            scale: circleTap.pressed ? 0.94 : 1

                            Behavior on color {
                                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: 80 }
                            }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: Math.round(parent.width * 0.55)
                                height: width
                                source: fly.iconUrl(card.modelData.icon)
                                isMask: true
                                color: card.modelData.on ? "white" : Kirigami.Theme.textColor
                            }

                            TapHandler {
                                id: circleTap
                                onTapped: fly.source.toggle(card.modelData.key)
                            }
                        }

                        Item {
                            anchors.left: circle.right
                            anchors.leftMargin: Kirigami.Units.smallSpacing * 1.5
                            anchors.right: parent.right
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            scale: labelTap.pressed ? 0.97 : 1

                            Behavior on scale {
                                NumberAnimation { duration: 80 }
                            }

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: chev.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: card.modelData.label
                                    font.pixelSize: Math.round(fly.unit * 0.72)
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: card.modelData.sub
                                    font.pixelSize: Math.round(fly.unit * 0.66)
                                    opacity: 0.6
                                    elide: Text.ElideRight
                                }
                            }

                            Kirigami.Icon {
                                id: chev
                                visible: card.modelData.detail !== ""
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.round(fly.unit * 0.8)
                                height: width
                                source: fly.iconUrl("chevron-right")
                                isMask: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.4
                            }

                            TapHandler {
                                id: labelTap
                                onTapped: {
                                    if (card.modelData.detail !== "")
                                        fly.view = card.modelData.detail;
                                    else
                                        fly.source.toggle(card.modelData.key);
                                }
                            }
                        }
                    }
                }
            }

            // Brightness (one slider; the label cycles displays when there are several).
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
                Layout.rightMargin: Kirigami.Units.smallSpacing * 1.5
                visible: !!fly.source && fly.source.displays.length > 0
                spacing: Kirigami.Units.smallSpacing

                // Monitor button: with several displays it opens a menu to pick the one the slider drives.
                Rectangle {
                    id: monitorBtn
                    readonly property bool multi: !!fly.source && fly.source.displays.length > 1
                    Layout.preferredWidth: Math.round(fly.unit * (multi ? 2.6 : 1.6))
                    Layout.preferredHeight: Math.round(fly.unit * 1.6)
                    radius: height / 2
                    color: monTap.pressed ? Qt.alpha(Kirigami.Theme.textColor, 0.14)
                         : monHover.hovered && multi ? Qt.alpha(Kirigami.Theme.textColor, 0.08) : "transparent"
                    scale: monTap.pressed && multi ? 0.94 : 1

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Kirigami.Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(fly.unit * 1.15)
                            height: width
                            source: monitorBtn.multi && fly.source.displays[fly.source.displayIndex].internal
                                ? "computer-laptop-symbolic" : "video-display-brightness-symbolic"
                            isMask: true
                            color: Kirigami.Theme.textColor
                            opacity: 0.8
                        }
                        Kirigami.Icon {
                            visible: monitorBtn.multi
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(fly.unit * 0.7)
                            height: width
                            source: "arrow-down"
                            isMask: true
                            color: Kirigami.Theme.textColor
                            opacity: 0.5
                        }
                    }

                    HoverHandler {
                        id: monHover
                    }
                    TapHandler {
                        id: monTap
                        enabled: monitorBtn.multi
                        onTapped: displayMenu.popup(monitorBtn, 0, -displayMenu.implicitHeight)
                    }

                    QQC2.Menu {
                        id: displayMenu
                        popupType: QQC2.Popup.Window

                        Repeater {
                            model: fly.source ? fly.source.displays : []

                            QQC2.MenuItem {
                                required property var modelData
                                required property int index
                                text: modelData.label
                                checkable: true
                                checked: !!fly.source && fly.source.displayIndex === index
                                onTriggered: fly.source.displayIndex = index
                            }
                        }
                    }
                }
                PillSlider {
                    Layout.fillWidth: true
                    value: fly.source && fly.source.displays.length > 0 ? fly.source.displays[fly.source.displayIndex].value : 0
                    onDraggingChanged: fly.source.dragging = dragging
                    onCommit: v => fly.source.setBrightness(v)
                }
                PlasmaComponents.Label {
                    Layout.preferredWidth: Math.round(fly.unit * 2.2)
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(fly.source && fly.source.displays.length > 0 ? fly.source.displays[fly.source.displayIndex].value : 0) + "%"
                    font.pixelSize: Math.round(fly.unit * 0.66)
                    font.features: { "tnum": 1 }
                    opacity: 0.6
                }
            }

            // Volume: the speaker button mutes.
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
                Layout.rightMargin: Kirigami.Units.smallSpacing * 1.5
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    Layout.preferredWidth: Math.round(fly.unit * 1.6)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: muteTap.pressed ? Qt.alpha(Kirigami.Theme.textColor, 0.14)
                         : muteHover.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.08) : "transparent"
                    scale: muteTap.pressed ? 0.94 : 1

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Math.round(fly.unit * 1.15)
                        height: width
                        source: fly.iconUrl(fly.source && (fly.source.muted || fly.source.volume === 0) ? "speaker-muted" : "speaker")
                        isMask: true
                        color: fly.source && fly.source.muted ? fly.accent : Kirigami.Theme.textColor
                    }
                    HoverHandler {
                        id: muteHover
                    }
                    TapHandler {
                        id: muteTap
                        onTapped: fly.source.toggle("mute")
                    }
                }
                PillSlider {
                    Layout.fillWidth: true
                    dimmed: !!fly.source && fly.source.muted
                    value: fly.source ? fly.source.volume : 0
                    onDraggingChanged: fly.source.dragging = dragging
                    onCommit: v => fly.source.setVolume(v)
                }
                PlasmaComponents.Label {
                    Layout.preferredWidth: Math.round(fly.unit * 2.2)
                    horizontalAlignment: Text.AlignRight
                    text: fly.source && fly.source.muted ? i18n("Muted") : (fly.source ? fly.source.volume : 0) + "%"
                    font.pixelSize: Math.round(fly.unit * 0.66)
                    font.features: { "tnum": 1 }
                    opacity: 0.6
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing * 1.5
                Layout.rightMargin: Kirigami.Units.smallSpacing * 1.5
                Layout.bottomMargin: Kirigami.Units.smallSpacing * 1.5

                Item {
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: settingsLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                    implicitHeight: Math.round(fly.unit * 1.6)
                    radius: height / 2
                    color: settingsTap.pressed ? Qt.alpha(Kirigami.Theme.textColor, 0.16) : fly.cardColor
                    scale: settingsTap.pressed ? 0.97 : 1

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 80 }
                    }

                    PlasmaComponents.Label {
                        id: settingsLabel
                        anchors.centerIn: parent
                        text: i18n("System Settings")
                        font.pixelSize: Math.round(fly.unit * 0.7)
                    }
                    TapHandler {
                        id: settingsTap
                        onTapped: {
                            fly.visible = false;
                            fly.settingsRequested();
                        }
                    }
                }
            }
        }

        // ---- detail view (Wi-Fi list or Bluetooth list) ----
        ColumnLayout {
            id: detailView
            width: panel.width
            x: fly.view === "main" ? panel.width * 0.3 : 0
            opacity: fly.view === "main" ? 0 : 1
            visible: opacity > 0
            spacing: 0

            // Wi-Fi network awaiting a password.
            property string pending: ""
            readonly property bool isWifi: fly.view === "wifi"

            Behavior on x {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
            onIsWifiChanged: pending = ""

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    Layout.preferredWidth: Math.round(fly.unit * 1.7)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: backTap.pressed ? Qt.alpha(Kirigami.Theme.textColor, 0.16)
                         : backHover.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.08) : "transparent"

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Math.round(fly.unit * 1.0)
                        height: width
                        source: "go-previous-symbolic"
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }
                    HoverHandler {
                        id: backHover
                    }
                    TapHandler {
                        id: backTap
                        onTapped: fly.view = "main"
                    }
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: detailView.isWifi ? "Wi-Fi" : "Bluetooth"
                    font.weight: Font.DemiBold
                }
                PlasmaComponents.Label {
                    visible: !!fly.source && fly.source.scanning
                    text: i18n("Scanning…")
                    font.pixelSize: Math.round(fly.unit * 0.66)
                    opacity: 0.6
                }
                QQC2.Switch {
                    checked: fly.source ? (detailView.isWifi ? fly.source.wifiOn : fly.source.btOn) : false
                    onToggled: fly.source.toggle(detailView.isWifi ? "wifi" : "bluetooth")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                visible: !!fly.source && fly.source.netStatus !== "" && detailView.isWifi
                text: fly.source ? fly.source.netStatus : ""
                color: fly.source && fly.source.netStatus.indexOf("…") < 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                font.pixelSize: Math.round(fly.unit * 0.7)
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, Math.round(fly.unit * 16))
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: !fly.source ? [] : detailView.isWifi ? (fly.source.wifiOn ? fly.source.networks : []) : (fly.source.btOn ? fly.source.devices : [])

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                delegate: Item {
                    id: entry
                    required property var modelData
                    readonly property bool wifi: detailView.isWifi
                    readonly property bool connected: wifi ? modelData.active : modelData.connected
                    readonly property bool asking: wifi && detailView.pending === modelData.ssid
                    // Secured and never saved: the password comes first.
                    readonly property bool needsPassword: wifi && modelData.secure && !modelData.known
                    width: ListView.view.width
                    height: rowItem.height + (asking ? (needsPassword ? pwRow.height : actionRow.height) : 0)

                    Behavior on height {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: rowItem
                        width: parent.width
                        height: Math.round(fly.unit * 2.6)
                        color: rowTap.pressed ? Qt.alpha(Kirigami.Theme.textColor, 0.12)
                             : rowHover.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.07) : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.largeSpacing
                            anchors.rightMargin: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.smallSpacing * 1.5

                            Rectangle {
                                Layout.preferredWidth: Math.round(fly.unit * 1.6)
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: width / 2
                                color: entry.connected ? fly.accent : Qt.alpha(Kirigami.Theme.textColor, 0.1)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Math.round(parent.width * 0.58)
                                    height: width
                                    source: entry.wifi ? "network-wireless-symbolic" : (entry.modelData.icon || "bluetooth")
                                    isMask: entry.wifi
                                    color: entry.connected ? "white" : Kirigami.Theme.textColor
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: entry.wifi ? entry.modelData.ssid : entry.modelData.name
                                    font.weight: entry.connected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: entry.wifi
                                        ? (entry.connected ? i18n("Connected") : entry.modelData.known ? i18n("Saved") : entry.modelData.secure ? i18n("Secured") : i18n("Open"))
                                          + " · " + entry.modelData.signal + "%"
                                        : (entry.connected ? i18n("Connected") : i18n("Paired"))
                                          + (entry.modelData.battery >= 0 ? " · " + entry.modelData.battery + "%" : "")
                                    font.pixelSize: Math.round(fly.unit * 0.62)
                                    color: entry.connected ? fly.accent : Kirigami.Theme.textColor
                                    opacity: entry.connected ? 1 : 0.55
                                    elide: Text.ElideRight
                                }
                            }
                            Kirigami.Icon {
                                visible: entry.wifi && entry.modelData.secure
                                Layout.preferredWidth: Math.round(fly.unit * 0.8)
                                Layout.preferredHeight: Layout.preferredWidth
                                source: "object-locked-symbolic"
                                isMask: true
                                color: Kirigami.Theme.textColor
                                opacity: 0.45
                            }
                            Kirigami.Icon {
                                visible: entry.connected
                                Layout.preferredWidth: Math.round(fly.unit * 0.9)
                                Layout.preferredHeight: Layout.preferredWidth
                                source: "dialog-ok-apply-symbolic"
                                isMask: true
                                color: fly.accent
                            }
                        }

                        HoverHandler {
                            id: rowHover
                        }
                        TapHandler {
                            id: rowTap
                            onTapped: {
                                if (!entry.wifi) {
                                    fly.source.toggleDevice(entry.modelData.mac, entry.modelData.connected);
                                } else {
                                    detailView.pending = entry.asking ? "" : entry.modelData.ssid;
                                    if (detailView.pending !== "" && entry.needsPassword)
                                        pwField.forceActiveFocus();
                                }
                            }
                        }
                    }

                    // Saved or open network: Connect / Disconnect and Forget.
                    RowLayout {
                        id: actionRow
                        visible: entry.asking && !entry.needsPassword
                        y: rowItem.height
                        width: parent.width
                        height: visible ? Math.round(fly.unit * 2.5) : 0
                        spacing: Kirigami.Units.smallSpacing

                        Item {
                            Layout.fillWidth: true
                        }
                        QQC2.Button {
                            visible: entry.modelData.known
                            text: i18n("Forget")
                            icon.name: "edit-delete"
                            onClicked: {
                                detailView.pending = "";
                                fly.source.forgetNetwork(entry.modelData.ssid);
                            }
                        }
                        QQC2.Button {
                            Layout.rightMargin: Kirigami.Units.largeSpacing
                            highlighted: !entry.connected
                            text: entry.connected ? i18n("Disconnect") : i18n("Connect")
                            onClicked: {
                                detailView.pending = "";
                                if (entry.connected)
                                    fly.source.disconnectNetwork(entry.modelData.ssid);
                                else
                                    fly.source.connectNetwork(entry.modelData.ssid);
                            }
                        }
                    }

                    // New secured network: own password field.
                    RowLayout {
                        id: pwRow
                        visible: entry.asking && entry.needsPassword
                        y: rowItem.height
                        width: parent.width
                        height: visible ? Math.round(fly.unit * 2.5) : 0
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.TextField {
                            id: pwField
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing
                            placeholderText: i18n("Password")
                            echoMode: TextInput.Password
                            onAccepted: connectBtn.clicked()
                        }
                        QQC2.Button {
                            id: connectBtn
                            Layout.rightMargin: Kirigami.Units.largeSpacing
                            text: i18n("Connect")
                            enabled: pwField.text.length >= 8
                            onClicked: {
                                fly.source.connectNetwork(entry.modelData.ssid, pwField.text);
                                pwField.text = "";
                                detailView.pending = "";
                            }
                        }
                    }
                }

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    width: parent.width - fly.unit * 2
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    opacity: 0.55
                    visible: list.count === 0
                    text: !fly.source ? "" : detailView.isWifi
                        ? (fly.source.wifiOn ? (fly.source.scanning ? i18n("Looking for networks…") : i18n("No networks found")) : i18n("Wi-Fi is off"))
                        : (fly.source.btOn ? (fly.source.scanning ? i18n("Looking for devices…") : i18n("No paired devices")) : i18n("Bluetooth is off"))
                }
            }

            Item {
                Layout.preferredHeight: Kirigami.Units.smallSpacing
            }
        }
    }

    // Pill slider shared by brightness and volume: dark track, accent fill, white knob.
    component PillSlider: QQC2.Slider {
        id: slider
        property bool dimmed: false
        readonly property bool dragging: pressed

        // New value in 0-100, at most once per 80 ms while the user drags.
        signal commit(real v)

        Layout.preferredHeight: Math.round(fly.unit * 1.5)
        from: 0
        to: 100
        stepSize: 1

        Timer {
            id: apply
            interval: 80
            onTriggered: slider.commit(slider.value)
        }
        onMoved: {
            if (!apply.running)
                apply.restart();
        }
        onPressedChanged: {
            if (!pressed)
                slider.commit(slider.value);
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: slider.availableHeight
            radius: height / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

            Rectangle {
                width: Math.max(parent.height, slider.visualPosition * parent.width)
                height: parent.height
                radius: height / 2
                color: fly.accent
                opacity: slider.dimmed ? 0.4 : 1
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableHeight * 0.84
            height: width
            radius: width / 2
            color: "white"
            border.width: 1
            border.color: Qt.alpha("black", 0.15)
        }
    }
}
