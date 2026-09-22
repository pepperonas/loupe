# Loupe — Quick-Look-Vorschau mit zuklappbaren Bäumen (Design)

**Stand:** 2026-09-22 · **Status:** freigegeben, noch nicht umgesetzt
**Repo:** `pepperonas/loupe` (öffentlich, MIT) · **Bundles:** `io.celox.loupe`, `io.celox.loupe.preview`
**Plattform:** macOS 14+ · Swift 6 · SwiftPM · **keine Abhängigkeiten**
_(Plattform und Lizenz übernommen von MarkLook; bewusst festgelegt statt offengelassen, jederzeit änderbar.)_

---

## 1. Zweck

Loupe ist eine native macOS-Quick-Look-Erweiterung, die Entwicklerdateien im
Finder-Vorschaufenster **strukturiert und aufklappbar** darstellt statt als
Fließtext. Version 1 liefert **ausschließlich JSON** aus; die Naht für weitere
Formate wird jetzt gebaut, aber nicht befüllt.

Loupe ist der **Nachfolger von MarkLook**, nicht dessen Geschwister: der
bestehende Markdown-Renderer zieht später als zweiter Renderer ein, danach geht
MarkLook in Ruhestand. Bis dahin laufen beide unabhängig nebeneinander.

## 2. Bewiesene Kernannahme

Die tragende Frage — *kommen Mausklicks im Finder-Vorschaufenster an?* — wurde
am 2026-09-22 **praktisch beantwortet: ja**. Verschachtelte `<details>`/`<summary>`
klappen im Space-Preview auf und zu.

Damit braucht das Feature **kein JavaScript**. Das ist kein Kompromiss, sondern
der Grund, warum es überhaupt trägt: die Zero-JavaScript-Doktrin bleibt nicht
trotz des Features erhalten, sie *ermöglicht* es.

Die Probe wurde gegengeprüft, bevor sie lief: ein Testrender belegte, dass vier
`<details>`- und vier `<summary>`-Tags samt `open`-Attribut den Renderer
überleben. Ein ausbleibender Klick-Effekt wäre also nachweislich am
Durchreichen gelegen, nicht an weggeputzten Tags.

## 3. Entscheidungen und ihre Begründung

| # | Entscheidung | Begründung |
|---|---|---|
| E1 | **Eigenes Repo, kopieren statt koppeln** | Ein gemeinsames Paket zwischen einem Vorgänger und seinem Nachfolger ist verschwendete Arbeit. Kein Umbau an laufender, ausgelieferter Software. |
| E2 | **Dach-Werkzeug, nicht JSON-App** | Weitere Formate sind geplant, MarkLook zieht später ein. Der Name ist deshalb formatneutral. |
| E3 | **v1 nur JSON** | Ein zweiter Renderer, der nur die Abstraktion rechtfertigt, ist Ballast. Die Naht beweist sich, wenn Markdown einzieht. |
| E4 | **Eigener Parser statt `JSONSerialization`** | Siehe §5 — drei unabhängige Gründe, jeder für sich hinreichend. |
| E5 | **Keine Abhängigkeiten** | Foundation genügt. MarkLook braucht `swift-markdown`; Loupe braucht nichts. |
| E6 | **Begleit-App minimal** | Eine Host-App ist technisch zwingend (eine `.appex` kann nicht allein existieren), ein Live-Editor ist es nicht: Markdown schreibt man, JSON schaut man an. |

**Überschriebene Zwischenstände** (zur Nachvollziehbarkeit): In der Sitzung war
zunächst „zwei bewusst getrennte Werkzeuge" entschieden und der Name `JsonLook`
im Gespräch. Beides wurde hinfällig, als klar wurde, dass MarkLook später
einziehen soll. Mit dieser Wende dreht sich auch ein Argument um: geteiltes CSS
war für *zwei Apps* falsch und ist für *eine* richtig — der `CSSGenerator` ist
damit Fundament, nicht kopierter Baustein.

