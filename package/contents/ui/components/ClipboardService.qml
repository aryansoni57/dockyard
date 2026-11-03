import QtQuick
import org.kde.plasma.private.clipboard as Clipboard

// Starts Klipper inside plasmashell. Klipper normally lives in the System Tray's
// clipboard applet; with no tray in any panel it never starts, and Meta+V
// (Show Clipboard Items at Mouse Position) does nothing. KlipperInterface brings
// up the shared Klipper instance, which then owns its shortcuts and popup.
Item {
    Clipboard.KlipperInterface {}
}
