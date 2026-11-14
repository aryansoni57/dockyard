import QtQuick
import "../components"

// System stats tile. Concentric: CPU, RAM and disk as nested rings.
// Classic (statsConcentric off): CPU and RAM rings side by side.
Tile {
    id: stats

    property real cpu
    property real mem
    property real disk
    property bool concentric: true

    implicitWidth: (concentric ? rings.implicitWidth : row.implicitWidth) + padding * 2

    ConcentricRing {
        id: rings
        visible: stats.concentric
        anchors.centerIn: parent
        height: stats.height - stats.padding * 2
        width: height
        cpu: stats.cpu
        mem: stats.mem
        disk: stats.disk
    }

    Row {
        id: row
        visible: !stats.concentric
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