## 4. Architektur

```text
Sources/
├── LoupeCore/
│   ├── JSON/
│   │   ├── JSONLexer.swift        Bytes → Tokens (mit Zeile/Spalte)
│   │   ├── JSONParser.swift       Tokens → Baum, ordnungserhaltend, mit Budget
│   │   └── JSONValue.swift        das Modell
│   ├── Render/
│   │   ├── JSONTreeRenderer.swift Baum → verschachtelte <details>
│   │   └── HTMLEscape.swift       escapeHTML, aus MarkLook übernommen
│   ├── Preview/
│   │   └── PreviewRenderer.swift  das Format-Protokoll + Registry
│   ├── Theme/CSSGenerator.swift
│   └── Configuration/LoupeSettings.swift
├── LoupePreview/                  die .appex (QLPreviewProvider)
└── Loupe/                         Begleit-App (Status, Einstellungen, Anleitung)
Tests/LoupeTests/                  eigenes Harness, via `swift run LoupeTests`
```

**Die tragende Naht:**

```swift
public protocol PreviewRenderer {
    static var supportedTypes: [UTType] { get }
    func renderHTML(data: Data, url: URL, settings: LoupeSettings) -> String
}
```

Die `.appex` listet alle unterstützten UTTypes in ihrer `Info.plist`, sucht beim
Aufruf den passenden Renderer und ruft ihn. Markdown wird später ein weiterer
Eintrag; der bestehende `MarkdownRenderer` passt nahezu unverändert hinein.

**Datenfluss:**

```text
Datei → begrenztes Byte-Lesen → Lexer → Parser (Budget) → JSONValue-Baum
     → JSONTreeRenderer → HTML + eingebettetes CSS → QLPreviewReply
```

## 5. Das Modell und warum nicht `JSONSerialization`

```swift
public indirect enum JSONValue: Sendable {
    case null
    case bool(Bool)
    case number(String)                               // ROH als Zeichenkette
    case string(String)
    case array([JSONValue], omitted: Int)
    case object([(key: String, value: JSONValue)], omitted: Int)   // Reihenfolge!
}
```

Drei Eigenschaften dieses Modells sind keine Geschmacksfragen, sondern
Bedingungen dafür, dass der Betrachter **nicht über das Dokument lügt**:

1. **Objekt als Paar-Liste, nicht als `Dictionary`.** Ein Dictionary ist
   ungeordnet — die Schlüssel stünden in anderer Reihenfolge als in der Datei.
   Nebeneffekt: **doppelte Schlüssel** (laut JSON-Spezifikation erlaubt, Verhalten
   undefiniert) bleiben beide erhalten und sichtbar, statt still verworfen zu
   werden.
2. **Zahl als Zeichenkette.** `Double` macht aus `1.0` eine `1`, verliert bei
   großen Ganzzahlen Stellen und kippt bei `1e400` ins Unendliche. Angezeigt
   wird, was in der Datei steht.
3. **`omitted` am Container.** Wo eine Grenze greift, weiß der Baum das und kann
   es ausweisen (§7).

