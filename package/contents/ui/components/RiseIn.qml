import QtQuick
import org.kde.kirigami as Kirigami
import "motion.js" as Motion

// Drop inside any item to make it fade in and rise a few pixels when it is created,
// `order` x 40 ms after the others (the AvdanOS panel stagger, enter curve). Uses a
// transform, so a layout is not disturbed. Skipped entirely when animations are off.
Item {
    id: rise

    // Invisible, so a layout does not give it a slot or a gap.
    visible: false

    property int order: 0
    readonly property Item host: parent

    Translate {
        id: shift
        y: Kirigami.Units.gridUnit * 0.55
    }

    SequentialAnimation {
        id: anim
        PauseAnimation {
            duration: Motion.ms(60 + rise.order * Motion.staggerMs, Kirigami.Units.longDuration)
        }
        ParallelAnimation {
            NumberAnimation {
                target: rise.host
                property: "opacity"
                to: 1
                duration: Motion.ms(Motion.enterMs, Kirigami.Units.longDuration)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.enter
            }
            NumberAnimation {
                target: shift
                property: "y"
                to: 0
                duration: Motion.ms(Motion.enterMs, Kirigami.Units.longDuration)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.enter
            }
        }
    }

    Component.onCompleted: {
        if (Kirigami.Units.longDuration === 0)
            return;
        host.opacity = 0;
        host.transform = [shift];
        anim.start();
    }
}
