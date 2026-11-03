import QtQuick

// One seven-segment digit. Unlit segments stay faintly visible, like an LCD.
// Width follows height (about 0.56); size it by height.
Item {
    id: seg

    property int digit: 0
    property color onColor: "white"
    property color offColor: Qt.alpha(onColor, 0.12)

    // Segments a..g lit for 0..9.
    readonly property var map: ["abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc", "abcdefg", "abcdfg"]
    readonly property string lit: digit >= 0 && digit <= 9 ? map[digit] : ""
    readonly property real thick: Math.max(1.5, height * 0.11)
    readonly property real gap: Math.max(0.5, thick * 0.25)

    implicitHeight: 20
    implicitWidth: Math.round(height * 0.56)

    component Bar: Rectangle {
        property string key
        radius: Math.min(width, height) / 2
        antialiasing: true
        color: seg.lit.indexOf(key) >= 0 ? seg.onColor : seg.offColor
    }

    // Horizontal: a (top), g (middle), d (bottom).
    Bar { key: "a"; x: seg.thick / 2 + seg.gap; y: 0; width: seg.width - seg.thick - seg.gap * 2; height: seg.thick }
    Bar { key: "g"; x: seg.thick / 2 + seg.gap; y: (seg.height - seg.thick) / 2; width: seg.width - seg.thick - seg.gap * 2; height: seg.thick }
    Bar { key: "d"; x: seg.thick / 2 + seg.gap; y: seg.height - seg.thick; width: seg.width - seg.thick - seg.gap * 2; height: seg.thick }
    // Vertical: f/b upper, e/c lower.
    Bar { key: "f"; x: 0; y: seg.thick / 2 + seg.gap; width: seg.thick; height: seg.height / 2 - seg.thick / 2 - seg.gap * 2 }
    Bar { key: "b"; x: seg.width - seg.thick; y: seg.thick / 2 + seg.gap; width: seg.thick; height: seg.height / 2 - seg.thick / 2 - seg.gap * 2 }
    Bar { key: "e"; x: 0; y: seg.height / 2 + seg.gap; width: seg.thick; height: seg.height / 2 - seg.thick / 2 - seg.gap * 2 }
    Bar { key: "c"; x: seg.width - seg.thick; y: seg.height / 2 + seg.gap; width: seg.thick; height: seg.height / 2 - seg.thick / 2 - seg.gap * 2 }
}
