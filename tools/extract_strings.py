#!/usr/bin/env python3
"""Collects all user-facing string keys from the Swift sources -> tools/i18n/keys.json"""
import json, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CALLS = r'(?:Text|Button|Label|Toggle|Picker|Section|TextField|DatePicker|LabeledContent|ContentUnavailableView|alert|confirmationDialog|Menu|Link|CommandMenu|Stepper|String\(localized:|LocalizedStringKey\(|text:|prompt: Text|description: Text)'
LIT = r'"((?:[^"\\]|\\.)*)"'
pat = re.compile(CALLS + r'\s*\(?\s*' + LIT)
# string constants used as dynamic keys
DYN = re.compile(r'return "([A-Z][^"]*)"')
EXTRA = re.compile(r'\("([A-Z][A-Za-z &]+)", \[')  # emoji group names

def convert(s):
    def rep(m):
        expr = m.group(1)
        if any(k in expr for k in ("count", "weekNumber", "Int(", "minutes")) or expr.strip() in ("n", "c", "days", "rule?.count ?? 1"):
            return "%lld"
        return "%@"
    out, i = "", 0
    while i < len(s):
        if s.startswith("\\(", i):
            depth, j = 1, i + 2
            while j < len(s) and depth:
                if s[j] == "(":
                    depth += 1
                elif s[j] == ")":
                    depth -= 1
                j += 1
            out += rep(re.match(r"(.*)", s[i + 2:j - 1]))
            i = j
        else:
            out += s[i]
            i += 1
    return out.replace('\\"', '"').replace("\\n", "\n")

keys = set()
for base in ("Weekdot", "Shared", "WeekdotWatch", "WeekdotWidgets"):
    for dp, _, fs in os.walk(os.path.join(ROOT, base)):
        for f in fs:
            if not f.endswith(".swift"):
                continue
            src = open(os.path.join(dp, f)).read()
            for m in pat.finditer(src):
                keys.add(convert(m.group(1)))
            for m in DYN.finditer(src):
                keys.add(m.group(1))
            for m in EXTRA.finditer(src):
                keys.add(m.group(1))

skip = {"", "%@", "%lld", "+%lld", "·", "🙂", "•", "C", "F", "%@ %@%@"}
EXTRA_KEYS = ["Hide Event", "Mark as Completed", "Mark as Not Completed", "List", "Delete Event", "Add", "Done"]
keys |= set(EXTRA_KEYS)
keys = sorted(k for k in keys if k not in skip and not k.startswith(("#", "weekdot", "http", "webcal", "x-apple", "hour-", "circle", "chevron", "/System"))
              and not re.fullmatch(r"[a-z]+(\.[a-z.]+)+", k) and "%02X" not in k)
os.makedirs(os.path.join(ROOT, "tools", "i18n"), exist_ok=True)
json.dump(keys, open(os.path.join(ROOT, "tools", "i18n", "keys.json"), "w"), indent=1, ensure_ascii=False)
print(len(keys), "keys")
