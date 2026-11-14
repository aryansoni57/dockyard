pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import "../components"

// Stats popup: CPU and memory as a rolling graph of the last two minutes, disk as a
// usage bar, each in the colour of its ring on the tile.
ColumnLayout {
    id: panel

    property var applet
    readonly property real diskUsed: applet.diskUsed
    readonly property real diskTotal: applet.diskTotal
    readonly property real diskPercent: diskTotal > 0 ? Math.max(0, Math.min(100, diskUsed / diskTotal * 100)) : 0

    spacing: 0
    implicitHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

    // One labelled metric: name, current value, and a graph or bar underneath.
    component Metric: ColumnLayout {
        id: metric
        property string name
        property string valueText
        property color color
        // 0..100 samples, oldest first. Empty for a bar-only metric.
        property var history: []
        property real percent: 0
        // Samples across the full graph width.
        property int length: 60

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing / 2

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.smallSpacing * 2
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: metric.color
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: metric.name
                font.weight: Font.DemiBold
            }
            PlasmaComponents.Label {
                text: metric.valueText
                opacity: 0.7
                font.features: { "tnum": 1 }
            }
        }

        // Graph.
        Canvas {
            id: graph
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.6
            visible: metric.history.length > 0

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const h = metric.history;
                if (h.length < 2)
                    return;
                const w = width, ht = height;
                const step = w / (metric.length - 1);
                const x0 = w - (h.length - 1) * step;
                ctx.beginPath();
                for (let i = 0; i < h.length; ++i) {
                    const x = x0 + i * step;
                    const y = ht - 1 - (ht - 2) * Math.max(0, Math.min(100, h[i])) / 100;
                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.strokeStyle = metric.color;
                ctx.lineWidth = 1.5;
                ctx.lineJoin = "round";
                ctx.stroke();
                // Soft fill under the line.
                ctx.lineTo(w, ht);
                ctx.lineTo(x0, ht);
                ctx.closePath();
                ctx.globalAlpha = 0.14;
                ctx.fillStyle = metric.color;
                ctx.fill();
            }
            Connections {
                target: metric
                function onHistoryChanged() { graph.requestPaint(); }
                function onColorChanged() { graph.requestPaint(); }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            Rectangle {
                anchors.fill: parent
                z: -1
                radius: Kirigami.Units.smallSpacing
                color: Qt.alpha(Kirigami.Theme.textColor, 0.045)
            }
        }

        // Bar, for the disk.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            visible: metric.history.length === 0
            radius: 3
            color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * metric.percent / 100
                color: metric.color
            }
        }
    }

    ColumnLayout {
        id: content
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                source: "utilities-system-monitor-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("System")
                font.weight: Font.DemiBold
            }
            PlasmaComponents.ToolButton {
                text: i18n("Open System Monitor")
                icon.name: "utilities-system-monitor-symbolic"
                onClicked: {
                    panel.applet.launch("plasma-systemmonitor");
                    panel.applet.dockItem.hide();
                }
            }
        }

        Metric {
            name: i18n("CPU")
            color: panel.applet.accent
            valueText: Math.round(panel.applet.statsCpu) + "%"
            history: panel.applet.cpuHistory
            length: panel.applet.statsHistoryLength
        }
        Metric {
            name: i18n("Memory")
            color: "#30D158"
            valueText: Math.round(panel.applet.statsMem) + "%"
            history: panel.applet.memHistory
            length: panel.applet.statsHistoryLength
        }
        Metric {
            name: i18n("Disk")
            color: "#FF9F0A"
            valueText: panel.diskTotal > 0
                ? i18n("%1 of %2", KCoreAddons.Format.formatByteSize(panel.diskUsed), KCoreAddons.Format.formatByteSize(panel.diskTotal))
                : "--"
            percent: panel.diskPercent
        }
    }
}
