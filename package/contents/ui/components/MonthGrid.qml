import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Month grid for the popup (docs/STYLE.md, "Popups"): weekday letters, rounded
// day cells, today in a 2 px blue outline with a blue number.
Item {
    id: grid

    property date now: new Date()

    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7 // 0 = Sunday
    readonly property int monthStart: new Date(now.getFullYear(), now.getMonth(), 1).getDay()
    readonly property int offset: (monthStart - firstDay + 7) % 7
    readonly property int days: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    readonly property real cell: Math.floor((width - Kirigami.Units.largeSpacing * 2) / 7)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2

    GridLayout {
        id: layout
        x: Kirigami.Units.largeSpacing
        y: Kirigami.Units.largeSpacing
        columns: 7
        rowSpacing: 2
        columnSpacing: 0

        Repeater {
            model: 7

            PlasmaComponents.Label {
                required property int index
                Layout.preferredWidth: grid.cell
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((grid.firstDay + index) % 7, Locale.NarrowFormat).toUpperCase()
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
                opacity: 0.5
            }
        }

        Repeater {
            model: grid.offset + grid.days

            Item {
                required property int index
                readonly property int day: index - grid.offset + 1
                readonly property bool today: day === grid.now.getDate()

                Layout.preferredWidth: grid.cell
                Layout.preferredHeight: grid.cell

                Rectangle {
                    anchors.centerIn: parent
                    visible: parent.day >= 1
                    width: parent.width - 4
                    height: width
                    radius: width * 0.28
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.05)
                    border.width: parent.today ? 2 : 0
                    border.color: Kirigami.Theme.highlightColor

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: parent.parent.day
                        color: parent.parent.today ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        font.weight: parent.parent.today ? Font.Bold : Font.Normal
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
