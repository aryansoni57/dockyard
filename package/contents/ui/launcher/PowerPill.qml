import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components/motion.js" as Motion
import "../components/accent"

// Power button that grows to the right on hover, showing Lock, Sleep and Restart.
// The base button is Shut down. Shut down and Restart ask for a second click within
// four seconds, so a stray hover-click cannot end the session (docs/mockups/power-menu.html).
// It takes 40 px in the layout and widens it when open, using the free space to its right.
Item {
    id: pwr

    // Dashboard panel (px, colors) and the session manager.
    property var dash
    property var session
    // Emitted before an action runs, so the dashboard can close first.
    signal chosen()

    // The item asked to confirm, or "".
    property string armed: ""
    readonly property bool expanded: hover.hovered || focusScope.activeFocus || armed !== ""

    // Grows with the pill, so the footer makes room and the whole pill stays inside this item's
    // bounds (events outside an item's bounds are not reliably delivered).
    implicitWidth: bg.width
    implicitHeight: dash.px(40)
    // Above the footer's later siblings while it overlays them.
    z: 10

    // Disarm when the pointer or focus leaves.
    onExpandedChanged: if (!expanded) armed = ""
    Timer { id: armTimer; interval: 4000; onTriggered: pwr.armed = "" }
    // Waits a moment before closing, so the pointer can cross the 1 px edge.
    Timer { id: openDelay; interval: 120; onTriggered: pwr.open = true }
    Timer { id: closeDelay; interval: 280; onTriggered: pwr.open = false }
    property bool open: false
    readonly property bool shown: open || focusScope.activeFocus || armed !== ""

    readonly property var options: [
        { id: "lock", icon: "system-lock-screen-symbolic", tip: i18n("Lock"), can: session.canLock, danger: false },
        { id: "sleep", icon: "system-suspend-symbolic", tip: i18n("Sleep"), can: session.canSuspend, danger: false },
        { id: "restart", icon: "system-reboot-symbolic", tip: i18n("Restart"), ask: i18n("Restart?"), can: session.canReboot, danger: true }
    ]

    function run(id) {
        pwr.chosen();
        // Our own confirm step replaces KDE's logout screen, so skip its prompt (Skip = 0).
        if (id === "lock")
            session.lock();
        else if (id === "sleep")
            session.suspend();
        else if (id === "restart")
            session.requestReboot(0);
        else
            session.requestShutdown(0);
    }
    function activate(id, danger) {
        if (danger && armed !== id) {
            armed = id;
            armTimer.restart();
            return;
        }
        armed = "";
        run(id);
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
    }

    Rectangle {
        id: bg
        x: 0
        y: 0
        height: parent.height
        width: pwr.shown ? Math.max(pwr.dash.px(40), content.implicitWidth + pwr.dash.px(4)) : pwr.dash.px(40)
        radius: pwr.dash.px(12)
        color: pwr.shown ? Qt.tint(Kirigami.Theme.backgroundColor, pwr.dash.btnFillHover) : (hover.hovered ? pwr.dash.btnFillHover : pwr.dash.btnFill)
        border.width: 1
        border.color: pwr.dash.hairline
        clip: true

        // On the pill, not the 40 px item: the open pill is wider than its layout slot.
        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) {
                    closeDelay.stop();
                    openDelay.start();
                } else {
                    openDelay.stop();
                    closeDelay.start();
                }
            }
        }


        Behavior on width {
            NumberAnimation {
                duration: Motion.ms(320, Kirigami.Units.longDuration)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.enter
            }
        }
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Row {
            id: content
            x: pwr.dash.px(2)
            height: parent.height

            // Shut down, always first. A click while collapsed only opens the pill.
            PowerButton {
                id: base
                itemId: "shutdown"
                glyph: "system-shutdown-symbolic"
                tip: i18n("Shut down")
                ask: i18n("Shut down?")
                can: pwr.session.canShutdown
                danger: true
                shown: true
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: pwr.dash.px(18)
                color: pwr.dash.hairline
                opacity: pwr.shown ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Repeater {
                model: pwr.options
                PowerButton {
                    required property var modelData
                    required property int index
                    itemId: modelData.id
                    glyph: modelData.icon
                    tip: modelData.tip
                    ask: modelData.ask || ""
                    can: modelData.can
                    danger: modelData.danger
                    shown: pwr.shown
                    order: index
                }
            }
        }
    }

    // One round button: the icon, and when armed a red "Restart?" label with a countdown bar.
    component PowerButton: QQC2.AbstractButton {
        id: pb
        required property string itemId
        property string glyph
        property string tip
        property string ask: ""
        property bool can: true
        property bool danger: false
        property bool shown: false
        property int order: 0
        readonly property bool isArmed: pwr.armed === itemId

        height: parent.height - pwr.dash.px(4)
        y: pwr.dash.px(2)
        implicitWidth: isArmed ? armedRow.implicitWidth + pwr.dash.px(24) : pwr.dash.px(38)
        width: implicitWidth
        enabled: can
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        opacity: shown ? (can ? 1 : 0.35) : 0
        visible: opacity > 0
        scale: down ? 0.96 : 1
        transform: Translate { x: pb.shown ? 0 : -pwr.dash.px(6) }

        Behavior on opacity { NumberAnimation { duration: 200 + pb.order * 30 } }
        Behavior on scale { NumberAnimation { duration: 80 } }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: Motion.ms(220, Kirigami.Units.longDuration)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.enter
            }
        }

        PlasmaComponents.ToolTip.text: tip
        PlasmaComponents.ToolTip.visible: hovered && !isArmed && pwr.shown
        Accessible.name: tip

        onClicked: {
            // Collapsed: only open, so a stray click cannot shut the machine down.
            if (!pwr.shown) {
                pwr.open = true;
                return;
            }
            pwr.activate(itemId, danger);
        }
        onActiveFocusChanged: if (activeFocus && pwr.armed !== "" && pwr.armed !== itemId) pwr.armed = ""

        // Right-click on Shut down: KDE's own logout screen, with every choice.
        TapHandler {
            enabled: pb.itemId === "shutdown"
            acceptedButtons: Qt.RightButton
            onTapped: {
                pwr.chosen();
                pwr.session.requestLogoutPrompt();
            }
        }

        background: Rectangle {
            radius: pwr.dash.px(10)
            color: pb.isArmed ? Qt.alpha(pwr.dash.low, 0.16) : (pb.hovered || pb.visualFocus ? pwr.dash.btnFillHover : "transparent")
            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
            border.width: pb.visualFocus ? 2 : 0
            border.color: DockAccent.color

            // Time left to confirm. Its length is a share of the button's current width, so it
            // starts full whatever width the button is animating through.
            Rectangle {
                id: bar
                property real remaining: 1
                visible: pb.isArmed
                x: pwr.dash.px(10)
                y: parent.height - height - pwr.dash.px(3)
                height: 2
                radius: 1
                color: pwr.dash.low
                width: Math.max(0, parent.width - pwr.dash.px(20)) * remaining
                NumberAnimation {
                    target: bar
                    property: "remaining"
                    running: pb.isArmed
                    from: 1
                    to: 0
                    duration: 4000
                }
            }
        }
        contentItem: Item {
            Row {
                id: armedRow
                anchors.centerIn: parent
                spacing: pwr.dash.px(6)
                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: pwr.dash.px(18)
                    height: width
                    source: pb.glyph
                    isMask: true
                    color: pb.isArmed || (pb.danger && pb.itemId === "shutdown" && (pb.hovered || pwr.shown)) ? pwr.dash.low : Kirigami.Theme.textColor
                }
                PlasmaComponents.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pb.isArmed
                    text: pb.ask
                    color: pwr.dash.low
                    font.pixelSize: pwr.dash.px(13)
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
