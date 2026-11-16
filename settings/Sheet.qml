import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// One scrolling settings page on the deck: icon chip, title and subtitle, header actions, then cards.
Item {
    id: s
    property string title
    property string subtitle: ""
    property string iconName: ""
    property int maxWidth: 800
    property bool hero: false
    property var app: null
    property QtObject sys: null
    readonly property bool narrow: width < 640
    signal openKcm(string id)
    signal openPage(int i)
    signal openGroup(string id)
    signal toast(string text, string icon)
    default property alias content: col.data
    property alias actions: act.data
    property alias flick: fl

    Flickable {
        id: fl
        anchors.fill: parent
        contentHeight: col.implicitHeight + col.y + Theme.s10 + 24
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: Scroller {}
        SmoothWheel { view: fl; parent: fl }
        ColumnLayout {
            id: col
            width: Math.min(s.maxWidth, fl.width - (s.narrow ? Theme.s6 : Theme.s10) * 2)
            x: Math.round((fl.width - width) / 2)
            y: s.narrow ? Theme.s6 : Theme.s8 + 4
            spacing: Theme.s6 + 4
            RowLayout {
                visible: s.title !== ""
                Layout.fillWidth: true
                Layout.bottomMargin: -Theme.s1
                spacing: Theme.s4
                Chip { visible: s.iconName !== ""; iconName: s.iconName; box: 46; tone: "accent"; Layout.alignment: Qt.AlignVCenter }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QQC2.Label { text: s.title; color: Theme.ink; font.pixelSize: s.hero ? Theme.fsHero : Theme.fsH1; font.weight: Font.DemiBold; font.letterSpacing: -0.4; Layout.fillWidth: true; elide: Text.ElideRight }
                    QQC2.Label { visible: s.subtitle !== ""; text: s.subtitle; color: Theme.ink3; font.pixelSize: Theme.fsSmall + 1; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                RowLayout { id: act; spacing: Theme.s2; Layout.alignment: Qt.AlignVCenter }
            }
        }
    }
}
