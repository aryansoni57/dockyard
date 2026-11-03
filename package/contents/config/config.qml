import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Widgets")
        icon: "view-grid"
        source: "configWidgets.qml"
    }
    ConfigCategory {
        name: i18n("Apps")
        icon: "applications-all"
        source: "configApps.qml"
    }
    ConfigCategory {
        name: i18n("Clock & Calendar")
        icon: "preferences-system-time"
        source: "configClock.qml"
    }
    ConfigCategory {
        name: i18n("Weather")
        icon: "weather-few-clouds"
        source: "configWeather.qml"
    }
    ConfigCategory {
        name: i18n("System")
        icon: "preferences-system"
        source: "configSystem.qml"
    }
}
