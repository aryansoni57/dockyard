/*
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2022 Aleix Pol Gonzalez <aleixpol@kde.org>
    SPDX-FileCopyrightText: Dockyard

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.components as WorkspaceComponents

import org.kde.plasma.login as PlasmaLogin

PlasmaComponents.ToolButton {
    id: root

    focusPolicy: Qt.TabFocus
    Accessible.description: i18ndc("plasma_login", "Button to change keyboard layout", "Switch layout")
    icon.name: "input-keyboard"
    icon.color: DockyardTheme.text
    palette.buttonText: DockyardTheme.text

    // Dockyard: 36 px clear capsule, as the lock screen's controls.
    implicitHeight: 36
    background: Rectangle {
        id: glassBg
        radius: height / 2
        // Hover lifts only the alpha; the blur behind stays.
        color: root.hovered ? Qt.rgba(1, 1, 1, 0.18) : DockyardTheme.clearFill
        border.width: 1
        border.color: DockyardTheme.hi

        // Dockyard: frost behind this control (GlassBlur reads radius and visibility).
        Component.onCompleted: PlasmaLogin.GlassBlur.addItem(glassBg)
        Component.onDestruction: PlasmaLogin.GlassBlur.removeItem(glassBg)
    }

    WorkspaceComponents.KeyboardLayoutSwitcher {
        id: keyboardLayoutSwitcher

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
    }

    text: keyboardLayoutSwitcher.layoutNames.longName
    onClicked: keyboardLayoutSwitcher.keyboardLayout.switchToNextLayout()

    visible: keyboardLayoutSwitcher.hasMultipleKeyboardLayouts
}
