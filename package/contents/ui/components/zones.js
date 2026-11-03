.pragma library

// Time zones the world clock tiles can show, as [standard offset in minutes, DST rule].
// QML has no Intl, so only these zones work. The settings page offers the same list.
var table = {
    "UTC": [0, "none"],
    "America/New_York": [-300, "us"], "America/Toronto": [-300, "us"],
    "America/Chicago": [-360, "us"], "America/Denver": [-420, "us"],
    "America/Los_Angeles": [-480, "us"], "America/Vancouver": [-480, "us"],
    "Europe/London": [0, "eu"], "Europe/Dublin": [0, "eu"], "Europe/Lisbon": [0, "eu"],
    "Europe/Paris": [60, "eu"], "Europe/Berlin": [60, "eu"], "Europe/Madrid": [60, "eu"],
    "Europe/Rome": [60, "eu"], "Europe/Amsterdam": [60, "eu"],
    "Europe/Athens": [120, "eu"], "Europe/Helsinki": [120, "eu"],
    "Europe/Istanbul": [180, "none"], "Europe/Moscow": [180, "none"],
    "Asia/Dubai": [240, "none"], "Asia/Kolkata": [330, "none"],
    "Asia/Singapore": [480, "none"], "Asia/Shanghai": [480, "none"],
    "Asia/Hong_Kong": [480, "none"], "Asia/Tokyo": [540, "none"], "Asia/Seoul": [540, "none"],
    "Australia/Perth": [480, "none"], "Australia/Brisbane": [600, "none"],
    "Australia/Sydney": [600, "au"], "Australia/Melbourne": [600, "au"]
};
