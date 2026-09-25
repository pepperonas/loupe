# Changelog

Alle nennenswerten Änderungen an **Loupe** stehen in dieser Datei.

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [0.5.1] - 2026-09-26

### Behoben
- **Abgeschaltet zeigte Quick Look nur eine Datei-Karte mit Bild statt des Rohtexts.** Eine Absage der
  Erweiterung lässt Quick Look nicht auf den Text-Generator von macOS zurückfallen. Loupe reicht den
  Inhalt jetzt als reinen Text durch, Quick Look stellt ihn selbst dar – nebeneinander verglichen mit
  abgemeldetem Loupe identisch bei JSON, Markdown, TSV, Logs, XML und PowerShell. Kodierungen wie bei
  macOS: UTF-8 (BOM wird unabhängig von der macOS-Version entfernt), UTF-16 mit BOM, sonst Latin-1; ein am Leseende halb abgeschnittenes
  UTF-8-Zeichen wird verworfen, ohne Latin-1-Text zu kürzen.

## [0.5.0] - 2026-09-26

### Hinzugefügt
- **Vorschauen ein- und ausschalten** in der Begleit-App: ein globaler Schalter „Loupe-Vorschauen aktiv“
  und je ein Schalter für die Rubriken Markdown, JSON, Tabellen (TSV), Log-Dateien und Code (alle
  Programmiersprachen, Skripte, XML). Abgeschaltet liefert Loupe keine Vorschau, Quick Look zeigt wieder
  seine Standard-Ansicht. Die Wahl je Rubrik bleibt erhalten, solange global aus ist; eine Rubrik, die
  eine spätere Version neu einführt, ist automatisch an (gespeichert wird, was AUS ist).

### Behoben
- **Einstellungen kamen nie in der Erweiterung an.** Erscheinungsbild, Textgröße und Markdown-Breite
  wurden in eine App-Group-Suite geschrieben, ohne dass App oder Erweiterung das App-Group-Entitlement
  trugen – die Suite landete im Sandbox-Container der App, die Erweiterung sah immer die Standardwerte.
  Beide teilen sich jetzt die Präferenz-Domain `io.celox.loupe.shared` über die Sandbox-Ausnahme
  `shared-preference` (App: lesen und schreiben, Erweiterung: nur lesen; funktioniert auch ohne
  Team-ID). Bestehende Einstellungen übernimmt die App beim ersten Start.
- Der Erweiterungsstatus in der App lautete immer „Nicht registriert“: aus der Sandbox verweigert
  `pluginkit` die Abfrage (`unauthorized discovery flag`). Die App sagt jetzt ehrlich, dass sie den
  Status nicht prüfen kann, statt einen Fehler zu behaupten.
- Die Trennlinien der App zeigten die Beschriftung „Title“; die Einrichtungshinweise nennen den Pfad
  für macOS 15 und neuer.

## [0.4.0] - 2026-09-24

### Hinzugefügt
- **XML-Hervorhebung neu geschrieben** (auch für HTML-Codeblöcke): eigene Farben für Elementname,
  Attribut, Wert und Klammern, `<?xml … ?>`, `<!DOCTYPE …>` samt internem DTD-Teil, CDATA und Entities
  (`&amp;`, `&#169;`, `&#x1F600;`). Tags werden quote-bewusst gelesen – ein `>` in einem Attributwert,
  Kommentar, CDATA-Block oder DOCTYPE beendet nichts mehr. HTML: Inhalt von `<script>`/`<style>` ist Rohtext,
  unquotierte Attributwerte werden erkannt.
- XML-Dialekte erreichen Quick Look: `.xsd`, `.xsl`, `.xslt`, `.xaml`, `.csproj`, `.vbproj`, `.fsproj`,
  `.vcxproj`, `.props`, `.targets`, `.resx`, `.wsdl`, `.nuspec` über den neuen Typ
  `io.celox.loupe.xml-document` (abgeleitet von `public.xml`). `.storyboard`, `.xib` und `.entitlements`
  bleiben bewusst Xcode überlassen.
- Vorschau für **PowerShell** (`.ps1`, `.psm1`, `.psd1`) und **Windows-Batch** (`.bat`, `.cmd`) mit eigenen
  Tokenizern: PowerShell-Variablen samt Bereichen (`$env:PATH`), Cmdlets, Parameter, Wort-Operatoren
  (`-eq`), Typ-Literale, Einsetzung von `$var`/`$(…)` in Strings, Here-Strings, `<# #>`-Blöcke;
  Batch-Kommentare (`REM`, `::`), Sprungmarken, alle Variablenformen (`%VAR%`, `%~dp0`, `%%i`, `!VAR!`,
  `%DATE:~0,4%`), Schalter. Da macOS für diese Endungen nur dynamische Typen vergibt, deklariert Loupe
  `com.microsoft.powershell-script` und `com.microsoft.batch-file` – sonst würde Quick Look die Dateien
  nie an die Erweiterung geben.
