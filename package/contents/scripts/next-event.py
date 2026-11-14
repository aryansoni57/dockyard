#!/usr/bin/env python3
"""Print the next calendar event or Plane due date as one JSON line.

usage: next-event.py '<json>'  with {"ical": "<url-or-path>", "plane": {"url", "workspace", "key"}}
Either source may be empty. Plane issues assigned to you with a due date count as all-day
items (kind "plane"); everything else is kind "event".
Handles UTC / TZID / floating times, all-day events and the common RRULE forms
(DAILY/WEEKLY/MONTHLY/YEARLY, INTERVAL, BYDAY, COUNT, UNTIL, EXDATE). Stdlib only.
"""
import json, os, re, sys, urllib.request, urllib.error
from datetime import datetime, timedelta, timezone, date
from zoneinfo import ZoneInfo

LOCAL = datetime.now().astimezone().tzinfo
DAYS = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]


def out(**kw):
    print(json.dumps(kw))
    sys.exit(0)


def load(src):
    if re.match(r"^(https?|webcal)://", src):
        src = re.sub(r"^webcal://", "https://", src)
        req = urllib.request.Request(src, headers={"User-Agent": "Dockyard"})
        return urllib.request.urlopen(req, timeout=15).read().decode("utf-8", "replace")
    return open(os.path.expanduser(src), encoding="utf-8", errors="replace").read()


def unfold(text):
    return re.sub(r"\r?\n[ \t]", "", text).splitlines()


def parse_dt(value, params):
    """-> (aware datetime, all_day)"""
    v = value.strip()
    if params.get("VALUE") == "DATE" or re.fullmatch(r"\d{8}", v):
        d = datetime.strptime(v[:8], "%Y%m%d")
        return d.replace(tzinfo=LOCAL), True
    if v.endswith("Z"):
        return datetime.strptime(v, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc), False
    d = datetime.strptime(v[:15], "%Y%m%dT%H%M%S")
    tz = LOCAL
    if "TZID" in params:
        try:
            tz = ZoneInfo(params["TZID"])
        except Exception:
            pass
    return d.replace(tzinfo=tz), False


def unescape(s):
    return s.replace("\\n", " ").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")


def events(text):
    cur = None
    for line in unfold(text):
        if line == "BEGIN:VEVENT":
            cur = {"exdate": []}
        elif line == "END:VEVENT" and cur is not None:
            if "start" in cur:
                yield cur
            cur = None
        elif cur is not None and ":" in line:
            head, _, val = line.partition(":")
            name, *plist = head.split(";")
            params = dict(p.split("=", 1) for p in plist if "=" in p)
            name = name.upper()
            try:
                if name == "DTSTART":
                    cur["start"], cur["allday"] = parse_dt(val, params)
                elif name == "DTEND":
                    cur["end"], _ = parse_dt(val, params)
                elif name == "DURATION":
                    m = re.fullmatch(r"P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?)?", val.strip())
                    if m:
                        w, d, h, mi = (int(x or 0) for x in m.groups())
                        cur["dur"] = timedelta(weeks=w, days=d, hours=h, minutes=mi)
                elif name == "SUMMARY":
                    cur["title"] = unescape(val)
                elif name == "LOCATION":
                    cur["location"] = unescape(val)
                elif name == "STATUS":
                    cur["status"] = val.strip().upper()
                elif name == "RRULE":
                    cur["rrule"] = dict(p.split("=", 1) for p in val.split(";") if "=" in p)
                elif name == "EXDATE":
                    for x in val.split(","):
                        cur["exdate"].append(parse_dt(x, params)[0])
                elif name == "RECURRENCE-ID":
                    cur["recid"], _ = parse_dt(val, params)
                elif name == "UID":
                    cur["uid"] = val.strip()
            except Exception:
                pass


