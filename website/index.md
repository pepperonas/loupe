<!--# block name="none" --><!--# endblock -->
# Loupe — Quick Look for JSON, Markdown, Logs & Code

> Loupe is a free, open-source Quick Look extension for macOS 14+. Press Space on a file in Finder and it shows JSON as a collapsible tree with exact error positions, renders Markdown, turns log files into a colour-coded table (newest lines first in view), lays out TSV as a table and highlights source code in 20+ languages, PowerShell, Batch and XML dialects included. It runs sandboxed, read-only and offline, and its previews contain no JavaScript. A companion app switches previews on or off per category and sets appearance, text size and language (English or German).

This is the Markdown version of https://loupe.celox.io/ for agents and text tools. A short summary with every link lives at https://loupe.celox.io/llms.txt.

## Download

- **Newest release:** https://loupe.celox.io/download (picks the file for your platform; always the current release)
- **Current version:** <!--# include virtual="/ssi/version.txt" stub="none" --> · released <!--# include virtual="/ssi/date.txt" stub="none" -->
- **Release data as JSON:** https://loupe.celox.io/latest.json
- **Requirements:** macOS: macOS 14+ · Apple silicon

Files in the current release:

<!--# include virtual="/ssi/files.md" stub="none" -->

## Features

- **JSON you can read** — A collapsible tree with counts and a peek at each object. A broken file shows the exact line and column, with the offending spot marked.
- **Markdown, rendered** — Headings, tables, task lists and highlighted code blocks. Remote images stay blocked, so a preview never phones home.
- **Logs at a glance** — Time, level, source and message in columns; seven formats, from nginx to JSON Lines. Big logs are read from the end, where the news is.
- **Code in 20+ languages** — Swift, Python, Go, Rust, SQL, YAML and more, plus PowerShell, Batch and 13 XML dialects that macOS would otherwise never show.
- **You decide** — Switch Loupe off globally or per category — Markdown, JSON, tables, logs, code. Off means plain text, exactly as without Loupe.
- **Private and fast** — Sandboxed, read-only, offline, and not a single byte of JavaScript in a preview. Light and dark mode; the app speaks English and German.

### In numbers

Counted from the source code, updated with every change:

- **Lines of Swift:** <!--# include virtual="/ssi/stat-loc.txt" stub="none" --> (<!--# include virtual="/ssi/stat-loc-detail.txt" stub="none" -->)
- **Unit tests:** <!--# include virtual="/ssi/stat-tests.txt" stub="none" --> (<!--# include virtual="/ssi/stat-tests-detail.txt" stub="none" -->)

### What it looks like

- **JSON tree** — Every object with its key count and a peek at its content. ([image](https://loupe.celox.io/assets/gallery/json.jpg))
- **JSON errors** — The exact position of the problem, with the lines around it. ([image](https://loupe.celox.io/assets/gallery/json-error.jpg))
- **Markdown** — Rendered like on GitHub, in your system's appearance. ([image](https://loupe.celox.io/assets/gallery/markdown.jpg))
- **Log files** — Levels counted in the toolbar, errors tinted with their stack trace. ([image](https://loupe.celox.io/assets/gallery/log.jpg))
- **Tables** — TSV laid out as a table, numbers aligned on the right. ([image](https://loupe.celox.io/assets/gallery/tsv.jpg))
- **Source code** — Highlighting with line numbers and the language badge. ([image](https://loupe.celox.io/assets/gallery/code.jpg))
- **PowerShell** — Variables, cmdlets, parameters and here-strings. ([image](https://loupe.celox.io/assets/gallery/powershell.jpg))
- **XML** — Elements, attributes, CDATA and entities, each in its own colour. ([image](https://loupe.celox.io/assets/gallery/xml.jpg))
- **The companion app** — Switches per category, appearance, text size and language. ([image](https://loupe.celox.io/assets/gallery/app.jpg))

## Install

1. **Download** — Get the ZIP above and unpack it.
2. **Move and open** — Drag **Loupe.app** to Applications. The app is not notarized: open it once with right-click → *Open*.
3. **Turn it on** — System Settings → General → Login Items & Extensions → Quick Look → enable **Loupe**. Then press Space on a file.

## Verify

<!--# include virtual="/ssi/checksums.md" stub="none" -->
['- **Lines of Swift:** <!--# include virtual="/ssi/stat-loc.txt" stub="none" --> (<!--# include virtual="/ssi/stat-loc-detail.txt" stub="none" -->)', '- **Unit tests:** <!--# include virtual="/ssi/stat-tests.txt" stub="none" --> (<!--# include virtual="/ssi/stat-tests-detail.txt" stub="none" -->)']
- Loupe is ad-hoc signed, not notarized — there is no Apple Team ID to check. Compare the SHA-256 of your download with the value above; the release on GitHub lists the same checksum.

## FAQ

**Is Loupe free?** Yes. It is free and open source under the MIT licence, with no ads, no account and no tracking.

**Why isn't it in the App Store?** Loupe is a small open-source project without a paid Apple developer account. That is also why it is not notarized and needs right-click → Open on the first launch.

**What do I need?** A Mac with Apple silicon and macOS 14 Sonoma or later.

**Why does my .csv file still look plain?** macOS reserves CSV for its own preview, and no extension gets asked. Save the table as `.tsv` and Loupe shows it. A few other types (`.ts`, `.tsx`, `.scss` …) never reach extensions either.

**How do I update?** Download the new ZIP from this page and replace Loupe.app in Applications. Your settings stay.

**Does Loupe send my files anywhere?** No. The extension runs sandboxed and read-only, has no network access in its previews and contains no JavaScript. Remote images in Markdown stay blocked.

## Limits

- macOS 14 or later on Apple silicon only
- CSV (.csv) cannot be previewed: macOS reserves that type for its own generator — use .tsv
- Some file types (.ts, .tsx, .jsx, .scss …) never reach Quick Look extensions because macOS types them differently
- Not notarized: ad-hoc signed, so the first launch needs right-click → Open
- Read-only: Loupe shows files, it does not edit them

## Links

- Source code: https://github.com/pepperonas/loupe
- Changelog: https://loupe.celox.io/changelog.md
- Licence (MIT): https://github.com/pepperonas/loupe/blob/main/LICENSE
- Support the project: https://www.paypal.com/donate/?business=martin.pfeffer@celox.io&currency_code=EUR&item_name=Loupe
- Author: Martin Pfeffer, https://celox.io — Imprint https://celox.io/impressum/ · Privacy https://celox.io/datenschutz/
