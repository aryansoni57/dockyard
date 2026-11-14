import QtQuick
import org.kde.plasma.private.clipboard as Clipboard

// Starts Klipper inside plasmashell. Klipper normally lives in the System Tray's
// clipboard applet; with no tray in any panel it never starts, and Meta+V
// (Show Clipboard Items at Mouse Position) does nothing. KlipperInterface brings
// up the shared Klipper instance, which then owns its shortcuts and popup.
// The history model reads that same instance, for the dock's clipboard tile and popup.
Item {
    Clipboard.KlipperInterface {}

    // Klipper's history: roles display (text), decoration (image), type (2 text, 4 image, 8 urls), uuid.
    readonly property alias history: historyModel
    readonly property int count: historyModel.count

    Clipboard.HistoryModel {
        id: historyModel
    }
}