def occurrences(ev, lo, hi):
    """Start times of ev between lo and hi (aware datetimes)."""
    start = ev["start"]
    rule = ev.get("rrule")
    if not rule:
        if lo <= start <= hi:
            yield start
        return
    freq = rule.get("FREQ")
    step = int(rule.get("INTERVAL", 1))
    count = int(rule["COUNT"]) if "COUNT" in rule else None
    until = None
    if "UNTIL" in rule:
        try:
            until = parse_dt(rule["UNTIL"], {})[0]
            if until.time() == datetime.min.time():
                until += timedelta(days=1)
        except Exception:
            pass
    byday = [d[-2:] for d in rule["BYDAY"].split(",")] if "BYDAY" in rule else None
    tz = start.tzinfo
    n = 0
    # walk period by period from the series start; cheap enough for a few years
    k = 0
    while k < 5000:
        if freq == "DAILY":
            bases = [start + timedelta(days=k * step)]
        elif freq == "WEEKLY":
            wk = start - timedelta(days=start.weekday()) + timedelta(weeks=k * step)
            days = byday or [DAYS[start.weekday()]]
            bases = [wk + timedelta(days=DAYS.index(d)) for d in days if d in DAYS]
            bases.sort()
        elif freq == "MONTHLY":
            m = start.month - 1 + k * step
            try:
                bases = [start.replace(year=start.year + m // 12, month=m % 12 + 1)]
            except ValueError:
                bases = []
        elif freq == "YEARLY":
            try:
                bases = [start.replace(year=start.year + k * step)]
            except ValueError:
                bases = []
        else:
            return
        for b in bases:
            if b < start:
                continue
            if until and b > until:
                return
            n += 1
            if count and n > count:
                return
            if b > hi:
                return
            if b >= lo and not any(abs((b - x).total_seconds()) < 1 for x in ev["exdate"]):
                yield b
        k += 1


def plane_items(cfg):
    """Open issues assigned to me with a due date -> list of (start, end, title, project)."""
    base = (cfg.get("url") or "https://api.plane.so").rstrip("/") + "/api/v1"
    ws, key = cfg["workspace"].strip(), cfg["key"].strip()

    def get(path):
        req = urllib.request.Request(base + path, headers={"X-API-Key": key, "User-Agent": "Dockyard"})
        d = json.load(urllib.request.urlopen(req, timeout=15))
        return d.get("results", []) if isinstance(d, dict) else d

    def get_one(path):
        req = urllib.request.Request(base + path, headers={"X-API-Key": key, "User-Agent": "Dockyard"})
        return json.load(urllib.request.urlopen(req, timeout=15))

    me = get_one("/users/me/")["id"]
    items = []
    for proj in get("/workspaces/%s/projects/" % ws):
        pid = proj["id"]
        try:
            closed = {st["id"] for st in get("/workspaces/%s/projects/%s/states/" % (ws, pid))
                      if st.get("group") in ("completed", "cancelled")}
        except Exception:
            closed = set()
        for iss in get("/workspaces/%s/projects/%s/issues/?per_page=100" % (ws, pid)):
            due = iss.get("target_date")
            if not due or iss.get("state") in closed or iss.get("archived_at"):
                continue
            if me not in (iss.get("assignees") or []):
                continue
            try:
                d = datetime.strptime(due[:10], "%Y-%m-%d").replace(tzinfo=LOCAL)
            except ValueError:
                continue
            ident = "%s-%s " % (proj.get("identifier", ""), iss["sequence_id"]) if iss.get("sequence_id") else ""
            items.append((d, d + timedelta(days=1), ident + iss.get("name", ""), proj.get("name", "")))
    return items


def main():
    try:
        cfg = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
    except ValueError:
        cfg = {}
    ical = (cfg.get("ical") or "").strip()
    plane = cfg.get("plane") or {}
    use_plane = bool(plane.get("workspace", "").strip() and plane.get("key", "").strip())
    if not ical and not use_plane:
        out(ok=False, error="nosource")

    now = datetime.now(timezone.utc)
    hi = now + timedelta(days=60)
    cands = []  # (start, end, title, kind, allday, project)
    errors = {}

    if ical:
        try:
            text = load(ical)
            evs = list(events(text))
            moved = {(e.get("uid"), e["recid"]) for e in evs if "recid" in e}
            for ev in evs:
                if ev.get("status") == "CANCELLED":
                    continue
                length = (ev["end"] - ev["start"]) if "end" in ev else ev.get("dur", timedelta(0))
                if ev.get("allday") and length <= timedelta(0):
                    length = timedelta(days=1)
                for s in occurrences(ev, now - length, hi):
                    if "recid" not in ev and (ev.get("uid"), s) in moved:
                        continue
                    e = s + length
                    if e < now or (ev.get("allday") and e <= now):
                        continue
                    cands.append((s, e, ev.get("title", "(no title)"), "event", bool(ev.get("allday")), ev.get("location", "")))
        except Exception:
            errors["ical"] = "fetch"

    if use_plane:
        try:
            for s, e, title, project in plane_items(plane):
                if e > now and s <= hi:
                    cands.append((s, e, title, "plane", True, project))
        except urllib.error.HTTPError as ex:
            errors["plane"] = "auth" if ex.code in (401, 403) else "http%d" % ex.code
        except Exception:
            errors["plane"] = "fetch"

    if not cands:
        if errors and len(errors) == (1 if ical else 0) + (1 if use_plane else 0):
            out(ok=False, error="fetch", errors=errors)
        out(ok=True, none=True, errors=errors)
    # all-day items sort after timed ones that start the same day
    cands.sort(key=lambda c: (c[0].astimezone(timezone.utc), c[4]))
    s, e, title, kind, allday, extra = cands[0]
    # Everything that starts today, for the launcher dashboard's Today card.
    today = datetime.now(LOCAL).date()
    items = [dict(title=c[2], kind=c[3], allDay=c[4],
                  start=c[0].astimezone(timezone.utc).isoformat(), end=c[1].astimezone(timezone.utc).isoformat())
             for c in cands if c[0].astimezone(LOCAL).date() == today][:6]
    out(ok=True, title=title, extra=extra, kind=kind, errors=errors, items=items,
        start=s.astimezone(timezone.utc).isoformat(), end=e.astimezone(timezone.utc).isoformat(), allDay=allday)


main()
