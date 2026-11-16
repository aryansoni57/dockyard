import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// Button. kind: "secondary" (default), "primary", "quiet" or "danger". Optional line icon on the left.
QQC2.Button {
    id: b
    property bool primary: false
    property bool danger: false
    property bool quiet: false
    property bool small: false
    property string iconName: ""
    readonly property string kind: primary ? "primary" : danger ? "danger" : quiet ? "quiet" : "secondary"
    readonly property color fg: kind === "primary" ? Theme.accentFg : kind === "danger" ? Theme.bad : Theme.ink
    implicitHeight: small ? 28 : 34
    implicitWidth: Math.max(small ? 56 : 72, implicitContentWidth + leftPadding + rightPadding)
    leftPadding: iconName !== "" && text !== "" ? (small ? 9 : 11) : (small ? 11 : 15)
    rightPadding: small ? 11 : 15
    focusPolicy: Qt.TabFocus
    scale: b.down && Theme.motion ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }
    contentItem: RowLayout {
        spacing: 6
        opacity: b.enabled ? 1 : 0.5
        Ico { visible: b.iconName !== ""; name: b.iconName; size: b.small ? 15 : 16; color: b.fg }
        QQC2.Label {
            visible: b.text !== ""
            text: b.text
            color: b.fg
            font.pixelSize: b.small ? Theme.fsCaption : Theme.fsSmall
            font.weight: b.kind === "primary" ? Font.DemiBold : Font.Medium
            Layout.alignment: Qt.AlignVCenter
        }
    }
    background: Rectangle {
        radius: Theme.rCtl
        opacity: b.enabled ? 1 : 0.5
        color: {
            if (b.kind === "primary") return b.down ? Qt.darker(Theme.accent, 1.15) : (b.hovered ? Qt.lighter(Theme.accent, 1.07) : Theme.accent);
            if (b.kind === "danger") return b.down ? Theme.a(Theme.bad, 0.24) : (b.hovered ? Theme.a(Theme.bad, 0.18) : Theme.badSoft);
            if (b.kind === "quiet") return b.down ? Theme.press : (b.hovered ? Theme.hover : "transparent");
            return b.down ? Theme.press : (b.hovered ? Theme.cardHi : Theme.well);
        }
        border.width: b.kind === "secondary" ? 1 : 0
        border.color: Theme.wellRim
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        FocusRing { shown: b.visualFocus; round: Theme.rCtl }
    }
}
