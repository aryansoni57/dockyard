import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "settings"

// Location and units for the Weather tile, the Clock tile and the forecast clock styles.
KCM.SimpleKCM {
    id: page

    property alias cfg_latitude: latitude.text
    property alias cfg_longitude: longitude.text
    property string cfg_locationName
    property bool cfg_fahrenheit

    readonly property bool hasLocation: (Number(cfg_latitude) || 0) !== 0 || (Number(cfg_longitude) || 0) !== 0
    property var results: []
    property string status

    function setLocation(lat, lon, name) {
        latitude.text = Number(lat).toFixed(4);
        longitude.text = Number(lon).toFixed(4);
        cfg_locationName = name;
        results = [];
        status = "";
    }

    function getJson(url, onDone) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            try {
                if (xhr.status !== 200)
                    throw new Error(xhr.status);
                onDone(JSON.parse(xhr.responseText));
            } catch (e) {
                page.status = i18n("Lookup failed. Check your connection.");
            }
        };
        status = i18n("Looking up…");
        xhr.open("GET", url);
        xhr.send();
    }

    function searchCity() {
        getJson("https://geocoding-api.open-meteo.com/v1/search?count=6&name="
                + encodeURIComponent(cityField.text.trim()), function (d) {
            page.results = d.results || [];
            page.status = page.results.length === 0 ? i18n("No city called “%1”", cityField.text.trim()) : "";
        });
    }

    function detectLocation() {
        getJson("https://ipapi.co/json/", function (d) {
            if (d.latitude === undefined || d.longitude === undefined)
                throw new Error("no coordinates");
            setLocation(d.latitude, d.longitude,
                        (d.city || "") + (d.country_name ? ", " + d.country_name : ""));
        });
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        Card {
            title: i18n("Location")
            subtitle: i18n("Used by the Weather tile, the Clock tile and the 7 days and Today clock styles.")

            // Current location, front and centre.
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: page.hasLocation ? "mark-location" : "dialog-warning"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: !page.hasLocation ? i18n("No location set")
                            : page.cfg_locationName !== "" ? page.cfg_locationName : i18n("Custom coordinates")
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        text: page.hasLocation ? i18n("%1, %2", page.cfg_latitude, page.cfg_longitude)
                            : i18n("Weather stays empty until you pick a city.")
                        opacity: 0.6
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
                QQC2.Button {
                    icon.name: "find-location"
                    text: i18n("Detect")
                    onClicked: page.detectLocation()
                    QQC2.ToolTip.text: i18n("Guess from your IP address (ipapi.co)")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            Kirigami.SearchField {
                id: cityField
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                placeholderText: i18n("Search for a city, then press Enter")
                autoAccept: false
                // Take Enter here, or the settings dialog treats it as OK and closes.
                Keys.onReturnPressed: event => {
                    event.accepted = true;
                    if (text.trim() !== "")
                        page.searchCity();
                }
                Keys.onEnterPressed: event => {
                    event.accepted = true;
                    if (text.trim() !== "")
                        page.searchCity();
                }
            }
            QQC2.Label {
                visible: page.status !== ""
                text: page.status
                opacity: 0.7
                Layout.fillWidth: true
            }

            // Results: several cities can share a name, so let the user pick.
            Repeater {
                model: page.results

                QQC2.ItemDelegate {
                    id: hit
                    required property var modelData
                    readonly property string place: modelData.name
                        + (modelData.admin1 ? ", " + modelData.admin1 : "")
                        + (modelData.country ? ", " + modelData.country : "")
                    Layout.fillWidth: true
                    icon.name: "mark-location"
                    text: place
                    onClicked: page.setLocation(modelData.latitude, modelData.longitude,
                                                modelData.name + (modelData.country ? ", " + modelData.country : ""))
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }
            QQC2.CheckBox {
                id: manual
                text: i18n("Enter coordinates by hand")
            }
            FormRow {
                visible: manual.checked
                label: i18n("Latitude, longitude:")
                QQC2.TextField {
                    id: latitude
                    Layout.fillWidth: true
                    placeholderText: i18n("Latitude")
                    validator: DoubleValidator { bottom: -90; top: 90 }
                    onTextEdited: page.cfg_locationName = ""
                }
                QQC2.TextField {
                    id: longitude
                    Layout.fillWidth: true
                    placeholderText: i18n("Longitude")
                    validator: DoubleValidator { bottom: -180; top: 180 }
                    onTextEdited: page.cfg_locationName = ""
                }
            }
        }

        Card {
            title: i18n("Units")

            RowLayout {
                spacing: Kirigami.Units.largeSpacing * 2
                QQC2.RadioButton {
                    text: i18n("Celsius (°C)")
                    checked: !page.cfg_fahrenheit
                    onToggled: if (checked) page.cfg_fahrenheit = false
                }
                QQC2.RadioButton {
                    text: i18n("Fahrenheit (°F)")
                    checked: page.cfg_fahrenheit
                    onToggled: if (checked) page.cfg_fahrenheit = true
                }
            }
        }

        QQC2.Label {
            text: i18n("Forecast data from Open-Meteo.")
            opacity: 0.5
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
