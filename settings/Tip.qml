import QtQuick
import QtQuick.Controls as QQC2

// Small tooltip. Use as a child: Tip { text: "…"; shown: parent.hovered }.
QQC2.ToolTip {
    id: tp
    property bool shown: false
    visible: shown && text !== ""
    delay: 450
    timeout: -1
    padding: 0
    topPadding: 5
    bottomPadding: 5
    leftPadding: 9
    rightPadding: 9
    contentItem: Text { text: tp.text; color: Theme.ink; font.pixelSize: Theme.fsCaption; font.weight: Font.Medium }
    background: Rectangle { radius: 7; color: Theme.raise; border.width: 1; border.color: Theme.wellRim }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }
}
