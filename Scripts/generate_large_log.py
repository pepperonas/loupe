#!/usr/bin/env python3
"""Erzeugt eine große Log-Datei zum Testen des Tail-Lesens der Log-Vorschau.

Loupe liest bei Logs nur die letzten 4 MB und zeigt davon die neuesten 5.000
Zeilen. Diese Datei ist deutlich größer, damit genau dieser Pfad greift.

Jede Zeile nennt ihre eigene Zeilennummer ("line=N"). In der Vorschau muss die
Nummer in der linken Spalte mit diesem Wert übereinstimmen -- so lässt sich
prüfen, dass die Zeilennummern trotz übersprungenem Dateianfang absolut sind.

Aufruf:  python3 Scripts/generate_large_log.py [Zieldatei] [MB]
Default: Tests/Fixtures/logs/14-large-tail.log, 12 MB (per .gitignore ausgeschlossen)
"""
import random
import sys
from datetime import datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
target = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "Tests/Fixtures/logs/14-large-tail.log"
megabytes = float(sys.argv[2]) if len(sys.argv) > 2 else 12.0

rng = random.Random(42)  # deterministisch: jeder Lauf ergibt dieselbe Datei
levels = ["DEBUG"] * 30 + ["INFO"] * 55 + ["WARN"] * 10 + ["ERROR"] * 5
sources = ["http", "db", "cache", "worker-1", "worker-2", "scheduler", "auth"]
paths = ["/api/orders", "/api/users", "/api/reports/monthly", "/health", "/api/cart"]

limit = int(megabytes * 1024 * 1024)
start = datetime(2026, 9, 24, 0, 0, 0)
written = 0
line_no = 0

with target.open("w", encoding="utf-8", newline="\n") as fh:
    while written < limit:
        line_no += 1
        ts = (start + timedelta(milliseconds=line_no * 137)).strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        level = rng.choice(levels)
        source = rng.choice(sources)
        path = rng.choice(paths)
        ms = rng.randint(1, 2500)
        line = (f"{ts} {level:<5} [{source}] line={line_no} GET {path} took {ms}ms "
                f"from 10.0.{rng.randint(0, 255)}.{rng.randint(1, 254)} request_id={rng.getrandbits(64):016x}\n")
        if level == "ERROR" and rng.random() < 0.3:
            # Gelegentlich ein Stacktrace als Folgezeilen.
            line_no += 2
            line += (f"java.lang.IllegalStateException: pool exhausted\n"
                     f"\tat com.example.Pool.acquire(Pool.java:{rng.randint(10, 400)})\n")
        fh.write(line)
        written += len(line.encode("utf-8"))

    line_no += 1
    last = f"2026-09-24 23:59:59.999 FATAL [main] line={line_no} LAST LINE OF THE FILE - its row number must be {line_no}\n"
    fh.write(last)
    written += len(last.encode("utf-8"))

print(f"{target}: {written / 1024 / 1024:.1f} MB, {line_no} Zeilen (letzte Zeile = {line_no})")
