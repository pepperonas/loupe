#!/usr/bin/env python3
"""Setzt Loupes gerenderte HTML-Vorschauen in ein Fenster im Stil des macOS-
Quick-Look-Panels und schreibt je Bild eine eigenständige HTML-Seite.

Der Fensterinhalt ist die UNVERÄNDERTE Ausgabe der Loupe-Renderer (per iframe
eingebettet) -- nur Rahmen und Hintergrund sind gestaltet.

Aufruf: compose.py <html-ordner> <seiten-ordner>
Ausgabe: <seiten-ordner>/<id>-<light|dark>.html und sizes.txt (id breite höhe)
"""
import html
import sys
from pathlib import Path

HTML_DIR = Path(sys.argv[1])
PAGE_DIR = Path(sys.argv[2])
PAGE_DIR.mkdir(parents=True, exist_ok=True)

# id, Quelldatei (Name wie von render-previews geschrieben), Titelzeile, Knopf rechts, Fensterhöhe
SINGLES = [
    ("json", "package.json", "package.json", "Open with Xcode", 720),
    ("json-error", "broken.json", "broken.json", "Open with Xcode", 560),
    ("markdown", "README.md", "README.md", "Open with TextEdit", 720),
    ("log", "server.log", "server.log", "Open with Console", 680),
    ("tsv", "sales.tsv", "sales.tsv", "Open with Numbers", 720),
    ("code", "RendererRegistry.swift", "RendererRegistry.swift", "Open with Xcode", 720),
    ("powershell", "deploy.ps1", "deploy.ps1", "Open with Visual Studio Code", 720),
    ("batch", "build.bat", "build.bat", "Open with TextEdit", 720),
    ("xml", "01-config.xml", "01-config.xml", "Open with Xcode", 470),
]
# Heldenbild: hinten -> vorne
HERO = [
    ("README.md", "README.md", "Open with TextEdit"),
    ("package.json", "package.json", "Open with Xcode"),
    ("server.log", "server.log", "Open with Console"),
]

THEMES = {
    "dark": {
        "canvas": "radial-gradient(1100px 700px at 12% 8%, #3a2d8c 0%, transparent 62%),"
                  "radial-gradient(1000px 650px at 92% 95%, #0c5f7d 0%, transparent 58%),"
                  "radial-gradient(700px 500px at 60% 40%, #1d1a44 0%, transparent 70%), #0a0c16",
        "window": "#1e1e1e", "titlebar": "#2b2b2e", "border": "rgba(255,255,255,0.12)",
        "title": "#e5e5ea", "button_bg": "rgba(255,255,255,0.10)", "button_fg": "#e5e5ea",
        "shadow": "0 50px 100px rgba(0,0,0,0.55), 0 18px 40px rgba(0,0,0,0.45)",
    },
    "light": {
        "canvas": "radial-gradient(1100px 700px at 12% 8%, #c9d3ff 0%, transparent 62%),"
                  "radial-gradient(1000px 650px at 92% 95%, #b3ecf7 0%, transparent 58%),"
                  "radial-gradient(700px 500px at 60% 40%, #efe6ff 0%, transparent 70%), #f4f6fb",
        "window": "#ffffff", "titlebar": "#f1f1f3", "border": "rgba(0,0,0,0.12)",
        "title": "#1d1d1f", "button_bg": "rgba(0,0,0,0.06)", "button_fg": "#1d1d1f",
        "shadow": "0 50px 100px rgba(30,40,90,0.28), 0 18px 40px rgba(30,40,90,0.18)",
    },
}

CSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: %(w)dpx; height: %(h)dpx; overflow: hidden; }
body { background: %(canvas)s; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; }
.win { position: absolute; border-radius: 12px; overflow: hidden; background: %(window)s;
       border: 1px solid %(border)s; box-shadow: %(shadow)s; display: flex; flex-direction: column; }
.bar { height: 44px; flex: none; display: flex; align-items: center; padding: 0 14px;
       background: %(titlebar)s; border-bottom: 1px solid %(border)s; position: relative; }
.lights { display: flex; gap: 8px; }
.lights i { width: 12px; height: 12px; border-radius: 50%%; display: block;
            box-shadow: inset 0 0 0 0.5px rgba(0,0,0,0.25); }
.lights i:nth-child(1) { background: #ff5f57; }
.lights i:nth-child(2) { background: #febc2e; }
.lights i:nth-child(3) { background: #28c840; }
.title { position: absolute; left: 0; right: 0; text-align: center; pointer-events: none;
         font-size: 13px; font-weight: 600; color: %(title)s; letter-spacing: -0.01em; }
.open { margin-left: auto; font-size: 12px; font-weight: 500; color: %(button_fg)s;
        background: %(button_bg)s; border-radius: 6px; padding: 4px 10px; position: relative; }
iframe { border: 0; flex: 1; width: 100%%; background: %(window)s; }
"""


def window(src_name: str, title: str, button: str, theme: str, box: tuple) -> str:
    x, y, w, h = box
    doc = (HTML_DIR / f"{src_name}-{theme}.html").read_text(encoding="utf-8")
    return (f'<div class="win" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px">'
            f'<div class="bar"><div class="lights"><i></i><i></i><i></i></div>'
            f'<div class="title">{html.escape(title)}</div>'
            f'<div class="open">{html.escape(button)}</div></div>'
            f'<iframe srcdoc="{html.escape(doc, quote=True)}"></iframe></div>')


def page(theme: str, size: tuple, windows: list) -> str:
    w, h = size
    css = CSS % dict(THEMES[theme], w=w, h=h)
    return f'<!DOCTYPE html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{"".join(windows)}</body></html>'


sizes = []
for theme in THEMES:
    for ident, src, title, button, height in SINGLES:
        size = (1400, height + 140)
        body = [window(src, title, button, theme, (100, 70, 1200, height))]
        (PAGE_DIR / f"{ident}-{theme}.html").write_text(page(theme, size, body), encoding="utf-8")
        sizes.append((f"{ident}-{theme}", *size))

    size = (1600, 920)
    boxes = [(70, 60, 1000, 620), (320, 160, 1000, 620), (570, 260, 1000, 620)]
    body = [window(src, title, button, theme, box) for (src, title, button), box in zip(HERO, boxes)]
    (PAGE_DIR / f"hero-{theme}.html").write_text(page(theme, size, body), encoding="utf-8")
    sizes.append((f"hero-{theme}", *size))

(PAGE_DIR / "sizes.txt").write_text("".join(f"{i} {w} {h}\n" for i, w, h in sizes), encoding="utf-8")
print(f"{len(sizes)} Seiten in {PAGE_DIR}")
