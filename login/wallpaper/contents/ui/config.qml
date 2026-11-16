import QtQuick
import org.kde.kquickcontrols as KQuickControls
import org.kde.kirigami as Kirigami
import QtQuick.Controls as QQC2

// Colour options for the Dockyard wallpaper: Dockyard preset, the AvdanOS one
// plus four individual colour buttons. Picking a preset fills the buttons; editing a button switches to Custom.
Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property var configDialog
    property var wallpaperConfiguration
    property color cfg_BaseDefault
    property color cfg_Flow1Default
    property color cfg_Flow2Default
    property color cfg_Flow3Default
    property bool cfg_AnimateDefault
    property alias cfg_Base: base.color
    property alias cfg_Flow1: f1.color
    property alias cfg_Flow2: f2.color
    property alias cfg_Flow3: f3.color
    property alias cfg_Animate: anim.checked
    property alias formLayout: root

    readonly property var presets: [
        { name: i18n("Dockyard"), c: ["#0b1020", "#0A84FF", "#5E5CE6", "#64D2FF"] },
        { name: i18n("AvdanOS"), c: ["#4a0f6e", "#ff2d6a", "#a01780", "#ff6f91"] },
        { name: i18n("Classic"), c: ["#dfe6ff", "#9db4ff", "#d9b8ff", "#ffffff"] },
        { name: i18n("Pastel"), c: ["#ffe8ee", "#ffb199", "#ff8fa8", "#ffd9c2"] },
        { name: i18n("Neon"), c: ["#07021a", "#7b2cff", "#ff2d95", "#00e5ff"] },
        { name: i18n("Organic"), c: ["#04170f", "#2e9e5b", "#0b6b5a", "#a5d6a7"] },
        { name: i18n("Pro"), c: ["#080911", "#1a237e", "#7c4dff", "#00e5ff"] },
        { name: i18n("Dynamic"), c: ["#120a22", "#ff7a1a", "#7c4dff", "#2dd4ff"] },
        { name: i18n("Basic"), c: ["#d6f3ff", "#7fd8ff", "#00bcd4", "#ffffff"] },
        { name: i18n("Vapor"), c: ["#0c0d14", "#d49b72", "#6a4fc0", "#e8d7ff"] }
    ]

    function same(a, b) { return String(a).toLowerCase() === b.toLowerCase(); }
    function matchIndex() {
        for (let i = 0; i < presets.length; i++) {
            const c = presets[i].c;
            if (same(base.color, c[0]) && same(f1.color, c[1]) && same(f2.color, c[2]) && same(f3.color, c[3])) return i;
        }
        return presets.length;   // Custom
    }
    function refresh() { if (!applying) preset.currentIndex = matchIndex(); }
    property bool applying: false

    QQC2.ComboBox {
        id: preset
        Kirigami.FormData.label: i18n("Colour preset:")
        model: root.presets.map(p => p.name).concat([i18n("Custom")])
        onActivated: index => {
            if (index >= root.presets.length) return;
            const c = root.presets[index].c;
            root.applying = true;
            base.color = c[0]; f1.color = c[1]; f2.color = c[2]; f3.color = c[3];
            root.applying = false;
        }
        Component.onCompleted: currentIndex = root.matchIndex()
    }

    Item { Kirigami.FormData.isSection: true }

    KQuickControls.ColorButton { id: base; Kirigami.FormData.label: i18n("Base:"); dialogTitle: i18n("Base colour"); onColorChanged: root.refresh() }
    KQuickControls.ColorButton { id: f1; Kirigami.FormData.label: i18n("Flow 1:"); dialogTitle: i18n("Flow colour 1"); onColorChanged: root.refresh() }
    KQuickControls.ColorButton { id: f2; Kirigami.FormData.label: i18n("Flow 2:"); dialogTitle: i18n("Flow colour 2"); onColorChanged: root.refresh() }
    KQuickControls.ColorButton { id: f3; Kirigami.FormData.label: i18n("Flow 3:"); dialogTitle: i18n("Flow colour 3"); onColorChanged: root.refresh() }

    QQC2.CheckBox { id: anim; Kirigami.FormData.label: i18n("Motion:"); text: i18n("Animate") }
}
