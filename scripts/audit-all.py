#!/usr/bin/env python3
import json, pathlib, datetime
domains = pathlib.Path("domains.txt").read_text().splitlines()
rows = []
today = datetime.date.today().isoformat()
for d in domains:
    p = pathlib.Path(d)/"docs"/"CHECKLIST.json"
    if not p.exists():
        rows.append((d, 0, today, "no checklist"))
        continue
    data = json.loads(p.read_text())
    total = sum(len(items) for items in data.values())
    ok = sum(1 for sec in data.values() for v in sec.values() if v)
    percent = round(100*ok/total, 1) if total else 0
    rows.append((d, percent, today, ""))
lines = ["# Domain Readiness Scoreboard\n",
         "| Domain | Readiness % | Last Audit | Notes |",
         "|--------|-------------|------------|-------|"]
for d, percent, date, notes in rows:
    lines.append(f"| {d} | {percent}% | {date} | {notes or '—'} |")
pathlib.Path("docs/PROGRESS.md").write_text("\n".join(lines)+"\n")
