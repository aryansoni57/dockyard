import QtQuick
import "../components"

// System stats tile: CPU and RAM ring gauges side by side.
Tile {
    id: stats

    property real cpu
    property real mem

    implicitWidth: row.implicitWidth + padding * 2

    Row {
        id: row
        anchors.centerIn: parent
        spacing: stats.padding

        RingGauge {
            height: stats.height - stats.padding * 2
            width: height
            value: stats.cpu
            label: i18n("CPU")
        }
        RingGauge {
            height: stats.height - stats.padding * 2
            width: height
            value: stats.mem
            label: i18n("RAM")
        }
    }
}
