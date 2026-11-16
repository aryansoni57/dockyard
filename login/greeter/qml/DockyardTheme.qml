/*
 * Dockyard greeter theme. Tokens copied from the Dockyard lock screen LockScreenUi.qml (lines 25-35)
 * so the login screen and the lock screen share one look.
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma Singleton

import QtQuick

import org.kde.plasma.login as PlasmaLogin

QtObject {
    // True when the compositor blurs behind the capsules (GlassBlur, C++). Fills are then more transparent.
    readonly property bool glass: PlasmaLogin.GlassBlur.available

    // Theme tokens.
    readonly property color accent: "#0A84FF"
    readonly property color accent2: "#5E5CE6"
    readonly property color text: "#ffffff"
    readonly property color text2: "#aeaeb2"
    readonly property color text3: "#8e8e93"
    readonly property color islandFill: glass ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0.11, 0.11, 0.118, 0.70)
    readonly property color glassFill: glass ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0.11, 0.11, 0.118, 0.62)
    readonly property color clearFill: glass ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0.11, 0.11, 0.118, 0.55)
    readonly property color edge: glass ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.14)
    readonly property color hi: Qt.rgba(1, 1, 1, 0.16)
    readonly property string face: "Inter"

    // Shadow and state colours used by the lock screen.
    readonly property color shadow: "#59000000"
    readonly property color shadowWindow: "#73000000"   // web window shadow 0.45
    readonly property color failRed: "#ff5252"
    readonly property color okGreen: "#34c759"
}