- `.toml` und `.ini` erreichen die Quellcode-Vorschau jetzt auch aus dem Finder (`public.toml`,
  `com.microsoft.ini` in `QLSupportedContentTypes`) – vorher wurde TOML beworben, kam aber nie an.
- Log-Vorschau für `.log`-Dateien (`com.apple.log`, `public.log`): Tabelle mit Zeit, Level-Badge,
  Quelle und Nachricht; Level vereinheitlicht (WARN/warning/W/pino 40 → WARN), Fehler- und
  Fatal-Zeilen getönt, Level-Zählung in der Werkzeugleiste.
  - Erkannte Formate: generische Anwendungs-Logs (inkl. Laravel/Monolog und Python logging),
    nginx/Apache-Access-Logs (Status nach Klasse eingefärbt), JSON Lines (inkl. pino-Zahlenlevel
    und Unix-Zeiten), logfmt, syslog/journalctl (auch mit ISO-Zeit, z. B. macOS `install.log`),
    macOS `log show` und Android logcat.
  - Stacktraces und andere Folgezeilen bleiben am Eintrag.
  - Hervorhebung von URLs (jedes Schema), IPs, Zahlen mit Einheit, UUIDs, Pfaden und `key=value`.
  - Große Logs werden vom **Ende** gelesen (letzte 4 MB, neueste 5.000 Zeilen); die Zeilennummern
    bleiben absolut, weil die übersprungenen Umbrüche gezählt werden (bis 512 MB).
- Lesestrategie je Renderer (`PreviewReadStrategy`: Anfang oder Ende) und `PreviewFileReader`.
- 109 neue Unit-Tests gegenüber 0.3.2 (Gesamt: 306), darunter eine WCAG-AA-Prüfung aller Log-Farben in
  beiden Erscheinungsbildern, eine Leistungsprobe mit 4 MB und die Doku-Abgleichstests.

### Behoben
- Quellcode-Vorschauen zeigten am Ende eine leere Phantomzeile (und „n+1 Zeilen“), sobald die Datei mit
  einem Zeilenumbruch endet – also bei praktisch jeder Datei.
- XML-Vorschau: ein `>` in einem Attributwert beendete die Tag-Färbung mitten im Wert; `a < b` in CDATA
  wurde als Tag eingefärbt.
- Quellcode-Vorschau hing in einer Endlosschleife, sobald ein `$` außerhalb eines Strings
  vorkam – also bei jeder Swift-Datei mit `$0`/`$1` und jedem JavaScript mit jQuery-`$`.
  `$` war als Anfang eines Bezeichners erlaubt, wurde von der Bezeichner-Schleife aber nicht
  verbraucht. Neuer Test prüft jedes druckbare ASCII-Zeichen in jeder Sprache auf Abbruch
  und verlustfreie Ausgabe.

### Dokumentation
- README (EN/DE) komplett überarbeitet: Inhaltsverzeichnis, 45 Badges, Galerie je Format, Tabelle der
  unterstützten Dateitypen **mit tatsächlicher Finder-Erreichbarkeit**, Installation inkl. Gatekeeper-Hinweis
  (ad hoc signiert, nur Apple Silicon), gemessene Leistungswerte, Architekturdiagramm, Fehlersuche.
- Neue Mockups statt Screenshots: Loupes echte Renderer-Ausgabe in einem Quick-Look-Fenster, hell und
  dunkel; die README zeigt passend zum GitHub-Theme. Reproduzierbar mit `Tools/ScreenshotGenerator/generate.sh`.
- `DocsSyncTests` prüft die README gegen den Code (Versionen, Test-Badge, Bildpfade, Gleichstand EN/DE,
  welche Endungen Quick Look wirklich erreicht); `Scripts/update_readme_stats.sh` aktualisiert die Badges.
- Falsches Versprechen zu CSV korrigiert: Die Finder-Vorschau von `.csv`-Dateien
  (`public.comma-separated-values-text`) liefert macOS über seinen eigenen
  `Office.qlgenerator`, der Vorrang vor allen Quick-Look-Erweiterungen hat und sich
  weder per `Info.plist` noch per eigener Typdeklaration übergehen lässt. Loupes
  Tabellen-Renderer greift deshalb nur für `.tsv` und andere
  `public.delimited-values-text`-Dateien. README (EN/DE) um den Abschnitt
  „CSV limitation" / „Einschränkung bei CSV" ergänzt.

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
