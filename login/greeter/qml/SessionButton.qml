/*
    SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import org.kde.plasma.login as PlasmaLogin

PlasmaComponents.ComboBox {
    id: root

    model: PlasmaLogin.SessionModel
    textRole: "display"

    visible: count > 1
    flat: true
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: indicator.width + 12
    indicator.anchors.rightMargin: 12
    popup.topPadding: 6
    popup.bottomPadding: 6
    popup.leftPadding: 6
    popup.rightPadding: 6
    displayText: i18nd("plasma_login", "Desktop Session: %1", currentText)

    // Dockyard: 36 px clear capsule with the island popup, as the lock screen's controls.
    background: Rectangle {
        id: glassBg
        implicitWidth: 200
        implicitHeight: 36
        radius: height / 2
        color: DockyardTheme.clearFill
        border.width: 1
        border.color: DockyardTheme.hi

        // Dockyard: frost behind this control (GlassBlur reads radius and visibility).
        Component.onCompleted: PlasmaLogin.GlassBlur.addItem(glassBg)
        Component.onDestruction: PlasmaLogin.GlassBlur.removeItem(glassBg)
    }
    popup.background: Rectangle {
        id: popupBg
        radius: 18
        Component.onCompleted: PlasmaLogin.GlassBlur.addItem(popupBg)
        Component.onDestruction: PlasmaLogin.GlassBlur.removeItem(popupBg)
        color: DockyardTheme.islandFill
        border.width: 1
        border.color: DockyardTheme.edge
    }

    contentItem: QQC2.Label {
        font: root.font
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: DockyardTheme.text
        leftPadding: 16
        rightPadding: 16

        text: root.displayText
    }

    // Dockyard: session items are plain translucent rows (no Breeze highlight frame) over the frosted popup.
    delegate: QQC2.ItemDelegate {
        width: ListView.view.width
        highlighted: root.highlightedIndex === index
        text: model.display
        contentItem: QQC2.Label {
            text: parent.text
            color: DockyardTheme.text
            leftPadding: 12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 12
            color: (parent.highlighted || parent.hovered) ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
        }
    }

    // Dockyard: glass tooltip for a truncated session name, frosted like the capsules.
    QQC2.ToolTip {
        id: tip
        text: root.currentText
        visible: root.hovered && root.contentItem.truncated && !root.popup.visible
        delay: Kirigami.Units.toolTipDelay
        contentItem: Text {
            text: tip.text
            color: DockyardTheme.text
            font.family: DockyardTheme.face
            font.pixelSize: 12
        }
        background: Rectangle {
            id: tipBg
            radius: height / 2
            color: DockyardTheme.islandFill
            border.width: 1
            border.color: DockyardTheme.edge
            Component.onCompleted: PlasmaLogin.GlassBlur.addItem(tipBg)
            Component.onDestruction: PlasmaLogin.GlassBlur.removeItem(tipBg)
        }
    }

    Binding {
        target: PlasmaLogin.GreeterState
        property: "greeterHasSessionButtonPopup"
        value: true
        when: popup.visible
    }

    currentIndex: PlasmaLogin.GreeterState.sessionIndex

    Connections {
        target: PlasmaLogin.GreeterState

        function onSessionIndexChanged() {
            if (root.currentIndex != PlasmaLogin.GreeterState.sessionIndex) {
                root.currentIndex = PlasmaLogin.GreeterState.sessionIndex;
            }
        }
    }

    onCurrentIndexChanged: {
        PlasmaLogin.GreeterState.sessionIndex = root.currentIndex;
    }
}
