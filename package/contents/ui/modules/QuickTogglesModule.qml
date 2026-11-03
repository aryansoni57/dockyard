import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../components"

// Quick toggles tile (docs/STYLE.md): glass tile holding a row of pills, one per
// toggle. Toggles with a detail view (Wi-Fi, Bluetooth) are two-part pills:
// icon button, hairline divider, chevron button. Plain toggles are round
// buttons. A rounded-square grid button closes the row. Dumb view: state and
// actions live in ToggleSource; icons are the custom set in contents/icons.
Tile {
    id: qt

    // [{ key, label, icon, on, available, detail }] from ToggleSource.items
    property var items: []
    // The ToggleSource, for the flyout's sliders and lists.
    property var source: null
    // "strip": four status glyphs, tap opens the flyout. "toggles": the pill row.
    property string layoutStyle: "strip"
    // Screen edge the dock sits on, so the flyout opens away from it.
    property int edge: PlasmaCore.Types.BottomEdge

    readonly property bool strip: layoutStyle === "strip"
    readonly property bool flyoutOpen: flyout.visible

    signal toggled(string key)
    signal detailRequested(string key)
    signal moreRequested()

    readonly property real inner: height - padding * 2
    readonly property real iconSize: Math.round(inner * 0.56)
    // System blue from docs/STYLE.md; the "on" look stays blue whatever the theme accent is.
    readonly property color accent: "#0A84FF"

    implicitWidth: strip ? Math.round(inner * 2.7) + padding * 2 : row.implicitWidth + padding * 2

    // Tapping the tile body opens the flyout (the pill row opens it from its grid button).
    onClicked: if (strip) openFlyout("main")

    function openFlyout(view) {
        if (flyout.visible && flyout.view === view) {
            flyout.visible = false;
            return;
        }
        flyout.view = view;
        flyout.visible = true;
    }

    QuickSettingsFlyout {
        id: flyout
        source: qt.source
        visualParent: qt
        location: qt.edge
        onSettingsRequested: qt.moreRequested()
    }

    function iconUrl(name) {
        return Qt.resolvedUrl("../../icons/" + name + ".svg");
    }

    function fillFor(on) {
        return on ? Qt.alpha(accent, 0.2) : Qt.alpha(Kirigami.Theme.textColor, 0.12);
    }

    function borderFor(on) {
        return on ? accent : "transparent";
    }

    function inkFor(on) {
        return on ? accent : Kirigami.Theme.textColor;
    }

    // Press feedback shared by every button in the row.
    component PressButton: QQC2.AbstractButton {
        id: pb
        scale: pressed ? 0.94 : 1
        hoverEnabled: true

        Behavior on scale {
            NumberAnimation { duration: 80 }
        }

        background: Item {}
    }

    // Strip layout: one glyph per toggle, blue when on, dim when off.
    Rectangle {
        anchors.fill: parent
        radius: qt.radius
        visible: qt.strip
        color: qt.flyoutOpen ? Qt.alpha(qt.accent, 0.14) : "transparent"
        border.width: qt.flyoutOpen ? 2 : 0
        border.color: qt.accent

        Behavior on color {
            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    Row {
        visible: qt.strip
        anchors.centerIn: parent
        spacing: Math.round(qt.inner * 0.22)

        Repeater {
            model: qt.strip ? 4 : 0

            Kirigami.Icon {
                id: glyph
                required property int index
                readonly property var entry: qt.source && qt.source.stripItems[index] ? qt.source.stripItems[index] : ({})
                width: Math.round(qt.inner * 0.5)
                height: width
                source: qt.iconUrl(entry.icon || "grid")
                isMask: true
                color: entry.on ? qt.accent : Kirigami.Theme.textColor
                opacity: entry.on ? 1 : 0.42

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }
        }
    }

    Row {
        id: row
        visible: !qt.strip
        anchors.centerIn: parent
        height: qt.inner
        spacing: qt.inner * 0.2

        // Count-based model: delegates are kept across polls and only re-read `item`.
        Repeater {
            model: qt.items.length

            delegate: Rectangle {
                id: pill
                required property int index
                readonly property var item: qt.items[index] ?? ({})
                readonly property bool on: !!item.on
                readonly property bool detail: !!item.detail
                readonly property color ink: qt.inkFor(on)

                width: detail ? main.width + divider.width + chevron.width : qt.inner
                height: qt.inner
                radius: height / 2
                color: qt.fillFor(on)
                border.width: on ? 2 : 0
                border.color: qt.borderFor(on)
                opacity: item.available ? 1 : 0.4

                Behavior on color {
                    ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                PressButton {
                    id: main
                    width: pill.detail ? Math.round(qt.inner * 1.12) : qt.inner
                    height: qt.inner
                    enabled: !!pill.item.available
                    onClicked: qt.toggled(pill.item.key)

                    contentItem: Item {
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            // Optically centre the icon in the left half of a pill.
                            anchors.horizontalCenterOffset: pill.detail ? qt.inner * 0.04 : 0
                            width: qt.iconSize
                            height: qt.iconSize
                            source: qt.iconUrl(pill.item.icon || "grid")
                            isMask: true
                            color: pill.ink
                        }
                    }

                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: (pill.item.label ?? "") + (pill.on ? " · on" : " · off")
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                // Hairline between the toggle half and the detail half.
                Rectangle {
                    id: divider
                    visible: pill.detail
                    x: main.width
                    anchors.verticalCenter: parent.verticalCenter
                    width: pill.detail ? 1 : 0
                    height: qt.inner * 0.46
                    color: pill.on ? Qt.alpha(qt.accent, 0.5) : Qt.alpha(Kirigami.Theme.textColor, 0.2)
                }

                PressButton {
                    id: chevron
                    visible: pill.detail
                    x: main.width + divider.width
                    width: pill.detail ? Math.round(qt.inner * 0.78) : 0
                    height: qt.inner
                    enabled: !!pill.item.available
                    onClicked: qt.openFlyout(pill.item.key === "wifi" ? "wifi" : "bluetooth")

                    contentItem: Item {
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -qt.inner * 0.04
                            width: Math.round(qt.inner * 0.36)
                            height: width
                            source: qt.iconUrl("chevron-right")
                            isMask: true
                            color: pill.ink
                            opacity: 0.85
                        }
                    }

                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: (pill.item.label ?? "") + " settings"
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }

        // More: opens the full quick settings panel (wired by the host).
        PressButton {
            id: more
            width: qt.inner
            height: qt.inner
            onClicked: qt.openFlyout("main")

            background: Rectangle {
                radius: qt.inner * 0.3
                color: qt.fillFor(true)
                border.width: 2
                border.color: qt.accent
            }

            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: qt.iconSize
                    height: qt.iconSize
                    source: qt.iconUrl("grid")
                    isMask: true
                    color: qt.accent
                }
            }

            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: "More settings"
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
