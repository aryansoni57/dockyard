import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../components"

// Temperature tile (website "Temperature"): CPU temperature as a ring gauge, with
// CPU and memory load as thin bars beside it. The ring goes green, amber, red.
Tile {
    id: root

    property real temp // degrees C
    property real cpu  // percent
    property real mem  // percent

    readonly property real inner: height - padding * 2
    readonly property color heat: temp >= 85 ? "#FF453A" : temp >= 70 ? "#FF9F0A" : "#30D158"

    implicitWidth: Math.round(height * 2.7)

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.rightMargin: root.padding * 1.4
        spacing: root.inner * 0.2

        RingGauge {
            Layout.preferredWidth: root.inner
            Layout.preferredHeight: root.inner
            Layout.alignment: Qt.AlignVCenter
            value: Math.min(100, root.temp)
            suffix: "°"
            label: "CPU"
            accent: root.heat
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.inner * 0.14

            Repeater {
                model: [
                    { name: "CPU", value: root.cpu },
                    { name: "RAM", value: root.mem }
                ]

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: root.inner * 0.1

                    PlasmaComponents.Label {
                        text: modelData.name
                        opacity: 0.6
                        font.pixelSize: Math.max(7, root.inner * 0.2)
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(3, root.inner * 0.07)
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                        Rectangle {
                            width: parent.width * Math.min(100, modelData.value) / 100
                            height: parent.height
                            radius: height / 2
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                    PlasmaComponents.Label {
                        text: Math.round(modelData.value) + "%"
                        font.pixelSize: Math.max(7, root.inner * 0.2)
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
