import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"
import "../components/motion.js" as Motion

// Job pill, after AvdanOS's render pill: the app's icon, the job's title over a
// thin progress bar with the percent, and a round count badge when several jobs run.
// main.qml hides it when no job is running, so it takes no room. Tap opens the list.
Tile {
    id: pill

    property int count: 0
    property int percent: 0
    property string iconName: ""
    property string title: ""
    // Every job has ended. The pill stays up, full, saying so.
    property bool done: false

    readonly property real inner: height - padding * 2
    readonly property real textSize: Math.max(Kirigami.Theme.smallFont.pixelSize, inner * 0.3)

    implicitWidth: row.implicitWidth + padding * 2

    RowLayout {
        id: row
        anchors.centerIn: parent
        height: pill.inner
        spacing: pill.padding

        Kirigami.Icon {
            Layout.preferredWidth: Math.round(pill.inner * 0.62)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            source: pill.iconName
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.max(1, pill.padding * 0.2)

            PlasmaComponents.Label {
                Layout.maximumWidth: Kirigami.Units.gridUnit * 7
                text: pill.title
                elide: Text.ElideRight
                font.pixelSize: pill.textSize
                font.weight: Font.DemiBold
            }
            RowLayout {
                spacing: pill.padding * 0.6

                PlasmaComponents.Label {
                    text: pill.done ? i18n("Finished") : pill.percent + "%"
                    font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize * 0.9, pill.inner * 0.24)
                    font.features: { "tnum": 1 }
                    opacity: 0.6
                }
                Rectangle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Math.max(3, pill.inner * 0.09)
                    Layout.alignment: Qt.AlignVCenter
                    radius: height / 2
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.18)

                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        color: Kirigami.Theme.highlightColor
                        width: pill.done ? parent.width : parent.width * Math.max(0, Math.min(100, pill.percent)) / 100

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.ms(Motion.enterMs, Kirigami.Units.longDuration)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.enter
                            }
                        }
                    }
                }
            }
        }

        // Count badge, only when more than one job runs.
        Rectangle {
            visible: pill.count > 1
            Layout.preferredWidth: Math.round(pill.inner * 0.5)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

            Text {
                anchors.centerIn: parent
                text: pill.count
                color: Kirigami.Theme.textColor
                font.pixelSize: parent.height * 0.55
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }
    }
}
