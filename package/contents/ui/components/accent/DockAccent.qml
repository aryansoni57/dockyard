pragma Singleton
import QtQuick

// The dock's accent colour, for everything drawn inside the dock. Kirigami.Theme.highlightColor
// overrides do not reach child items in plasmashell, so main.qml publishes the accent here
// (a Binding on `color`) and the dock's items read it directly.
// `tint` is the "Tint dock with the accent" option from Configure Dockyard.
QtObject {
    property color color: "#3b82f6"
    property bool tint: true
}
