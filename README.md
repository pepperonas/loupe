<div align="center">

# 🔍 Loupe

**Native Quick Look previews for developer files — JSON, Markdown, logs, source code and scripts.**<br>
Press <kbd>Space</kbd> in Finder. Get a readable, theme-aware preview. Zero JavaScript, zero telemetry, fully offline.

<a href="README.md"><img src="https://img.shields.io/badge/Language-English-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="English"></a>
&nbsp;
<a href="README.de.md"><img src="https://img.shields.io/badge/Sprache-Deutsch-555555?style=for-the-badge&logo=apple&logoColor=white" alt="Deutsch"></a>

<br>

<!-- Project status -->
[![Latest release](https://img.shields.io/github/v/release/pepperonas/loupe?logo=github&label=release&color=007AFF)](https://github.com/pepperonas/loupe/releases/latest)
[![CI](https://github.com/pepperonas/loupe/actions/workflows/ci.yml/badge.svg)](https://github.com/pepperonas/loupe/actions/workflows/ci.yml)
[![Release build](https://github.com/pepperonas/loupe/actions/workflows/release.yml/badge.svg)](https://github.com/pepperonas/loupe/actions/workflows/release.yml)
[![Tests](https://img.shields.io/badge/Tests-306%20passing-brightgreen?logo=checkmarx&logoColor=white)](#-testing)
[![Swift LoC](https://img.shields.io/badge/Swift%20LoC-5%2C495-blue?logo=swift&logoColor=white)](Sources/)
[![License](https://img.shields.io/github/license/pepperonas/loupe?color=yellow)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/pepperonas/loupe?logo=git&logoColor=white)](https://github.com/pepperonas/loupe/commits/main)
[![Commit activity](https://img.shields.io/github/commit-activity/m/pepperonas/loupe?logo=github)](https://github.com/pepperonas/loupe/graphs/commit-activity)

<!-- Platform & technology -->
[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](#-installation)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-arm64-000000?logo=apple&logoColor=white)](#-installation)
[![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Strict Concurrency](https://img.shields.io/badge/Concurrency-Swift%206%20strict-FA7343?logo=swift&logoColor=white)](Package.swift)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-no%20Xcode%20project-FA7343?logo=swift&logoColor=white)](Package.swift)
[![Quick Look](https://img.shields.io/badge/Quick%20Look-QLPreviewProvider-1575F9?logo=apple&logoColor=white)](Sources/LoupePreview/PreviewProvider.swift)
[![AppKit](https://img.shields.io/badge/UI-AppKit-1575F9?logo=apple&logoColor=white)](Sources/Loupe/)
[![Dependencies](https://img.shields.io/badge/Dependencies-1%20(swift--markdown)-informational)](Package.swift)

<!-- Formats -->
[![JSON](https://img.shields.io/badge/JSON-collapsible%20tree-F7DF1E?logo=json&logoColor=black)](#-json)
[![Markdown](https://img.shields.io/badge/Markdown-CommonMark%20%2B%20GFM-000000?logo=markdown&logoColor=white)](#-markdown)
[![Logs](https://img.shields.io/badge/Logs-7%20formats-EF6C00?logo=logstash&logoColor=white)](#-log-files)
[![Source code](https://img.shields.io/badge/Highlighting-23%20languages-8E44AD?logo=codefactor&logoColor=white)](#-source-code)
[![PowerShell](https://img.shields.io/badge/PowerShell-.ps1%20.psm1%20.psd1-5391FE?logo=powershell&logoColor=white)](#-powershell--batch)
[![Batch](https://img.shields.io/badge/Batch-.bat%20.cmd-4D4D4D?logo=windowsterminal&logoColor=white)](#-powershell--batch)
[![XML](https://img.shields.io/badge/XML-%2B%2013%20dialects-E34F26?logo=xml&logoColor=white)](#-xml)
[![TSV](https://img.shields.io/badge/TSV-sticky%20table-217346?logo=googlesheets&logoColor=white)](#-tsv--csv)

<!-- Privacy, security, accessibility -->
[![App Sandbox](https://img.shields.io/badge/App%20Sandbox-read--only-success?logo=apple&logoColor=white)](Sources/LoupePreview/Resources/LoupePreview.entitlements)
[![JavaScript](https://img.shields.io/badge/JavaScript-0%20bytes-success?logo=javascript&logoColor=white)](#-security--privacy)
[![CSP](https://img.shields.io/badge/CSP-default--src%20'none'-success)](#-security--privacy)
[![Offline](https://img.shields.io/badge/Network-100%25%20offline-success?logo=wireguard&logoColor=white)](#-security--privacy)
[![Telemetry](https://img.shields.io/badge/Telemetry-none-success?logo=datadog&logoColor=white)](#-security--privacy)
[![Tracking pixels](https://img.shields.io/badge/Remote%20images-blocked-success)](#-security--privacy)
[![WCAG AA](https://img.shields.io/badge/Contrast-WCAG%20AA-success?logo=accessibility&logoColor=white)](#-accessibility--theming)
[![Dark Mode](https://img.shields.io/badge/Dark%20%26%20Light-native-222222?logo=apple&logoColor=white)](#-accessibility--theming)

<!-- Community -->
[![Stars](https://img.shields.io/github/stars/pepperonas/loupe?style=flat&logo=github)](https://github.com/pepperonas/loupe/stargazers)
[![Forks](https://img.shields.io/github/forks/pepperonas/loupe?style=flat&logo=github)](https://github.com/pepperonas/loupe/network/members)
[![Watchers](https://img.shields.io/github/watchers/pepperonas/loupe?style=flat&logo=github)](https://github.com/pepperonas/loupe/watchers)
[![Issues](https://img.shields.io/github/issues/pepperonas/loupe?logo=github)](https://github.com/pepperonas/loupe/issues)
[![Pull requests](https://img.shields.io/github/issues-pr/pepperonas/loupe?logo=github)](https://github.com/pepperonas/loupe/pulls)
[![Downloads](https://img.shields.io/github/downloads/pepperonas/loupe/total?logo=github)](https://github.com/pepperonas/loupe/releases)
[![Repo size](https://img.shields.io/github/repo-size/pepperonas/loupe?logo=github)](https://github.com/pepperonas/loupe)
[![Top language](https://img.shields.io/github/languages/top/pepperonas/loupe?logo=swift&logoColor=white)](https://github.com/pepperonas/loupe)
[![SemVer](https://img.shields.io/badge/SemVer-2.0.0-3F4551)](https://semver.org)
[![Keep a Changelog](https://img.shields.io/badge/Changelog-Keep%20a%20Changelog-E05735?logo=keepachangelog&logoColor=white)](CHANGELOG.md)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?logo=github)](#-contributing)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/hero-dark.png">
  <img src="docs/screenshots/hero-light.png" alt="Loupe previewing a Markdown file, a JSON file and a log file in Quick Look" width="100%">
</picture>

<sub>Every preview on this page is Loupe's real HTML output, rendered by its actual renderers — only the window frame is drawn around it (<a href="#-screenshots--mockups">how</a>). Images follow your GitHub light/dark theme.</sub>

<br><br>

<a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
  <img src="https://img.shields.io/badge/☕_Buy_the_dev_a_coffee-Donate_via_PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" height="40" alt="Donate via PayPal" />
</a>

</div>

---

## 📑 Contents

- [Why Loupe?](#-why-loupe)
- [Gallery](#-gallery) — [JSON](#-json) · [Markdown](#-markdown) · [Log files](#-log-files) · [Source code](#-source-code) · [XML](#-xml) · [PowerShell & Batch](#-powershell--batch) · [TSV & CSV](#-tsv--csv)
- [Supported file types](#-supported-file-types)
- [Installation](#-installation)
- [Settings](#%EF%B8%8F-settings)
- [Performance](#-performance)
- [Security & privacy](#-security--privacy)
- [Accessibility & theming](#-accessibility--theming)
- [How it works](#%EF%B8%8F-how-it-works)
- [Testing](#-testing)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Why Loupe?

macOS shows most developer files in Quick Look as a grey wall of monospace text — or not at all. Loupe replaces that with previews that are built for reading:

| | |
| :--- | :--- |
| 🌳 **JSON as a tree** — collapsible, in source order, with counts and type colors. Broken files still show everything up to the error, plus a caret pointing at it. | 🪵 **Logs you can scan** — time, level, source and message in columns, errors tinted, stack traces kept together. Seven log formats recognized. |
| 📝 **Markdown, rendered** — CommonMark + GFM: tables, task lists, highlighted code, local images. | 🌈 **23 languages highlighted** — including PowerShell and Batch, which macOS doesn't even know as file types. |
| ⚡ **Fast** — a 5 MB JSON file renders in 162 ms, a 4 MB log in 338 ms. | 🔒 **Safe by design** — sandboxed, read-only, strict CSP, not a single byte of JavaScript, no network. |

---

## 🖼 Gallery

### 🌳 JSON

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/json-dark.png">
  <img src="docs/screenshots/json-light.png" alt="Loupe JSON preview: collapsible tree with key counts" width="100%">
</picture>

- **Order-preserving parser** — keys stay in file order, duplicate keys are kept, numbers keep their spelling (`1.000` stays `1.000`, not `1`).
- **Smart expansion** — nodes open breadth-first within a budget of 300 visible rows: a `package.json` opens completely, a 50,000-element array stays folded.
- **Collapsed summaries** — every object and array shows its size and a peek at its first keys.
- **Pure HTML** — folding uses `<details>`/`<summary>`, no script involved.

#### When the JSON is broken

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/json-error-dark.png">
  <img src="docs/screenshots/json-error-light.png" alt="Loupe JSON error banner with line, column, excerpt and caret" width="100%">
</picture>

A syntax error doesn't produce a blank page: Loupe shows **line, column and a source excerpt with a caret**, and below it the tree **up to the point of failure**. The caret stays aligned with tabs, umlauts and emoji. A file that was merely *cut off* by Loupe's size limit is reported as a notice, never as an error.

<details>
<summary><b>All JSON capabilities</b></summary>

| Feature | Detail |
| :--- | :--- |
| Objects & arrays | Member/item count badges and a peek of the collapsed content |
| Source key order | Preserved exactly, no alphabetical re-sorting |
| Duplicate keys | Both occurrences are shown |
| Numbers | Kept as written — no float rounding, `1e400` doesn't become `inf` |
| Strings & escapes | `\uXXXX`, surrogate pairs (😀), control characters |
| Partial tree on error | Everything parsed before the error stays visible |
| Error excerpt | Line, column, context lines, caret — aligned for tabs and multi-byte characters |
| JSON Lines hint | Content after the first value is recognized as JSON Lines and explained |
| Limits | Depth 64 · 20,000 nodes · 1,000 children per container · 4 KB per string · 20 MB per file |

</details>

### 📝 Markdown

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/markdown-dark.png">
  <img src="docs/screenshots/markdown-light.png" alt="Loupe Markdown preview with callout, lists, task list and table" width="100%">
</picture>

CommonMark and GitHub Flavored Markdown via Apple's [`swift-markdown`](https://github.com/apple/swift-markdown): headings with anchors, emphasis, ~~strikethrough~~, blockquotes, nested and numbered lists, **task lists**, **tables with alignment**, fenced code blocks with syntax highlighting and a language badge, links, and **local images** (embedded as data URIs, confined to the document's folder). Raw HTML is sanitized, remote images are blocked unless you allow them.

<details>
<summary><b>All Markdown capabilities</b></summary>

| Feature | Syntax | Detail |
| :--- | :--- | :--- |
| Headings | `#` … `######` | Auto-generated anchor slugs |
| Emphasis | `**bold**`, `*italic*`, `~~strike~~` | SF Pro typography |
| Code | `` `inline` ``, fenced ```` ```lang ```` | Highlighted, with language badge |
| Blockquotes | `> note` | Callout style with accent border |
| Lists | `-`, `1.`, `3.` | Nested lists, custom start numbers |
| Task lists | `- [x]`, `- [ ]` | Native-looking checkboxes |
| Tables | `\| a \| b \|` | Column alignment, zebra rows |
| Links | `[t](https://…)` | Dangerous schemes (`javascript:`, `vbscript:`, `data:text/html`) are neutralized |
| Images | `![a](./pic.png)` | Local files only, path traversal blocked, remote images off by default |
| Raw HTML | `<div>…</div>` | `<script>`, `<iframe>`, `<form>`, event handlers etc. are stripped |

</details>

### 🪵 Log files

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/log-dark.png">
  <img src="docs/screenshots/log-light.png" alt="Loupe log preview with time, level badges, sources, tinted errors and a stack trace" width="100%">
</picture>

Every line is split into **time · level · source · message** — whatever format it's in, even when formats are mixed in one file. The level is normalized (`WARN`, `warning`, `W` and pino's `40` all become **WARN**), the toolbar counts FATAL/ERROR/WARN, and error rows are tinted together with their stack trace. URLs, IPs, numbers with units, UUIDs, paths and `key=value` pairs are highlighted inside messages.

| Format | Example | Extracted |
| :--- | :--- | :--- |
| **Generic application log** | `2026-09-24 17:01:02.123 INFO [main] Started` | Time, level, `[source]`, message — also `[time]`, time-only, `[LEVEL]`, `level=…`, `channel.LEVEL:` (Laravel/Monolog), `LEVEL:logger:msg` (Python) |
| **nginx / Apache access log** | `203.0.113.7 - - [24/Sep/2026:…] "GET / HTTP/1.1" 503 0 …` | Client, method, path, protocol, status colored by class, size, referer, user agent · 4xx → WARN, 5xx → ERROR |
| **JSON Lines** | `{"time":…,"level":"error","msg":"boom"}` | `time`/`ts`/`@timestamp`, `level`/`severity` (incl. pino numbers), `msg`/`message`, `logger`; everything else as `key=value`. Unix times become readable UTC |
| **logfmt** | `time=… level=warning msg="disk low"` | Same fields as JSON Lines |
| **syslog / journalctl** | `Sep 24 17:01:02 host sshd[1234]: …` | Time, host + process[pid], message — also ISO time (`journalctl -o short-iso`, macOS `install.log`) |
| **macOS unified log** | output of `log show` | Time, process[pid], type → level (Default → NOTICE, Error → ERROR, Fault → FATAL) |
| **Android logcat** | `09-24 17:01:02.123 1234 5678 E Tag: …` | Time, level letter, tag, message (threadtime and brief) |

- **Levels come from the head of a line only** — a message that merely mentions "error" is not an error. Without a timestamp, a bare level word must be UPPERCASE or followed by `:` (`Info about the job` stays prose).
- **Big logs are read from the end.** Logs grow at the bottom, so Loupe reads the last 4 MB and shows the newest 5,000 lines — with **absolute line numbers** (the skipped part is counted, up to 512 MB). A banner says exactly what was skipped.
- Try it: [`Tests/Fixtures/logs/`](Tests/Fixtures/logs/) has one sample per format plus edge cases; `python3 Scripts/generate_large_log.py` creates a 12 MB log for the tail path.

### 🌈 Source code

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/code-dark.png">
  <img src="docs/screenshots/code-light.png" alt="Loupe Swift source preview with line numbers and highlighting" width="100%">
</picture>

An in-process tokenizer written in Swift highlights **23 languages**: Swift, Rust, Python, JavaScript, TypeScript, Go, Java, Kotlin, C, C++, PHP, Ruby, SQL, Shell/Bash/Zsh, **PowerShell**, **Batch**, JSON, YAML, TOML/INI, XML/HTML, CSS, Dockerfile — with line numbers, a language badge and file statistics. Tokens become `<span>`s on the host side; nothing executes in the preview.

### 🧩 XML

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/xml-dark.png">
  <img src="docs/screenshots/xml-light.png" alt="Loupe XML preview with distinct colors for elements, attributes, values, CDATA and entities" width="100%">
</picture>

A dedicated, quote-aware XML tokenizer: element names, attributes, values and brackets each get their own color, as do the `<?xml … ?>` declaration, `<!DOCTYPE …>` (including an internal DTD subset), comments, **CDATA sections** (shown as text, not markup) and entities like `&amp;` or `&#x1F600;`. A `>` inside an attribute value, comment, CDATA block or DOCTYPE never ends a tag. The same tokenizer powers HTML code blocks in Markdown, where `<script>`/`<style>` content is treated as raw text.

Besides `.xml`, Loupe declares a type for **13 XML dialects** macOS doesn't know — `.xsd`, `.xsl`, `.xslt`, `.xaml`, `.csproj`, `.vbproj`, `.fsproj`, `.vcxproj`, `.props`, `.targets`, `.resx`, `.wsdl`, `.nuspec` — so Quick Look hands them to Loupe too. `.svg`, `.rss` and `.plist` stay with macOS (an SVG keeps showing as an image), and `.storyboard`/`.xib`/`.entitlements` are left to Xcode.

### 🪟 PowerShell & Batch

<table>
<tr>
<td width="50%">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/powershell-dark.png">
  <img src="docs/screenshots/powershell-light.png" alt="Loupe PowerShell preview" width="100%">
</picture>
</td>
<td width="50%">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/batch-dark.png">
  <img src="docs/screenshots/batch-light.png" alt="Loupe Batch preview" width="100%">
</picture>
</td>
</tr>
</table>

macOS assigns `.ps1`, `.bat` and `.cmd` only a *dynamic* type, so no Quick Look extension is ever asked to preview them. Loupe declares proper types (`com.microsoft.powershell-script`, `com.microsoft.batch-file`) and brings dedicated tokenizers:

- **PowerShell** — `<# help #>` blocks and `#` comments, variables incl. scopes (`$env:PATH`, `$script:x`, `${any name}`), cmdlets (`Get-ChildItem`), parameters (`-Path`), word operators (`-eq`, `-notin`, `-match`), type literals (`[string]`, `[System.IO.File]`), strings with **interpolation** of `$var` and `$(…)`, here-strings `@" … "@`, size literals (`10MB`), case-insensitive keywords.
- **Batch** — `REM` and `::` comments, labels and `goto :eof`, every variable form (`%PATH%`, `%~dp0`, `%1`, `%%i`, `%%~nxf`, `!delayed!`, `%DATE:~0,4%`), switches (`/b`, `/a`), case-insensitive keywords (`IF NOT EXIST`, `EQU`, `ERRORLEVEL`).

### 📊 TSV & CSV

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/tsv-dark.png">
  <img src="docs/screenshots/tsv-light.png" alt="Loupe TSV preview with sticky header, row numbers and right-aligned numbers" width="100%">
</picture>

Tab-separated and other delimited files become a proper table: **sticky header**, **sticky row numbers**, numbers right-aligned with tabular digits, delimiter auto-detection (`,` `;` `\t`), RFC 4180 quoting incl. multi-line cells, and a summary bar. Limits: 2,000 rows × 200 columns.

> [!IMPORTANT]
> **Comma-separated `.csv` files are not previewed by Loupe — and no Quick Look extension can change that.** macOS routes `public.comma-separated-values-text` to its built-in `/System/Library/QuickLook/Office.qlgenerator`, which takes precedence over every third-party extension and ignores Dark Mode. Loupe registers the type, yet Quick Look never calls it for `.csv` (verified in the unified log; a `.tsv` in the same session reaches Loupe). Declaring an own type for `.csv` doesn't help either — Launch Services keeps Apple's. The generator lives on the SIP-protected system volume. The same wall has been hit by CSV plugins since macOS 10.15 ([p2/quicklook-csv#26](https://github.com/p2/quicklook-csv/issues/26)). **Workaround:** save tabular data as `.tsv`.

---

## 📂 Supported file types

What matters is not what Loupe *can* render, but what **Quick Look actually hands to Loupe**. This table is checked against the extension's registration by a unit test (`DocsSyncTests`).

<!-- filetypes:start -->
| Format | Extensions | Type (UTI) | Finder preview |
| :--- | :--- | :--- | :---: |
| JSON | `.json` | `public.json` | ✅ |
| Markdown | `.md` `.markdown` | `net.daringfireball.markdown` | ✅ |
| Log | `.log` | `com.apple.log` → `public.log` | ✅ |
| Tab-separated | `.tsv` | `public.tab-separated-values-text` | ✅ |
| Comma-separated | `.csv` | `public.comma-separated-values-text` | ❌ reserved by macOS, [see above](#-tsv--csv) |
| PowerShell | `.ps1` `.psm1` `.psd1` | `com.microsoft.powershell-script` *(declared by Loupe)* | ✅ |
| Batch | `.bat` `.cmd` | `com.microsoft.batch-file` *(declared by Loupe)* | ✅ |
| Swift · Rust · Go | `.swift` `.rs` `.go` | `public.swift-source` · `org.rust-lang.rust-script` · `org.golang.go-script` | ✅ |
| Python · Ruby · PHP | `.py` `.rb` `.php` | `public.python-script` · `public.ruby-script` · `public.php-script` | ✅ |
| JavaScript | `.js` `.mjs` | `com.netscape.javascript-source` | ✅ |
| Java · Kotlin | `.java` `.kt` `.kts` | `com.sun.java-source` · `org.kotlinlang.source` | ✅ |
| C · C++ | `.c` `.h` `.cpp` `.cc` `.cxx` `.hpp` `.hxx` `.h++` | `public.c-source` · `public.c-plus-plus-source` · headers | ✅ |
| Shell | `.sh` `.bash` `.zsh` | `public.shell-script` and variants | ✅ |
| SQL | `.sql` | `org.iso.sql` | ✅ |
| YAML · TOML · INI | `.yaml` `.yml` `.toml` `.ini` | `public.yaml` · `public.toml` · `com.microsoft.ini` | ✅ |
| XML | `.xml` | `public.xml` | ✅ |
| XML dialects | `.xsd` `.xsl` `.xslt` `.xaml` `.csproj` `.vbproj` `.fsproj` `.vcxproj` `.props` `.targets` `.resx` `.wsdl` `.nuspec` | `io.celox.loupe.xml-document` *(declared by Loupe)* | ✅ |
| CSS | `.css` | `public.css` | ✅ |
<!-- filetypes:end -->

**Highlighted, but not reachable from Finder** — macOS gives these either a *dynamic* type or one that belongs to something else, so Quick Look never asks Loupe:

<!-- unreachable:start -->
- `.ts` — macOS types it as an **MPEG-2 transport stream** (video). Claiming it would turn real video files into text.
- `.tsx` `.jsx` `.cjs` `.pyw` `.scss` `.sass` `.less` `.dockerfile` — dynamic types only.
<!-- unreachable:end -->

The same is true for `.out`, `.err` and rotated logs like `app.log.1`: dynamic types — and claiming `.out` would additionally turn binaries like `a.out` into text.

---

## 📦 Installation

### Download (recommended)

1. Download `Loupe-vX.Y.Z-macOS.zip` from the [latest release](https://github.com/pepperonas/loupe/releases/latest) — builds are **Apple Silicon (arm64)**. Each release ships a `SHA256SUMS.txt`.
2. Unzip and move `Loupe.app` to `/Applications`.
3. The app is **ad-hoc signed**, not notarized. On first launch macOS will refuse to open it — either right-click → **Open**, use **System Settings → Privacy & Security → Open Anyway**, or run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Loupe.app
   ```
4. Launch Loupe once. The window shows whether the Quick Look extension is registered.

### Build from source

Requires Xcode 16 / Swift 6 command line tools. No Xcode project needed.

```bash
git clone https://github.com/pepperonas/loupe.git
cd loupe
./Scripts/install_app.sh      # build (release), sign ad-hoc, install to /Applications, register, reset Quick Look
```

`Scripts/build_app.sh [debug|release]` only builds the bundle into `build/Loupe.app`; `Scripts/package_release.sh vX.Y.Z` creates the release zip plus checksums.

### Enable the extension

Third-party Quick Look extensions need a one-time approval:

- **macOS 15 and later:** System Settings → **General → Login Items & Extensions** → *Quick Look* → enable **Loupe**.
- **macOS 14:** System Settings → **Privacy & Security → Extensions → Quick Look** → enable **Loupe**.
- Or from the terminal: `pluginkit -e use -i io.celox.loupe.preview`

Then select a file in Finder and press <kbd>Space</kbd>.

---

## ⚙️ Settings

The companion app (`Loupe.app`) shows the live registration status of the extension, setup hints, and three settings shared with the extension through an App Group:

| Setting | Options | Applies to |
| :--- | :--- | :--- |
| **Appearance** (Erscheinungsbild) | System · Light · Dark | All previews |
| **Text size** (Textgröße) | Small · Standard · Large | All previews |
| **Markdown width** (Markdown-Breite) | Compact 680 px · Standard 840 px · Wide 1040 px · Full width | Markdown |

> [!NOTE]
> The user interface of the app and the preview chrome (e.g. "12 Schlüssel", "25 Zeilen") is currently **German**. File contents are of course shown as they are.

---

## ⚡ Performance

Measured by the test suite (release build, Apple M1 Pro, macOS 27). The suite enforces hard upper bounds for the large cases — 1 s in release builds, 2.5 s in debug builds on shared CI runners — so a performance regression fails the build.

| Input | Renderer | Time |
| :--- | :--- | ---: |
| Small JSON document | JSON tree | **8 ms** |
| 5 MB JSON | JSON tree (node limit applies) | **162 ms** |
| 4 MB log (≈ 40,000 lines → newest 5,000) | Log table | **338 ms** |

Large files are never read completely: JSON and code are capped at 20 MB from the start, logs are read from the end (4 MB).

---

## 🔒 Security & privacy

Developer files often come from untrusted sources (`git clone`, downloads, build artifacts). Loupe treats every file as hostile input:

- **Sandboxed & read-only** — the extension runs in the App Sandbox with `com.apple.security.files.user-selected.read-only`, nothing else.
- **No JavaScript, anywhere** — previews are static HTML + CSS. Collapsing uses `<details>`.
- **Strict Content Security Policy** — `default-src 'none'; style-src 'unsafe-inline'; img-src 'none'` (Markdown: `img-src data: cid:`). No policy allows `script-src`.
- **Everything is escaped** — every value, key, log field, file name and code token goes through HTML escaping; tests feed `<script>` and `onerror=` through every renderer.
- **Markdown sanitizing** — dangerous elements and event handlers are stripped, `javascript:`/`vbscript:`/`data:text/html` links neutralized.
- **Path traversal guard** — local images are resolved with symlinks canonicalized and must stay inside the document's folder.
- **No network** — remote images are blocked by default (no tracking pixels), there is no telemetry and no update check.
- **Hard limits against hostile files** — JSON depth 64 (stack-overflow guard), 20,000 nodes, 1,000 children per container, 4 KB per displayed string, 20 MB per file; logs 4 MB / 5,000 lines; tables 2,000 rows × 200 columns.

---

## 🎨 Accessibility & theming

Light and dark themes follow the system (or your choice in the app) and use SF Pro / SF Mono. Every color role meets **WCAG AA (≥ 4.5 : 1)**:

- **JSON, Markdown and code colors** were measured on a canvas, composited over their real backgrounds (`Scripts/measure_contrast.html`) — ratios from **6.4 : 1** to **16.8 : 1**.
- **Log colors** (all levels, HTTP status classes, timestamps, sources) are checked by a **unit test** in both themes — including on the tinted background of error rows.

<details>
<summary><b>Measured JSON/Markdown color roles</b></summary>

| Role | Light (`#ffffff`) | Dark (`#1e1e1e`) |
| :--- | :--- | :--- |
| Text | `#1d1d1f` · 16.83 : 1 | `#f5f5f7` · 15.31 : 1 |
| Dimmed text | `#5b5e69` · 6.46 : 1 | `#a1a1a6` · 6.48 : 1 |
| Object key | `#0b5fb0` · 6.41 : 1 | `#7ab8ff` · 8.04 : 1 |
| String | `#b3261e` · 6.54 : 1 | `#ff8170` · 6.85 : 1 |
| Number | `#1c00cf` · 10.77 : 1 | `#dabaff` · 9.88 : 1 |
| Boolean | `#7a3ea3` · 6.90 : 1 | `#d8a0ff` · 8.25 : 1 |
| Keyword | `#af00db` · 6.42 : 1 | `#ff7ab2` · 8.12 : 1 |
| Link | `#0066cc` · 6.82 : 1 | `#2997ff` · 7.84 : 1 |
| Error banner | `#a5251c` · 6.72 : 1 | `#ff8a80` · 6.64 : 1 |

Negative control: `#cccccc` on `#ffffff` measures 1.61 : 1, proving the harness catches failures.

</details>

---

## 🏗️ How it works

```mermaid
flowchart LR
    F["Finder<br/>(Space)"] --> Q["Quick Look<br/>daemon"]
    Q -->|file URL| P["LoupePreview.appex<br/>PreviewProvider"]
    P --> R["RendererRegistry<br/>extension → UTI"]
    R --> J["JSON"] & M["Markdown"] & L["Log"] & C["TSV/CSV"] & S["Source code"]
    P -.->|read strategy| FR["PreviewFileReader<br/>head · tail"]
    J & M & L & C & S --> H["HTML + CSS<br/>strict CSP, 0 JS"]
    H -->|QLPreviewReply| Q
```

1. **Finder** asks Quick Look for a preview; Quick Look hands the file URL to the **extension** because its type is listed in `QLSupportedContentTypes`.
2. The **`RendererRegistry`** picks a renderer by file extension first, then by type (UTI).
3. The renderer declares **how to read** the file: from the start (documents, code) or from the **end** (logs); `PreviewFileReader` reads only that part.
4. The renderer returns a **self-contained HTML page** (styles inline, strict CSP); Quick Look displays it in WebKit.

<details>
<summary><b>Project layout</b></summary>

```text
Loupe.app                         Companion app (AppKit): status, settings
└── Contents/PlugIns/LoupePreview.appex   Quick Look extension (QLPreviewProvider)

Sources/
├── Loupe/                        Companion app
├── LoupePreview/                 Extension entry point + Info.plist (QLSupportedContentTypes)
└── LoupeCore/                    Everything testable
    ├── JSON/                     Lexer, order-preserving parser with recovery, source excerpts
    ├── Markdown/                 swift-markdown visitor, sanitizer, safe image resolver
    ├── CSV/                      RFC 4180 parser with delimiter detection, table renderer
    ├── Log/                      Log model, format detection, message highlighter
    ├── Highlighting/             Tokenizers for 23 languages (incl. PowerShell & Batch)
    ├── Preview/                  Renderer protocol, registry, file reader, one renderer per format
    ├── Render/                   JSON tree, expansion planner, HTML escaping
    ├── Theme/                    CSS generator (light/dark, WCAG AA)
    ├── Configuration/            Settings shared via App Group
    └── Utilities/                Extension status checker (pluginkit)

Tests/LoupeTests/                 Test suite (swift run LoupeTests)
Tests/Fixtures/                   Sample files: JSON, Markdown, logs/, scripts/
Tools/ScreenshotGenerator/        Generates the mockups on this page
Scripts/                          Build, install, package, badges, large-log generator
```

</details>

---

## 🧪 Testing

```bash
swift run LoupeTests              # debug
swift run -c release LoupeTests   # release (as in the release workflow)
```

**306 tests** in a dependency-free harness, run by CI on every push:

| Area | Tests | Highlights |
| :--- | ---: | :--- |
| JSON | 70 | Order, duplicates, number spelling, recovery, limits incl. depth bomb, caret alignment |
| Log files | 64 | All seven formats, level normalization, stack traces, CRLF, tail reading, absolute line numbers, WCAG contrast |
| Highlighting | 63 | 23 languages, quote-aware XML/HTML, PowerShell & Batch, no phantom last line, **every printable character in every language must terminate and round-trip** |
| Markdown & safety | 41 | GFM, sanitizer bypass attempts, path traversal, remote-image blocking |
| TSV / CSV | 22 | RFC 4180 quoting, delimiter detection, limits |
| Theming & settings | 19 | Light/dark CSS, settings migration |
| Registry & app | 18 | Type routing, CSP, invalid UTF-8, empty files, pluginkit parsing |
| Docs sync | 6 | This README against the code: versions, test badge, image paths, EN/DE parity, Finder reachability |
| Performance | 3 | Hard time limits for large inputs |

How the tests are kept honest:

- **Mutation-checked.** New tests are verified by deliberately breaking the code they guard — a test that stays green against broken code is rewritten. This is how several initially blind tests were found and sharpened.
- **Documentation is tested.** `DocsSyncTests` fails when this README promises a file type Quick Look never delivers, when the test badge is stale, or when the English and German READMEs drift apart. `Scripts/update_readme_stats.sh` refreshes the badges.
- **Fixtures for manual testing** live in [`Tests/Fixtures/logs/`](Tests/Fixtures/logs/) and [`Tests/Fixtures/scripts/`](Tests/Fixtures/scripts/).

---

## 🛠️ Troubleshooting

| Symptom | Fix |
| :--- | :--- |
| Finder still shows plain text | Enable the extension ([see above](#enable-the-extension)), then `qlmanage -r && qlmanage -r cache && killall Finder` |
| Is the extension registered? | `pluginkit -m -v -i io.celox.loupe.preview` — a leading `+` means enabled |
| Old version keeps answering | List all copies: `pluginkit -m -A -v -p com.apple.quicklook.preview \| grep -i loupe`, remove stale ones, reinstall with `./Scripts/install_app.sh` |
| Which type does macOS assign a file? | `mdls -name kMDItemContentType <file>` — `dyn.…` means no extension will be asked |
| `.csv` is still white | Expected — macOS reserves CSV, [see above](#-tsv--csv). Use `.tsv`. |
| Watch the extension live | `log stream --predicate 'subsystem == "io.celox.loupe.preview"' --info` — logs the chosen renderer and output size for every preview |

---

## 🤝 Contributing

Issues and pull requests are welcome.

1. `swift run LoupeTests` must stay green — new behavior comes with tests (and ideally a failing test first).
2. User-visible changes go into [`CHANGELOG.md`](CHANGELOG.md) (Keep a Changelog, SemVer).
3. Changed rendering? Regenerate the mockups: `Tools/ScreenshotGenerator/generate.sh` (needs Google Chrome; `pngquant` optional).
4. Changed test count or code size? `Scripts/update_readme_stats.sh`.
5. Keep [`README.md`](README.md) and [`README.de.md`](README.de.md) in step — the docs-sync test checks it.

## 📸 Screenshots & mockups

The images on this page are generated by [`Tools/ScreenshotGenerator`](Tools/ScreenshotGenerator/): a small Swift tool renders the sample files through Loupe's **real `RendererRegistry` and renderers** (light and dark), a Python script places each result into a macOS-style Quick Look window, and headless Chrome captures it at 1.5× resolution. The window frame and background are drawn; the content is Loupe's unmodified output.

---

## 💖 Support

If Loupe saves you time, consider supporting its development:

<a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR"><img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal&logoColor=white&style=for-the-badge" alt="Donate via PayPal"></a>

## 📄 License

MIT — see [LICENSE](LICENSE). Made with ❤️ by **Martin Pfeffer** · [celox.io](https://celox.io) · © 2026
