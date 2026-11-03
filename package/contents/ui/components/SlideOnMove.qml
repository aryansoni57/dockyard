import QtQuick
import org.kde.kirigami as Kirigami

// Drop inside a layout-managed item: when the layout moves its parent sideways
// (a reorder, or a neighbour showing or hiding), the parent glides from where it
// was to its new spot instead of jumping. Uses a transform, so layout is untouched.
Item {
    id: mover

    readonly property Item host: parent
    property real lastX: host.x
    property bool ready: false

    Translate {
        id: shift
    }

    NumberAnimation {
        id: slide
        target: shift
        property: "x"
        to: 0
        duration: Kirigami.Units.longDuration
        easing.type: Easing.OutCubic
    }

    Connections {
        target: mover.host

        function onXChanged() {
            const delta = mover.lastX - mover.host.x;
            mover.lastX = mover.host.x;
            // Skip the startup layout pass and tiny shifts.
            if (!mover.ready || Math.abs(delta) < 2)
                return;
            // Carry on from the current offset if a slide is still running.
            shift.x += delta;
            slide.restart();
        }
    }

    // Layout settles over the first moments after load; start animating after that.
    Timer {
        interval: 600
        running: true
        onTriggered: mover.ready = true
    }

    Component.onCompleted: host.transform = [shift]
}
