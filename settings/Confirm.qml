import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// "Keep these settings?" prompt with a countdown. Reverts on its own when the time runs out
// (a bad display mode can leave the screen unreadable, so nobody can click Revert).
QQC2.Popup {
    id: c
    property string title: "Keep these settings?"
    property string message: ""
    property int seconds: 15
    property int left: seconds
    signal keep()
    signal revert()
    function begin() { left = seconds; open(); tick.restart(); }
    parent: QQC2.Overlay.overlay
    modal: true
    anchors.centerIn: parent
    width: Math.min(400, (parent ? parent.width : 400) - 48)
    padding: 22
    closePolicy: QQC2.Popup.NoAutoClose
    QQC2.Overlay.modal: Rectangle { color: Theme.scrim }
    background: Rectangle { radius: Theme.rCard + 2; color: Theme.card; border.width: 1; border.color: Theme.wellRim }
    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: { c.left -= 1; if (c.left <= 0) { stop(); c.close(); c.revert(); } }
    }
    contentItem: ColumnLayout {
        spacing: 10
        QQC2.Label { text: c.title; color: Theme.ink; font.pixelSize: Theme.fsTitle + 1; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.Wrap }
        QQC2.Label { text: c.message + "  Reverting in " + c.left + " s."; color: Theme.ink2; font.pixelSize: Theme.fsSmall; wrapMode: Text.Wrap; Layout.fillWidth: true }
        RowLayout {
            Layout.topMargin: 8
            spacing: 8
            Item { Layout.fillWidth: true }
            Btn { text: "Revert"; quiet: true; onClicked: { tick.stop(); c.close(); c.revert(); } }
            Btn { text: "Keep"; primary: true; onClicked: { tick.stop(); c.close(); c.keep(); } }
        }
    }
}
