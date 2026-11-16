import QtQuick

// Rounded square holding a line icon. tone: "neutral", "accent" (soft tint) or "solid" (accent fill).
Rectangle {
    id: c
    property string iconName
    property string tone: "neutral"
    property int box: 32
    property int glyph: Math.round(box * 0.56)
    // A theme icon name (not one of ours) is shown in full colour without the tinted square.
    readonly property bool own: Theme.icons.indexOf(iconName) >= 0
    implicitWidth: box
    implicitHeight: box
    width: box
    height: box
    radius: Math.round(box * 0.3)
    color: !own ? "transparent" : tone === "solid" ? Theme.accent : tone === "accent" ? Theme.accentSoft : Theme.a(Theme.ink, Theme.dark ? 0.07 : 0.06)
    Behavior on color { ColorAnimation { duration: Theme.dur } }
    Ico {
        anchors.centerIn: parent
        name: c.iconName
        size: c.own ? c.glyph : c.box - 4
        color: c.tone === "solid" ? Theme.accentFg : c.tone === "accent" ? Theme.accentInk : Theme.ink2
    }
}
