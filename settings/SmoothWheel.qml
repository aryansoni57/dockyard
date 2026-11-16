import QtQuick

// Mouse wheel scrolling for a Flickable: about 100 px per notch, eased. Touchpads scroll 1:1.
WheelHandler {
    id: wh
    property Flickable view: null
    property real step: 0.9
    property real pending: 0
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: (e) => {
        if (!view) return;
        const max = Math.max(0, view.contentHeight - view.height);
        // On Wayland a wheel notch can also carry a small pixelDelta (about one line), so use the
        // angle whenever there is one and fall back to pixels only for pure pixel scrolling.
        if (e.angleDelta.y === 0 && e.pixelDelta.y !== 0) {
            anim.stop();
            view.contentY = Math.max(0, Math.min(max, view.contentY - e.pixelDelta.y));
            return;
        }
        const d = e.angleDelta.y * step;
        pending = Math.max(0, Math.min(max, (anim.running ? pending : view.contentY) - d));
        anim.stop();
        anim.from = view.contentY;
        anim.to = pending;
        anim.start();
    }
    property NumberAnimation anim: NumberAnimation {
        target: wh.view; property: "contentY"
        duration: 140; easing.type: Easing.OutCubic
    }
}
