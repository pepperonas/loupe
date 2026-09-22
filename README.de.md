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

[![Release](https://img.shields.io/badge/Release-v0.1.0-007AFF?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe/releases)
[![Build](https://img.shields.io/badge/Build-Bestanden-brightgreen?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/Tests-98%20Unit--Tests%20bestanden-brightgreen?logo=apple&logoColor=white)](Tests/LoupeTests/)
[![Zeilen Code](https://img.shields.io/badge/LoC-2.888%20Zeilen%20Swift-blue?logo=swift&logoColor=white)](Sources/)
[![Lizenz: MIT](https://img.shields.io/badge/Lizenz-MIT-yellow.svg)](LICENSE)
<br>
[![Plattform](https://img.shields.io/badge/Plattform-macOS%2014%2B-000000?logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Sandboxed](https://img.shields.io/badge/Sandbox-App%20Sandbox%20%2B%20Read--Only-success?logo=apple&logoColor=white)](Sources/LoupePreview/Resources/LoupePreview.entitlements)
[![Zero JS](https://img.shields.io/badge/JavaScript-0%20Bytes%20%E2%9C%93-success)](https://github.com/pepperonas/loupe)
[![Offline](https://img.shields.io/badge/Funktioniert-100%25%20Offline-blue?logo=apple&logoColor=white)](https://github.com/pepperonas/loupe)
[![Keine Telemetrie](https://img.shields.io/badge/Telemetrie-Keine%20%E2%9C%93-success)](https://github.com/pepperonas/loupe)
[![SemVer](https://img.shields.io/badge/SemVer-2.0.0-3F4551)](https://semver.org)
[![Changelog](https://img.shields.io/badge/Changelog-Keep%20a%20Changelog-E05735?logo=keepachangelog&logoColor=white)](CHANGELOG.md)
<br><br>
<a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
  <img src="https://img.shields.io/badge/☕_Entwickler_einen_Kaffee_ausgeben-Spende_via_PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" height="42" alt="Spende via PayPal" />
</a>

<br><br>

```
┌────────────────────────────────────────────────────────────┐
│  Finder → Beliebige JSON-Datei (.json) wählen → Leertaste  │
│  Aufklappbare Baumvorschau mit null Byte JavaScript!       │
└────────────────────────────────────────────────────────────┘
```

</div>

---

## Übersicht

**Loupe** ist eine extrem schlanke, blitzschnelle native macOS-Anwendung und Quick Look Preview Extension (`io.celox.loupe.preview`), die interaktive, aufklappbare Entwicklerdateien direkt in den macOS Finder bringt.

Loupe ist der offizielle Nachfolger von [MarkLook](https://github.com/pepperonas/marklook). In Version 0.1.0 bietet Loupe erstklassige, gehärtete Unterstützung für JSON-Dateien (`public.json`). Weitere Entwicklerformate (darunter Markdown, YAML und CSV) folgen in kommenden Versionen über eine modulare Renderer-Architektur.

Ein Druck auf die **Leertaste** bei einer beliebigen `.json`-Datei öffnet unmittelbar einen aufklappbaren Baum mit erhaltener Schlüsselreihenfolge, Typ-Badges, Elementzählern, Syntax-Farbrollen und intelligenter Breitensuche-Voraufklappung – **ohne ein einziges Byte JavaScript**, ohne Electron und ohne ressourcenhungrige Hintergrunddienste.

Entwickelt streng nach Apples Human Interface Guidelines fügt sich Loupe optisch, funktional und ergonomisch wie eine offizielle macOS-Systemkomponente ein.

---

## Hauptmerkmale

- ⚡ **Sofortige Vorschau**: Schneller Start dank Apples moderner datenbasierter `QLPreviewProvider`- und `QLPreviewReply`-APIs (macOS 14.0+). Rendert 50 KB JSON in unter 10 ms und 5 MB JSON in ~160 ms.
- 🌳 **Aufklappbarer Baum ohne JavaScript**: 100% interaktiver Baum, ausschließlich realisiert über HTML5 `<details>`- und `<summary>`-Elemente. Keinerlei Skriptausführung, kein DOM-Scripting, keine Event-Listener-Last.
- 📐 **Ordnungserhaltender & exakter AST**: Im Gegensatz zu `JSONSerialization` oder Standard-Dictionary-Decodern bewahrt Loupe die originale Schlüsselreihenfolge der Datei, behält doppelte Schlüssel und erhält die exakte Quelltext-Schreibweise von Zahlen (z. B. `1.000` vs `1e3`).
- 🧭 **Intelligente Vor-Aufklappung (BFS-Budget)**: Statt starrer Tiefengrenzen nutzt Loupe einen Breitensuche-Algorithmus mit Zeilenbudget (Standard: 120 sichtbare Zeilen). Eine typische `package.json` liegt vollständig offen, während ein flaches Array mit 2.000 Einträgen an der Wurzel zugeklappt bleibt.
- 🩹 **Tolerante Fehleranzeige & Quelltext-Ausschnitt**: Bei Syntaxfehlern bricht Loupe nicht mit einer leeren Seite ab. Der bis zum Fehler gültig geparste Teilbaum bleibt sichtbar, begleitet von einem roten Fehlerbanner mit Zeile, Spalte, Quelltext-Kontext und exaktem Zeiger (`^`) unter Berücksichtigung von UTF-8-Multibyte-Zeichen und Tabulator-Breite.
- 🛡️ **Gehärtete Obergrenzen & DoS-Schutz**: Schutz vor Stack Overflow durch Tiefenbremse (max. 64 Ebenen), Speichersicherheit durch Knotengrenze (20.000 Knoten), Container-Kinder-Grenze (1.000 Kinder), String-Längenbegrenzung (4 KB) und Dateigrößen-Grenze (20 MB).
- 🎨 **Apple-Typografie & Kontrast-geprüfte Themes**: Helles und dunkles Theme, gesetzt in `SF Mono` und `ui-monospace`. Alle semantischen Farbrollen wurden im Browser auf einem Canvas gegen die WCAG AA-Norm geprüft (alle Kontrastwerte > 4,5:1, von 6,4:1 bis 16,8:1).
- 💻 **Native Begleit-App**: Integrierte AppKit-Begleit-App mit Echtzeit-Statusdiagnose der Quick-Look-Erweiterung, Hilfestellungen zur Systemaktivierung sowie Einstellungen für Erscheinungsbild und Textgröße.

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
| **Konfigurierbare Textgröße** | Klein, Mittel, Groß | ✅ | Gespeichert über Shared App Group UserDefaults |

---

## Kontrast-geprüfte Farbrollen (WCAG AA)

Alle Farbwerte wurden auf einem HTML5-Canvas über den Hintergrundschichten gerastert und pixelgenau gemessen (`Scripts/measure_contrast.html`):

| Farbrolle | Helles Theme (`#ffffff`) | Dunkles Theme (`#1e1e1e`) | WCAG-Status |
| :--- | :--- | :--- | :---: |
| **Text (`--text`)** | `#1d1d1f` → **16,83:1** | `#f5f5f7` → **15,31:1** | ✅ Pass (> 4,5:1) |
| **Gedimmt (`--text-dim`)** | `#5b5e69` → **6,46:1** | `#a1a1a6` → **6,48:1** | ✅ Pass (> 4,5:1) |
| **Objektschlüssel (`--key`)** | `#0b5fb0` → **6,41:1** | `#7ab8ff` → **8,04:1** | ✅ Pass (> 4,5:1) |
| **String-Literal (`--str`)** | `#b3261e` → **6,54:1** | `#ff8170` → **6,85:1** | ✅ Pass (> 4,5:1) |
| **Zahlen-Literal (`--num`)** | `#1c00cf` → **10,77:1** | `#dabaff` → **9,88:1** | ✅ Pass (> 4,5:1) |
| **Boolean-Literal (`--bool`)** | `#7a3ea3` → **6,90:1** | `#d8a0ff` → **8,25:1** | ✅ Pass (> 4,5:1) |
| **Null-Literal (`--null`)** | `#5b5e69` → **6,46:1** | `#a1a1a6` → **6,48:1** | ✅ Pass (> 4,5:1) |
| **Zähler / Peek (`--count`)** | `#5b5e69` → **6,46:1** | `#a1a1a6` → **6,48:1** | ✅ Pass (> 4,5:1) |
| **Fehler-Banner (`--err-fg`)** | `#a5251c` auf `--err-bg` → **6,72:1** | `#ff8a80` auf `--err-bg` → **6,64:1** | ✅ Pass (> 4,5:1) |
| **Hinweis-Banner (`--note-fg`)** | `#0a5aa8` auf `--note-bg` → **6,39:1** | `#7ab8ff` auf `--note-bg` → **7,05:1** | ✅ Pass (> 4,5:1) |
| **Hover / Ausschnitt-Box** | `#1d1d1f` auf `#f6f8fa` → **15,81:1** | `#f5f5f7` auf `#28282b` → **13,50:1** | ✅ Pass (> 4,5:1) |

*(Gegenprobe: Eine absichtlich blasse Farbe `#cccccc` auf `#ffffff` ergab 1,61:1 – der Nachweis, dass die Prüfmethode zu geringen Kontrast verlässlich abfängt).*

---

## Projektarchitektur

```text
Loupe
├── Loupe.app (Haupt- und Begleit-Applikation)
│   ├── Contents/MacOS/Loupe (AppKit Host-Binary)
│   ├── Contents/Info.plist (Bundle-Metadaten & registrierte UTTypes)
│   └── Contents/PlugIns/
│       └── LoupePreview.appex (Quick Look App Extension)
│           ├── Contents/MacOS/LoupePreview (QLPreviewProvider Binary)
│           └── Contents/Info.plist (NSExtension & QLSupportedContentTypes)
│
├── LoupeCore (Geteiltes Swift-Modul)
│   ├── JSON/
│   │   ├── JSONValue.swift (AST-Knoten, Member, Diagnostic, ParseOutcome)
│   │   ├── JSONLexer.swift (Byte-orientierter Scanner, Surrogatpaar-Decodierung)
│   │   ├── JSONParser.swift (Ordnungserhaltender Parser, Fehlerbehandlung)
│   │   └── SourceExcerpt.swift (Kontextfenster, Tab-Breite, UTF-8 Zeigerausrichtung)
│   ├── Preview/
│   │   ├── PreviewRenderer.swift (PreviewInput, PreviewRenderer-Protokoll)
│   │   ├── JSONPreviewRenderer.swift (End-to-End JSON-Vorschau-Koordinator)
│   │   ├── RendererRegistry.swift (UTType-Auflösung und Renderer-Registry)
│   │   └── HTMLDocument.swift (Single Source of Truth für CSP-Dokumentenhülle)
│   ├── Render/
│   │   ├── JSONTreeRenderer.swift (Verschachtelter details/summary HTML-Emitter)
│   │   ├── ExpansionPolicy.swift (Breitensuche-Expansionsplaner mit Zeilenbudget)
│   │   └── HTMLEscape.swift (Single-Pass Zeichen-Entschärfung gegen XSS)
│   ├── Theme/
│   │   └── CSSGenerator.swift (WCAG AA Hell-/Dunkel-Stylesheets mit Media-Queries)
│   ├── Configuration/
│   │   └── LoupeSettings.swift (Theme, Schriftgröße, Zeilenbudget, App Group Defaults)
│   └── Utilities/
│       └── ExtensionStatusChecker.swift (Pluginkit-Parser und Statusdiagnose)
│
└── LoupeTests (Automatisierte Test-Suite)
    ├── JSONValueTests.swift (Werte-Modell & Ordnungserhaltung)
    ├── JSONLexerTests.swift (Tokenisierung, Literale, Surrogatpaare, Positionen)
    ├── JSONParserTests.swift (Grammatik, Grenzen, Teilbaum-Rettung bei Fehlern)
    ├── SourceExcerptTests.swift (Clipping, Multibyte-UTF-8, Tabulator-Caret)
    ├── HTMLEscapeTests.swift (XSS-Neutralisierung, Entity-Reihenfolge)
    ├── SettingsTests.swift (JSON-Codierung, App Group Defaults)
    ├── CSSGeneratorTests.swift (Monospace-Regeln, Media-Query-Isolation, Klassen)
    ├── JSONTreeRendererTests.swift (Details-Struktur, Badges, Banners, Zero-JS)
    ├── ExpansionPolicyTests.swift (Warteschlangen-Ordnung, Budget-Grenzen, BFS)
    ├── RegistryTests.swift (UTType-Auflösung, exakte CSP, End-to-End-Render)
    ├── ExtensionStatusTests.swift (Pluginkit-Interpretation, Betriebsstatus)
    └── PerformanceTests.swift (50 KB in < 10 ms, 5 MB in < 170 ms Benchmarks)
```

---

## Installation & Quick Look Aktivierung

### 1. Vorkompiliertes Release herunterladen (Empfohlen)

1. Lade das neueste `Loupe-v*.zip` aus den [GitHub Releases](https://github.com/pepperonas/loupe/releases) herunter.
2. Entpacke die ZIP-Datei und ziehe `Loupe.app` in deinen Programme-Ordner (`/Applications`).
3. Starte `Loupe.app` einmalig, um die Erweiterung bei LaunchServices und `pluginkit` zu registrieren.

### 2. Aus dem Quelltext bauen & installieren

```bash
# Repository klonen
git clone https://github.com/pepperonas/loupe.git
cd loupe

# Bauen und nach /Applications/Loupe.app installieren
./Scripts/install_app.sh
```

### 3. In den macOS-Systemeinstellungen aktivieren

macOS erfordert die einmalige Freigabe von Quick-Look-Erweiterungen von Drittanbietern:

1. Öffne **Systemeinstellungen → Datenschutz & Sicherheit → Erweiterungen**.
2. Klicke auf **Quick Look**.
3. Aktiviere den Haken bei **„Loupe QuickLook Preview“** (bzw. `io.celox.loupe.preview`).
4. Falls der Finder weiterhin die Standard-Textansicht zeigt, lade den Generator-Cache neu:
   ```bash
   qlmanage -r && qlmanage -r cache && killall Finder
   ```

---

## Manuelle Verifikation im Finder

1. Öffne den Fixture-Ordner im Projekt:
   ```bash
   open Tests/Fixtures
   ```
2. Wähle eine der mitgelieferten Testdateien aus und drücke die **Leertaste**:
   - **`package.json`**: Vollständiges, geschachteltes JSON-Dokument. Öffnet sich strukturiert im Zeilenbudget; untergeordnete Blöcke lassen sich per Mausklick auf- und zuklappen.
   - **`broken.json`**: Enthält ein absichtlich fehlendes Komma. Zeigt ein rotes Fehlerbanner mit Zeile 3, Spalte 3, Quelltext-Ausschnitt und Zeiger (`^`), während der davorliegende gültige Schlüssel `"a": 1` weiterhin sichtbar bleibt.
   - **`unicode.json`**: Prüft Umlaute (`äöü`), Emojis (`😀`), japanische Zeichen (`日本語`) und maskierte Backslashes (`C:\tmp`).

---

## Automatisierte Test-Suite ausführen

Loupe verfügt über ein eigenes Test-Framework mit 98 Unit-Tests und Performanz-Messungen:

```bash
# Test-Suite im Debug-Modus ausführen
swift run LoupeTests

# Im optimierten Release-Modus testen
swift run -c release LoupeTests
```

Ausgabe:
```text
Starting Loupe Test Suite...

--- Suite: JSONValue ---
  ✓ testObjectPreservesMemberOrder (0.02ms)
  ✓ testObjectKeepsDuplicateKeys (0.00ms)
  ✓ testNumberKeepsSourceSpelling (0.00ms)
  ✓ testPositionIsOneBased (0.00ms)
  ✓ testOutcomeDistinguishesTruncationFromFailure (0.00ms)

--- Suite: JSONLexer ---
  ✓ testStructuralTokens (0.02ms)
  ✓ testLiterals (0.02ms)
  ✓ testNumbersKeepSourceSpelling (0.00ms)
  ✓ testLeadingZeroIsInvalid (0.01ms)
  ✓ testStringEscapes (0.01ms)
  ✓ testUnicodeEscapeAndSurrogatePair (0.00ms)
  ✓ testLoneSurrogateDoesNotCrash (0.00ms)
  ✓ testPositionsAreOneBasedAndCountLines (0.00ms)
  ✓ testUnterminatedStringReportsPosition (0.00ms)
  ✓ testByteOrderMarkIsSkipped (0.00ms)

--- Suite: JSONParser ---
  ✓ testKeyOrderIsSourceOrder (0.01ms)
  ✓ testDuplicateKeysBothSurvive (0.00ms)
  ✓ testNestedStructure (0.01ms)
  ✓ testBareScalarIsValidJSON (0.00ms)
  ✓ testEmptyContainers (0.00ms)
  ✓ testEmptyInputFails (0.00ms)
  ✓ testMissingCommaReportsPosition (0.00ms)
  ✓ testPartialTreeSurvivesFailure (0.00ms)
  ✓ testTrailingContentHintsAtJSONLines (0.04ms)
  ✓ testLexErrorPreservesPartialTree (0.00ms)
  ✓ testAncestorSiblingsSurviveNestedFailure (0.01ms)
  ✓ testTruncatedMidTokenReportsTruncationNotFailure (0.02ms)
  ✓ testLexErrorInTopLevelArrayPreservesItems (0.00ms)
  ✓ testArrayNestedInObjectPreservesBothLevels (0.00ms)
  ✓ testDepthBombDoesNotCrash (3.56ms)
  ✓ testDepthLimitIsExactlySixtyFour (0.04ms)
  ✓ testChildrenLimitTruncatesAndCounts (0.22ms)
  ✓ testChildrenLimitTruncatesAndCountsObject (1.70ms)
  ✓ testChildrenLimitAppliesOnFailurePathForArray (0.26ms)
  ✓ testChildrenLimitAppliesOnFailurePathForObject (1.01ms)
  ✓ testNodeLimitStopsBuilding (0.10ms)
  ✓ testLongStringIsTruncatedForDisplay (0.01ms)
  ✓ testLongObjectKeyIsTruncatedForDisplay (0.40ms)
  ✓ testTruncationIsNotReportedAsFailure (0.01ms)
  ✓ testMissingCommaInNestedObjectNestsPartialUnderAncestorKey (0.01ms)

--- Suite: SourceExcerpt ---
  ✓ testExcerptShowsContextAndCaret (0.10ms)
  ✓ testExcerptAtFirstLineDoesNotUnderflow (0.01ms)
  ✓ testVeryLongLineIsClipped (0.44ms)
  ✓ testTabsBecomeSpacesSoCaretAligns (0.02ms)
  ✓ testTabsPin_TwoTabsAndX (0.01ms)
  ✓ testEmojiPin_FireAndX (0.01ms)
  ✓ testUmlautPin_GrueseAndX (0.01ms)
  ✓ testASCIIPin_ABCAndX (0.00ms)
  ✓ testErrorOnLastLineWithContext (0.01ms)
  ✓ testLongContextLineWithCentre1Clipping (0.02ms)

--- Suite: HTMLEscape ---
  ✓ testEscapesAllFiveDangerousCharacters (0.00ms)
  ✓ testAmpersandEscapedFirst (0.00ms)
  ✓ testScriptInJSONStringIsNeutralised (0.02ms)
  ✓ testUnicodeAndEmojiSurviveUnchanged (0.00ms)

--- Suite: LoupeSettings ---
  ✓ testDefaults (0.00ms)
  ✓ testRoundTripThroughJSON (0.23ms)
  ✓ testAppGroupConstants (0.00ms)
  ✓ testTextSizeFontSizes (0.00ms)

--- Suite: CSSGenerator ---
  ✓ testSystemAppearanceEmitsBothThemes (0.02ms)
  ✓ testFixedAppearanceOmitsMediaQuery (0.06ms)
  ✓ testAllRenderClassesArePresent (0.63ms)
  ✓ testTextSizeReachesTheCSS (0.03ms)
  ✓ testNoJavaScriptAnywhere (0.28ms)
  ✓ testTreeIsMonospace (0.04ms)

--- Suite: JSONTreeRenderer ---
  ✓ testContainersBecomeDetailsElements (0.03ms)
  ✓ testScalarsAreNotCollapsible (0.01ms)
  ✓ testKeyOrderSurvivesIntoHTML (0.02ms)
  ✓ testCollapsedSummaryCarriesCountAndPeek (0.05ms)
  ✓ testOpenPathsControlTheOpenAttribute (0.07ms)
  ✓ testValueTypesGetTheirClasses (0.06ms)
  ✓ testScriptTagInStringIsEscaped (0.02ms)
  ✓ testKeyWithAngleBracketsIsEscaped (0.01ms)
  ✓ testOmittedChildrenAreDeclared (3.37ms)
  ✓ testParseErrorRendersBannerWithExcerpt (0.07ms)
  ✓ testTruncationUsesNoticeNotError (0.02ms)
  ✓ testNoJavaScriptInOutput (0.10ms)

--- Suite: ExpansionPolicy ---
  ✓ testSmallDocumentOpensCompletely (0.03ms)
  ✓ testFlatArrayBeyondBudgetStaysClosed (0.30ms)
  ✓ testBreadthFirstPrefersUpperLevels (0.02ms)
  ✓ testBudgetIsRespected (0.11ms)
  ✓ testScalarRootYieldsEmptyPlan (0.00ms)
  ✓ testZeroBudgetOpensNothing (0.00ms)
  ✓ testSmallerSiblingOpensEvenIfEarlierSiblingExceedsBudget (0.01ms)
  ✓ testBreadthFirstPrefersUpperLevelsOverDeepDescent (0.01ms)

--- Suite: Registry & Document ---
  ✓ testJSONTypeResolvesToJSONRenderer (0.05ms)
  ✓ testUnknownTypeResolvesToNil (2.16ms)
  ✓ testDocumentCarriesTheExactCSP (0.02ms)
  ✓ testDocumentEscapesTheTitle (0.02ms)
  ✓ testEndToEndRenderOfRealFile (0.70ms)
  ✓ testInvalidUTF8DoesNotCrash (0.05ms)
  ✓ testEmptyFileRendersBannerNotBlankPage (0.11ms)
  ✓ testTruncatedInputRendersTruncationNotice (0.23ms)

--- Suite: ExtensionStatus ---
  ✓ testTitles (0.00ms)
  ✓ testIsOperational (0.00ms)
  ✓ testBundleIdConstant (0.00ms)
  ✓ testParsesPluginkitOutput (0.01ms)

--- Suite: Performance ---
  ✓ testSmallDocumentUnder50ms (11.39ms)
  ✓ testFiveMegabytesUnderOneSecond (162.32ms)

==================================================
TEST RESULT: SUCCESS
All 98 unit tests passed successfully!
==================================================
```

---

## Sicherheitsarchitektur

Entwicklerdateien stammen oft aus ungesicherten externen Quellen (z. B. fremde Git-Repositories, Web-Downloads, API-Antworten). Loupe setzt kompromisslose Sicherheitsgarantien durch:

- **App Sandbox**: Sowohl die Begleit-App als auch die Quick Look App Extension laufen in separaten macOS App Sandboxes (`com.apple.security.app-sandbox`) mit reinem Lesezugriff (`com.apple.security.files.user-selected.read-only`).
- **Strikte Content Security Policy (CSP)**: Das Dokumenten-Gerüst setzt eine strikte Sicherheitsrichtlinie:
  ```text
  default-src 'none'; style-src 'unsafe-inline'; img-src 'none'
  ```
- **Null JavaScript-Ausführung**: Im Gegensatz zu anderen Vorschau-Plugins, die JavaScript-Highlighter oder Script-Bibliotheken einbetten, führt Loupe **kein einziges Byte JavaScript** aus. Das interaktive Auf- und Zuklappen läuft nativ über WebKits HTML5-Engine.
- **Single-Pass HTML-Sanitization**: Sämtliche Schlüssel, Zeichenketten, Fehlermeldungen und Fenstertitel werden in einem einzigen Zeichen-Durchlauf bereinigt (`HTMLEscape`). Re-Escaping-Angriffe (`&` vorab maskiert) sind dadurch architektonisch ausgeschlossen.
- **Harte Limits gegen Denial-of-Service (DoS)**:
  - **Tiefenbremse**: Maximal 64 geschachtelte Ebenen schützen vor Stapelüberläufen (Stack Overflow) bei rekursiven Klammer-Bomben (`[[[[...]]]]`).
  - **Knotengrenze**: Stoppt den AST-Aufbau bei 20.000 Knoten, um ungebremstes Speicherwachstum zu verhindern.
  - **Kinder-Grenze**: Begrenzt die Anzeige in Containern auf 1.000 Kinder mit explizitem Auslassungs-Zähler.
  - **String-Grenze**: Strings über 4 KB werden zur Anzeige gekürzt.
  - **Byte-Grenze**: Dateien über 20 MB werden nur bis zur Grenze eingelesen und sauber als gekürzt gemeldet, statt als fehlerhaft.
- **Kein Netzwerkzugriff**: Die Sandbox verbietet jegliche ein- und ausgehende Netzwerkkommunikation.
- **Keine Telemetrie / Analytics**: Loupe sammelt keinerlei Daten, setzt keine Tracker ein und arbeitet zu 100 % offline.

---

## Unterstützung & Spenden

Loupe ist freie, unabhängige Open-Source-Software unter der MIT-Lizenz. Wenn dir Loupe den Arbeitsalltag erleichtert, freue ich mich über einen Kaffee:

<div align="center">
  <a href="https://www.paypal.com/donate/?business=martin.pfeffer%40celox.io&item_name=Loupe&currency_code=EUR">
    <img src="https://img.shields.io/badge/☕_Entwickler_einen_Kaffee_ausgeben-Spende_via_PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" height="42" alt="Spende via PayPal" />
  </a>
  <br>
  <strong>PayPal:</strong> <a href="mailto:martin.pfeffer@celox.io">martin.pfeffer@celox.io</a>
</div>

---

## Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert — siehe die Datei [LICENSE](LICENSE) für Details.

Entwickelt mit ❤️ von **Martin Pfeffer** ([celox.io](https://celox.io)) © 2026.
