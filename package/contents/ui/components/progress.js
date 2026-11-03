.pragma library

// Month / day / year progress math, shared by the dock tiles and the popup.
// kind: "month" | "day" | "year"; now: a Date.

function total(kind, now) {
    if (kind === "month")
        return new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    return kind === "day" ? 24 : 52;
}

function fraction(kind, now) {
    const minutes = now.getHours() * 60 + now.getMinutes();
    if (kind === "month")
        return (now.getDate() - 1 + minutes / 1440) / total(kind, now);
    if (kind === "day")
        return minutes / 1440;
    const start = new Date(now.getFullYear(), 0, 1);
    const end = new Date(now.getFullYear() + 1, 0, 1);
    return (now - start) / (end - start);
}

function caption(kind, now) {
    if (kind === "month")
        return Qt.formatDate(now, "MMM yyyy");
    return kind === "day" ? Qt.formatDate(now, "MMM d") : Qt.formatDate(now, "yyyy");
}
