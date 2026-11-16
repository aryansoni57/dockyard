/*
 * SPDX-FileCopyrightText: Oliver Beard
 * SPDX-FileCopyrightText: David Edmundson
 * SPDX-FileCopyrightText: Dockyard
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.workspace.keyboardlayout as Keyboards

import org.kde.plasma.login as PlasmaLogin

Item {
    id: root
    anchors.fill: parent

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property date now: new Date()

    // Small clear capsule used for the top-right controls (36 px, as in the design brief).
    component IconButton: Capsule {
        id: btn

        property string iconName: ""
        property string label: ""
        signal clicked()

        width: 36
        height: 36
        // Hover lifts only the alpha; the blur behind stays.
        fill: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : DockyardTheme.clearFill
        stroke: DockyardTheme.hi
        hiInset: 14

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: btn.iconName
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
        Accessible.role: Accessible.Button
        Accessible.name: btn.label
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // A failed attempt shows red for this long, then the capsule resets.
    Timer {
        id: failedResetTimer
        interval: 1500
        onTriggered: login.failed = false
    }

    PlasmaLogin.GreeterEventFilter {
        window: root.Window.window

        onKeyPressed: {
            // callLater, as otherwise 'enter' key press would arrive after waking
            // and the uiVisible check would pass and a login attempt would be made
            Qt.callLater(() => PlasmaLogin.GreeterState.activateWindow(loginScreenRoot.Window.window));
        }

        onEscapeKeyPressed: {
            PlasmaLogin.GreeterState.timeoutWindow(loginScreenRoot.Window.window);
            if (Keyboards.KWinVirtualKeyboard.visible) {
                Keyboards.KWinVirtualKeyboard.active = false;
            }
            PlasmaLogin.GreeterState.clearPasswords();
        }
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        hoverEnabled: true

        property bool uiVisible: PlasmaLogin.GreeterState.activeWindow === Window.window

        cursorShape: uiVisible ? Qt.ArrowCursor : Qt.BlankCursor

        onPressed: PlasmaLogin.GreeterState.activateWindow(Window.window);
        onPositionChanged: PlasmaLogin.GreeterState.activateWindow(Window.window);
        // A click on empty space puts the caret back in the active input.
        onClicked: login.focusInput()

        Item {
            id: stage
            anchors.fill: parent
            opacity: 0
            scale: login.unlocking ? 1.04 : 1
            Behavior on scale {
                NumberAnimation { duration: 450; easing.type: Easing.OutQuint }
            }
            Component.onCompleted: stageIn.start()

            NumberAnimation { id: stageIn; target: stage; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutQuint }
            NumberAnimation { id: stageOut; target: stage; property: "opacity"; to: 0; duration: 450; easing.type: Easing.OutQuint }

            // Welcome, weather, password capsule and the control row hide when the UI is idle.
            Item {
                id: uiLayer
                anchors.fill: parent
                opacity: loginScreenRoot.uiVisible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }

                Login {
                    id: login
                    anchors.fill: parent
                    loginScreenUiVisible: loginScreenRoot.uiVisible
                    capsLockOn: capsLockState.locked

                    onLoginRequest: (username, password) => root.handleLoginRequest(username, password)
                }

                // Top-right controls: keyboard layout, on-screen keyboard, session, power, user prompt toggle.
                Row {
                    id: controlRow
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 20
                        rightMargin: 24
                    }
                    spacing: 8

                    KeyboardButton {
                        height: 36
                    }

                    IconButton {
                        iconName: Keyboards.KWinVirtualKeyboard.visible ? "input-keyboard-virtual-hide" : "input-keyboard-virtual-show"
                        label: Keyboards.KWinVirtualKeyboard.visible
                            ? i18ndc("plasmashellprivateplugin", "@action:button", "Hide On-Screen Keyboard")
                            : i18ndc("plasmashellprivateplugin", "@action:button", "Show On-Screen Keyboard")
                        onClicked: {
                            if (Keyboards.KWinVirtualKeyboard.visible) {
                                Keyboards.KWinVirtualKeyboard.active = false;
                            } else {
                                login.focusInput();
                                Keyboards.KWinVirtualKeyboard.forceActivate();
                            }
                        }
                    }

                    SessionButton {
                        height: 36
                    }

                    IconButton {
                        iconName: "system-hibernate"
                        label: i18ndc("plasma_login", "Suspend to disk", "Hibernate")
                        visible: PlasmaLogin.SessionManagement.canHibernate
                        onClicked: {
                            PlasmaLogin.GreeterState.clearPasswords();
                            PlasmaLogin.SessionManagement.hibernate();
                        }
                    }

                    IconButton {
                        iconName: "system-suspend"
                        label: i18ndc("plasma_login", "Suspend to RAM", "Sleep")
                        visible: PlasmaLogin.SessionManagement.canSuspend
                        onClicked: {
                            PlasmaLogin.GreeterState.clearPasswords();
                            PlasmaLogin.SessionManagement.suspend();
                        }
                    }

                    IconButton {
                        iconName: "system-reboot"
                        label: i18nd("plasma_login", "Restart")
                        visible: PlasmaLogin.SessionManagement.canReboot
                        onClicked: PlasmaLogin.SessionManagement.requestReboot(PlasmaLogin.SessionManagement.ConfirmationMode.Skip)
                    }

                    IconButton {
                        iconName: "system-shutdown"
                        label: i18nd("plasma_login", "Shut Down")
                        visible: PlasmaLogin.SessionManagement.canShutdown
                        onClicked: PlasmaLogin.SessionManagement.requestShutdown(PlasmaLogin.SessionManagement.ConfirmationMode.Skip)
                    }

                    // Shows "Other..." on the user list and "List Users" on the username prompt.
                    IconButton {
                        iconName: login.usernamePrompt ? "system-user-list" : "system-user-prompt"
                        label: login.usernamePrompt
                            ? i18nd("plasma_login", "List Users")
                            : i18ndc("plasma_login", "For switching to a username and password prompt", "Other…")
                        visible: !PlasmaLogin.GreeterState.beyondUserLimit
                        onClicked: PlasmaLogin.GreeterState.loginState = login.usernamePrompt
                            ? PlasmaLogin.GreeterState.LoginState.UserList
                            : PlasmaLogin.GreeterState.LoginState.UserPrompt
                    }
                }

                // Dockyard: the hint sits on a small frosted pill, so it reads on the bright wallpaper.
                Capsule {
                    anchors {
                        top: controlRow.bottom
                        right: parent.right
                        topMargin: 8
                        rightMargin: 24
                    }
                    width: hint.implicitWidth + 24
                    height: 24
                    fill: DockyardTheme.clearFill
                    stroke: DockyardTheme.hi
                    hiInset: 10
                    shadowOffset: 4
                    shadowColor: "transparent"

                    Text {
                        id: hint
                        anchors.centerIn: parent
                        text: i18nd("plasma_login", "Type your password to log in")
                        color: DockyardTheme.text
                        font { family: DockyardTheme.face; pixelSize: 12 }
                    }
                }
            }

            // Toggle disc and clock capsule stay visible when idle, as on the lock screen.
            Row {
                id: bottom
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 64
                }
                spacing: 16
                opacity: 0
                property real dy: 30
                transform: Translate { y: bottom.dy }
                Component.onCompleted: bottomIn.start()

                ParallelAnimation {
                    id: bottomIn
                    PauseAnimation { duration: 100 }
                    NumberAnimation { target: bottom; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutQuint }
                    NumberAnimation { target: bottom; property: "dy"; to: 0; duration: 450; easing.type: Easing.OutQuint }
                }

                // Decorative toggle disc: both toggles flip when the password is accepted.
                Capsule {
                    width: 104
                    height: 104
                    fill: DockyardTheme.glassFill
                    stroke: DockyardTheme.hi
                    hiInset: 30

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Repeater {
                            model: 2
                            delegate: Rectangle {
                                id: toggle
                                required property int index
                                readonly property bool on: (index === 0) !== login.unlocking
                                width: 44
                                height: 24
                                radius: 12
                                color: "transparent"
                                border.width: 2
                                border.color: DockyardTheme.text
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: toggle.on ? 5 : parent.width - width - 5
                                    color: toggle.on ? "transparent" : DockyardTheme.text
                                    border.width: 2
                                    border.color: DockyardTheme.text
                                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                }
                            }
                        }
                    }
                }

                Capsule {
                    id: clock
                    visible: PlasmaLogin.Settings.showClock
                    width: Math.max(timeText.implicitWidth, dateText.implicitWidth) + 96
                    height: 104
                    fill: DockyardTheme.glassFill
                    stroke: DockyardTheme.hi
                    hiInset: 40

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            id: timeText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(root.now, "hh:mm AP").toUpperCase()
                            color: DockyardTheme.text
                            font { family: DockyardTheme.face; pixelSize: 48; weight: Font.DemiBold; letterSpacing: -1; features: { "tnum": 1 } }
                        }
                        Text {
                            id: dateText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
                            color: DockyardTheme.text
                            font { family: DockyardTheme.face; pixelSize: 20; weight: Font.Light }
                        }
                    }
                }
            }
        }
    }

    function handleLoginRequest(username, password) {
        // GreeterState handles updating stateconfig with user/session of successful login
        PlasmaLogin.GreeterState.handleLoginRequest(username, password);
    }

    Connections {
        target: PlasmaLogin.Authenticator

        // e.g. pam_u2f's "cue" asking the user to touch their key. Not auto-cleared:
        // Login.submit() clears it on the next attempt.
        function onInformationMessage(message) {
            login.infoMessage = message;
        }

        function onLoginFailed() {
            login.busy = false;
            login.failed = true;
            login.shake();
            failedResetTimer.restart();
            login.focusInput();
        }

        function onLoginSucceeded() {
            login.unlocking = true;
            stageOut.start();
        }
    }
}
