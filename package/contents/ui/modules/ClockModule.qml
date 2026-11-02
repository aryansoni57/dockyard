import QtQuick
import org.kde.plasma.components as PlasmaComponents

// Clock tile (docs/STYLE.md, "Themes and color"): fixed red band with the time
// over a black base with day and date. Same colors in every theme.
Rectangle {
    id: clock

    property date now

    signal clicked()

    implicitWidth: Math.max(height * 1.15, timeText.implicitWidth + height * 0.2)
    radius: height * 0.24
    color: "black"
    scale: tap.pressed ? 0.97 : 1

    Behavior on scale {
        NumberAnimation { duration: 80 }
    }

    Rectangle {
        id: band
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height * 0.52
        radius: clock.radius
        color: "#FF3B30"

        // Square off the band's bottom corners.
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.radius
            color: parent.color
        }

        PlasmaComponents.Label {
            id: timeText
            anchors.centerIn: parent
            text: Qt.formatTime(clock.now, Qt.locale().timeFormat(Locale.ShortFormat))
            color: "white"
            font.pixelSize: Math.max(8, band.height * 0.62)
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    Row {
        anchors {
            top: band.bottom
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: clock.height * 0.08

        PlasmaComponents.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(clock.now, "ddd")
            color: "white"
            opacity: 0.7
            font.pixelSize: Math.max(6, clock.height * 0.2)
        }
        PlasmaComponents.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(clock.now, "d")
            color: "white"
            font.pixelSize: Math.max(7, clock.height * 0.26)
            font.weight: Font.Bold
        }
    }

    TapHandler {
        id: tap
        onTapped: clock.clicked()
    }
}
