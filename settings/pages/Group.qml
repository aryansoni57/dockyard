import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

// All modules of one System Settings category, in sections by sub-category, two columns when wide.
Sheet {
    id: pg
    property string groupId
    property string groupName
    property var mods: app ? app.kcmModel.inGroup(groupId) : []
    title: groupName
    subtitle: mods.length + (mods.length === 1 ? " setting" : " settings")
    maxWidth: 920
    readonly property var sections: {
        const out = [];
        mods.forEach(m => {
            const name = m.subName || "";
            let s = out.find(x => x.name === name);
            if (!s) { s = { name: name, items: [] }; out.push(s); }
            s.items.push(m);
        });
        // Loose modules (no sub-category) read best under a "General" heading when other sections exist.
        if (out.length > 1 && out[0].name === "") out[0].name = "General";
        return out;
    }

    Repeater {
        model: pg.sections
        delegate: Card {
            id: sec
            required property var modelData
            title: modelData.name
            description: modelData.name !== "" ? modelData.items.length + (modelData.items.length === 1 ? " module" : " modules") : ""
            GridLayout {
                id: grid
                Layout.fillWidth: true
                Layout.margins: 4
                columns: pg.width > 860 && sec.modelData.items.length > 1 ? 2 : 1
                columnSpacing: 0
                rowSpacing: 0
                Repeater {
                    model: sec.modelData.items
                    delegate: QQC2.AbstractButton {
                        id: tile
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 62
                        focusPolicy: Qt.TabFocus
                        Accessible.name: modelData.name
                        onClicked: pg.openKcm(modelData.kcmId)
                        background: Rectangle {
                            radius: Theme.rCard - 4
                            color: tile.down ? Theme.press : (tile.hovered ? Theme.hover : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                            FocusRing { shown: tile.visualFocus; round: Theme.rCard - 4; anchors.margins: -1 }
                        }
                        leftPadding: 14
                        rightPadding: 12
                        contentItem: RowLayout {
                            spacing: Theme.s3 + 2
                            Kirigami.Icon { source: tile.modelData.icon; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                QQC2.Label { text: tile.modelData.name; color: Theme.ink; font.pixelSize: Theme.fsBody; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                QQC2.Label { text: tile.modelData.comment; visible: text !== ""; color: Theme.ink3; font.pixelSize: Theme.fsCaption; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            Ico { name: "chevron-right"; size: 15; color: tile.hovered ? Theme.ink2 : Theme.ink4 }
                        }
                    }
                }
            }
        }
    }
    EmptyState { visible: pg.mods.length === 0; Layout.fillWidth: true; Layout.topMargin: Theme.s8; iconName: "dots"; title: "Nothing here"; body: "This category has no modules installed." }
}