Dazu kommen zwei Gründe, die `JSONSerialization` ohnehin ausschließen:
**Fehlertoleranz** (dort gibt es nur „ungültig", siehe §8) und **Abbruchbarkeit**
(kein Budget, kein Zwischenstand).

**Parse-Ergebnis:**

```swift
public struct ParseResult: Sendable {
    public let root: JSONValue?
    public let outcome: Outcome
    public let diagnostics: [Diagnostic]   // Meldung + Zeile/Spalte
}

public enum Outcome: Sendable {
    case complete
    case truncatedByLimit(LimitKind)   // WIR haben gekürzt
    case failed(at: Position)          // die DATEI ist kaputt
}
```

Die Trennung von `truncatedByLimit` und `failed` ist tragend — siehe §8.

**Leistung:** Der Lexer arbeitet byte-orientiert auf `[UInt8]`. Gemessen in Task 13: 5 MB synthetisches JSON werden in ~165 ms (Release-Modus) vollständig verarbeitet und gerendert. Ein Wechsel auf `UnsafeBufferPointer<UInt8>` ist daher nicht erforderlich; `[UInt8]` bietet vollständige Speichersicherheit bei weit unterbotenem Quick-Look-Zeitbudget (< 1.000 ms).

## 6. Darstellung und Interaktion

```text
▾ { }  6 Schlüssel
    "name"     : "loupe"
    "version"  : "0.1.0"
    "private"  : true
  ▸ "scripts"  : { }  4 Schlüssel   · build, test, lint, …
  ▾ "keywords" : [ ]  3 Einträge
      0 : "quicklook"
      1 : "json"
```

**Die zugeklappte Zeile trägt die Last.** Ein bloßes `▸ "scripts"` wäre wertlos —
man müsste jeden Knoten öffnen, um zu wissen, ob er interessant ist. Jede
zugeklappte Zeile zeigt daher Typ, Anzahl und einen kurzen Blick auf den Inhalt.
Das ist der Unterschied zwischen einem Baum, den man durchsucht, und einem, den
man blind auf- und zuklappt.

**Voreingestellte Klappstellung: nach Zeilenbudget, nicht nach Tiefe.**
Breitensuche klappt auf, bis ~300 sichtbare Zeilen verbraucht sind. Eine
`package.json` liegt damit vollständig offen, ein 8-MB-Export zeigt die oberen
Ebenen. Feste Tiefe wäre einfacher und versagte genau dort, wo es zählt: ein
flaches Array mit 2.000 Einträgen ist „Ebene 1" und stünde komplett offen.

**Farbrollen** für Schlüssel, String, Zahl, Boolean und `null`, je eigen in Hell
und Dunkel. Kontraste wurden **im Browser auf HTML-Canvas gemessen** (`Scripts/measure_contrast.html`):

| Farbrolle | Hell (`#ffffff`) | Dunkel (`#1e1e1e`) | Status |
|---|---|---|---|
| Text (`--text`) | `#1d1d1f` → 16,83:1 | `#f5f5f7` → 15,31:1 | ✓ Pass |
| Gedimmt (`--text-dim`) | `#5b5e69` → 6,46:1 | `#a1a1a6` → 6,48:1 | ✓ Pass |
| Schlüssel (`--key`) | `#0b5fb0` → 6,41:1 | `#7ab8ff` → 8,04:1 | ✓ Pass |
| String (`--str`) | `#b3261e` → 6,54:1 | `#ff8170` → 6,85:1 | ✓ Pass |
| Zahl (`--num`) | `#1c00cf` → 10,77:1 | `#dabaff` → 9,88:1 | ✓ Pass |
| Boolean (`--bool`) | `#7a3ea3` → 6,90:1 | `#d8a0ff` → 8,25:1 | ✓ Pass |
| Null (`--null`) | `#5b5e69` → 6,46:1 | `#a1a1a6` → 6,48:1 | ✓ Pass |
| Zähler/Peek (`--count`) | `#5b5e69` → 6,46:1 | `#a1a1a6` → 6,48:1 | ✓ Pass |
| Fehler-Vordergrund (`--err-fg`) | `#a5251c` → 6,72:1 (auf `--err-bg`) | `#ff8a80` → 6,64:1 (auf `--err-bg`) | ✓ Pass |
| Hinweis-Vordergrund (`--note-fg`) | `#0a5aa8` → 6,39:1 (auf `--note-bg`) | `#7ab8ff` → 7,05:1 (auf `--note-bg`) | ✓ Pass |
| Hover / Excerpt Hintergrund | `#1d1d1f` auf `#f6f8fa` → 15,81:1 | `#f5f5f7` auf `#28282b` → 13,50:1 | ✓ Pass |

*Gegenprobe:* `#cccccc` auf `#ffffff` ergab 1,61:1 (erwarteter Fehlschlag gegen Grenze 4,5:1).

**Geschenkt:** `<summary>` ist nativ tastaturbedienbar (Tab, Enter, Leertaste)
und wird von VoiceOver als aufklappbares Element angesagt — ohne Zusatzarbeit.

## 7. Grenzen

`<details>` **versteckt** Inhalt, es **spart** ihn nicht: ein zugeklappter Knoten
steht vollständig im HTML. Ohne JavaScript gibt es kein Nachladen. Über die
Größe entscheidet daher nicht die Klappstellung, sondern was überhaupt gerendert
wird — das Budget greift **am Baum**, nicht an der Darstellung.

| Grenze | Wert | Wogegen |
|---|---|---|
| Gelesene Bytes | 20 MB | Speicher |
| Knoten gesamt | 20.000 | HTML-Größe, WebKit-Trägheit |
| Kinder je Container | 1.000 | Array mit 500.000 Einträgen |
| Länge eines String-Werts | 4 KB (Anzeige) | ein einzelner 10-MB-String |
| **Verschachtelungstiefe** | **64** | **Stapelüberlauf** |

Die letzte Zeile ist kein Komfort, sondern eine Lücke: ein rekursiver Parser
stirbt an `[[[[[…`, und 100.000 Ebenen sind eine **100-KB-Datei**, die die
Erweiterung zum Absturz brächte. Die Tiefenbremse gehört in den **Parser**, nicht
in den Renderer.

Jede greifende Grenze wird im Dokument **ausgewiesen** —
`… 4.312 weitere Einträge nicht dargestellt` — statt still abzuschneiden. Ein
Betrachter, der heimlich Daten unterschlägt, ist schlimmer als einer, der aufgibt.

## 8. Fehlerbehandlung

Bei kaputtem JSON zeigt Loupe **was bis dahin gelesen wurde**, darüber ein Banner
mit Position und Ausschnitt:

```text
⚠  Zeile 47, Spalte 12: Komma erwartet, ',' oder '}' fehlt

    46 │     "version": "1.0.0"
    47 │     "private": true
       │     ^
```

Das ist der eigentliche Mehrwert gegenüber der System-Textvorschau: die meisten
Betrachter sagen „ungültig" und zeigen nichts — ausgerechnet dann, wenn man am
dringendsten hinschauen will.

**Gezielte Hinweise, wo sie tragen:** bricht es unmittelbar nach einem
vollständigen Wert ab, lautet die Meldung nicht „unerwartetes Zeichen", sondern
*„Inhalt nach dem Ende des Dokuments — möglicherweise JSON Lines?"*.

**Die Falle, die man sich sonst selbst baut:** Wir lesen höchstens 20 MB. Eine
**gültige** 50-MB-Datei ist damit zwangsläufig mitten in einer Struktur
abgeschnitten — und ein naiver Parser meldete sie als **kaputt**. Das wäre eine
Lüge über die Datei des Nutzers. Der Parser muss wissen, dass *wir* gekürzt
haben, und das Ergebnis als `truncatedByLimit` statt `failed` kennzeichnen.

Weitere Fälle: leere Datei, reiner Skalar (`42` ist gültiges JSON), BOM am
Dateianfang, ungültiges UTF-8.

## 9. Sicherheit

Loupes Angriffsfläche ist **kleiner** als die von MarkLook — das wird ausgenutzt,
nicht bloß kopiert:

| MarkLook braucht | Loupe | Warum |
|---|---|---|
| HTML-Sanitizer (135 Z.) | nur `escapeHTML` | JSON enthält kein eingebettetes HTML |
| Pfad-Traversal-Guard | entfällt | keine Bildauflösung, kein Zugriff außer auf die Datei selbst |
| `img-src data: cid:` | `img-src 'none'` | es gibt keine Bilder |

CSP: `default-src 'none'; style-src 'unsafe-inline'; img-src 'none'`.
Sandbox-Entitlements unverändert von MarkLook übernommen
(`com.apple.security.app-sandbox`, `files.user-selected.read-only`).
Ein JSON-String darf `<script>` enthalten — escaped ist er Text.

⚠ **Notiz für beide Repos:** `escapeHTML` liegt nach E1 in zwei Kopien vor. Eine
Korrektur dort erreicht die jeweils andere App nicht von selbst. Bei 15 Zeilen
mit vollständiger Testabdeckung ist das tragbar, muss aber in beiden Repos
vermerkt sein.

## 10. Tests

Eigenes Harness als Executable (Muster von MarkLook), damit
`swift run LoupeTests` in der CI ohne XCTest läuft.

1. **Lexer** — Escapes, `\uXXXX` inklusive Surrogatpaare, Zahlenformate
   (führende Null ist ungültig), Positionsangaben stimmen
2. **Parser** — **Schlüsselreihenfolge bleibt erhalten** (fällt dieser Test, lügt
   das Produkt), doppelte Schlüssel überleben beide, jede Grenze aus §7 zündet,
   Fehlerposition stimmt, **die Tiefenbombe stürzt nicht ab**, `truncatedByLimit`
   und `failed` werden nicht verwechselt
3. **Renderer** — Escaping, Budget-Marker sind sichtbar, Struktur, Zeilenbudget
4. **Fixtures** — echte `package.json`, Tiefenbombe, Riesen-Array, kaputte Datei,
   Unicode, leere Datei, nackter Skalar

Jeder neue Pin wird **einmal mutiert und rot gesehen**. Was man nicht hat
scheitern sehen, ist keine Zusicherung — und eine Mutation muss zuerst per
Prüfsumme belegen, dass sie überhaupt gegriffen hat.

## 11. Risiken

**R1 — Vorrang gegenüber der System-Textvorschau.** macOS zeigt `.json` heute
über die eingebaute Textvorschau. Ob eine eigene `.appex` für `public.json`
diesen Vorrang übernimmt, ist **nicht belegt** — bei Markdown funktioniert es,
`public.json` ist aber ein Systemtyp mit vorhandenem Anbieter. **Das ist als
Allererstes zu prüfen**, sobald ein leeres Skelett baut: eine `.appex`, die
schlicht „hallo" ausgibt, beantwortet die Frage in Minuten. Fällt sie negativ
aus, ändert das den Zuschnitt grundlegend.

**Ergebnis 2026-09-22: bestätigt.** Manuell in Finder verifiziert (Leertaste
auf `~/Desktop/loupe-r1.json`) — die Loupe-Vorschau erscheint, nicht die
System-Textvorschau.

**R2 — Quick-Look-Zeitbudget.** Eine zu langsame Vorschau wird abgebrochen. Das
Byte-orientierte Lexen (§5) adressiert es; nachzumessen ist es an einer realen
20-MB-Datei.

**Ergebnis 2026-09-22: erfüllt.** Gemessen mit `PerformanceTests` (`swift run -c release LoupeTests`):
- 50 KB JSON: **8,3 ms** (Grenze: 50 ms)
- 5 MB synthetisches JSON: **164,7 ms** (Grenze: 1.000 ms, mehr als 6x schneller als gefordert)
- Gesamtlaufzeit der Suite (98 Tests): **192,2 ms**

## 12. Bewusst nicht in v1

Live-Editor in der Begleit-App · weitere Formate (YAML, TOML, CSV) · Markdown-Umzug ·
Suche im Baum · JSON-Pointer kopieren · Zeilennummern · JSON Lines als eigener Typ ·
Vergleich zweier Dateien. Alles davon braucht JavaScript, eine zweite Naht oder
beides — und nichts davon ist nötig, um die Kernfrage „was steht in dieser Datei"
zu beantworten.
