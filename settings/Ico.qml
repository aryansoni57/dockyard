import QtQuick
import org.kde.kirigami as Kirigami

// One monochrome line icon from settings/icons, tinted with `color`.
// A name with a dash that is not in our set (a theme icon name) is shown as-is in full colour.
Kirigami.Icon {
    id: i
    property string name
    property int size: 18
    readonly property bool own: name !== "" && Theme.icons.indexOf(name) >= 0
    implicitWidth: size
    implicitHeight: size
    width: size
    height: size
    source: own ? Qt.resolvedUrl("icons/" + name + ".svg") : name
    isMask: own
    color: Theme.ink2
    Behavior on color { ColorAnimation { duration: Theme.fast } }
}
