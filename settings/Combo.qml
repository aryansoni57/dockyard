import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Templates as T

// Drop-down list styled like our fields, with a matching popup.
T.ComboBox {
    id: c
    implicitHeight: 34
    implicitWidth: 240
    leftPadding: 0
    rightPadding: 0
    focusPolicy: Qt.TabFocus
    contentItem: Text {
        leftPadding: 12
        rightPadding: 30
        text: c.displayText
        color: Theme.ink
        font.pixelSize: Theme.fsSmall
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Ico { x: c.width - width - 10; y: (c.height - height) / 2; name: "chevron-down"; size: 16; color: Theme.ink2 }
    background: Rectangle {
        radius: Theme.rCtl
        color: c.pressed ? Theme.press : (c.hovered ? Theme.cardHi : Theme.well)
        border.width: 1
        border.color: c.popup.visible ? Theme.accentLine : Theme.wellRim
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        FocusRing { shown: c.visualFocus; round: Theme.rCtl }
    }
    delegate: QQC2.ItemDelegate {
        id: d
        required property int index
        required property var model
        width: c.popup.availableWidth
        height: 34
        highlighted: c.highlightedIndex === index
        contentItem: Row {
            spacing: 8
            Text {
                width: d.width - 46
                text: d.model[c.textRole] !== undefined ? d.model[c.textRole] : d.model.modelData
                color: Theme.ink
                font.pixelSize: Theme.fsSmall
                font.weight: c.currentIndex === d.index ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            Ico { visible: c.currentIndex === d.index; name: "check"; size: 15; color: Theme.accentInk; anchors.verticalCenter: parent.verticalCenter }
        }
        background: Rectangle { radius: 7; color: d.highlighted ? Theme.hover : "transparent" }
    }
    popup: QQC2.Popup {
        y: c.height + 4
        width: Math.max(c.width, 220)
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 320)
        padding: 6
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: c.popup.visible ? c.delegateModel : null
            currentIndex: c.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollIndicator.vertical: QQC2.ScrollIndicator {}
        }
        background: Rectangle { radius: 12; color: Theme.raise; border.width: 1; border.color: Theme.wellRim }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast } }
    }
}
