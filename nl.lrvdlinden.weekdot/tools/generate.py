#!/usr/bin/env python3
"""Writes the translated Homey compose files, locales and READMEs from tools/strings.py.

    python3 tools/generate.py      (then: homey app build / homey app validate --level publish)
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from strings import L, S, C, R, W, TAGS, README  # noqa: E402

VERSION = "0.0.2"


def write(path, data):
    p = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def calendar_arg():
    return {"name": "calendar", "type": "autocomplete", "title": S["arg_calendar"], "placeholder": S["arg_calendar_ph"]}


def keyword_arg():
    return {"name": "keyword", "type": "text", "required": False, "title": S["arg_keyword"], "placeholder": S["arg_keyword_ph"]}


def tok(name, typ, title, example):
    return {"name": name, "type": typ, "title": S[title], "example": example}


EVENT_TOKENS = [
    tok("title", "string", "tok_title", {l: "Lunch" for l in L}),
    tok("emoji", "string", "tok_emoji", {l: "🥗" for l in L}),
    tok("location", "string", "tok_location", {l: "Café" for l in L}),
    tok("calendar", "string", "tok_calendar", S["tok_calendar"]),
    tok("start_time", "string", "tok_start", {l: "12:30" for l in L}),
    tok("end_time", "string", "tok_end", {l: "13:30" for l in L}),
    tok("all_day", "boolean", "tok_allday", False),
]
AGENDA_TOKENS = [
    tok("count", "number", "tok_count", 3),
    tok("summary", "string", "tok_summary", {l: "09:30 …, 12:30 …" for l in L}),
    tok("first_title", "string", "tok_first_title", {l: "Stand-up" for l in L}),
    tok("first_time", "string", "tok_first_time", {l: "09:30" for l in L}),
]


def card(cid, args, tokens=None):
    title, formatted = C[cid]
    d = {"id": cid, "title": title}
    if formatted:
        d["titleFormatted"] = formatted
    if args:
        d["args"] = args
    if tokens:
        d["tokens"] = tokens
    return d


def main():
    # app
    app = {
        "id": "nl.lrvdlinden.weekdot",
        "version": VERSION,
        "compatibility": ">=12.3.0",
        "sdk": 3,
        "platforms": ["local", "cloud"],
        "name": S["app_name"],
        "description": S["app_desc"],
        "category": ["tools"],
        "tags": TAGS,
        "permissions": [],
        "brandColor": "#E8352F",
        "images": {"small": "/assets/images/small.png", "large": "/assets/images/large.png", "xlarge": "/assets/images/xlarge.png"},
        "author": {"name": "Léon van der Linden", "email": "homey@vdlinden.xyz", "website": "https://lrvdlinden.app"},
        "homepage": "https://weekdot.com",
        "contributing": {"donate": {"paypal": {"username": "lrvdlinden"}, "bunq": {"username": "lrvdlinden"}}},
        "api": {
            # Web API clients only get the read-only app scope, so a POST with the user's token is refused
            # ("Missing Scopes"). Weekdot first reads a pairing key with the token (GET /pair) and then sends the
            # schedule to this public endpoint together with that key, which the app checks.
            "getPairing": {"method": "GET", "path": "/pair"},
            "postSchedule": {"method": "POST", "path": "/schedule", "public": True},
            "getStatus": {"method": "GET", "path": "/status"},
            "deleteSchedule": {"method": "DELETE", "path": "/schedule"},
        },
    }
    write(".homeycompose/app.json", app)

    # flow cards
    minutes = {"name": "minutes", "type": "number", "min": 1, "max": 1440, "step": 1, "title": S["arg_minutes"], "placeholder": {l: "15" for l in L}}
    time_arg = {"name": "time", "type": "time", "title": S["arg_time"]}
    day_arg = {"name": "day", "type": "dropdown", "title": S["arg_day"],
               "values": [{"id": "today", "title": S["today"]}, {"id": "tomorrow", "title": S["tomorrow"]}]}
    triggers = {
        "event_started": card("event_started", [keyword_arg(), calendar_arg()], EVENT_TOKENS),
        "event_ended": card("event_ended", [keyword_arg(), calendar_arg()], EVENT_TOKENS),
        "event_starts_in": card("event_starts_in", [keyword_arg(), calendar_arg(), minutes], EVENT_TOKENS),
        "agenda_at_time": card("agenda_at_time", [time_arg], AGENDA_TOKENS),
        "schedule_received": card("schedule_received", None,
                                  [tok("count", "number", "tok_count", 12), tok("device", "string", "tok_device", {l: "iPhone" for l in L})]),
    }
    conditions = {k: card(k, [keyword_arg(), calendar_arg()]) for k in ["event_now", "event_today", "event_tomorrow"]}
    next_tokens = [tok("found", "boolean", "tok_found", True)] + EVENT_TOKENS[:5] + [
        tok("date", "string", "tok_date", {l: "2026-10-30" for l in L}),
        tok("minutes_until", "number", "tok_minutes_until", 45)]
    actions = {
        "get_next_event": card("get_next_event", [keyword_arg(), calendar_arg()], next_tokens),
        "get_agenda": card("get_agenda", [day_arg], AGENDA_TOKENS),
    }
    for kind, cards in (("triggers", triggers), ("conditions", conditions), ("actions", actions)):
        for cid, c in cards.items():
            c = dict(c)
            c.pop("id")
            write(f".homeycompose/flow/{kind}/{cid}.json", c)

    # widget
    write("widgets/agenda/widget.compose.json", {
        "name": W["w_name"],
        "height": 210,
        "transparent": False,
        "settings": [
            {"id": "days", "type": "dropdown", "title": W["w_days"], "value": "today",
             "values": [{"id": "today", "title": W["w_today"]}, {"id": "today_tomorrow", "title": W["w_today_tomorrow"]}]},
            {"id": "allday", "type": "checkbox", "title": W["w_allday"], "value": True},
        ],
        "api": {"getAgenda": {"method": "GET", "path": "/"}},
    })

    # locales
    for i, l in enumerate(L):
        out = {"tokens": {"next_title": S["g_next_title"][l], "next_time": S["g_next_time"][l], "today_count": S["g_today_count"][l]}}
        for key, val in R.items():
            node = out
            parts = key.split(".")
            for p in parts[:-1]:
                node = node.setdefault(p, {})
            node[parts[-1]] = val[l]
        write(f"locales/{l}.json", out)

    # READMEs
    for l in L:
        name = "README.txt" if l == "en" else f"README.{l}.txt"
        with open(os.path.join(ROOT, name), "w", encoding="utf-8") as f:
            f.write(README[l].strip() + "\n")
    print("generated", len(triggers), "triggers,", len(conditions), "conditions,", len(actions), "actions,", len(L), "languages")


if __name__ == "__main__":
    main()
