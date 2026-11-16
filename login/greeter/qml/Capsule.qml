/*
 * Rounded glass capsule from LockScreenUi.qml: fill, 1 px edge, top highlight and drop shadow.
 * Children go into the capsule (default property), anchored to its inner area.
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import Qt5Compat.GraphicalEffects

import org.kde.plasma.login as PlasmaLogin

Item {
    id: capsule

    property color fill: DockyardTheme.islandFill
    property color stroke: DockyardTheme.edge
    property int strokeWidth: 1
    property real radius: height / 2
    // Inset of the 1 px top highlight from each side (lock screen uses 18, 22, 30 or 40).
    property real hiInset: 18
    // Read by GlassBlur (C++) by name: frost behind this capsule, and its radius.
    property bool glassBlur: true
    property real shadowOffset: 12
    property color shadowColor: DockyardTheme.shadow

    Component.onCompleted: PlasmaLogin.GlassBlur.addItem(capsule)
    Component.onDestruction: PlasmaLogin.GlassBlur.removeItem(capsule)

    default property alias content: inner.data

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: capsule.radius
        color: capsule.fill
        border.width: capsule.strokeWidth
        border.color: capsule.stroke
        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Sheen: light falls off from the top edge, like a lit glass pane.
        Rectangle {
            anchors.fill: parent
            radius: capsule.radius
            visible: DockyardTheme.glass
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.08) }
            }
        }
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 1
                leftMargin: capsule.hiInset
                rightMargin: capsule.hiInset
            }
            height: 1
            color: DockyardTheme.glass ? Qt.rgba(1, 1, 1, 0.45) : DockyardTheme.hi
        }
    }

    // Outer-only shadow, like CSS box-shadow: the part under the capsule is cut out,
    // so a translucent fill does not show a dark smudge through the glass.
    Item {
        id: shadowLayer
        readonly property real pad: 56
        x: -pad
        y: -pad
        width: capsule.width + 2 * pad
        height: capsule.height + 2 * pad
        z: -1
        // Software rendering draws no DropShadow (same rule as upstream Main.qml).
        visible: GraphicsInfo.api !== GraphicsInfo.Software
        layer.enabled: visible
        layer.effect: OpacityMask {
            maskSource: hole
            invert: true
        }
        Rectangle {
            id: shape
            x: shadowLayer.pad
            y: shadowLayer.pad
            width: capsule.width
            height: capsule.height
            radius: capsule.radius
            color: "black"
            visible: false
        }
        DropShadow {
            anchors.fill: shape
            source: shape
            transparentBorder: true
            verticalOffset: capsule.shadowOffset
            radius: 32
            samples: 33
            color: capsule.shadowColor
        }
    }
    Item {
        id: hole
        width: shadowLayer.width
        height: shadowLayer.height
        visible: false
        layer.enabled: true
        Rectangle {
            x: shadowLayer.pad
            y: shadowLayer.pad
            width: capsule.width
            height: capsule.height
            radius: capsule.radius
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
