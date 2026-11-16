import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker
import org.kde.plasma.private.sessions
import org.kde.breeze.components

// Dockyard lock screen:
// welcome capsule on top, weather plane in the middle, toggle disc and clock capsule at the bottom.
// The password field is the one addition: it appears with the first key press.
Item {
    id: ui

    readonly property string userName: kscreenlocker_userName
    readonly property string displayName: userName.length > 0 ? userName.charAt(0).toUpperCase() + userName.slice(1) : "you"

    property string message: ""
    property bool failed: false
    property bool unlocking: false
    property int shakes: 0
    property date now: new Date()

    // Theme tokens.
    readonly property color accent: "#0A84FF"
    readonly property color accent2: "#5E5CE6"
    readonly property color text: "#ffffff"
    readonly property color text2: "#aeaeb2"
    readonly property color text3: "#8e8e93"
    readonly property color islandFill: Qt.rgba(28 / 255, 28 / 255, 30 / 255, 0.82)
    readonly property color clearFill: Qt.rgba(1, 1, 1, 0.12)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.14)
    readonly property color hi: Qt.rgba(1, 1, 1, 0.16)
    readonly property color glassTint: Qt.rgba(1, 1, 1, 0.03)
    readonly property color glassTintLight: Qt.rgba(1, 1, 1, 0.03)
    readonly property string face: "Inter"

    Timer { interval: 1000; running: true; repeat: true; onTriggered: ui.now = new Date() }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) return;
            ui.failed = true;
            ui.message = "Wrong password";
            ui.shakes++;
            input.text = "";
            retry.restart();
        }
        function onSucceeded() {
            ui.unlocking = true;
            quitTimer.start();
        }
        function onPromptForSecretChanged(msg) { input.forceActiveFocus(); }
        function onErrorMessageChanged() { if (authenticator.errorMessage) ui.message = authenticator.errorMessage; }
        function onInfoMessageChanged() { if (authenticator.infoMessage) ui.message = authenticator.infoMessage; }
    }
    Connections { target: root; function onClearPassword() { input.text = ""; ui.failed = false; } }

    // Lets the toggles finish flipping before the greeter exits.
    Timer { id: quitTimer; interval: 450; onTriggered: Qt.quit() }
    Timer { id: retry; interval: 1500; onTriggered: { ui.failed = false; ui.message = ""; authenticator.startAuthenticating(); } }

    // The wallpaper plugin, drawn unfaded.
    Item { id: dummyStack }
    Item { id: dummyFooter }
    Item { id: dummyClock; property Item shadow: Item {} }
    WallpaperFader {
        id: wp
        anchors.fill: parent
        state: "off"
        source: wallpaper
        mainStack: dummyStack
        footer: dummyFooter
        clock: dummyClock
    }

    // One shared blurred copy of the wallpaper; every glass pane samples it.
    ShaderEffectSource { id: wpSrc; anchors.fill: parent; sourceItem: wp; live: true; visible: false }
    FastBlur { id: blurred; anchors.fill: parent; source: wpSrc; radius: 72; transparentBorder: false; visible: false }
    HueSaturation { id: backdrop; anchors.fill: parent; source: blurred; saturation: 0.0; lightness: 0.0; visible: false }

    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        scale: ui.unlocking ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }
        Component.onCompleted: { fade.start(); authenticator.startAuthenticating(); typing.forceActiveFocus(); }
        NumberAnimation { id: fade; target: stage; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutQuint }

        // Typing anywhere goes to the hidden input; the capsule only shows dots.
        FocusScope {
            id: typing
            anchors.fill: parent
            focus: true
            TextInput {
                id: input
                width: 0; height: 0
                focus: true
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                enabled: !ui.unlocking
                onAccepted: { if (text.length > 0) authenticator.respond(text); }
                onTextChanged: if (text.length > 0) ui.failed = false
                Keys.onEscapePressed: { text = ""; ui.message = ""; }
            }
            MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }
        }

        // ---- welcome capsule -------------------------------------------------------------------
        Item {
            id: welcome
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 64 }
            width: 8 + 40 + 12 + greetClip.width + 20
            height: 56
            opacity: 0
            property real dy: -16
            transform: Translate { y: welcome.dy }
            Component.onCompleted: welcomeIn.start()
            ParallelAnimation {
                id: welcomeIn
                NumberAnimation { target: welcome; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutQuint }
                NumberAnimation { target: welcome; property: "dy"; to: 0; duration: 600; easing.type: Easing.OutQuint }
            }

            Glass { id: welcomeBg; anchors.fill: parent; backdrop: backdrop; tint: ui.glassTint }

            Rectangle {
                id: avatar
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                width: 40; height: 40; radius: 20
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: ui.accent }
                    GradientStop { position: 1; color: ui.accent2 }
                }
                Text { anchors.centerIn: parent; text: ui.displayName.charAt(0); color: "white"; font { family: ui.face; pixelSize: 14; weight: Font.DemiBold } }
            }
            Item {
                id: greetClip
                anchors { left: avatar.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                height: parent.height
                clip: true
                width: 0
                opacity: 0
                Text {
                    id: greet
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Welcome back, " + ui.displayName + "!"
                    color: ui.text
                    font { family: ui.face; pixelSize: 14 }
                }
                SequentialAnimation on width { running: true; PauseAnimation { duration: 500 } NumberAnimation { to: greet.implicitWidth; duration: 450; easing.type: Easing.OutQuint } }
                SequentialAnimation on opacity { running: true; PauseAnimation { duration: 500 } NumberAnimation { to: 1; duration: 450; easing.type: Easing.OutQuint } }
            }
        }

        // ---- weather plane (static placeholder text, same as the web mock) ---------------------
        Item {
            id: weather
            anchors.centerIn: parent
            width: weatherRow.implicitWidth + 48
            height: weatherRow.implicitHeight + 32
            opacity: 0
            property real dy: 24
            transform: Translate { y: weather.dy }
            visible: !field.shown
            Component.onCompleted: weatherIn.start()
            ParallelAnimation {
                id: weatherIn
                PauseAnimation { duration: 250 }
                NumberAnimation { target: weather; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutQuint }
                NumberAnimation { target: weather; property: "dy"; to: 0; duration: 450; easing.type: Easing.OutQuint }
            }
            Glass { id: weatherBg; anchors.fill: parent; radius: 36; backdrop: backdrop; tint: ui.glassTint }
            Row {
                id: weatherRow
                anchors.centerIn: parent
                spacing: 20
                Kirigami.Icon { source: "weather-showers"; width: 56; height: 56; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "25°"; color: ui.text; font { family: ui.face; pixelSize: 36; weight: Font.Light } }
                    Text { text: "Ankara · Rainy 27° / 14°"; color: ui.text2; font { family: ui.face; pixelSize: 12 } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 208
                    wrapMode: Text.WordWrap
                    text: "It looks like it's going to start raining soon. Don't forget to take precautions."
                    color: ui.text2
                    font { family: ui.face; pixelSize: 12 }
                }
            }
        }

        // ---- password capsule --------------------------------------------------------------------
        Item {
            id: field
            readonly property bool shown: input.text.length > 0 || ui.failed || ui.unlocking
            anchors.centerIn: parent
            width: 300; height: 52
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
            transform: Translate { id: shakeX }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 80 }
                NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: 8; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50 }
            }
            Connections { target: ui; function onShakesChanged() { shake.restart(); } }

            Glass {
                id: fieldBg
                anchors.fill: parent
                backdrop: backdrop
                tint: ui.glassTint
                borderWidth: ui.failed || ui.unlocking ? 2 : 1
                borderColor: ui.failed ? "#ff5252" : (ui.unlocking ? "#34c759" : Qt.rgba(1, 1, 1, 0.30))
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                visible: input.text.length > 0
                Repeater {
                    model: Math.min(input.text.length, 18)
                    delegate: Rectangle { width: 10; height: 10; radius: 5; color: ui.text }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: ui.message
                color: ui.failed ? "#ff5252" : ui.text2
                font { family: ui.face; pixelSize: 13 }
            }
        }

        // ---- toggle disc + clock capsule ---------------------------------------------------------
        Row {
            id: bottom
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 64 }
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

            Item {
                width: 104; height: 104
                Glass { id: discBg; anchors.fill: parent; backdrop: backdrop; tint: ui.glassTintLight }
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: 2
                        delegate: Rectangle {
                            id: toggle
                            required property int index
                            // Both toggles flip when the password is accepted.
                            readonly property bool on: (index === 0) !== ui.unlocking
                            width: 44; height: 24; radius: 12
                            color: "transparent"
                            border.width: 2
                            border.color: ui.text
                            Rectangle {
                                width: 14; height: 14; radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                x: toggle.on ? 5 : parent.width - width - 5
                                color: toggle.on ? "transparent" : ui.text
                                border.width: 2
                                border.color: ui.text
                                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                            }
                        }
                    }
                }
            }

            Item {
                width: Math.max(timeText.implicitWidth, dateText.implicitWidth) + 96
                height: 104
                Glass { id: clockBg; anchors.fill: parent; backdrop: backdrop; tint: ui.glassTintLight }
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        id: timeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(ui.now, "hh:mm AP").toUpperCase()
                        color: ui.text
                        font { family: ui.face; pixelSize: 48; weight: Font.DemiBold; letterSpacing: -1; features: { "tnum": 1 } }
                    }
                    Text {
                        id: dateText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(ui.now, "dddd, d MMMM")
                        color: ui.text
                        font { family: ui.face; pixelSize: 20; weight: Font.Light }
                    }
                }
            }
        }

        Text {
            anchors { right: parent.right; rightMargin: 24; top: parent.top; topMargin: 20 }
            text: "Type your password to unlock"
            color: ui.text3
            font { family: ui.face; pixelSize: 12 }
        }
    }
}
