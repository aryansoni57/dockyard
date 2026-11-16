/*
 * Dockyard login content. Layout, sizes and motion follow the Dockyard lock screen LockScreenUi.qml:
 * welcome capsule on top, weather plane in the middle, password capsule with dots in the centre.
 * Auth, user and session state stay in GreeterState (upstream); this file only shows them.
 *
 * SPDX-FileCopyrightText: Oliver Beard
 * SPDX-FileCopyrightText: David Edmundson
 * SPDX-FileCopyrightText: Dockyard
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami

import org.kde.plasma.login as PlasmaLogin

Item {
    id: root

    // Set by Main.qml.
    property bool loginScreenUiVisible: false
    property string infoMessage: ""
    property bool capsLockOn: false
    property bool failed: false
    property bool busy: false
    property bool unlocking: false

    signal loginRequest(string username, string password)

    // ---- selected user (from GreeterState, replaces the upstream user list) -----------------
    readonly property bool isUserList: PlasmaLogin.GreeterState.loginState === PlasmaLogin.GreeterState.LoginState.UserList
        && !PlasmaLogin.GreeterState.beyondUserLimit
    readonly property bool usernamePrompt: !isUserList
    readonly property int userCount: PlasmaLogin.UserModel.rowCount()

    readonly property var selectedIndex: PlasmaLogin.UserModel.index(PlasmaLogin.GreeterState.userListIndex, 0)
    readonly property string selectedUser: PlasmaLogin.UserModel.data(selectedIndex, PlasmaLogin.UserModel.NameRole) ?? ""
    readonly property string selectedRealName: PlasmaLogin.UserModel.data(selectedIndex, PlasmaLogin.UserModel.RealNameRole) ?? ""
    readonly property bool needsPassword: PlasmaLogin.UserModel.data(selectedIndex, PlasmaLogin.UserModel.NeedsPasswordRole) ?? true
    readonly property string selectedIcon: PlasmaLogin.UserModel.data(selectedIndex, PlasmaLogin.UserModel.IconRole) ?? ""
    readonly property string faceSource: selectedIcon.startsWith("/") ? "file://" + selectedIcon : selectedIcon

    readonly property string rawName: selectedRealName !== "" ? selectedRealName : selectedUser
    readonly property string displayName: rawName.length > 0 ? rawName.charAt(0).toUpperCase() + rawName.slice(1) : "you"

    readonly property string statusText: infoMessage !== ""
        ? infoMessage
        : (failed ? i18nd("plasma_login", "Login Failed")
                  : (capsLockOn ? i18nd("plasma_login", "Caps Lock is on") : ""))

    // ---- actions ----------------------------------------------------------------------------
    function currentUsername() {
        return usernamePrompt ? userInput.text : selectedUser;
    }

    function submit() {
        if (busy || unlocking) {
            return;
        }
        const user = currentUsername();
        if (user === "") {
            if (usernamePrompt) {
                userInput.forceActiveFocus();
            }
            return;
        }
        // A user who has a password needs one before Enter does anything.
        if (!usernamePrompt && needsPassword && input.text.length === 0) {
            return;
        }
        infoMessage = "";
        failed = false;
        busy = true;
        loginRequest(user, input.text);
    }

    function focusInput() {
        if (usernamePrompt && userInput.text.length === 0) {
            userInput.forceActiveFocus();
        } else {
            input.forceActiveFocus();
        }
    }

    function changeUser(step) {
        if (userCount < 1) {
            return;
        }
        PlasmaLogin.GreeterState.userListIndex = Math.max(0, Math.min(userCount - 1, PlasmaLogin.GreeterState.userListIndex + step));
    }

    function shake() {
        shakeAnim.restart();
    }

    function replayGreet() {
        greetIn.stop();
        greetClip.width = 0;
        greetClip.opacity = 0;
        greetIn.restart();
    }

    function playIntro() {
        welcome.opacity = 0;
        welcome.dy = -16;
        usernameCapsule.opacity = 0;
        usernameCapsule.dy = -16;
        weather.opacity = 0;
        weather.dy = 24;
        welcomeIn.restart();
        usernameIn.restart();
        weatherIn.restart();
        replayGreet();
    }

    Component.onCompleted: {
        playIntro();
        focusInput();
    }

    onLoginScreenUiVisibleChanged: {
        if (loginScreenUiVisible) {
            playIntro();
        }
    }

    // ---- intro and shake animations (LockScreenUi.qml lines 113-118, 170-176, 218-225) ------
    ParallelAnimation {
        id: welcomeIn
        NumberAnimation { target: welcome; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutQuint }
        NumberAnimation { target: welcome; property: "dy"; to: 0; duration: 600; easing.type: Easing.OutQuint }
    }
    ParallelAnimation {
        id: usernameIn
        NumberAnimation { target: usernameCapsule; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutQuint }
        NumberAnimation { target: usernameCapsule; property: "dy"; to: 0; duration: 600; easing.type: Easing.OutQuint }
    }
    ParallelAnimation {
        id: weatherIn
        PauseAnimation { duration: 250 }
        NumberAnimation { target: weather; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutQuint }
        NumberAnimation { target: weather; property: "dy"; to: 0; duration: 450; easing.type: Easing.OutQuint }
    }
    ParallelAnimation {
        id: greetIn
        SequentialAnimation {
            PauseAnimation { duration: 500 }
            NumberAnimation { target: greetClip; property: "width"; to: greet.implicitWidth; duration: 450; easing.type: Easing.OutQuint }
        }
        SequentialAnimation {
            PauseAnimation { duration: 500 }
            NumberAnimation { target: greetClip; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutQuint }
        }
    }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
        NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 80 }
        NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 70 }
        NumberAnimation { target: shakeX; property: "x"; to: 8; duration: 70 }
        NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50 }
    }

    // ---- welcome capsule (user list) --------------------------------------------------------
    Capsule {
        id: welcome
        visible: root.isUserList
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 64
        }
        width: 8 + 40 + 12 + greetClip.width + 20
        height: 56
        opacity: 0
        property real dy: -16
        transform: Translate { y: welcome.dy }

        Rectangle {
            id: avatar
            anchors {
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            width: 40
            height: 40
            radius: 20
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: DockyardTheme.accent }
                GradientStop { position: 1; color: DockyardTheme.accent2 }
            }
            Text {
                anchors.centerIn: parent
                text: root.displayName.charAt(0)
                color: "white"
                font { family: DockyardTheme.face; pixelSize: 14; weight: Font.DemiBold }
            }
        }

        // The user's picture, clipped to the circle. Shown only when the file loads.
        Image {
            id: faceImage
            anchors.fill: avatar
            source: root.faceSource
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: OpacityMask { maskSource: faceMask }
        }
        Rectangle {
            id: faceMask
            anchors.fill: avatar
            radius: 20
            visible: false
        }

        Item {
            id: greetClip
            anchors {
                left: avatar.right
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            height: parent.height
            clip: true
            width: 0
            opacity: 0
            Text {
                id: greet
                anchors.verticalCenter: parent.verticalCenter
                text: "Welcome back, " + root.displayName + "!"
                color: DockyardTheme.text
                font { family: DockyardTheme.face; pixelSize: 14 }
            }
        }
    }

    // Chevrons beside the welcome capsule switch the user, as Left and Right do with an empty password.
    Text {
        id: prevUser
        visible: root.isUserList && root.userCount > 1
        anchors {
            right: welcome.left
            rightMargin: 4
            verticalCenter: welcome.verticalCenter
        }
        text: "‹"
        color: DockyardTheme.text2
        font { family: DockyardTheme.face; pixelSize: 26 }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            onClicked: root.changeUser(-1)
        }
    }
    Text {
        id: nextUser
        visible: root.isUserList && root.userCount > 1
        anchors {
            left: welcome.right
            leftMargin: 4
            verticalCenter: welcome.verticalCenter
        }
        text: "›"
        color: DockyardTheme.text2
        font { family: DockyardTheme.face; pixelSize: 26 }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            onClicked: root.changeUser(1)
        }
    }

    // ---- username capsule (no user list, or "Other...") --------------------------------------
    Capsule {
        id: usernameCapsule
        visible: root.usernamePrompt
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 64
        }
        width: 320
        height: 56
        opacity: 0
        property real dy: -16
        transform: Translate { y: usernameCapsule.dy }

        TextInput {
            id: userInput
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 24
                rightMargin: 24
                verticalCenter: parent.verticalCenter
            }
            color: DockyardTheme.text
            font { family: DockyardTheme.face; pixelSize: 16 }
            selectByMouse: true
            enabled: !root.busy && !root.unlocking
            inputMethodHints: Qt.ImhNoPredictiveText
            // Enter moves on to the password, as upstream did.
            onAccepted: input.forceActiveFocus()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: userInput.text.length === 0
                text: i18nd("plasma_login", "Username")
                color: DockyardTheme.text3
                font: userInput.font
            }
        }
    }

    // ---- weather plane (static placeholder text, same as the lock screen) -------------------
    Capsule {
        id: weather
        anchors.centerIn: parent
        width: weatherRow.implicitWidth + 48
        height: weatherRow.implicitHeight + 32
        radius: 36
        hiInset: 22
        fill: DockyardTheme.glassFill
        shadowOffset: 20
        shadowColor: DockyardTheme.shadowWindow
        opacity: 0
        property real dy: 24
        transform: Translate { y: weather.dy }
        visible: !field.shown

        Row {
            id: weatherRow
            anchors.centerIn: parent
            spacing: 20
            Kirigami.Icon { source: "weather-showers"; width: 56; height: 56; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "25°"; color: DockyardTheme.text; font { family: DockyardTheme.face; pixelSize: 36; weight: Font.Light } }
                Text { text: "Ankara · Rainy 27° / 14°"; color: DockyardTheme.text2; font { family: DockyardTheme.face; pixelSize: 12 } }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 208
                wrapMode: Text.WordWrap
                text: "It looks like it's going to start raining soon. Don't forget to take precautions."
                color: DockyardTheme.text2
                font { family: DockyardTheme.face; pixelSize: 12 }
            }
        }
    }

    // ---- password capsule: dots while typing, status text otherwise -------------------------
    Capsule {
        id: field
        readonly property bool shown: input.text.length > 0 || root.failed || root.unlocking
            || root.infoMessage !== "" || root.capsLockOn
        anchors.centerIn: parent
        width: 340
        height: 52
        fill: DockyardTheme.islandFill
        stroke: root.failed ? DockyardTheme.failRed : (root.unlocking ? DockyardTheme.okGreen : DockyardTheme.edge)
        strokeWidth: root.failed || root.unlocking ? 2 : 1
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
        transform: Translate { id: shakeX }

        Row {
            anchors.centerIn: parent
            spacing: 8
            visible: input.text.length > 0
            Repeater {
                model: Math.min(input.text.length, 18)
                delegate: Rectangle { width: 10; height: 10; radius: 5; color: DockyardTheme.text }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: input.text.length === 0
            text: root.statusText
            color: (root.failed && root.infoMessage === "") ? DockyardTheme.failRed : DockyardTheme.text2
            font { family: DockyardTheme.face; pixelSize: 13 }
        }
    }

    // Hidden input: keystrokes go here and the capsule shows only dots.
    TextInput {
        id: input
        width: 0
        height: 0
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        enabled: !root.busy && !root.unlocking

        // Enter with no password submits only when the user has none (submit() checks this).
        onAccepted: root.submit()
        onTextChanged: if (text.length > 0) root.failed = false
        Keys.onEscapePressed: text = ""

        // Left and Right with an empty password switch the user (upstream behaviour).
        Keys.onPressed: event => {
            if (text.length === 0 && root.isUserList) {
                if (event.key === Qt.Key_Left) {
                    root.changeUser(-1);
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Right) {
                    root.changeUser(1);
                    event.accepted = true;
                }
            }
        }
    }

    // ---- state sync: keeps the inputs and GreeterState in step (upstream logic, renamed) -----
    Item {
        id: sync

        Component.onCompleted: {
            if (root.isUserList) {
                input.text = PlasmaLogin.GreeterState.userListPassword;
            } else {
                userInput.text = PlasmaLogin.StateConfig.lastLoggedInUser;
                input.text = PlasmaLogin.GreeterState.userPromptPassword;
            }
        }

        // Login -> GreeterState
        Connections {
            target: userInput

            function onTextChanged() {
                if (!root.isUserList) {
                    if (PlasmaLogin.GreeterState.userPromptUsername != userInput.text) {
                        PlasmaLogin.GreeterState.userPromptUsername = userInput.text;
                    }
                }
            }
        }

        Connections {
            target: input

            function onTextChanged() {
                if (root.isUserList) {
                    if (PlasmaLogin.GreeterState.userListPassword != input.text) {
                        PlasmaLogin.GreeterState.userListPassword = input.text;
                    }
                } else {
                    if (PlasmaLogin.GreeterState.userPromptPassword != input.text) {
                        PlasmaLogin.GreeterState.userPromptPassword = input.text;
                    }
                }
            }
        }

        // GreeterState -> Login
        Connections {
            target: PlasmaLogin.GreeterState

            function onUserListIndexChanged() {
                // A new user starts with an empty password and replays the greeting.
                input.text = "";
                root.replayGreet();
            }

            function onLoginStateChanged() {
                Qt.callLater(root.focusInput);
            }

            function onUserListPasswordChanged() {
                if (!root.isUserList) {
                    return;
                }

                if (input.text != PlasmaLogin.GreeterState.userListPassword) {
                    input.text = PlasmaLogin.GreeterState.userListPassword;
                }
            }

            function onUserPromptUsernameChanged() {
                if (root.isUserList) {
                    return;
                }

                if (userInput.text != PlasmaLogin.GreeterState.userPromptUsername) {
                    userInput.text = PlasmaLogin.GreeterState.userPromptUsername;
                }
            }

            function onUserPromptPasswordChanged() {
                if (root.isUserList) {
                    return;
                }

                if (input.text != PlasmaLogin.GreeterState.userPromptPassword) {
                    input.text = PlasmaLogin.GreeterState.userPromptPassword;
                }
            }
        }
    }
}
