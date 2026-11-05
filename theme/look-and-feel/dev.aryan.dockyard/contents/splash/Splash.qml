import QtQuick

// Dockyard boot splash. ksplashqml sets stage from 1 to 6 as the session starts.
Rectangle {
    id: root
    property int stage: 0
    color: "#16161a"

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Dockyard"
            color: "#ffffff"
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: 160
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                width: parent.width * Math.min(root.stage, 6) / 6
                height: parent.height
                radius: 2
                color: "#0A84FF"
                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }
}
