#!/usr/bin/env python3
"""Print Claude plan usage as one JSON line, for the dock's Claude tile.

Asks Anthropic's usage endpoint (the one Claude Code's /usage uses) with the OAuth token
Claude Code keeps in ~/.claude/.credentials.json. The endpoint is unofficial and may change.
The token is read per run and never written anywhere. Results are cached for 90 s so a
short refresh interval cannot hammer the endpoint (it answers 429 when asked too often);
if a request fails, the last cached numbers are returned with an "error" reason.

usage: claude-usage.py [--force]
Output: {"ok": bool, "five": {"used": 0-100, "resetsAt": iso|""}, "week": {...},
         "fable": {...}|null, "error": str, "age": seconds-since-data}
"""
import json, os, sys, time, urllib.request, urllib.error
from datetime import datetime, timezone

URL = "https://api.anthropic.com/api/oauth/usage"
TTL = 90
CRED = os.environ.get("CLAUDE_CREDENTIALS_PATH") or os.path.expanduser("~/.claude/.credentials.json")
CACHE_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "dockyard")
CACHE = os.path.join(CACHE_DIR, "claude-usage.json")


def token():
    with open(CRED, encoding="utf-8") as f:
        d = json.load(f)
    o = d.get("claudeAiOauth") or d
    return o.get("accessToken") or o.get("access_token") or ""


def bucket(b):
    if not isinstance(b, dict):
        return None
    v = b.get("utilization", b.get("percent"))
    if v is None:
        return None
    r = b.get("resets_at") or b.get("resetsAt") or ""
    if r:
        try:
            r = datetime.fromisoformat(str(r).replace("Z", "+00:00")).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        except ValueError:
            r = ""
    return {"used": max(0, min(100, round(float(v)))), "resetsAt": r}


def parse(p):
    five, week = bucket(p.get("five_hour")), bucket(p.get("seven_day"))
    fable = None
    for k in ("seven_day_fable", "fable_weekly", "fableWeekly"):
        fable = fable or bucket(p.get(k))
    for it in p.get("limits") or []:
        kind = it.get("kind")
        if kind == "session" and not five:
            five = bucket(it)
        elif kind == "weekly_all" and not week:
            week = bucket(it)
    if not five and not week:
        raise ValueError("bad_response")
    return {"five": five, "week": week, "fable": fable}


def load_cache():
    try:
        with open(CACHE, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def save_cache(d):
    try:
        os.makedirs(CACHE_DIR, mode=0o700, exist_ok=True)
        tmp = CACHE + ".tmp"
        fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(d, f)
        os.replace(tmp, CACHE)
    except OSError:
        pass


def emit(d, ok, err=""):
    d = dict(d or {})
    # A window that has already reset since the numbers were fetched is empty now, not still full.
    now = time.time()
    for k in ("five", "week", "fable"):
        b = d.get(k)
        if b and b.get("resetsAt"):
            try:
                if datetime.fromisoformat(b["resetsAt"].replace("Z", "+00:00")).timestamp() <= now:
                    d[k] = {"used": 0, "resetsAt": ""}
            except ValueError:
                pass
    d["ok"] = ok
    d["error"] = err
    d["age"] = int(time.time() - d.get("at", time.time()))
    print(json.dumps(d))
    sys.exit(0)


def main():
    force = "--force" in sys.argv
    cached = load_cache()
    if cached and not force and time.time() - cached.get("at", 0) < TTL:
        emit(cached, True)
    try:
        tok = token()
        if not tok:
            raise PermissionError("no_credentials")
        req = urllib.request.Request(URL, headers={
            "Authorization": "Bearer " + tok,
            "anthropic-beta": "oauth-2025-04-20",
            "Accept": "application/json",
            "User-Agent": "dockyard-claude-tile/1.0",
        })
        data = parse(json.load(urllib.request.urlopen(req, timeout=8)))
        data["at"] = time.time()
        save_cache(data)
        emit(data, True)
    except FileNotFoundError:
        err = "no_credentials"
    except PermissionError as e:
        err = str(e)
    except urllib.error.HTTPError as e:
        err = "rate_limited" if e.code == 429 else "auth_expired" if e.code in (401, 403) else "server_error"
    except (urllib.error.URLError, OSError, TimeoutError):
        err = "network"
    except ValueError:
        err = "bad_response"
    emit(cached, False, err)


main()
