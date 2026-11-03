import QtQuick

// One split-flap card. When `digit` changes, the old top half folds down and the
// new bottom half lands over the old one (about 450 ms), then everything rests.
Item {
    id: flip

    property string digit: "0"
    property color cardColor: "#3A3A3C"
    property color textColor: "white"

    property string prev: digit
    property string cur: digit
    property real phase: 1 // 0..1 while flipping, 1 at rest

    implicitHeight: 30
    implicitWidth: Math.round(height * 0.72)

    onDigitChanged: {
        prev = cur;
        cur = digit;
        anim.restart();
    }

    NumberAnimation {
        id: anim
        target: flip
        property: "phase"
        from: 0
        to: 1
        duration: 450
        easing.type: Easing.InOutQuad
    }

    component Half: Item {
        id: half
        property string label
        property bool upper: true
        width: flip.width
        height: flip.height / 2
        y: upper ? 0 : flip.height / 2
        clip: true

        Rectangle {
            width: flip.width
            height: flip.height
            y: half.upper ? 0 : -flip.height / 2
            radius: flip.width * 0.16
            color: flip.cardColor
            // Faint top-lit edge, matching the glass tiles.
            border.width: 1
            border.color: Qt.alpha("white", 0.06)

            Text {
                anchors.centerIn: parent
                text: half.label
                color: flip.textColor
                font.pixelSize: flip.height * 0.68
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
        }
    }

    // Resting halves: new top, old bottom until the flap lands.
    Half { label: flip.cur; upper: true }
    Half { label: flip.phase >= 1 ? flip.cur : flip.prev; upper: false }

    // Old top half folding down.
    Half {
        label: flip.prev
        upper: true
        visible: flip.phase < 0.5
        transform: Rotation {
            origin.x: flip.width / 2
            origin.y: flip.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: -flip.phase * 180
        }
    }
    // New bottom half landing.
    Half {
        label: flip.cur
        upper: false
        visible: flip.phase >= 0.5 && flip.phase < 1
        transform: Rotation {
            origin.x: flip.width / 2
            origin.y: 0
            axis { x: 1; y: 0; z: 0 }
            angle: (1 - flip.phase) * 180
        }
    }

    // Split line across the middle.
    Rectangle {
        y: Math.round(flip.height / 2 - height / 2)
        width: flip.width
        height: Math.max(1, flip.height * 0.025)
        color: Qt.alpha("black", 0.6)
    }
}
