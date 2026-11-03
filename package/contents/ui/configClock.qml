import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "settings"
import "components/zones.js" as Zones

// Clock styles, world clock zones and the calendar tile's sources.
KCM.SimpleKCM {
    id: page

    property string cfg_clockStyle
    property string cfg_worldZones
    property alias cfg_calendarSource: calendarSource.text
    property alias cfg_planeUrl: planeUrl.text
    property alias cfg_planeWorkspace: planeWorkspace.text
    property alias cfg_planeApiKey: planeApiKey.text

    readonly property var clockStyles: [
        { value: "digital", text: i18n("Digital"), hint: i18n("Seconds and date") },
        { value: "flip", text: i18n("Flip"), hint: i18n("Split-flap digits") },
        { value: "segment", text: i18n("Segment"), hint: i18n("Seven-segment display") },
        { value: "classic", text: i18n("Analog classic"), hint: i18n("Light face") },
        { value: "classicdark", text: i18n("Analog dark"), hint: i18n("Dark face") },
        { value: "minimal", text: i18n("Analog minimal"), hint: i18n("Hands only") },
        { value: "worldanalog", text: i18n("World analog"), hint: i18n("A face per time zone") },
        { value: "worldlist", text: i18n("World list"), hint: i18n("Zones as rows") },
        { value: "worldtime", text: i18n("World time"), hint: i18n("First zone only") },
        { value: "week", text: i18n("7 days"), hint: i18n("Forecast for the week") },
        { value: "today", text: i18n("Today"), hint: i18n("Date and forecast") }
    ]
    readonly property var supportedZones: Object.keys(Zones.table)

    function cityName(zone) {
        return zone.split("/").pop().replace(/_/g, " ");
    }
    function zoneLabel(zone) {
        const mins = Zones.table[zone] ? Zones.table[zone][0] : 0;
        const sign = mins < 0 ? "−" : "+";
        const h = Math.floor(Math.abs(mins) / 60), m = Math.abs(mins) % 60;
        return i18n("%1  (UTC%2%3)", cityName(zone), sign, h + (m ? ":" + String(m).padStart(2, "0") : ""));
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 1.5

        Card {
            title: i18n("Clock style")
            subtitle: i18n("Look of the Clock styles tile. Turn the tile on in Widgets.")

            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: page.clockStyles

                    QQC2.AbstractButton {
                        id: chip
                        required property var modelData
                        readonly property bool picked: modelData.value === page.cfg_clockStyle
                        width: Kirigami.Units.gridUnit * 9
                        padding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.smallSpacing * 1.5
                        bottomPadding: Kirigami.Units.smallSpacing * 1.5
                        text: modelData.text
                        onClicked: page.cfg_clockStyle = modelData.value

                        background: Rectangle {
                            radius: Kirigami.Units.cornerRadius * 2
                            color: chip.picked ? Qt.alpha(Kirigami.Theme.highlightColor, 0.2)
                                : Qt.alpha(Kirigami.Theme.textColor, chip.hovered ? 0.1 : 0.05)
                            border.width: chip.visualFocus ? 2 : 1
                            border.color: chip.picked || chip.visualFocus ? Kirigami.Theme.highlightColor
                                : Qt.alpha(Kirigami.Theme.textColor, 0.12)
                        }
                        contentItem: ColumnLayout {
                            spacing: 0
                            QQC2.Label {
                                text: chip.text
                                color: chip.picked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                font.weight: chip.picked ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            QQC2.Label {
                                text: chip.modelData.hint
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.6
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
            QQC2.Label {
                visible: page.cfg_clockStyle === "week" || page.cfg_clockStyle === "today"
                text: i18n("This style shows the forecast. Set your location on the Weather page.")
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.7
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        Card {
            title: i18n("World clocks")
            subtitle: i18n("Used by the World clocks tile and the world clock styles. The tile shows the first three.")

            StringListEditor {
                value: page.cfg_worldZones
                onEdited: v => page.cfg_worldZones = v
                choices: page.supportedZones
                labelFor: z => Zones.table[z] ? page.zoneLabel(z) : i18n("%1 (not supported)", z)
                iconFor: z => "preferences-system-time"
                emptyText: i18n("No time zones yet.")
            }
        }

        Card {
            title: i18n("Calendar")
            subtitle: i18n("The Calendar tile shows your next event from either source, or both.")

            FormRow {
                label: i18n("Calendar feed:")
                hint: i18n("An iCal or webcal link (Google: Settings → Integrate calendar → Secret address), or a local .ics file.")
                QQC2.TextField {
                    id: calendarSource
                    Layout.fillWidth: true
                    placeholderText: "https://calendar.google.com/calendar/ical/…/basic.ics"
                }
                QQC2.Button {
                    icon.name: "document-open"
                    text: i18n("Browse…")
                    onClicked: icsDialog.open()
                }
            }
            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }
            QQC2.Label {
                text: i18n("Plane issues assigned to you with a due date")
                font.weight: Font.DemiBold
            }
            FormRow {
                label: i18n("Server:")
                hint: i18n("Change only for a self-hosted Plane.")
                QQC2.TextField {
                    id: planeUrl
                    Layout.fillWidth: true
                    placeholderText: "https://api.plane.so"
                }
            }
            FormRow {
                label: i18n("Workspace slug:")
                QQC2.TextField {
                    id: planeWorkspace
                    Layout.fillWidth: true
                    placeholderText: "my-workspace"
                }
            }
            FormRow {
                label: i18n("API key:")
                hint: i18n("Plane → Profile settings → Personal access tokens. Stored in the Plasma config file.")
                Kirigami.PasswordField {
                    id: planeApiKey
                    Layout.fillWidth: true
                    placeholderText: "plane_api_…"
                }
            }
        }
    }

    FileDialog {
        id: icsDialog
        title: i18n("Choose a calendar file")
        nameFilters: [i18n("iCalendar files (*.ics)"), i18n("All files (*)")]
        onAccepted: calendarSource.text = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
    }
}
