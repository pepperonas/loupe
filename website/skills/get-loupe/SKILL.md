---
name: get-loupe
description: Download, verify and install the newest Loupe. Use when someone asks for Loupe, its latest version, a download link, or how to check the file is genuine.
license: MIT
---

# Get Loupe

Loupe is a free, open-source Quick Look extension for macOS 14+. Press Space on a file in Finder and it shows JSON as a collapsible tree with exact error positions, renders Markdown, turns log files into a colour-coded table (newest lines first in view), lays out TSV as a table and highlights source code in 20+ languages, PowerShell, Batch and XML dialects included. It runs sandboxed, read-only and offline, and its previews contain no JavaScript. A companion app switches previews on or off per category and sets appearance, text size and language (English or German).

## 1. Find the newest release

`GET https://loupe.celox.io/latest.json` returns `version`, `published`, `notes` and `assets[]`, each with `target`,
`name`, `url`, `size` (bytes) and `sha256`. It is refreshed from GitHub Releases every 15 minutes. On the
page itself, browsers with WebMCP expose the same data as the tools `get_latest_release`,
`get_download_url` and `get_checksums`.

## 2. Download

- Stable link, always the newest file for the visitor's platform: <https://loupe.celox.io/download>
- macOS: <https://loupe.celox.io/download/macos> — macOS 14+ · Apple silicon

## 3. Verify

- The file's SHA-256 must equal the matching `assets[].sha256` in `latest.json`.

- Loupe is ad-hoc signed, not notarized — there is no Apple Team ID to check. Compare the SHA-256 of your download with the value above; the release on GitHub lists the same checksum.

## 4. Install

1. Get the ZIP above and unpack it.
2. Drag **Loupe.app** to Applications. The app is not notarized: open it once with right-click → *Open*.
3. System Settings → General → Login Items & Extensions → Quick Look → enable **Loupe**. Then press Space on a file.

## Limits

- macOS 14 or later on Apple silicon only
- CSV (.csv) cannot be previewed: macOS reserves that type for its own generator — use .tsv
- Some file types (.ts, .tsx, .jsx, .scss …) never reach Quick Look extensions because macOS types them differently
- Not notarized: ad-hoc signed, so the first launch needs right-click → Open
- Read-only: Loupe shows files, it does not edit them

More: [product page](https://loupe.celox.io/) · [Markdown version](https://loupe.celox.io/index.md) · [changelog](https://loupe.celox.io/changelog.md) · [source](https://github.com/pepperonas/loupe)
