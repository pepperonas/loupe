# Changelog

Alle nennenswerten Änderungen an **Loupe** stehen in dieser Datei.

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [0.3.2] - 2026-09-23

### Behoben
- Finder-/Quick-Look-Vorschauen für Quellcodedateien und weitere registrierte Formate wiederhergestellt.
- Quick-Look-Erweiterung korrekt mit ihrem Swift-Modulnamen registriert.
- Syntaxhervorhebung für größere Quelldateien beschleunigt, damit Vorschauen nicht beim Laden hängen bleiben.
- Veraltete doppelte Quick-Look-Registrierungen bei der Installation entfernt.

## [0.3.0] - 2026-09-22

### Hinzugefügt
- Nativer CSV- und TSV-Vorschau-Renderer (`public.comma-separated-values-text`, `public.tab-separated-values-text`, `public.delimited-values-text`, `.csv`, `.tsv`):
  - Vollständige Dark- und Light-Mode-Unterstützung: Behebt das bekannte Problem von macOS Quick Look, CSV-Dateien im dunklen System-Erscheinungsbild mit grell-weißer Blendung anzuzeigen.
  - Fixierte Tabellenkopfzeile (`<thead>`), die beim Scrollen durch große Tabellen stets sichtbar bleibt.
  - Fixierte Index-Spalte `#` mit Zeilennummern.
  - Automatische Erkennung des Trennzeichens (Komma `,`, Semikolon `;` für europäische/deutsche CSV-Dateien, Tabulator `\t` für TSV).
  - Automatische Zahlenerkennung mit rechtsbündiger Ausrichtung und `tabular-nums`.
  - RFC 4180-Konformität: Unterstützung für Anführungszeichen, maskierte Anführungszeichen (`""`) und mehrzeilige Textzellen.
  - Zusammenfassungsleiste mit Zeilenanzahl, Spaltenanzahl und Trennzeichen-Badge.
  - Sichere Obergrenzen (maximal 2.000 Zeilen, 200 Spalten) mit Informationsbanner bei gekürzten Dateien.
  - 100% JavaScript-frei mit strikter Content Security Policy.
- 30 neue Unit-Tests für CSV-Parsing, Tabellen-Rendering, Themes und Registry-Auflösung (Gesamt: 183 Tests).

## [0.2.0] - 2026-09-22

### Hinzugefügt
- Vollständige Markdown-Unterstützung (`net.daringfireball.markdown`, `.md`, `.markdown`):
  - CommonMark- und GitHub Flavored Markdown (GFM)-Rendering
  - Überschriften (H1–H6) mit automatisch generierten Anker-Slugs
  - Tabellen mit abwechselnden Zeilenfarben und Ausrichtung
  - Aufgabenlisten mit nativen Checkboxen
  - Blockzitate im Apple-Callout-Stil
- Syntaxhervorhebung in reinem Swift für 17+ Programmiersprachen (Swift, Rust, Python, JavaScript, TypeScript, Go, Java, Kotlin, C, C++, HTML, XML, CSS, JSON, YAML, SQL, Shell/Bash, Markdown)
- Sicheres relatives Laden lokaler Bilder via Base64 mit Pfad-Traversal-Schutz
- Schutz vor Tracking-Pixeln durch Blockieren entfernter Bilder als Standard
- Strikte Content Security Policy für Markdown (`img-src data: cid:`, null JavaScript)
- Einstellungen für konfigurierbare Markdown-Inhaltsbreite in der Begleit-App
- 55 neue Unit-Tests für Markdown, Syntaxhervorhebung, Bildauflösung und HTML-Sanitizing (Gesamt: 153 Tests)

## [0.1.0] - 2026-09-22

### Hinzugefügt
- Quick-Look-Erweiterung `io.celox.loupe.preview` für `public.json`
- Aufklappbarer JSON-Baum aus verschachtelten `<details>` — **ohne JavaScript**
- Ordnungserhaltender Parser: Schlüsselreihenfolge, doppelte Schlüssel und
  Zahlen-Schreibweise bleiben wie in der Datei
- Fehlerbanner mit Zeile, Spalte und Quelltext-Ausschnitt; der bis dahin
  gelesene Teilbaum bleibt sichtbar
- Grenzen gegen große und bösartige Dateien, darunter eine Tiefenbremse
  gegen den Stapelüberlauf durch tief verschachtelte Arrays
- Voreingestellte Klappstellung nach Zeilenbudget statt fester Tiefe
- Begleit-App mit Erweiterungs-Status und Einstellungen
