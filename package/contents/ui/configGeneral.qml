import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showClock: showClock.checked
    property alias cfg_showStats: showStats.checked
    property alias cfg_showMedia: showMedia.checked
    property alias cfg_statsInterval: statsInterval.value

    property alias cfg_showTemperature: showTemperature.checked
    property alias cfg_showNetwork: showNetwork.checked
    property alias cfg_showStorage: showStorage.checked
    property alias cfg_showBattery: showBattery.checked
    property alias cfg_showWeather: showWeather.checked
    property alias cfg_showPomodoro: showPomodoro.checked
    property alias cfg_showTimer: showTimer.checked
    property alias cfg_showStopwatch: showStopwatch.checked
    property alias cfg_showWorldClocks: showWorldClocks.checked
    property alias cfg_showTodos: showTodos.checked

    property alias cfg_batteryDevice: batteryDevice.text
    property alias cfg_latitude: latitude.text
    property alias cfg_longitude: longitude.text
    property alias cfg_fahrenheit: fahrenheit.checked
    property alias cfg_worldZones: worldZones.text

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showClock
            Kirigami.FormData.label: i18n("Modules:")
            text: i18n("Clock")
        }
        QQC2.CheckBox {
            id: showStats
            text: i18n("CPU and RAM")
        }
        QQC2.CheckBox {
            id: showMedia
            text: i18n("Now playing")
        }
        QQC2.CheckBox {
            id: showTemperature
            text: i18n("CPU temperature")
        }
        QQC2.CheckBox {
            id: showNetwork
            text: i18n("Network speed")
        }
        QQC2.CheckBox {
            id: showStorage
            text: i18n("Disk usage")
        }
        QQC2.CheckBox {
            id: showBattery
            text: i18n("Battery")
        }
        QQC2.CheckBox {
            id: showWeather
            text: i18n("Weather")
        }
        QQC2.CheckBox {
            id: showPomodoro
            text: i18n("Pomodoro")
        }
        QQC2.CheckBox {
            id: showTimer
            text: i18n("Timer")
        }
        QQC2.CheckBox {
            id: showStopwatch
            text: i18n("Stopwatch")
        }
        QQC2.CheckBox {
            id: showWorldClocks
            text: i18n("World clocks")
        }
        QQC2.CheckBox {
            id: showTodos
            text: i18n("Todos")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Settings")
        }
        QQC2.SpinBox {
            id: statsInterval
            Kirigami.FormData.label: i18n("Stats refresh (ms):")
            from: 500
            to: 60000
            stepSize: 500
        }
        QQC2.TextField {
            id: batteryDevice
            Kirigami.FormData.label: i18n("Battery device:")
            placeholderText: "SerialNumber"
        }
        QQC2.TextField {
            id: latitude
            Kirigami.FormData.label: i18n("Weather latitude:")
            validator: DoubleValidator { bottom: -90; top: 90 }
        }
        QQC2.TextField {
            id: longitude
            Kirigami.FormData.label: i18n("Weather longitude:")
            validator: DoubleValidator { bottom: -180; top: 180 }
        }
        QQC2.CheckBox {
            id: fahrenheit
            text: i18n("Fahrenheit")
        }
        QQC2.TextField {
            id: worldZones
            Kirigami.FormData.label: i18n("World clock zones:")
            placeholderText: "America/New_York,Europe/London,Asia/Tokyo"
        }
    }
}
