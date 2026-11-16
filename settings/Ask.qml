import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// Small modal form: a title, an optional network name, a password, OK / Cancel.
QQC2.Popup {
    id: a
    property string title: ""
    property string message: ""
    property bool askName: false
    property string nameLabel: "Network name"
    property string okText: "Connect"
    property alias name: nameField.text
    property alias secret: pwField.text
    signal accepted()
    parent: QQC2.Overlay.overlay
    modal: true
    anchors.centerIn: parent
    width: Math.min(400, (parent ? parent.width : 400) - 48)
    padding: 22
    closePolicy: QQC2.Popup.CloseOnEscape
    QQC2.Overlay.modal: Rectangle { color: Theme.scrim }
    background: Rectangle { radius: Theme.rCard + 2; color: Theme.card; border.width: 1; border.color: Theme.wellRim }
    onOpened: (askName ? nameField : pwField).forceActiveFocus()
    onClosed: pwField.text = ""
    component Field: QQC2.TextField {
        Layout.fillWidth: true
        color: Theme.ink
        placeholderTextColor: Theme.ink3
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentFg
        font.pixelSize: Theme.fsBody
        leftPadding: 12
        rightPadding: 12
        implicitHeight: 38
        background: Rectangle { radius: Theme.rCtl; color: Theme.well; border.width: 1; border.color: parent.activeFocus ? Theme.accentLine : Theme.wellRim }
    }
    contentItem: ColumnLayout {
        spacing: 10
        QQC2.Label { text: a.title; color: Theme.ink; font.pixelSize: Theme.fsTitle + 1; font.weight: Font.DemiBold; wrapMode: Text.Wrap; Layout.fillWidth: true }
        QQC2.Label { visible: a.message !== ""; text: a.message; color: Theme.ink2; font.pixelSize: Theme.fsSmall; wrapMode: Text.Wrap; Layout.fillWidth: true }
        Field { id: nameField; visible: a.askName; placeholderText: a.nameLabel; onAccepted: pwField.forceActiveFocus() }
        Field { id: pwField; placeholderText: "Password"; echoMode: TextInput.Password; onAccepted: okBtn.clicked() }
        RowLayout {
            Layout.topMargin: 8
            spacing: 8
            Item { Layout.fillWidth: true }
            Btn { text: "Cancel"; quiet: true; onClicked: a.close() }
            Btn { id: okBtn; text: a.okText; primary: true; enabled: (!a.askName || nameField.text !== "") ; onClicked: { if (enabled) { a.accepted(); a.close(); } } }
        }
    }
}
