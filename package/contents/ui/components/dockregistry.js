.pragma library

// Which Dockyard dock does the once-only jobs (notification toasts, the day and night
// notice) when there are several, one per monitor. Docks are applets of one plasmashell,
// which shares this library between them. If it were not shared, each dock would see only
// itself and do the jobs, as a lone dock does.
// The owner is the dock on the primary screen, else the one with the lowest applet id.

var docks = {};

function register(id, onPrimary) {
    docks[id] = { onPrimary: onPrimary };
}
function unregister(id) {
    delete docks[id];
}
function count() {
    return Object.keys(docks).length;
}
function ownerId() {
    const ids = Object.keys(docks).map(Number);
    if (ids.length === 0)
        return -1;
    const primary = ids.filter(i => docks[i].onPrimary);
    return Math.min(...(primary.length > 0 ? primary : ids));
}
