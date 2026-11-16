import QtQuick
import QtQuick.Controls as QQC2

// Segmented control with a sliding thumb. model: list of strings, or {t, i} for text plus icon.
Rectangle {
    id: s
    property var model: []
    property int currentIndex: 0
    property bool stretch: false
    signal picked(int i)
    implicitWidth: stretch ? 120 : row.implicitWidth + 6
    implicitHeight: 34
    radius: Theme.rCtl
    color: Theme.well
    border.width: 1
    border.color: Theme.wellRim
    Rectangle {
        id: thumb
        readonly property Item cur: rep.count > s.currentIndex && s.currentIndex >= 0 ? rep.itemAt(s.currentIndex) : null
        visible: cur !== null
        x: cur ? cur.x + 3 : 3
        y: 3
        width: cur ? cur.width : 0
        height: s.height - 6
        radius: Theme.rCtl - 3
        color: Theme.raise
        border.width: 1
        border.color: Theme.dark ? Theme.a("#ffffff", 0.06) : Theme.a("#000000", 0.08)
        Behavior on x { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Theme.dur; easing.type: Easing.OutCubic } }
    }
    Row {
        id: row
        x: 3; y: 3
        Repeater {
            id: rep
            model: s.model
            delegate: QQC2.AbstractButton {
                id: seg
                required property int index
                required property var modelData
                readonly property string label: typeof modelData === "string" ? modelData : (modelData.t || "")
                readonly property string glyph: typeof modelData === "string" ? "" : (modelData.i || "")
                checked: s.currentIndex === index
                focusPolicy: Qt.TabFocus
                width: s.stretch ? (s.width - 6) / Math.max(1, rep.count) : Math.max(label === "" ? 34 : 52, implicitContentWidth + (label === "" ? 16 : 26))
                height: s.height - 6
                onClicked: s.picked(index)
                Accessible.name: label || (modelData.n || "")
                Tip { text: seg.label === "" ? (seg.modelData.n || "") : ""; shown: seg.hovered }
                contentItem: Item { implicitWidth: inner.implicitWidth; implicitHeight: inner.implicitHeight
                Row {
                    id: inner
                    anchors.centerIn: parent
                    spacing: 6
                    Ico { visible: seg.glyph !== ""; name: seg.glyph; size: 15; color: seg.checked ? Theme.ink : Theme.ink2; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        visible: seg.label !== ""
                        text: seg.label
                        color: seg.checked ? Theme.ink : Theme.ink2
                        font.pixelSize: Theme.fsSmall
                        font.weight: seg.checked ? Font.DemiBold : Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                }
                background: Rectangle {
                    radius: Theme.rCtl - 3
                    color: !seg.checked && seg.hovered ? Theme.hover : "transparent"
                    FocusRing { shown: seg.visualFocus; round: Theme.rCtl - 3 }
                }
            }
        }
    }
}
