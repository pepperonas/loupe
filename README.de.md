# Loupe

<div align="center">

  <a href="README.md">
    <img src="https://img.shields.io/badge/Language-English-555555?style=for-the-badge&logo=apple&logoColor=white" alt="English">
  </a>
  &nbsp;
  <a href="README.de.md">
    <img src="https://img.shields.io/badge/Sprache-Deutsch-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Deutsch">
  </a>

  <br><br>

[![Release](https://img.shields.io/badge/Release-v0.3.2-007AFF?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe/releases)
[![Build](https://img.shields.io/badge/Build-Bestanden-brightgreen?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/Tests-197%20Unit--Tests%20bestanden-brightgreen?logo=apple&logoColor=white)](Tests/LoupeTests/)
[![Zeilen Code](https://img.shields.io/badge/LoC-4.021%20Zeilen%20Swift-blue?logo=swift&logoColor=white)](Sources/)
[![Lizenz: MIT](https://img.shields.io/badge/Lizenz-MIT-yellow.svg)](LICENSE)
<br>
[![Plattform](https://img.shields.io/badge/Plattform-macOS%2014%2B-000000?logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Sandboxed](https://img.shields.io/badge/Sandbox-App%20Sandbox%20%2B%20Read--Only-success?logo=apple&logoColor=white)](Sources/LoupePreview/Resources/LoupePreview.entitlements)
[![Zero JS](https://img.shields.io/badge/JavaScript-0%20Bytes%20%E2%9C%93-success)](https://github.com/pepperonas/loupe)
[![Offline](https://img.shields.io/badge/Funktioniert-100%25%20Offline-blue?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe)
[![Keine Telemetrie](https://img.shields.io/badge/Telemetrie-Keine%20%E2%9C%93-success)](https://github.com/pepperonas/loupe)
[![GitHub-Sterne](https://img.shields.io/github/stars/pepperonas/loupe?style=flat&logo=github)](https://github.com/pepperonas/loupe/stargazers)
[![GitHub-Forks](https://img.shields.io/github/forks/pepperonas/loupe?style=flat&logo=github)](https://github.com/pepperonas/loupe/network/members)
[![GitHub-Issues](https://img.shields.io/github/issues/pepperonas/loupe?style=flat&logo=github)](https://github.com/pepperonas/loupe/issues)
[![Downloads](https://img.shields.io/github/downloads/pepperonas/loupe/total?style=flat&logo=github)](https://github.com/pepperonas/loupe/releases)
[![SemVer](https://img.shields.io/badge/SemVer-2.0.0-3F4551)](https://semver.org)
[![Changelog](https://img.shields.io/badge/Changelog-Keep%20a%20Changelog-E05735?logo=keepachangelog&logoColor=white)](CHANGELOG.md)
<br><br>
<img src="docs/social-preview.png" alt="Loupe — native macOS Quick-Look-Vorschauen für JSON, Markdown und Quellcode" width="100%">
<br><br>
<a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
  <img src="https://img.shields.io/badge/☕_Entwickler_einen_Kaffee_ausgeben-Spende_via_PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" height="42" alt="Spende via PayPal" />
</a>

<br><br>

```
┌────────────────────────────────────────────────────────────────────────────┐
│  Finder → Beliebige JSON- (.json), Markdown- (.md) oder CSV/TSV-Datei      │
│  Leertaste drücken → Sofortige native Vorschau ohne JavaScript!            │
└────────────────────────────────────────────────────────────────────────────┘
```

</div>

---

## Übersicht

**Loupe** ist eine extrem schlanke, blitzschnelle native macOS-Anwendung und Quick Look Preview Extension (`io.celox.loupe.preview`), die interaktive, formatierte Entwicklerdateien direkt in den macOS Finder bringt.

Loupe bietet erstklassige, gehärtete Unterstützung für Entwicklerdateien einschließlich:
- **JSON** (`public.json`): Aufklappbarer Baum mit erhaltener Schlüsselreihenfolge, Typ-Badges, Elementzählern, Syntax-Farbrollen und intelligenter Breitensuche-Voraufklappung.
- **Markdown** (`net.daringfireball.markdown`): Vollständiges CommonMark- und GitHub Flavored Markdown (GFM)-Rendering mit reiner Swift-Syntaxhervorhebung für 17+ Programmiersprachen, formatierten Tabellen, Aufgabenlisten und sicheren relativen Bildern.
- **CSV & TSV** (`public.comma-separated-values-text`, `public.tab-separated-values-text`, `public.delimited-values-text`): Nativer Tabellen-Renderer mit vollständiger Dark-Mode-Unterstützung (keine grell-weiße Blendung wie bei macOS Quick Look). Mit automatischer Trennzeichenerkennung (`,`, `;`, `\t`), fixierter Kopfzeile, Zeilennummern `#` und Zahlenausrichtung.
- **Quellcode**: Native, syntax-hervorgehobene Vorschauen für Swift, Rust, Python, JavaScript/TypeScript, Go, Java/Kotlin, C/C++, HTML/XML, CSS, YAML, TOML, SQL, Shell, PHP, Ruby und weitere Formate.

Ein Druck auf die **Leertaste** bei einer beliebigen unterstützten Datei öffnet unmittelbar eine elegante Vorschau – **ohne ein einziges Byte JavaScript**, ohne Electron und ohne ressourcenhungrige Hintergrunddienste.

Entwickelt streng nach Apples Human Interface Guidelines fügt sich Loupe optisch, funktional und ergonomisch wie eine offizielle macOS-Systemkomponente ein.

## Screenshots

Diese Vorschauen werden direkt von Loupes Finder-Quick-Look-Erweiterung im Dunkelmodus gerendert – ohne JavaScript und ohne externen Dienst.

| Showcase & JSON-Baum | Syntaxhervorhebung | GFM-Aufgabenlisten & Tabellen |
| --- | --- | --- |
| <img src="docs/screenshots/json-preview.png" alt="Loupe JSON-Quick-Look-Vorschau" width="100%"> | <img src="docs/screenshots/source-code-preview.png" alt="Loupe Quellcode-Quick-Look-Vorschau" width="100%"> | <img src="docs/screenshots/markdown-preview.png" alt="Loupe Markdown-GFM-Vorschau mit Aufgabenlisten und Tabellen" width="100%"> |

---

## Hauptmerkmale

- ⚡ **Sofortige Vorschau**: Schneller Start dank Apples moderner datenbasierter `QLPreviewProvider`- und `QLPreviewReply`-APIs (macOS 14.0+). Rendert 50 KB JSON in unter 10 ms und 5-MB-Dateien in ~160 ms.
- 🌳 **Aufklappbarer Baum ohne JavaScript**: 100% interaktiver JSON-Baum, ausschließlich realisiert über HTML5 `<details>`- und `<summary>`-Elemente. Keinerlei Skriptausführung, kein DOM-Scripting, keine Event-Listener-Last.
- 📝 **Umfassendes CommonMark- & GFM-Markdown**: Überschriften (H1–H6 mit Auto-Slug-Ankern), Fett, Kursiv, Durchgestrichen, Blockzitate, geordnete/ungeordnete Listen, Aufgabenlisten mit Checkboxen sowie gestaltete Tabellen.
- 🌈 **Syntaxhervorhebung in reinem Swift**: Hostseitige Tokenisierung für 17+ Programmiersprachen (Swift, Rust, Python, JavaScript, TypeScript, Go, Java, Kotlin, C, C++, HTML, XML, CSS, JSON, YAML, SQL, Shell/Bash, Markdown) ganz ohne JavaScript-Engine im Vorschaufenster.
- 💻 **Quellcode als First-Class-Format**: Finder-Vorschauen für gängige Quelltextformate mit gut lesbarer Monospace-Darstellung, sprachabhängigen Token-Farben und sicherem Fallback für unbekannte Endungen.
- 📐 **Ordnungserhaltender & exakter AST**: Bewahrt die originale Schlüsselreihenfolge der Datei, behält doppelte Schlüssel und erhält die exakte Quelltext-Schreibweise von Zahlen (z. B. `1.000` vs `1e3`).
- 🧭 **Intelligente Vor-Aufklappung (BFS-Budget)**: Statt starrer Tiefengrenzen nutzt Loupe einen Breitensuche-Algorithmus mit Zeilenbudget (Standard: 300 sichtbare Zeilen). Eine typische `package.json` liegt vollständig offen, während riesige Arrays an der Wurzel zugeklappt bleiben.
- 🩹 **Tolerante Fehleranzeige & Quelltext-Ausschnitt**: Bei Syntaxfehlern bricht Loupe nicht mit einer leeren Seite ab. Der bis zum Fehler gültig geparste Teilbaum bleibt sichtbar, begleitet von einem roten Fehlerbanner mit Zeile, Spalte, Quelltext-Kontext und exaktem Zeiger (`^`) unter Berücksichtigung von UTF-8-Multibyte-Zeichen und Tabulator-Breite.
- 🛡️ **Gehärtete Obergrenzen & DoS-Schutz**: Schutz vor Stack Overflow durch Tiefenbremse (max. 64 Ebenen), Speichersicherheit durch Knotengrenze (20.000 Knoten), Container-Kinder-Grenze (1.000 Kinder), String-Längenbegrenzung (4 KB) und Dateigrößen-Grenzen (20 MB für JSON, 5 MB für Markdown).
- 🔒 **Zero Telemetry & Pfad-Traversal-Schutz**: Isoliert in Apples App Extension Sandbox (`com.apple.security.app-sandbox`) mit reinem Lesezugriff. Lokale relative Bilder werden via Base64 mit Symlink-Kanonisierung eingebettet. Remote-Bilder sind standardmäßig gesperrt, um Tracking-Pixel zu verhindern.
- 🎨 **Apple-Typografie & Kontrast-geprüfte Themes**: Helles und dunkles Theme, gesetzt in `SF Pro`, `SF Mono` und `ui-monospace`. Alle semantischen Farbrollen wurden auf einem Canvas gegen die WCAG AA-Norm geprüft (alle Kontrastwerte > 4,5:1, von 6,4:1 bis 16,8:1).
- 📊 **Natives, Theme-konformes CSV & TSV**: Beseitigt den Blendeffekt der standardmäßigen macOS-Vorschau, die CSV-Dateien auch im Dunkelmodus grell weiß anzeigt. RFC 4180-Parser mit automatischer Trennzeichenerkennung (`,`, `;`, `\t`), fixierter Tabellenkopfzeile, fixierter Zeilennummer `#` und rechtsbündiger Zahlenausrichtung.
- 💻 **Native Begleit-App**: Integrierte AppKit-Begleit-App mit Echtzeit-Statusdiagnose der Quick-Look-Erweiterung, Hilfestellungen zur Systemaktivierung sowie Einstellungen für Erscheinungsbild, Textgröße und Markdown-Breite.

---

## Unterstützte JSON-Features & Funktionen

| Feature | Beschreibung | Unterstützt | Technisches Detail |
| :--- | :--- | :---: | :--- |
| **Objekte (`{ ... }`)** | Verschachtelte Schlüssel-Wert-Strukturen | ✅ | Zeigt Schlüssel-Anzahl und Vorschau-Peek im zugeklappten Zustand |
| **Arrays (`[ ... ]`)** | Geordnete Wertlisten | ✅ | Zeigt Element-Anzahl und Index-/Typ-Vorschau im Header |
| **Original-Schlüsselreihenfolge** | Exakte Dateireihenfolge | ✅ | Bewahrt Quelltext-Reihenfolge ohne alphabetische Umsortierung |
| **Doppelte Schlüssel** | Mehrfach vergebene Schlüssel | ✅ | Behält beide Vorkommen bei und zeigt sie getreu an |
| **Exakte Zahlendarstellung** | Beliebige Zahlengenauigkeit | ✅ | Behält die Quellschreibweise ohne Gleitkomma-Rundungsfehler |
| **Strings & Escapes** | UTF-8 Zeichenketten & Surrogatpaare | ✅ | Verarbeitet `\uXXXX`, Surrogatpaare (z. B. `😀`) und Zeilenumbrüche |
| **Aufklappbare Knoten** | Native Baum-Interaktion | ✅ | HTML5 `<details>`/`<summary>` mit sanftem Rotationszeiger |
| **Intelligente Expansion** | Voreingestellte Aufklappung | ✅ | Breitensuche-Queue innerhalb konfigurierbarem Zeilenbudget |
| **Teilbaum-Erhalt bei Fehlern** | Resiliente Fehlerbehandlung | ✅ | Zeigt bereits gültig gelesene Knoten vor der Abbruchstelle |
| **Fehler-Ausschnitt & Zeiger** | Visueller Fehler-Lokalisierer | ✅ | Zeigt Zeilennummer, Spalte, Quelltext-Kontext und Zeiger (`^`) |
| **Unicode- & Emoji-Ausrichtung** | Mehrsprachiger Multibyte-Text | ✅ | Byte-zu-Zeichen-Umrechnung verhindert Zeiger-Versatz bei Umlauten/Emoji |
| **Tabulator-Ausrichtung** | Tab-Expansion im Ausschnitt | ✅ | Rechnet Tabulatoren in Leerzeichen um für visuell exakten Zeiger |
| **Kürzungs-Hinweisbanner** | Sichere Datei-Obergrenzen | ✅ | Unterscheidet zwischen gewollter Kürzungsbremse und echtem Syntaxfehler |
| **Dunkel- & Hellmodus** | Systemweites Erscheinungsbild | ✅ | Media-Query-Isolation; feste Überschreibung in den Einstellungen |
| **Konfigurierbare Textgröße** | Klein, Standard, Groß | ✅ | Gespeichert über Shared App Group UserDefaults |

---

## Unterstützte Markdown-Features

| Feature | Syntax-Beispiel | Unterstützt | Details |
| :--- | :--- | :---: | :--- |
| **Überschriften** | `# H1` bis `###### H6` | ✅ | Mit automatisch generierten Anker-IDs für interne Navigation |
| **Hervorhebung** | `**fett**`, `*kursiv*`, `***beides***` | ✅ | Typografie in Apple SF Pro |
| **Durchgestrichen** | `~~gelöschter Text~~` | ✅ | GitHub Flavored Markdown (GFM) `<del>` |
| **Inline-Code** | `` `let value = 10` `` | ✅ | Monospace-Schriftart mit dezentem Rahmen |
| **Codeblöcke** | ```` ```swift ... ``` ```` | ✅ | Syntaxhervorhebung mit Sprachen-Badge |
| **Blockzitate** | `> Apple Callout` | ✅ | Native Apple-Callout-Gestaltung mit Farbkante |
| **Listen** | `- Ungeordnet`, `1. Geordnet` | ✅ | Kompakte Abstände, verschachtelte Listen, benutzerdefinierte Startindizes |
| **Aufgabenlisten** | `- [x] Erledigt`, `- [ ] Offen` | ✅ | Native Checkboxen im macOS-Design |
| **Tabellen** | `\| Spalte \| Wert \|` | ✅ | Abwechselnde Zeilenfarben und dezente Rahmen |
| **Trennlinien** | `---` | ✅ | Elegante macOS-Trennlinien |
| **Sichere Links** | `[Titel](https://...)` | ✅ | Öffnet im Standard-Browser (`target="_blank"`) |
| **Bilder** | `![Alt](./images/bild.png)` | ✅ | Sicheres lokales relatives Laden über Base64 Data-URIs |
| **Unicode & Emojis** | Mehrsprachiger Text & Emojis | ✅ | Volle UTF-8-Unterstützung |

### Syntaxhervorhebung in reinem Swift

Loupe enthält einen maßgeschneiderten Tokenizer in reinem Swift für:

- **Sprachen**: Swift, Rust, Python, JavaScript, TypeScript, Go, Java, Kotlin, C, C++, HTML, XML, CSS, JSON, YAML, SQL, Shell/Bash und Markdown.
- **Sicherheit**: Der Quelltext wird auf der Host-Seite in sichere HTML-Spans (`<span class="hl-kw">...</span>`) zerlegt. Im WebKit-Vorschaufenster läuft kein JavaScript.

---

## Unterstützte CSV- & TSV-Features

macOS verfügt zwar über eine standardmäßige CSV-Vorschau, diese ignoriert das dunkle System-Erscheinungsbild jedoch vollständig und blendet Anwender mit einer rein weißen Seite. Loupe ersetzt dies durch eine elegante, vollständige Desktop-Tabellendarstellung:

| Feature | Beschreibung | Unterstützt | Technisches Detail |
| :--- | :--- | :---: | :--- |
| **Dunkel- & Hellmodus** | Theme-gerechte Tabellendarstellung | ✅ | Fügt sich nahtlos ins System ein; verhindert Blendung im Dark Mode |
| **Trennzeichen-Erkennung** | Intelligente Delimiter-Erkennung | ✅ | Erkennt Komma (`,`), Semikolon (`;` für deutsche Excel-CSVs) und Tabulator (`\t`) |
| **Fixierte Kopfzeile** | Pinned Spaltenköpfe | ✅ | `thead th` mit `position: sticky; top: 0` bleibt beim Scrollen fixiert |
| **Fixierte Zeilennummern** | Pinned Index-Spalte (`#`) | ✅ | Spalte `#` bleibt beim horizontalen Scrollen am linken Rand fixiert |
| **Rechtsbündige Zahlen** | Tabellarische Ziffern | ✅ | Erkennt Zahlenwerte automatisch und richtet sie mit `tabular-nums` rechtsbündig aus |
| **RFC 4180-Maskierung** | Vollständige Anführungszeichen | ✅ | Quoted Fields, maskierte Anführungszeichen (`""`) und mehrzeilige Zellen |
| **Status-Toolbar** | Tabellen-Statistiken | ✅ | Badges mit Zeilenanzahl, Spaltenanzahl und verwendetem Trennzeichen |
| **Sichere Obergrenzen** | Speicher- & DoS-Schutz | ✅ | Begrenzt auf 2.000 Zeilen / 200 Spalten mit sauberem Kürzungs-Hinweis |
| **Kein JavaScript** | Reines HTML5/CSS | ✅ | Null client-seitiges JavaScript, geschützt durch strikte CSP |

---

## Kontrast-geprüfte Farbrollen (WCAG AA)

Alle Farbwerte wurden auf einem HTML5-Canvas über den Hintergrundschichten gerastert und pixelgenau gemessen (`Scripts/measure_contrast.html`):

| Farbrolle | Helles Theme (`#ffffff`) | Dunkles Theme (`#1e1e1e`) | WCAG-Status |
| :--- | :--- | :--- | :---: |
| **Text (`--text` / `--text-primary`)** | `#1d1d1f` → **16,83:1** | `#f5f5f7` → **15,31:1** | ✅ Pass (> 4,5:1) |
| **Gedimmter Text (`--text-dim`)** | `#5b5e69` → **6,46:1** | `#a1a1a6` → **6,48:1** | ✅ Pass (> 4,5:1) |
| **Objektschlüssel (`--key`)** | `#0b5fb0` → **6,41:1** | `#7ab8ff` → **8,04:1** | ✅ Pass (> 4,5:1) |
| **String-Literal (`--str` / `--hl-str`)** | `#b3261e` → **6,54:1** | `#ff8170` → **6,85:1** | ✅ Pass (> 4,5:1) |
| **Zahlen-Literal (`--num` / `--hl-num`)** | `#1c00cf` → **10,77:1** | `#dabaff` → **9,88:1** | ✅ Pass (> 4,5:1) |
| **Boolean-Literal (`--bool`)** | `#7a3ea3` → **6,90:1** | `#d8a0ff` → **8,25:1** | ✅ Pass (> 4,5:1) |
| **Null-Literal (`--null`)** | `#5b5e69` → **6,46:1** | `#a1a1a6` → **6,48:1** | ✅ Pass (> 4,5:1) |
| **Zähler / Peek (`--count`)** | `#5b5e69` → **6,46:1** | `#a1a1a6` → **6,48:1** | ✅ Pass (> 4,5:1) |
| **Schlüsselwort (`--hl-kw`)** | `#af00db` → **6,42:1** | `#ff7ab2` → **8,12:1** | ✅ Pass (> 4,5:1) |
| **Typname (`--hl-type`)** | `#2b1378` → **11,02:1** | `#ac80ff` → **8,55:1** | ✅ Pass (> 4,5:1) |
| **Link (`--link-color`)** | `#0066cc` → **6,82:1** | `#2997ff` → **7,84:1** | ✅ Pass (> 4,5:1) |
| **Fehler-Banner (`--err-fg`)** | `#a5251c` auf `--err-bg` → **6,72:1** | `#ff8a80` auf `--err-bg` → **6,64:1** | ✅ Pass (> 4,5:1) |
| **Hinweis-Banner (`--note-fg`)** | `#0a5aa8` auf `--note-bg` → **6,39:1** | `#7ab8ff` auf `--note-bg` → **7,05:1** | ✅ Pass (> 4,5:1) |

*(Negativprobe: `#cccccc` auf `#ffffff` ergab 1,61:1 — das Messverfahren schlägt bei mangelhaftem Kontrast verlässlich an).*

---

## Projektarchitektur

```text
Loupe
├── Loupe.app (Host-Begleit-Anwendung)
│   ├── Contents/MacOS/Loupe (AppKit Host-Binary)
│   ├── Contents/Info.plist (Bundle-Metadaten & registrierte Formate: JSON, Markdown, CSV & Quellcode)
│   └── Contents/PlugIns/
│       └── LoupePreview.appex (Quick Look App Extension)
│           ├── Contents/MacOS/LoupePreview (QLPreviewProvider Binary)
│           └── Contents/Info.plist (QLSupportedContentTypes: JSON, Markdown, CSV/TSV & Quellcode-UTIs)
│
├── LoupeCore (Gemeinsame Swift-Bibliothek)
│   ├── JSON/
│   │   ├── JSONValue.swift (AST-Knotentypen, Member, Diagnostic, ParseOutcome)
│   │   ├── JSONLexer.swift (Byte-orientierter Token-Scanner, UTF-8-Surrogat-Decodierung)
│   │   ├── JSONParser.swift (Ordnungserhaltender Parser, Fehlerrettung)
│   │   └── SourceExcerpt.swift (Kontextfenster, Tab-Expansion, UTF-8-Zeigerausrichtung)
│   ├── Markdown/
│   │   ├── MarkdownRenderer.swift (AST-Visitor via swift-markdown)
│   │   ├── HTMLSanitizer.swift (XSS-Bereinigung, URL- & Protokoll-Sanitizer)
│   │   └── ResourceResolver.swift (Pfad-Traversal-Schutz & Base64-Bildauflösung)
│   ├── CSV/
│   │   ├── CSVParser.swift (RFC 4180-Parser, automatische Delimiter-Erkennung, CRLF-Handling)
│   │   └── CSVTableRenderer.swift (HTML-Tabellengenerator, fixierte Kopfzeilen, Zahlenausrichtung)
│   ├── Highlighting/
│   │   ├── SyntaxHighlighter.swift (Reine Swift-Tokenizer für 17+ Sprachen)
│   │   └── LanguageLexer.swift (Sprachdefinitionen, TokenType, HighlightToken)
│   ├── Preview/
│   │   ├── PreviewRenderer.swift (PreviewInput, PreviewRenderer Protokoll)
│   │   ├── JSONPreviewRenderer.swift (JSON-Vorschau-Koordinator)
│   │   ├── MarkdownPreviewRenderer.swift (Markdown-Vorschau-Koordinator)
│   │   ├── CSVPreviewRenderer.swift (CSV- & TSV-Vorschau-Koordinator)
│   │   ├── RendererRegistry.swift (Modulare Format-Auswahl über UTType)
│   │   └── HTMLDocument.swift (Zentrale CSP-Hülle für JSON, Markdown und CSV)
│   ├── Render/
│   │   ├── JSONTreeRenderer.swift (HTML-Generierung aus <details>/<summary>)
│   │   ├── ExpansionPolicy.swift (Breitensuche-Planung nach Zeilenbudget)
│   │   └── HTMLEscape.swift (Einpassige Zeichenmaskierung)
│   ├── Theme/
│   │   └── CSSGenerator.swift (WCAG AA Stylesheets für JSON, Markdown und CSV)
│   ├── Configuration/
│   │   └── LoupeSettings.swift (Erscheinungsbild, Textgröße, Budget, Breite, Defaults)
│   └── Utilities/
│       └── ExtensionStatusChecker.swift (Pluginkit-Parser und Diagnoseprüfung)
│
└── LoupeTests (Automatisiertes Test-Target)
    ├── JSONValueTests.swift
    ├── JSONLexerTests.swift
    ├── JSONParserTests.swift
    ├── SourceExcerptTests.swift
    ├── HTMLEscapeTests.swift
    ├── HTMLSanitizerTests.swift
    ├── ResourceResolverTests.swift
    ├── LanguageLexerTests.swift
    ├── SyntaxHighlighterTests.swift
    ├── MarkdownRendererTests.swift
    ├── CSVParserTests.swift
    ├── CSVTableRendererTests.swift
    ├── JSONTreeRendererTests.swift
    ├── ExpansionPolicyTests.swift
    ├── RegistryTests.swift
    ├── SettingsTests.swift
    ├── CSSGeneratorTests.swift
    ├── ExtensionStatusTests.swift
    └── PerformanceTests.swift
```

---

## Installation & Quick-Look-Aktivierung

### 1. Vorkompiliertes Release herunterladen (Empfohlen)

1. Die neueste Version `Loupe-v*.zip` aus den [GitHub Releases](https://github.com/pepperonas/loupe/releases) herunterladen.
2. Entpacken und `Loupe.app` in den Ordner `/Applications` ziehen.
3. `Loupe.app` einmalig starten, damit macOS die Erweiterung im System registriert.

### 2. Aus dem Quellcode bauen & installieren

```bash
# Repository klonen
git clone https://github.com/pepperonas/loupe.git
cd loupe

# Bauen, paketieren, signieren und nach /Applications/Loupe.app installieren
./Scripts/install_app.sh
```

### 3. In den macOS-Systemeinstellungen aktivieren

macOS verlangt eine einmalige Benutzerfreigabe für Quick-Look-Erweiterungen:

1. **Systemeinstellungen** → **Datenschutz & Sicherheit** → **Erweiterungen** öffnen.
2. Auf **Quick Look** klicken.
3. Den Schalter bei **Loupe QuickLook Preview** aktivieren.
4. Falls der Finder noch Rohtext anzeigt, den Cache neu einlesen:
   ```bash
   qlmanage -r && qlmanage -r cache && killall Finder
   ```

---

## Manuelle Prüfung im Finder

1. Im Finder zu einer beliebigen JSON- oder Markdown-Datei navigieren:
   - Eine `.json`-Datei wählen (z. B. `package.json`). **Leertaste** drücken: Der aufklappbare Baum öffnet sich sofort.
   - Eine `.md`-Datei wählen (z. B. `README.de.md`). **Leertaste** drücken: Formatierte Typografie, Codeblöcke mit Syntaxfarben und Tabellen erscheinen unmittelbar.
2. Im JSON-Baum:
   - Auf Pfeile oder Zeilen klicken, um Abschnitte auf- oder zuzuklappen.
   - Alle Typen und Schlüssel heben sich in kontrastgeprüften Farben ab.
3. Im Markdown:
   - Codeblöcke besitzen Sprachen-Header und Farb-Highlighting ohne clientseitiges JavaScript.
   - Aufgabenlisten zeigen native Checkboxen.

---

## Automatisierte Tests ausführen

Loupe verfügt über ein eigenes, abhängigkeitsfreies Testharnisch mit 153 Unit- und Performance-Tests:

```bash
swift run LoupeTests
```

Ausgabe:
```text
Starting Loupe Test Suite...

--- Suite: JSONValue ---
  ✓ testObjectPreservesMemberOrder (0.22ms)
  ✓ testObjectKeepsDuplicateKeys (0.00ms)
  ✓ testNumberKeepsSourceSpelling (0.01ms)
  ✓ testPositionIsOneBased (0.00ms)
  ✓ testOutcomeDistinguishesTruncationFromFailure (0.00ms)

--- Suite: JSONLexer ---
  ✓ testStructuralTokens (0.09ms)
  ✓ testLiterals (0.07ms)
  ✓ testNumbersKeepSourceSpelling (0.02ms)
  ✓ testLeadingZeroIsInvalid (0.01ms)
  ✓ testStringEscapes (0.02ms)
  ✓ testUnicodeEscapeAndSurrogatePair (0.06ms)
  ✓ testLoneSurrogateDoesNotCrash (0.01ms)
  ✓ testPositionsAreOneBasedAndCountLines (0.00ms)
  ✓ testUnterminatedStringReportsPosition (0.01ms)
  ✓ testByteOrderMarkIsSkipped (0.00ms)

--- Suite: JSONParser ---
  ✓ testKeyOrderIsSourceOrder (0.07ms)
  ✓ testDuplicateKeysBothSurvive (0.01ms)
  ✓ testNestedStructure (0.03ms)
  ✓ testBareScalarIsValidJSON (0.01ms)
  ✓ testEmptyContainers (0.01ms)
  ✓ testEmptyInputFails (0.01ms)
  ✓ testMissingCommaReportsPosition (0.01ms)
  ✓ testPartialTreeSurvivesFailure (0.01ms)
  ✓ testTrailingContentHintsAtJSONLines (0.05ms)
  ✓ testLexErrorPreservesPartialTree (0.01ms)
  ✓ testAncestorSiblingsSurviveNestedFailure (0.05ms)
  ✓ testTruncatedMidTokenReportsTruncationNotFailure (0.04ms)
  ✓ testLexErrorInTopLevelArrayPreservesItems (0.01ms)
  ✓ testArrayNestedInObjectPreservesBothLevels (0.02ms)
  ✓ testDepthBombDoesNotCrash (19.61ms)
  ✓ testDepthLimitIsExactlySixtyFour (0.13ms)
  ✓ testChildrenLimitTruncatesAndCounts (1.60ms)
  ✓ testChildrenLimitTruncatesAndCountsObject (3.70ms)
  ✓ testChildrenLimitAppliesOnFailurePathForArray (1.11ms)
  ✓ testChildrenLimitAppliesOnFailurePathForObject (2.38ms)
  ✓ testNodeLimitStopsBuilding (0.48ms)
  ✓ testLongStringIsTruncatedForDisplay (0.04ms)
  ✓ testLongObjectKeyIsTruncatedForDisplay (0.75ms)
  ✓ testTruncationIsNotReportedAsFailure (0.02ms)
  ✓ testMissingCommaInNestedObjectNestsPartialUnderAncestorKey (0.02ms)

--- Suite: SourceExcerpt ---
  ✓ testExcerptShowsContextAndCaret (0.21ms)
  ✓ testExcerptAtFirstLineDoesNotUnderflow (0.01ms)
  ✓ testVeryLongLineIsClipped (0.51ms)
  ✓ testTabsBecomeSpacesSoCaretAligns (0.02ms)
  ✓ testTabsPin_TwoTabsAndX (0.01ms)
  ✓ testEmojiPin_FireAndX (0.01ms)
  ✓ testUmlautPin_GrueseAndX (0.02ms)
  ✓ testASCIIPin_ABCAndX (0.01ms)
  ✓ testErrorOnLastLineWithContext (0.01ms)
  ✓ testLongContextLineWithCentre1Clipping (0.02ms)

--- Suite: HTMLEscape ---
  ✓ testEscapesAllFiveDangerousCharacters (0.04ms)
  ✓ testAmpersandEscapedFirst (0.00ms)
  ✓ testScriptInJSONStringIsNeutralised (0.01ms)
  ✓ testUnicodeAndEmojiSurviveUnchanged (0.00ms)

--- Suite: LoupeSettings ---
  ✓ testDefaults (0.00ms)
  ✓ testRoundTripThroughJSON (0.23ms)
  ✓ testAppGroupConstants (0.00ms)
  ✓ testTextSizeFontSizes (0.00ms)
  ✓ testBackwardCompatibilityFromV1 (0.01ms)

--- Suite: CSSGenerator ---
  ✓ testSystemAppearanceEmitsBothThemes (0.03ms)
  ✓ testFixedAppearanceOmitsMediaQuery (0.06ms)
  ✓ testAllRenderClassesArePresent (0.66ms)
  ✓ testTextSizeReachesTheCSS (0.03ms)
  ✓ testNoJavaScriptAnywhere (0.29ms)
  ✓ testTreeIsMonospace (0.03ms)

--- Suite: JSONTreeRenderer ---
  ✓ testContainersBecomeDetailsElements (0.13ms)
  ✓ testScalarsAreNotCollapsible (0.02ms)
  ✓ testKeyOrderSurvivesIntoHTML (0.03ms)
  ✓ testCollapsedSummaryCarriesCountAndPeek (0.05ms)
  ✓ testOpenPathsControlTheOpenAttribute (0.06ms)
  ✓ testValueTypesGetTheirClasses (0.07ms)
  ✓ testScriptTagInStringIsEscaped (0.03ms)
  ✓ testKeyWithAngleBracketsIsEscaped (0.02ms)
  ✓ testOmittedChildrenAreDeclared (5.59ms)
  ✓ testParseErrorRendersBannerWithExcerpt (0.15ms)
  ✓ testTruncationUsesNoticeNotError (0.03ms)
  ✓ testNoJavaScriptInOutput (0.11ms)

--- Suite: ExpansionPolicy ---
  ✓ testSmallDocumentOpensCompletely (0.13ms)
  ✓ testFlatArrayBeyondBudgetStaysClosed (2.08ms)
  ✓ testBreadthFirstPrefersUpperLevels (0.08ms)
  ✓ testBudgetIsRespected (0.45ms)
  ✓ testScalarRootYieldsEmptyPlan (0.00ms)
  ✓ testZeroBudgetOpensNothing (0.01ms)
  ✓ testSmallerSiblingOpensEvenIfEarlierSiblingExceedsBudget (0.03ms)
  ✓ testBreadthFirstPrefersUpperLevelsOverDeepDescent (0.04ms)

--- Suite: HTMLSanitizer ---
  ✓ testEscapeHTML (0.01ms)
  ✓ testSanitizeURLBlocksJavascript (0.05ms)
  ✓ testSanitizeURLEntityEncodedBypasses (1.19ms)
  ✓ testSanitizeURLAllowsSafeSchemes (0.12ms)
  ✓ testSanitizeURLTrimming (0.03ms)
  ✓ testSanitizeRawHTMLStripsScriptTags (1.89ms)
  ✓ testSanitizeRawHTMLStripsIframesAndObjects (0.81ms)
  ✓ testSanitizeRawHTMLStripsFormsAndButtons (0.81ms)
  ✓ testSanitizeRawHTMLStripsStylesAndMeta (0.81ms)
  ✓ testSanitizeRawHTMLStripsEventHandlers (0.82ms)
  ✓ testSanitizeRawHTMLStripsJavascriptInHrefAndSrc (0.85ms)

--- Suite: ResourceResolver ---
  ✓ testResolveDataURI (0.02ms)
  ✓ testResolveRemoteImageBlockedWhenDisallowed (0.01ms)
  ✓ testResolveRemoteImageAllowedWhenEnabled (0.04ms)
  ✓ testResolveLocalRelativeImage (8.29ms)
  ✓ testResolveAbsoluteDiskPath (0.76ms)
  ✓ testPathTraversalBlocked (0.34ms)
  ✓ testResolveNonExistentLocalImageReturnsError (0.08ms)
  ✓ testResolveImageWithNilDocumentURL (0.05ms)
  ✓ testMimeTypeDetectionComprehensive (0.24ms)

--- Suite: LanguageLexer & SupportedLanguages ---
  ✓ testLanguageFromIdentifierAliases (0.04ms)
  ✓ testLanguageDisplayNames (0.00ms)
  ✓ testUnknownLanguageHandling (0.00ms)
  ✓ testTokenStructInitialization (0.00ms)

--- Suite: SyntaxHighlighter ---
  ✓ testSwiftHighlighting (0.13ms)
  ✓ testRustHighlighting (0.06ms)
  ✓ testPythonHighlighting (0.04ms)
  ✓ testJavaScriptAndTypeScriptHighlighting (0.10ms)
  ✓ testJavaAndKotlinHighlighting (0.09ms)
  ✓ testSQLHighlighting (0.03ms)
  ✓ testBashHighlighting (0.03ms)
  ✓ testJSONHighlighting (0.02ms)
  ✓ testCSSHighlighting (0.04ms)
  ✓ testBlockComments (0.03ms)
  ✓ testEscapesRawHTMLInCode (0.02ms)
  ✓ testEmptyAndUnknownLanguageFallback (0.00ms)

--- Suite: MarkdownRenderer ---
  ✓ testBasicMarkdownRendering (3.96ms)
  ✓ testHeadingsLevels (1.22ms)
  ✓ testHeadingAnchorSlugGeneration (0.28ms)
  ✓ testInlineCodeRendering (0.25ms)
  ✓ testStrikethroughRendering (0.27ms)
  ✓ testThematicBreakRendering (0.36ms)
  ✓ testLinkWithTitleAndAttributes (1.46ms)
  ✓ testImageRenderingBlockedAndAllowed (1.08ms)
  ✓ testOrderedListCustomStartIndex (0.75ms)
  ✓ testTaskListRendering (0.67ms)
  ✓ testTableRendering (1.11ms)
  ✓ testBlockquoteRendering (0.49ms)
  ✓ testCodeBlockWithLanguage (0.78ms)
  ✓ testSyntaxHighlightingDisabledSetting (0.42ms)
  ✓ testPageTitleExtractionFromHeading (0.23ms)
  ✓ testMaliciousScriptTagSanitized (1.53ms)
  ✓ testLargeFileTruncation (1.90ms)

--- Suite: Registry & Document ---
  ✓ testJSONTypeResolvesToJSONRenderer (0.08ms)
  ✓ testMarkdownTypeResolvesToMarkdownRenderer (0.28ms)
  ✓ testUnknownTypeResolvesToNil (0.04ms)
  ✓ testDocumentCarriesTheExactCSP (0.01ms)
  ✓ testDocumentEscapesTheTitle (0.01ms)
  ✓ testEndToEndRenderOfRealFile (0.45ms)
  ✓ testInvalidUTF8DoesNotCrash (0.07ms)
  ✓ testEmptyFileRendersBannerNotBlankPage (0.09ms)
  ✓ testTruncatedInputRendersTruncationNotice (0.18ms)

--- Suite: ExtensionStatus ---
  ✓ testTitles (0.00ms)
  ✓ testIsOperational (0.00ms)
  ✓ testBundleIdConstant (0.00ms)
  ✓ testParsesPluginkitOutput (0.01ms)

--- Suite: Performance ---
  ✓ testSmallDocumentUnder50ms (20.66ms)
  ✓ testFiveMegabytesUnderOneSecond (670.93ms)
Total Test Suite Time: 775.55 ms

==================================================
TEST RESULT: SUCCESS
All 153 unit tests passed successfully!
==================================================
```

---

## Sicherheitsarchitektur

Entwicklerdateien stammen häufig aus ungesicherten Quellen (`git clone`, Downloads, Build-Artefakte). Loupe setzt kompromisslose Schutzmechanismen durch:

- **Strikte Sandbox-Isolation**: Die Erweiterung läuft in Apples App Extension Sandbox (`com.apple.security.app-sandbox`) mit reinem Lesezugriff (`com.apple.security.files.user-selected.read-only`).
- **Null Byte JavaScript**: WebKit-Skriptausführung ist vollständig deaktiviert. Weder `<script>`-Tags, noch DOM-Scripting oder clientseitige JavaScript-Engines werden ausgeführt.
- **Strikte Content Security Policy (CSP)**:
  - Für JSON: `default-src 'none'; style-src 'unsafe-inline'; img-src 'none'`
  - Für Markdown: `default-src 'none'; style-src 'unsafe-inline'; img-src data: cid:;`
  Keine Richtlinie erlaubt `script-src` unter irgendeiner Bedingung.
- **HTML- & URL-Bereinigung**: Eingebettetes HTML in Markdown wird von gefährlichen Tags (`<script>`, `<iframe>`, `<object>`, `<embed>`, `<form>`, `<button>`, `<style>`, `<meta>`, `<link>`) und Ereignis-Attributen (`onclick`, `onerror`, `onload`) befreit. Gefährliche Protokolle (`javascript:`, `vbscript:`, `data:text/html`) werden zu sicheren Ankern (`#`).
- **Pfad-Traversal-Schutz**: Relative Bildpfade werden über `resolvingSymlinksInPath()` kanonisiert und darauf geprüft, dass sie innerhalb des Dokumentenordners liegen. Fluchtversuche (`../../../../etc/passwd`) werden blockiert.
- **Schutz vor Tracking-Pixeln**: Externe Web-Bilder (`http://`, `https://`) sind standardmäßig blockiert, um unerwünschtes IP- und Lese-Tracking zu unterbinden.
- **Gehärtete Obergrenzen & DoS-Schutz**:
  - Rekursionstiefe bei max. 64 Ebenen zum Schutz vor Stapelüberläufen.
  - Speichersicherheits-Knotengrenze bei 20.000 Knoten.
  - Container-Kinder-Grenze bei 1.000 Elementen.
  - String-Längenbegrenzung bei 4.096 Zeichen.
  - Dateigrößen-Grenzen bei 20 MB (JSON) und 5 MB (Markdown) mit informativen Kürzungs-Bannern.

---

## Unterstützung & Spenden

Wenn dir Loupe gefällt oder es dir im Alltag wertvolle Zeit spart, kannst du die unabhängige Open-Source-Entwicklung unterstützen:

<div align="center">
  <a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
    <img src="https://img.shields.io/badge/Spenden-PayPal-00457C?logo=paypal&logoColor=white&style=for-the-badge" alt="Spende via PayPal" />
  </a>
  <br>
  <strong>PayPal:</strong> <a href="mailto:martin.pfeffer@celox.io">martin.pfeffer@celox.io</a>
</div>

---

## Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert — siehe die Datei [LICENSE](LICENSE) für Details.

Entwickelt mit ❤️ von **Martin Pfeffer** ([celox.io](https://celox.io)) © 2026.
