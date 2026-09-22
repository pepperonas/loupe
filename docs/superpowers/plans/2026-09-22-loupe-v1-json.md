# Loupe v1 (JSON) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eine native macOS-Quick-Look-Erweiterung, die `.json`-Dateien im Finder-Vorschaufenster als aufklappbaren Baum zeigt — ohne JavaScript.

**Architecture:** Ein `LoupeCore`-Modul enthält die gesamte Logik (byte-orientierter Lexer → ordnungserhaltender Parser mit Budget → Baum-Renderer nach verschachtelten `<details>`). Eine dünne `.appex` (`QLPreviewProvider`) sucht über eine Renderer-Registry den zum UTType passenden Renderer und liefert das HTML als `QLPreviewReply`. Eine minimale Begleit-App trägt die Erweiterung und zeigt deren Status.

**Tech Stack:** Swift 6, SwiftPM, Foundation, QuickLookUI, AppKit. **Keine externen Abhängigkeiten.**

**Spec:** `docs/superpowers/specs/2026-09-22-loupe-json-preview-design.md`

## Global Constraints

Diese gelten für **jede** Aufgabe und werden nicht wiederholt:

- **Plattform:** macOS 14+ · Swift 6 · SwiftPM · **keine Abhängigkeiten** (kein SPM-`dependencies`-Eintrag)
- **Repo:** `pepperonas/loupe`, öffentlich, MIT
- **Bundle-IDs:** App `io.celox.loupe`, Erweiterung `io.celox.loupe.preview`
- **Ziel-UTType v1:** `public.json` (Systemtyp — **keine** `UTImportedTypeDeclaration` nötig)
- **CSP im erzeugten HTML, wörtlich:** `default-src 'none'; style-src 'unsafe-inline'; img-src 'none'`
- **Entitlements:** `com.apple.security.app-sandbox` = true, `com.apple.security.files.user-selected.read-only` = true
- **Grenzen (Spec §7), exakte Werte:** Bytes 20 MB · Knoten 20.000 · Kinder je Container 1.000 · String-Anzeige 4 KB · **Tiefe 64**
- **Zeilenbudget für die Voreinstellung der Klappstellung:** 300 sichtbare Zeilen
- **Kein JavaScript.** Weder inline noch extern. Interaktion ausschließlich über `<details>`/`<summary>`.
- **Sprache:** Bezeichner und Commit-Botschaften auf Englisch, nutzersichtbare Texte auf Deutsch.
- **Testdisziplin:** Jeder neue Pin wird **einmal mutiert und rot gesehen**; eine Mutation muss zuerst per Prüfsumme belegen, dass sie gegriffen hat. Vor einem Mutationslauf committen.

### Abweichung von der Spec (bewusst, hier festgehalten)

Die Spec skizziert `func renderHTML(data: Data, url: URL, settings: LoupeSettings) -> String`.
Der Plan nutzt stattdessen ein Eingabe-Struct:

```swift
func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String
```

**Grund:** Der Leser kürzt bei 20 MB, und der Renderer **muss** wissen, dass *wir*
gekürzt haben — sonst meldet er eine gültige Datei als kaputt (Spec §8). Ein
Bool zusätzlich in die Signatur zu hängen bricht sie beim nächsten Format wieder;
das Struct wächst mit.

---

### Task 1: Skelett und R1 — kommt unsere Vorschau für `.json` überhaupt zum Zug?

> **Diese Aufgabe steht bewusst vor allem anderen.** Spec §11/R1: macOS zeigt
> `.json` heute über die eingebaute Textvorschau. Ob eine eigene `.appex` diesen
> Vorrang übernimmt, ist **nicht belegt**. Fällt es negativ aus, ändert das den
> Zuschnitt des ganzen Projekts — dann ist jede Zeile Parser-Code verfrüht.

**Files:**
- Create: `Package.swift`
- Create: `Sources/LoupeCore/Preview/PreviewRenderer.swift`
- Create: `Sources/LoupeCore/Configuration/LoupeSettings.swift` (Platzhalter, Task 7 ersetzt ihn)
- Create: `Sources/LoupeCore/Render/HTMLEscape.swift` (vorgezogen aus Task 7 — die Erweiterung
  schreibt ab dem ersten Commit einen Dateinamen ins HTML, und ein Dateiname ist fremder Eingabewert)
- Create: `Tests/LoupeTests/main.swift` (Platzhalter, Task 2 ersetzt ihn)
- Create: `Sources/LoupePreview/main.swift`
- Create: `Sources/LoupePreview/PreviewProvider.swift`
- Create: `Sources/LoupePreview/Resources/Info.plist`
- Create: `Sources/LoupePreview/Resources/LoupePreview.entitlements`
- Create: `Sources/Loupe/main.swift`
- Create: `Sources/Loupe/Resources/Info.plist`
- Create: `Sources/Loupe/Resources/Loupe.entitlements`
- Create: `Scripts/build_app.sh`, `Scripts/install_app.sh`
- Create: `LICENSE` (MIT, Martin Pfeffer, 2026)

**Interfaces:**
- Consumes: nichts
- Produces: `PreviewInput` (Struct mit `data: Data`, `url: URL`, `wasTruncatedByReader: Bool`) — von Task 11 gebraucht. Ein baubares, installierbares Bundle.

- [ ] **Step 1: `Package.swift` anlegen**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Loupe",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LoupeCore", targets: ["LoupeCore"]),
        .executable(name: "Loupe", targets: ["Loupe"]),
        .executable(name: "LoupePreview", targets: ["LoupePreview"]),
        .executable(name: "LoupeTests", targets: ["LoupeTests"])
    ],
    targets: [
        .target(name: "LoupeCore", path: "Sources/LoupeCore"),
        .executableTarget(
            name: "Loupe",
            dependencies: ["LoupeCore"],
            path: "Sources/Loupe",
            exclude: ["Resources"]
        ),
        .executableTarget(
            name: "LoupePreview",
            dependencies: ["LoupeCore"],
            path: "Sources/LoupePreview",
            exclude: ["Resources"],
            linkerSettings: [
                .linkedFramework("QuickLookUI"),
                .linkedFramework("Quartz"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("AppKit")
            ]
        ),
        .executableTarget(name: "LoupeTests", dependencies: ["LoupeCore"], path: "Tests/LoupeTests")
    ]
)
```

Damit `swift build` in diesem Schritt durchläuft, braucht `Tests/LoupeTests`
bereits eine Datei — lege `Tests/LoupeTests/main.swift` mit genau
`print("placeholder")` an. Task 2 ersetzt sie vollständig.

- [ ] **Step 2: `PreviewInput` und das Renderer-Protokoll anlegen**

Datei `Sources/LoupeCore/Preview/PreviewRenderer.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

/// Alles, was ein Renderer über die anzuzeigende Datei wissen muss.
public struct PreviewInput: Sendable {
    public let data: Data
    public let url: URL
    /// true, wenn der Leser bei der Byte-Grenze abgeschnitten hat.
    /// Ohne dieses Wissen meldet der Parser eine gültige Großdatei als kaputt.
    public let wasTruncatedByReader: Bool

    public init(data: Data, url: URL, wasTruncatedByReader: Bool) {
        self.data = data
        self.url = url
        self.wasTruncatedByReader = wasTruncatedByReader
    }
}

public protocol PreviewRenderer: Sendable {
    static var supportedTypes: [UTType] { get }
    func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String
}
```

`LoupeSettings` existiert noch nicht. Lege in dieser Aufgabe einen **minimalen
Platzhalter** an, den Task 7 durch die echte Fassung ersetzt — in
`Sources/LoupeCore/Configuration/LoupeSettings.swift`:

```swift
import Foundation

public struct LoupeSettings: Sendable, Equatable, Codable {
    public init() {}
}
```

- [ ] **Step 3: Die `.appex` mit fester Hallo-Ausgabe**

`Sources/LoupePreview/main.swift` — wörtlich wie bei MarkLook:

```swift
import Foundation

@_silgen_name("NSExtensionMain")
func NSExtensionMain()

NSExtensionMain()
```

`Sources/LoupePreview/PreviewProvider.swift` — bewusst **noch ohne Parser**,
die Aufgabe klärt nur den Vorrang:

```swift
import Foundation
import QuickLookUI
import UniformTypeIdentifiers
import LoupeCore

@objc(PreviewProvider)
public final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    public override init() { super.init() }

    public func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        let url = request.fileURL
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        let html = """
        <!DOCTYPE html>
        <html lang="de"><head><meta charset="UTF-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src 'none'">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 32px; }
          code { font-family: ui-monospace, SFMono-Regular, monospace; }
          @media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #f5f5f7; } }
        </style></head>
        <body>
          <h1>Loupe</h1>
          <p>R1-Nachweis: Diese Vorschau stammt von Loupe, nicht von der System-Textvorschau.</p>
          <p><code>\(url.lastPathComponent)</code> — \(size ?? 0) Bytes</p>
        </body></html>
        """
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 840, height: 640)) { _ in
            html.data(using: .utf8) ?? Data()
        }
        reply.title = url.lastPathComponent
        completionHandler(reply, nil)
    }
}
```

- [ ] **Step 4: `Info.plist` der Erweiterung**

`Sources/LoupePreview/Resources/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleDisplayName</key><string>Loupe QuickLook Preview</string>
    <key>CFBundleExecutable</key><string>LoupePreview</string>
    <key>CFBundleIdentifier</key><string>io.celox.loupe.preview</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>LoupePreview</string>
    <key>CFBundlePackageType</key><string>XPC!</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>QLIsDataBasedPreview</key><true/>
            <key>QLSupportedContentTypes</key>
            <array><string>public.json</string></array>
            <key>QLSupportsSearchableItems</key><false/>
        </dict>
        <key>NSExtensionPointIdentifier</key><string>com.apple.quicklook.preview</string>
        <key>NSExtensionPrincipalClass</key><string>PreviewProvider</string>
    </dict>
</dict>
</plist>
```

- [ ] **Step 5: App-Gerüst, Plists, Entitlements**

`Sources/Loupe/main.swift` — in dieser Aufgabe reicht ein Fenster, damit das
Bundle startbar ist (Task 12 baut die echte Oberfläche):

```swift
import AppKit

let app = NSApplication.shared
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 520, height: 260),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered, defer: false
)
window.title = "Loupe"
let label = NSTextField(labelWithString: "Loupe — Quick-Look-Vorschau\nOberfläche folgt in Task 12.")
label.alignment = .center
label.frame = NSRect(x: 20, y: 100, width: 480, height: 60)
window.contentView?.addSubview(label)
window.center()
window.makeKeyAndOrderFront(nil)
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
```

`Sources/Loupe/Resources/Info.plist` — wie MarkLooks App-Plist, aber mit
`io.celox.loupe`, `CFBundleExecutable` = `Loupe`, und diesem Dokumenttyp
(**kein** `UTImportedTypeDeclarations`-Block, `public.json` ist ein Systemtyp):

```xml
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key><string>JSON Document</string>
            <key>CFBundleTypeRole</key><string>Viewer</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array><string>public.json</string></array>
        </dict>
    </array>
```

Beide `.entitlements`-Dateien sind **byte-gleich zu MarkLooks**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key><true/>
    <key>com.apple.security.files.user-selected.read-only</key><true/>
</dict>
</plist>
```

- [ ] **Step 6: Build-Skripte übernehmen**

`Scripts/build_app.sh` und `Scripts/install_app.sh` von
`/Users/martin/claude/marklook/Scripts/` kopieren und darin ersetzen:
`MarkLook` → `Loupe`, `MarkLookPreview` → `LoupePreview`,
`io.celox.marklook.preview` → `io.celox.loupe.preview`. Danach
`chmod +x Scripts/*.sh`.

- [ ] **Step 7: Bauen und installieren**

Run: `swift build && ./Scripts/install_app.sh`
Expected: Bundle unter `/Applications/Loupe.app`, `pluginkit` meldet die
Erweiterung mit führendem `+`.

Prüfen: `pluginkit -m -v -i io.celox.loupe.preview`

- [ ] **Step 8: R1 beantworten — der eigentliche Zweck dieser Aufgabe**

```bash
printf '{"r1":"check","zahlen":[1,2,3]}' > ~/Desktop/loupe-r1.json
```

Danach im Finder: Datei auswählen, **Leertaste**.

- **Erscheint „Loupe" mit der R1-Zeile** → Vorrang bestätigt, weiter mit Task 2.
- **Erscheint der rohe JSON-Text** → System-Textvorschau gewinnt. **STOPP.**
  Nicht weiterbauen. Zuerst gegenprüfen, ob die Erweiterung in
  *Systemeinstellungen → Datenschutz & Sicherheit → Erweiterungen → Quick Look*
  aktiviert ist, dann `qlmanage -r && qlmanage -r cache && killall Finder`, dann
  erneut. Bleibt es dabei, ist R1 negativ und der Projektzuschnitt muss neu
  entschieden werden — das ist eine Rückfrage an den Auftraggeber, keine
  Entwicklungsentscheidung.

- [ ] **Step 9: Ergebnis in der Spec festhalten**

In `docs/superpowers/specs/2026-09-22-loupe-json-preview-design.md`, §11, den
Absatz R1 um eine Zeile ergänzen: `**Ergebnis 2026-__-__: bestätigt/negativ.**`
Ein Risiko, dessen Ausgang nirgends steht, wird beim nächsten Lesen erneut
untersucht.

- [ ] **Step 10: Committen**

```bash
rm -f ~/Desktop/loupe-r1.json
git add -A
git commit -m "feat: project skeleton and Quick Look extension for public.json

Answers risk R1 from the spec: a third-party appex does take precedence
over the built-in text preview for public.json."
```

---

### Task 2: Testharness und Kernmodell

**Files:**
- Create: `Tests/LoupeTests/TestFramework.swift`
- Modify: `Tests/LoupeTests/main.swift` (ersetzt den Platzhalter aus Task 1)
- Create: `Sources/LoupeCore/JSON/JSONValue.swift`
- Create: `Tests/LoupeTests/JSONValueTests.swift`

**Interfaces:**
- Consumes: nichts aus Task 1 außer dem bauenden Paket
- Produces: `Position`, `JSONValue`, `Member`, `LimitKind`, `Diagnostic`,
  `ParseOutcome`, `ParseResult` — das Vokabular **aller** folgenden Aufgaben.
  Dazu `TestRunner.shared`, `assertEqual`, `assertTrue`, `assertFalse`,
  `assertLessThan`.

- [ ] **Step 1: Testharness übernehmen**

`Tests/LoupeTests/TestFramework.swift` ist eine **wörtliche Kopie** von
`/Users/martin/claude/marklook/Tests/MarkLookTests/TestFramework.swift`.
Keine Änderung nötig — die Datei enthält nichts Markdown-Spezifisches.

`Tests/LoupeTests/main.swift`:

```swift
import Foundation

print("Starting Loupe Test Suite...")
let start = CFAbsoluteTimeGetCurrent()

JSONValueTests.run()

let totalTime = (CFAbsoluteTimeGetCurrent() - start) * 1000
print(String(format: "Total Test Suite Time: %.2f ms", totalTime))

let success = TestRunner.shared.report()
exit(success ? 0 : 1)
```

Jede folgende Aufgabe hängt ihre eigene `run()`-Zeile hier an.

- [ ] **Step 2: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/JSONValueTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum JSONValueTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONValue") {

            runner.runTest(name: "testObjectPreservesMemberOrder") {
                let obj = JSONValue.object(members: [
                    Member(key: "zebra", value: .number("1")),
                    Member(key: "alpha", value: .number("2"))
                ], omitted: 0)
                guard case .object(let members, _) = obj else {
                    throw TestFailure(message: "kein Objekt", file: #file, line: #line)
                }
                // Die Reihenfolge der Datei, NICHT alphabetisch.
                try assertEqual(members.map(\.key), ["zebra", "alpha"])
            }

            runner.runTest(name: "testObjectKeepsDuplicateKeys") {
                let obj = JSONValue.object(members: [
                    Member(key: "a", value: .number("1")),
                    Member(key: "a", value: .number("2"))
                ], omitted: 0)
                guard case .object(let members, _) = obj else {
                    throw TestFailure(message: "kein Objekt", file: #file, line: #line)
                }
                // Ein Dictionary haette den ersten still verworfen.
                try assertEqual(members.count, 2)
                try assertEqual(members.map(\.key), ["a", "a"])
            }

            runner.runTest(name: "testNumberKeepsSourceSpelling") {
                // 1.0 darf NICHT zu 1 werden, 1e400 nicht zu inf,
                // grosse Ganzzahlen duerfen keine Stellen verlieren.
                let cases = ["1.0", "1e400", "9007199254740993", "-0"]
                for raw in cases {
                    guard case .number(let text) = JSONValue.number(raw) else {
                        throw TestFailure(message: "keine Zahl", file: #file, line: #line)
                    }
                    try assertEqual(text, raw)
                }
            }

            runner.runTest(name: "testPositionIsOneBased") {
                let p = Position(line: 1, column: 1, offset: 0)
                try assertEqual(p.line, 1)
                try assertEqual(p.column, 1)
                try assertEqual(p.offset, 0)
            }

            runner.runTest(name: "testOutcomeDistinguishesTruncationFromFailure") {
                // Die wichtigste Unterscheidung des ganzen Projekts:
                // WIR haben gekuerzt ist nicht dasselbe wie die DATEI ist kaputt.
                let a = ParseOutcome.truncatedByLimit(.bytes)
                let b = ParseOutcome.failed(at: Position(line: 1, column: 1, offset: 0))
                try assertFalse(a == b)
            }
        }
    }
}
```

- [ ] **Step 3: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: Übersetzungsfehler — `JSONValue`, `Member`, `Position`,
`ParseOutcome` sind unbekannt.

- [ ] **Step 4: Das Modell schreiben**

`Sources/LoupeCore/JSON/JSONValue.swift`:

```swift
import Foundation

/// Stelle im Quelltext. Zeile und Spalte 1-basiert (wie Editoren zaehlen),
/// offset 0-basiert in Bytes.
public struct Position: Equatable, Sendable {
    public let line: Int
    public let column: Int
    public let offset: Int

    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }
}

/// Ein Schluessel-Wert-Paar eines Objekts.
///
/// Objekte sind eine LISTE von Paaren, kein Dictionary. Ein Dictionary ist
/// ungeordnet und verwirft doppelte Schluessel still -- beides waere eine
/// Luege ueber die Datei.
public struct Member: Sendable {
    public let key: String
    public let value: JSONValue

    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

public indirect enum JSONValue: Sendable {
    case null
    case bool(Bool)
    /// Roh als Zeichenkette. Double macht aus 1.0 eine 1, verliert bei grossen
    /// Ganzzahlen Stellen und kippt bei 1e400 ins Unendliche.
    case number(String)
    case string(String)
    case array(items: [JSONValue], omitted: Int)
    case object(members: [Member], omitted: Int)
}

/// Welche Grenze aus Spec §7 gegriffen hat.
public enum LimitKind: String, Equatable, Sendable {
    case bytes, nodes, children, depth, stringLength
}

public struct Diagnostic: Equatable, Sendable {
    public enum Severity: Equatable, Sendable { case error, notice }

    public let severity: Severity
    public let message: String
    public let position: Position

    public init(severity: Severity, message: String, position: Position) {
        self.severity = severity
        self.message = message
        self.position = position
    }
}

public enum ParseOutcome: Equatable, Sendable {
    case complete
    /// WIR haben gekuerzt. Die Datei ist in Ordnung, nur nicht vollstaendig
    /// gelesen. Darf NIEMALS als Fehler dargestellt werden.
    case truncatedByLimit(LimitKind)
    /// Die DATEI ist kaputt.
    case failed(at: Position)
}

public struct ParseResult: Sendable {
    public let root: JSONValue?
    public let outcome: ParseOutcome
    public let diagnostics: [Diagnostic]

    public init(root: JSONValue?, outcome: ParseOutcome, diagnostics: [Diagnostic]) {
        self.root = root
        self.outcome = outcome
        self.diagnostics = diagnostics
    }
}
```

- [ ] **Step 5: Tests laufen lassen, grün sehen**

Run: `swift run LoupeTests`
Expected: `All 5 unit tests passed successfully!`

- [ ] **Step 6: Mutationsprobe**

Ändere in `JSONValue.swift` `case object(members: [Member], omitted: Int)`
testweise zu einer Dictionary-Variante — oder einfacher und ausreichend:
kehre in `JSONValueTests` **nicht** den Test um, sondern belege, dass der
Reihenfolge-Test scharf ist, indem du in `JSONValueTests` den Erwartungswert
auf `["alpha", "zebra"]` setzt und siehst, dass der Test **rot** wird.
Danach zurücksetzen.

```bash
md5 -q Sources/LoupeCore/JSON/JSONValue.swift   # vor und nach der Mutation vergleichen
swift run LoupeTests                            # muss ROT sein
git checkout -- Tests/LoupeTests/JSONValueTests.swift
```

- [ ] **Step 7: Committen**

```bash
git add -A
git commit -m "feat: core JSON value model with order-preserving objects

Objects are a list of pairs, not a dictionary: a dictionary is unordered
and silently drops duplicate keys. Numbers keep their source spelling so
1.0 does not become 1 and large integers keep every digit."
```

---

### Task 3: JSONLexer — Bytes zu Tokens

**Files:**
- Create: `Sources/LoupeCore/JSON/JSONLexer.swift`
- Create: `Tests/LoupeTests/JSONLexerTests.swift`
- Modify: `Tests/LoupeTests/main.swift` (Zeile `JSONLexerTests.run()` ergänzen)

**Interfaces:**
- Consumes: `Position` aus Task 2
- Produces: `TokenKind`, `Token`, `LexError`, `JSONLexer` mit
  `init(bytes: [UInt8])` und `mutating func next() throws -> Token`

> **Hinweis zur Spec:** §5 nennt `UnsafeBufferPointer<UInt8>`. Der Plan startet
> mit `[UInt8]` — der Punkt der Spec ist *byte-orientiert statt `Character`*,
> und das ist erfüllt. Ob der unsichere Puffer nötig ist, entscheidet die
> Messung in Task 13, nicht die Vermutung.

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/JSONLexerTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum JSONLexerTests {

    private static func tokens(_ text: String) throws -> [TokenKind] {
        var lexer = JSONLexer(bytes: Array(text.utf8))
        var out: [TokenKind] = []
        while true {
            let token = try lexer.next()
            if token.kind == .endOfInput { break }
            out.append(token.kind)
        }
        return out
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONLexer") {

            runner.runTest(name: "testStructuralTokens") {
                try assertEqual(try tokens("{}[],:"),
                                [.braceOpen, .braceClose, .bracketOpen, .bracketClose, .comma, .colon])
            }

            runner.runTest(name: "testLiterals") {
                try assertEqual(try tokens("true false null"),
                                [.literalTrue, .literalFalse, .literalNull])
            }

            runner.runTest(name: "testNumbersKeepSourceSpelling") {
                try assertEqual(try tokens("1.0"), [.number("1.0")])
                try assertEqual(try tokens("-0"), [.number("-0")])
                try assertEqual(try tokens("1e400"), [.number("1e400")])
                try assertEqual(try tokens("9007199254740993"), [.number("9007199254740993")])
            }

            runner.runTest(name: "testLeadingZeroIsInvalid") {
                // JSON verbietet fuehrende Nullen. 01 ist KEINE gueltige Zahl.
                var threw = false
                do { _ = try tokens("01") } catch { threw = true }
                try assertTrue(threw, "01 muss abgelehnt werden")
            }

            runner.runTest(name: "testStringEscapes") {
                try assertEqual(try tokens("\"a\\\"b\""), [.string("a\"b")])
                try assertEqual(try tokens("\"\\n\\t\\\\\""), [.string("\n\t\\")])
                try assertEqual(try tokens("\"\\/\""), [.string("/")])
            }

            runner.runTest(name: "testUnicodeEscapeAndSurrogatePair") {
                try assertEqual(try tokens("\"\\u00e4\""), [.string("ä")])
                // U+1F600, als Surrogatpaar geschrieben -- muss zu EINEM Zeichen werden.
                try assertEqual(try tokens("\"\\ud83d\\ude00\""), [.string("😀")])
            }

            runner.runTest(name: "testLoneSurrogateDoesNotCrash") {
                // Ein einzelnes hohes Surrogat ist kein gueltiger Skalar.
                // Erwartung: sauberer Fehler, KEIN Absturz.
                var threw = false
                do { _ = try tokens("\"\\ud83d\"") } catch { threw = true }
                try assertTrue(threw, "einzelnes Surrogat muss einen Fehler geben")
            }

            runner.runTest(name: "testPositionsAreOneBasedAndCountLines") {
                var lexer = JSONLexer(bytes: Array("{\n  \"a\"".utf8))
                let brace = try lexer.next()
                try assertEqual(brace.position.line, 1)
                try assertEqual(brace.position.column, 1)
                let key = try lexer.next()
                try assertEqual(key.position.line, 2)
                try assertEqual(key.position.column, 3)
            }

            runner.runTest(name: "testUnterminatedStringReportsPosition") {
                var lexer = JSONLexer(bytes: Array("\"abc".utf8))
                do {
                    _ = try lexer.next()
                    throw TestFailure(message: "haette werfen muessen", file: #file, line: #line)
                } catch let e as LexError {
                    try assertEqual(e.position.line, 1)
                } 
            }

            runner.runTest(name: "testByteOrderMarkIsSkipped") {
                // Viele Werkzeuge schreiben ein BOM. Es ist kein Fehler.
                try assertEqual(try tokens("\u{FEFF}{}"), [.braceOpen, .braceClose])
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: Übersetzungsfehler — `JSONLexer` unbekannt.

- [ ] **Step 3: Den Lexer schreiben**

`Sources/LoupeCore/JSON/JSONLexer.swift`. Kernstruktur:

```swift
import Foundation

public enum TokenKind: Equatable, Sendable {
    case braceOpen, braceClose
    case bracketOpen, bracketClose
    case colon, comma
    case string(String)
    case number(String)
    case literalTrue, literalFalse, literalNull
    case endOfInput
}

public struct Token: Equatable, Sendable {
    public let kind: TokenKind
    public let position: Position
    public init(kind: TokenKind, position: Position) {
        self.kind = kind
        self.position = position
    }
}

public struct LexError: Error, Equatable, Sendable {
    public let message: String
    public let position: Position
    public init(message: String, position: Position) {
        self.message = message
        self.position = position
    }
}

public struct JSONLexer {
    private let bytes: [UInt8]
    private var index: Int = 0
    private var line: Int = 1
    private var lineStart: Int = 0

    public init(bytes: [UInt8]) {
        self.bytes = bytes
        // BOM (EF BB BF) ueberspringen -- kein Fehler, nur Rauschen.
        if bytes.count >= 3, bytes[0] == 0xEF, bytes[1] == 0xBB, bytes[2] == 0xBF {
            index = 3
            lineStart = 3
        }
    }

    private var currentPosition: Position {
        Position(line: line, column: index - lineStart + 1, offset: index)
    }

    private mutating func skipWhitespace() {
        while index < bytes.count {
            switch bytes[index] {
            case 0x0A:                      // \n
                index += 1; line += 1; lineStart = index
            case 0x20, 0x09, 0x0D:          // Space, Tab, CR
                index += 1
            default:
                return
            }
        }
    }

    public mutating func next() throws -> Token {
        skipWhitespace()
        guard index < bytes.count else {
            return Token(kind: .endOfInput, position: currentPosition)
        }
        let start = currentPosition
        switch bytes[index] {
        case UInt8(ascii: "{"): index += 1; return Token(kind: .braceOpen, position: start)
        case UInt8(ascii: "}"): index += 1; return Token(kind: .braceClose, position: start)
        case UInt8(ascii: "["): index += 1; return Token(kind: .bracketOpen, position: start)
        case UInt8(ascii: "]"): index += 1; return Token(kind: .bracketClose, position: start)
        case UInt8(ascii: ":"): index += 1; return Token(kind: .colon, position: start)
        case UInt8(ascii: ","): index += 1; return Token(kind: .comma, position: start)
        case UInt8(ascii: "\""): return Token(kind: .string(try lexString(from: start)), position: start)
        case UInt8(ascii: "t"): try expect("true", at: start); return Token(kind: .literalTrue, position: start)
        case UInt8(ascii: "f"): try expect("false", at: start); return Token(kind: .literalFalse, position: start)
        case UInt8(ascii: "n"): try expect("null", at: start); return Token(kind: .literalNull, position: start)
        default: return Token(kind: .number(try lexNumber(from: start)), position: start)
        }
    }
    // lexString, lexNumber, expect: siehe Schritte 4-6
}
```

- [ ] **Step 4: `expect` und `lexNumber` ergänzen**

```swift
    private mutating func expect(_ word: String, at start: Position) throws {
        let want = Array(word.utf8)
        guard index + want.count <= bytes.count,
              Array(bytes[index ..< index + want.count]) == want else {
            throw LexError(message: "'\(word)' erwartet", position: start)
        }
        index += want.count
    }

    private mutating func lexNumber(from start: Position) throws -> String {
        let begin = index
        if index < bytes.count, bytes[index] == UInt8(ascii: "-") { index += 1 }

        // Ganzzahlteil: entweder genau eine 0, oder 1-9 gefolgt von Ziffern.
        // Eine fuehrende Null wie 01 ist laut JSON ungueltig.
        guard index < bytes.count, isDigit(bytes[index]) else {
            throw LexError(message: "Ziffer erwartet", position: start)
        }
        if bytes[index] == UInt8(ascii: "0") {
            index += 1
            if index < bytes.count, isDigit(bytes[index]) {
                throw LexError(message: "führende Null ist nicht erlaubt", position: start)
            }
        } else {
            while index < bytes.count, isDigit(bytes[index]) { index += 1 }
        }

        if index < bytes.count, bytes[index] == UInt8(ascii: ".") {
            index += 1
            guard index < bytes.count, isDigit(bytes[index]) else {
                throw LexError(message: "Ziffer nach dem Dezimalpunkt erwartet", position: start)
            }
            while index < bytes.count, isDigit(bytes[index]) { index += 1 }
        }

        if index < bytes.count, bytes[index] | 0x20 == UInt8(ascii: "e") {
            index += 1
            if index < bytes.count, bytes[index] == UInt8(ascii: "+") || bytes[index] == UInt8(ascii: "-") {
                index += 1
            }
            guard index < bytes.count, isDigit(bytes[index]) else {
                throw LexError(message: "Ziffer im Exponenten erwartet", position: start)
            }
            while index < bytes.count, isDigit(bytes[index]) { index += 1 }
        }

        return String(decoding: bytes[begin ..< index], as: UTF8.self)
    }

    private func isDigit(_ b: UInt8) -> Bool {
        b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9")
    }
```

- [ ] **Step 5: `lexString` mit Escapes und Surrogatpaaren ergänzen**

```swift
    private mutating func lexString(from start: Position) throws -> String {
        index += 1                      // oeffnendes Anfuehrungszeichen
        var scalars = String.UnicodeScalarView()
        while true {
            guard index < bytes.count else {
                throw LexError(message: "Zeichenkette nicht geschlossen", position: start)
            }
            let b = bytes[index]
            if b == UInt8(ascii: "\"") { index += 1; break }
            if b == UInt8(ascii: "\\") {
                index += 1
                guard index < bytes.count else {
                    throw LexError(message: "Zeichenkette nicht geschlossen", position: start)
                }
                switch bytes[index] {
                case UInt8(ascii: "\""): scalars.append("\""); index += 1
                case UInt8(ascii: "\\"): scalars.append("\\"); index += 1
                case UInt8(ascii: "/"):  scalars.append("/");  index += 1
                case UInt8(ascii: "b"):  scalars.append(UnicodeScalar(8));  index += 1
                case UInt8(ascii: "f"):  scalars.append(UnicodeScalar(12)); index += 1
                case UInt8(ascii: "n"):  scalars.append("\n"); index += 1
                case UInt8(ascii: "r"):  scalars.append("\r"); index += 1
                case UInt8(ascii: "t"):  scalars.append("\t"); index += 1
                case UInt8(ascii: "u"):  scalars.append(try lexUnicodeEscape(from: start))
                default:
                    throw LexError(message: "unbekannte Escape-Sequenz", position: currentPosition)
                }
            } else {
                // Rohbytes sammeln bis zum naechsten Sonderzeichen und am Stueck dekodieren.
                let begin = index
                while index < bytes.count,
                      bytes[index] != UInt8(ascii: "\""),
                      bytes[index] != UInt8(ascii: "\\") {
                    if bytes[index] == 0x0A { line += 1; lineStart = index + 1 }
                    index += 1
                }
                scalars.append(contentsOf: String(decoding: bytes[begin ..< index], as: UTF8.self).unicodeScalars)
            }
        }
        return String(scalars)
    }

    /// Liest \uXXXX. Ein hohes Surrogat MUSS von einem niedrigen gefolgt werden --
    /// sonst entsteht kein gueltiger Unicode-Skalar.
    private mutating func lexUnicodeEscape(from start: Position) throws -> UnicodeScalar {
        let first = try readFourHexDigits(from: start)
        if first >= 0xD800 && first <= 0xDBFF {
            guard index + 1 < bytes.count,
                  bytes[index] == UInt8(ascii: "\\"),
                  bytes[index + 1] == UInt8(ascii: "u") else {
                throw LexError(message: "einzelnes Surrogat ohne Partner", position: start)
            }
            // NUR den Backslash ueberspringen -- readFourHexDigits erwartet
            // index AUF dem 'u' (siehe dessen eigenes `index += 1`). Mit
            // `index += 2` waere das 'u' schon konsumiert und die erste
            // Hexziffer des zweiten Quads wuerde verschluckt.
            index += 1
            let second = try readFourHexDigits(from: start)
            guard second >= 0xDC00 && second <= 0xDFFF else {
                throw LexError(message: "ungültiges Surrogatpaar", position: start)
            }
            let combined = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
            guard let scalar = UnicodeScalar(UInt32(combined)) else {
                throw LexError(message: "ungültiger Unicode-Wert", position: start)
            }
            return scalar
        }
        guard first < 0xD800 || first > 0xDFFF, let scalar = UnicodeScalar(UInt32(first)) else {
            throw LexError(message: "einzelnes Surrogat ohne Partner", position: start)
        }
        return scalar
    }

    private mutating func readFourHexDigits(from start: Position) throws -> Int {
        index += 1                      // das u
        guard index + 4 <= bytes.count else {
            throw LexError(message: "\\u braucht vier Hexziffern", position: start)
        }
        var value = 0
        for _ in 0 ..< 4 {
            let b = bytes[index]
            let digit: Int
            switch b {
            case UInt8(ascii: "0") ... UInt8(ascii: "9"): digit = Int(b - UInt8(ascii: "0"))
            case UInt8(ascii: "a") ... UInt8(ascii: "f"): digit = Int(b - UInt8(ascii: "a")) + 10
            case UInt8(ascii: "A") ... UInt8(ascii: "F"): digit = Int(b - UInt8(ascii: "A")) + 10
            default: throw LexError(message: "\\u braucht vier Hexziffern", position: start)
            }
            value = value * 16 + digit
            index += 1
        }
        return value
    }
```

- [ ] **Step 6: `main.swift` erweitern und Tests grün sehen**

In `Tests/LoupeTests/main.swift` nach `JSONValueTests.run()` einfügen:
`JSONLexerTests.run()`

Run: `swift run LoupeTests`
Expected: alle Tests grün, darunter die 10 neuen der Lexer-Suite.

- [ ] **Step 7: Mutationsprobe — drei gezielte Eingriffe**

Jede Mutation einzeln, jeweils mit `md5 -q` vorher/nachher belegen, dass sie
gegriffen hat, Testlauf muss **rot** werden, danach `git checkout --`:

1. In `lexNumber` die Prüfung auf führende Null entfernen →
   `testLeadingZeroIsInvalid` muss fallen.
2. In `lexUnicodeEscape` den Surrogat-Zweig überspringen und immer
   `UnicodeScalar(first)` zurückgeben → `testUnicodeEscapeAndSurrogatePair`
   muss fallen.
3. In `skipWhitespace` das `line += 1` entfernen →
   `testPositionsAreOneBasedAndCountLines` muss fallen.

- [ ] **Step 8: Committen**

```bash
git add -A
git commit -m "feat: byte-oriented JSON lexer with positions and escapes

Numbers keep their source spelling, leading zeros are rejected per spec,
surrogate pairs combine into one scalar and a lone surrogate is a clean
error rather than a crash."
```

---

### Task 4: JSONParser — Tokens zum Baum

**Files:**
- Create: `Sources/LoupeCore/JSON/JSONParser.swift`
- Create: `Tests/LoupeTests/JSONParserTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: `JSONLexer`, `Token`, `TokenKind`, `LexError` (Task 3);
  `JSONValue`, `Member`, `ParseResult`, `ParseOutcome`, `Diagnostic` (Task 2)
- Produces: `ParseLimits`, `JSONParser` mit
  `init(bytes: [UInt8], limits: ParseLimits, wasTruncatedByReader: Bool)` und
  `mutating func parse() -> ParseResult`

> Diese Aufgabe baut den Parser **ohne** Grenzen, nimmt `ParseLimits` aber
> schon entgegen. Task 5 verdrahtet die Grenzen. Trennung, weil der Parser
> allein schon prüfenswert ist und die Grenzen eigene, scharfe Tests brauchen.

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/JSONParserTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum JSONParserTests {

    static func parse(_ text: String,
                      limits: ParseLimits = ParseLimits(),
                      truncated: Bool = false) -> ParseResult {
        var parser = JSONParser(bytes: Array(text.utf8), limits: limits,
                                wasTruncatedByReader: truncated)
        return parser.parse()
    }

    static func keys(_ value: JSONValue?) throws -> [String] {
        guard case .object(let members, _)? = value else {
            throw TestFailure(message: "kein Objekt", file: #file, line: #line)
        }
        return members.map(\.key)
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONParser") {

            runner.runTest(name: "testKeyOrderIsSourceOrder") {
                // DER Test des Projekts. Faellt er, luegt das Produkt.
                let r = parse(#"{"zebra":1,"alpha":2,"mitte":3}"#)
                try assertEqual(r.outcome, .complete)
                try assertEqual(try keys(r.root), ["zebra", "alpha", "mitte"])
            }

            runner.runTest(name: "testDuplicateKeysBothSurvive") {
                let r = parse(#"{"a":1,"a":2}"#)
                try assertEqual(try keys(r.root), ["a", "a"])
            }

            runner.runTest(name: "testNestedStructure") {
                let r = parse(#"{"a":{"b":[1,"x",null,true]}}"#)
                guard case .object(let outer, _)? = r.root,
                      case .object(let inner, _) = outer[0].value,
                      case .array(let items, _) = inner[0].value else {
                    throw TestFailure(message: "Struktur falsch", file: #file, line: #line)
                }
                try assertEqual(items.count, 4)
                guard case .number("1") = items[0], case .string("x") = items[1],
                      case .null = items[2], case .bool(true) = items[3] else {
                    throw TestFailure(message: "Werte falsch", file: #file, line: #line)
                }
            }

            runner.runTest(name: "testBareScalarIsValidJSON") {
                // 42 allein ist gueltiges JSON (RFC 8259).
                try assertEqual(parse("42").outcome, .complete)
                try assertEqual(parse(#""hallo""#).outcome, .complete)
                try assertEqual(parse("null").outcome, .complete)
            }

            runner.runTest(name: "testEmptyContainers") {
                let r = parse(#"{"a":{},"b":[]}"#)
                try assertEqual(r.outcome, .complete)
            }

            runner.runTest(name: "testEmptyInputFails") {
                guard case .failed = parse("").outcome else {
                    throw TestFailure(message: "leere Datei muss fehlschlagen", file: #file, line: #line)
                }
            }

            runner.runTest(name: "testMissingCommaReportsPosition") {
                let r = parse("{\n  \"a\": 1\n  \"b\": 2\n}")
                guard case .failed(let at) = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                try assertEqual(at.line, 3)
            }

            runner.runTest(name: "testPartialTreeSurvivesFailure") {
                // Kern der Fehlertoleranz: was bis zum Bruch gelesen wurde,
                // muss erhalten bleiben -- sonst zeigt die Vorschau nichts.
                let r = parse(#"{"gut":1,"kaputt":}"#)
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                try assertTrue(r.root != nil, "Teilbaum muss erhalten bleiben")
                try assertTrue(try keys(r.root).contains("gut"))
            }

            runner.runTest(name: "testTrailingContentHintsAtJSONLines") {
                let r = parse("{\"a\":1}\n{\"b\":2}")
                guard case .failed = r.outcome else {
                    throw TestFailure(message: "haette fehlschlagen muessen", file: #file, line: #line)
                }
                let text = r.diagnostics.map(\.message).joined(separator: " ")
                try assertTrue(text.contains("JSON Lines"),
                               "Hinweis auf JSON Lines fehlt: \(text)")
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: Übersetzungsfehler — `JSONParser` und `ParseLimits` unbekannt.

- [ ] **Step 3: `ParseLimits` und das Parser-Gerüst schreiben**

`Sources/LoupeCore/JSON/JSONParser.swift`:

```swift
import Foundation

/// Grenzen aus Spec §7. Werte sind dort begruendet und gelten als Vertrag.
public struct ParseLimits: Sendable {
    public var maxBytes: Int
    public var maxNodes: Int
    public var maxChildrenPerContainer: Int
    public var maxDepth: Int
    public var maxStringDisplayLength: Int

    public init(maxBytes: Int = 20 * 1024 * 1024,
                maxNodes: Int = 20_000,
                maxChildrenPerContainer: Int = 1_000,
                maxDepth: Int = 64,
                maxStringDisplayLength: Int = 4096) {
        self.maxBytes = maxBytes
        self.maxNodes = maxNodes
        self.maxChildrenPerContainer = maxChildrenPerContainer
        self.maxDepth = maxDepth
        self.maxStringDisplayLength = maxStringDisplayLength
    }
}

public struct JSONParser {
    private var lexer: JSONLexer
    private let limits: ParseLimits
    private let wasTruncatedByReader: Bool

    private var lookahead: Token?
    private var diagnostics: [Diagnostic] = []
    private var nodeCount = 0
    private var hitLimit: LimitKind?

    /// Letzter vollstaendig gelesener Wert je Ebene -- traegt den Teilbaum,
    /// falls weiter unten etwas bricht.
    private var partialRoot: JSONValue?

    public init(bytes: [UInt8],
                limits: ParseLimits = ParseLimits(),
                wasTruncatedByReader: Bool = false) {
        self.lexer = JSONLexer(bytes: bytes)
        self.limits = limits
        self.wasTruncatedByReader = wasTruncatedByReader
    }

    private mutating func peek() throws -> Token {
        if let t = lookahead { return t }
        let t = try lexer.next()
        lookahead = t
        return t
    }

    private mutating func advance() throws -> Token {
        let t = try peek()
        lookahead = nil
        return t
    }

    public mutating func parse() -> ParseResult {
        do {
            let first = try peek()
            if first.kind == .endOfInput {
                diagnostics.append(Diagnostic(severity: .error,
                                              message: "Die Datei ist leer.",
                                              position: first.position))
                return ParseResult(root: nil, outcome: .failed(at: first.position),
                                   diagnostics: diagnostics)
            }
            let root = try parseValue(depth: 0)
            partialRoot = root

            let trailing = try peek()
            if trailing.kind != .endOfInput {
                // Direkt nach einem vollstaendigen Wert kommt noch Inhalt --
                // der klassische JSON-Lines-Fall. Das ist eine hilfreichere
                // Meldung als "unerwartetes Zeichen".
                diagnostics.append(Diagnostic(
                    severity: .error,
                    message: "Inhalt nach dem Ende des Dokuments — möglicherweise JSON Lines?",
                    position: trailing.position))
                return ParseResult(root: root, outcome: .failed(at: trailing.position),
                                   diagnostics: diagnostics)
            }
            return ParseResult(root: root, outcome: finalOutcome(), diagnostics: diagnostics)
        } catch let e as LexError {
            return failure(message: e.message, at: e.position)
        } catch let e as ParseError {
            return failure(message: e.message, at: e.position)
        } catch {
            return failure(message: "Unerwarteter Fehler beim Lesen.",
                           at: Position(line: 1, column: 1, offset: 0))
        }
    }

    /// Wenn WIR gekuerzt haben, ist die Datei nicht kaputt -- nur unvollstaendig
    /// gelesen. Diese Unterscheidung ist der Kern von Spec §8.
    private func finalOutcome() -> ParseOutcome {
        if let kind = hitLimit { return .truncatedByLimit(kind) }
        if wasTruncatedByReader { return .truncatedByLimit(.bytes) }
        return .complete
    }

    private mutating func failure(message: String, at position: Position) -> ParseResult {
        if wasTruncatedByReader {
            // Der Bruch ist Folge UNSERER Kuerzung, nicht eines Dateifehlers.
            diagnostics.append(Diagnostic(
                severity: .notice,
                message: "Datei bei \(limits.maxBytes / (1024 * 1024)) MB abgeschnitten — der Rest wurde nicht gelesen.",
                position: position))
            return ParseResult(root: partialRoot, outcome: .truncatedByLimit(.bytes),
                               diagnostics: diagnostics)
        }
        diagnostics.append(Diagnostic(severity: .error, message: message, position: position))
        return ParseResult(root: partialRoot, outcome: .failed(at: position),
                           diagnostics: diagnostics)
    }
}

struct ParseError: Error {
    let message: String
    let position: Position
}
```

- [ ] **Step 4: `parseValue`, `parseObject`, `parseArray` ergänzen**

```swift
extension JSONParser {

    mutating func parseValue(depth: Int) throws -> JSONValue {
        nodeCount += 1
        let token = try advance()
        switch token.kind {
        case .braceOpen:    return try parseObject(depth: depth + 1, at: token.position)
        case .bracketOpen:  return try parseArray(depth: depth + 1, at: token.position)
        case .string(let s):  return .string(s)
        case .number(let n):  return .number(n)
        case .literalTrue:    return .bool(true)
        case .literalFalse:   return .bool(false)
        case .literalNull:    return .null
        case .braceClose, .bracketClose, .colon, .comma:
            throw ParseError(message: "Wert erwartet", position: token.position)
        case .endOfInput:
            throw ParseError(message: "Datei endet unerwartet — Wert erwartet",
                             position: token.position)
        }
    }

    mutating func parseObject(depth: Int, at open: Position) throws -> JSONValue {
        var members: [Member] = []
        if try peek().kind == .braceClose {
            _ = try advance()
            return .object(members: [], omitted: 0)
        }
        while true {
            let keyToken = try advance()
            guard case .string(let key) = keyToken.kind else {
                throw ParseError(message: "Schlüssel in Anführungszeichen erwartet",
                                 position: keyToken.position)
            }
            let colon = try advance()
            guard colon.kind == .colon else {
                throw ParseError(message: "':' nach dem Schlüssel erwartet",
                                 position: colon.position)
            }
            let value = try parseValue(depth: depth)
            members.append(Member(key: key, value: value))

            let sep = try advance()
            if sep.kind == .braceClose { break }
            guard sep.kind == .comma else {
                throw ParseError(message: "Komma erwartet, ',' oder '}' fehlt",
                                 position: sep.position)
            }
            // Nachgestelltes Komma vor } ist laut JSON ungueltig.
            if try peek().kind == .braceClose {
                let brace = try advance()
                throw ParseError(message: "Komma vor '}' ist nicht erlaubt",
                                 position: brace.position)
            }
        }
        return .object(members: members, omitted: 0)
    }

    mutating func parseArray(depth: Int, at open: Position) throws -> JSONValue {
        var items: [JSONValue] = []
        if try peek().kind == .bracketClose {
            _ = try advance()
            return .array(items: [], omitted: 0)
        }
        while true {
            items.append(try parseValue(depth: depth))
            let sep = try advance()
            if sep.kind == .bracketClose { break }
            guard sep.kind == .comma else {
                throw ParseError(message: "Komma erwartet, ',' oder ']' fehlt",
                                 position: sep.position)
            }
            if try peek().kind == .bracketClose {
                let bracket = try advance()
                throw ParseError(message: "Komma vor ']' ist nicht erlaubt",
                                 position: bracket.position)
            }
        }
        return .array(items: items, omitted: 0)
    }
}
```

> **Zum Teilbaum bei Fehlern:** `partialRoot` wird in `parse()` erst nach dem
> vollständigen Wurzelwert gesetzt — das genügt für `testTrailingContentHints…`,
> **nicht** für `testPartialTreeSurvivesFailure`, wo der Bruch *innerhalb* der
> Wurzel liegt. Dafür muss `parseObject` seine bis dahin gelesenen `members`
> beim Werfen mitgeben. Lösung: `ParseError` um ein Feld erweitern und in
> `parseObject`/`parseArray` beim Werfen befüllen:
>
> ```swift
> struct ParseError: Error {
>     let message: String
>     let position: Position
>     var partial: JSONValue? = nil
> }
> ```
>
> In `parseObject` jedes `throw ParseError(...)` ersetzen durch
> `throw ParseError(message: ..., position: ..., partial: .object(members: members, omitted: 0))`,
> in `parseArray` analog mit `.array(items: items, omitted: 0)`. In `parse()`
> im `catch let e as ParseError`-Zweig vor dem `failure(...)`-Aufruf
> `if partialRoot == nil { partialRoot = e.partial }` setzen.
>
> ⚠️ **Das genügt NICHT** (Feldbefund 2026-09-22, vom Test gefunden): der Bruch in
> `{"gut":1,"kaputt":}` entsteht in **`parseValue`**, das seinen eigenen
> `ParseError` **ohne** `partial` wirft — keine der vier obigen Stellen wird je
> erreicht. Deshalb müssen `parseObject` und `parseArray` ihre rekursiven
> `parseValue`-Aufrufe zusätzlich umschließen und das bis dahin Gelesene
> nachtragen, wenn noch niemand tiefer eines gesetzt hat:
>
> ```swift
> do {
>     value = try parseValue(depth: depth)
> } catch var e as ParseError {
>     if e.partial == nil { e.partial = .object(members: members, omitted: 0) }
>     throw e
> }
> ```
>
> (in `parseArray` analog mit `.array(items: items, omitted: 0)`).
>
> **Bekannte Grenze, bewusst akzeptiert:** bei mehrfacher Verschachtelung kommt so
> der INNERSTE Container heraus, nicht der vollständige Pfad zur Wurzel. Für einen
> Betrachter tragbar, weil das Fehlerbanner Zeile, Spalte und Quelltext-Ausschnitt
> ohnehin zeigt — der Fund ist also lokalisiert, auch wenn der Teilbaum ein
> Fragment ist.

- [ ] **Step 5: `main.swift` erweitern, Tests grün sehen**

`JSONParserTests.run()` in `Tests/LoupeTests/main.swift` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün, darunter die 9 neuen der Parser-Suite.

- [ ] **Step 6: Mutationsprobe**

1. In `parseObject` die `members` vor der Rückgabe mit
   `members.sorted { $0.key < $1.key }` sortieren → `testKeyOrderIsSourceOrder`
   muss fallen. **Das ist die wichtigste Probe des Projekts.**
2. In `parse()` den Zweig für nachgestellten Inhalt entfernen →
   `testTrailingContentHintsAtJSONLines` muss fallen.
3. In `failure(...)` `root: partialRoot` durch `root: nil` ersetzen →
   `testPartialTreeSurvivesFailure` muss fallen.

Jede Mutation einzeln, `md5 -q` vorher/nachher, danach `git checkout --`.

- [ ] **Step 7: Committen**

```bash
git add -A
git commit -m "feat: recursive-descent JSON parser preserving source order

Objects keep source key order and duplicate keys. A parse failure still
returns the partial tree, and content after a complete value is reported
as a possible JSON Lines file rather than an unexplained syntax error."
```

---

### Task 5: Die Grenzen — Tiefe, Knoten, Kinder, Stringlänge

> Die Tiefenbremse ist **keine Bequemlichkeit, sondern eine Lücke**: ein
> rekursiver Parser stirbt an `[[[[[…`, und 100.000 Ebenen sind eine
> **100-KB-Datei**. Ohne diese Aufgabe bringt eine so kleine Datei die
> Erweiterung zum Absturz.

**Files:**
- Modify: `Sources/LoupeCore/JSON/JSONParser.swift`
- Modify: `Tests/LoupeTests/JSONParserTests.swift`

**Interfaces:**
- Consumes: `ParseLimits`, `JSONParser` (Task 4)
- Produces: keine neuen Typen. `ParseResult.outcome` liefert nun
  `.truncatedByLimit(.depth | .nodes | .children | .stringLength)`, und
  Container tragen ein von null verschiedenes `omitted`.

- [ ] **Step 1: Die fehlschlagenden Tests schreiben**

In `JSONParserTests.run()` ergänzen — die Suite heißt weiterhin `JSONParser`:

```swift
            runner.runTest(name: "testDepthBombDoesNotCrash") {
                // 100.000 Ebenen sind ~100 KB. Ohne Bremse stirbt der Prozess
                // am Stapelueberlauf -- der Test wuerde nicht rot, sondern
                // die ganze Suite abbrechen.
                let deep = String(repeating: "[", count: 100_000)
                let r = parse(deep)
                try assertEqual(r.outcome, .truncatedByLimit(.depth))
            }

            runner.runTest(name: "testDepthLimitIsExactlySixtyFour") {
                func nested(_ n: Int) -> String {
                    String(repeating: "[", count: n) + "1" + String(repeating: "]", count: n)
                }
                try assertEqual(parse(nested(60)).outcome, .complete)
                try assertEqual(parse(nested(200)).outcome, .truncatedByLimit(.depth))
            }

            runner.runTest(name: "testChildrenLimitTruncatesAndCounts") {
                let items = (0 ..< 1500).map(String.init).joined(separator: ",")
                let r = parse("[\(items)]")
                guard case .array(let kept, let omitted)? = r.root else {
                    throw TestFailure(message: "kein Array", file: #file, line: #line)
                }
                try assertEqual(kept.count, 1000)
                // Die Zahl muss STIMMEN -- sie steht spaeter so in der Anzeige.
                try assertEqual(omitted, 500)
                try assertEqual(r.outcome, .truncatedByLimit(.children))
            }

            runner.runTest(name: "testNodeLimitStopsBuilding") {
                var limits = ParseLimits()
                limits.maxNodes = 50
                let items = (0 ..< 500).map(String.init).joined(separator: ",")
                let r = parse("[\(items)]", limits: limits)
                try assertEqual(r.outcome, .truncatedByLimit(.nodes))
                try assertTrue(r.root != nil, "Teilbaum muss stehen bleiben")
            }

            runner.runTest(name: "testLongStringIsTruncatedForDisplay") {
                var limits = ParseLimits()
                limits.maxStringDisplayLength = 16
                let long = String(repeating: "x", count: 100)
                let r = parse("{\"a\":\"\(long)\"}", limits: limits)
                guard case .object(let members, _)? = r.root,
                      case .string(let s) = members[0].value else {
                    throw TestFailure(message: "Struktur falsch", file: #file, line: #line)
                }
                try assertLessThan(s.count, 100)
                try assertEqual(r.outcome, .truncatedByLimit(.stringLength))
            }

            runner.runTest(name: "testTruncationIsNotReportedAsFailure") {
                // Eine GUELTIGE Datei, die WIR gekuerzt haben, darf nie als
                // kaputt erscheinen. Sonst luegt die Vorschau ueber die Datei.
                let r = parse(#"{"a":1,"b"#, truncated: true)
                guard case .truncatedByLimit = r.outcome else {
                    throw TestFailure(message: "als Fehler gemeldet statt als Kuerzung",
                                      file: #file, line: #line)
                }
                try assertFalse(r.diagnostics.contains { $0.severity == .error },
                                "Kuerzung darf keine Fehlermeldung erzeugen")
            }
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: die sechs neuen Tests fallen.
⚠ `testDepthBombDoesNotCrash` wird die Suite an dieser Stelle voraussichtlich
**abstürzen lassen** statt rot zu werden — genau das ist der Befund. Notiere
ihn; nach Step 3 muss derselbe Test sauber durchlaufen.

- [ ] **Step 3: Grenzen im Parser verdrahten**

In `JSONParser` ein Hilfsmittel und vier Prüfstellen. Zuerst in `parseValue`,
**vor** der Rekursion:

```swift
    mutating func parseValue(depth: Int) throws -> JSONValue {
        if depth > limits.maxDepth {
            noteLimit(.depth)
            try skipValue()            // Rest dieses Zweigs verwerfen, nicht absteigen
            return .null
        }
        if nodeCount >= limits.maxNodes {
            noteLimit(.nodes)
            try skipValue()
            return .null
        }
        nodeCount += 1
        let token = try advance()
        switch token.kind {
        case .braceOpen:   return try parseObject(depth: depth + 1, at: token.position)
        case .bracketOpen: return try parseArray(depth: depth + 1, at: token.position)
        case .string(let s):
            if s.count > limits.maxStringDisplayLength {
                noteLimit(.stringLength)
                return .string(String(s.prefix(limits.maxStringDisplayLength)) + "…")
            }
            return .string(s)
        case .number(let n): return .number(n)
        case .literalTrue:   return .bool(true)
        case .literalFalse:  return .bool(false)
        case .literalNull:   return .null
        case .braceClose, .bracketClose, .colon, .comma:
            throw ParseError(message: "Wert erwartet", position: token.position)
        case .endOfInput:
            throw ParseError(message: "Datei endet unerwartet — Wert erwartet",
                             position: token.position)
        }
    }

    /// Merkt sich die ERSTE greifende Grenze. Spaetere ueberschreiben sie nicht --
    /// die erste erklaert, warum das Ergebnis unvollstaendig ist.
    private mutating func noteLimit(_ kind: LimitKind) {
        if hitLimit == nil { hitLimit = kind }
    }

    // ⚠️ Rangfolge in `failure()` (Feldbefund + Entscheid 2026-09-22, in DIESER
    // Reihenfolge -- eine fruehere Fassung dieser Notiz sagte das Gegenteil und
    // war falsch):
    //   1. wasTruncatedByReader -> .truncatedByLimit(.bytes) + Notiz.
    //      Dort ist der Bruch Folge UNSERES Schnitts, nicht der Datei.
    //   2. echter Wurf -> .failed(at:) + Fehlermeldung, PLUS Notiz falls
    //      zusaetzlich eine Grenze griff. Ein Syntaxfehler ist handlungsfaehig,
    //      eine Grenzen-Notiz ist blosse Information -- und die fruehere
    //      Rangfolge liess die Fehlermeldung RESTLOS verschwinden.
    //   3. sauberer Rueckweg mit hitLimit -> `finalOutcome()`, unveraendert.
    // Folge, gewollt: 100.000 UNGESCHLOSSENE Klammern melden `.failed` (die Datei
    // ist wirklich kaputt), 100.000 GESCHLOSSENE melden `.truncatedByLimit(.depth)`.

    /// Ueberspringt einen Wert, ohne einen Baum zu bauen -- ITERATIV.
    /// Rekursives Ueberspringen haette genau den Stapelueberlauf, den die
    /// Tiefenbremse verhindern soll.
    private mutating func skipValue() throws {
        var openContainers = 0
        repeat {
            let token = try advance()
            switch token.kind {
            case .braceOpen, .bracketOpen:   openContainers += 1
            case .braceClose, .bracketClose: openContainers -= 1
            case .endOfInput:                return
            default:                         break
            }
        } while openContainers > 0
    }
```

In `parseObject` und `parseArray` die Kinder-Grenze. Für `parseArray`:

```swift
        var items: [JSONValue] = []
        var omitted = 0
        // ...
        while true {
            let value = try parseValue(depth: depth)
            if items.count < limits.maxChildrenPerContainer {
                items.append(value)
            } else {
                omitted += 1
                noteLimit(.children)
            }
            // ... Trennzeichen wie in Task 4
        }
        return .array(items: items, omitted: omitted)
```

Für `parseObject` genauso mit `members` und `Member(key:value:)`.

⚠ **Wichtig:** Bei überschrittener Kinder-Grenze wird weiter **gelesen** (damit
die Zahl in `omitted` stimmt und die Datei korrekt zu Ende geparst wird), nur
nicht mehr **gespeichert**. Würde man abbrechen, stünde in `omitted` eine
geratene Zahl — und geratene Zahlen in der Anzeige sind schlimmer als keine.

- [ ] **Step 4: Tests grün sehen — besonders die Tiefenbombe**

Run: `swift run LoupeTests`
Expected: alle grün. `testDepthBombDoesNotCrash` läuft durch, ohne den
Prozess zu beenden.

- [ ] **Step 5: Mutationsprobe**

1. `if depth > limits.maxDepth` → `if depth > 1_000_000` → die Tiefenbombe
   stürzt wieder ab (Absturz zählt als „rot", aber notiere ihn als solchen).
2. In `parseArray` `omitted += 1` entfernen → `testChildrenLimitTruncatesAndCounts`
   muss fallen (Zahl stimmt nicht mehr).
3. ⚠️ **Nicht** `finalOutcome()` mutieren — diese Probe ist BLIND (Feldbefund
   2026-09-22): das Szenario von `testTruncationIsNotReportedAsFailure` WIRFT und
   laeuft damit ueber `failure()`, nicht ueber `finalOutcome()`. Die Mutation
   liesse den Test gruen und gaukelte eine Zusicherung vor, die es nicht gibt.
   Richtig ist der `if wasTruncatedByReader`-Zweig in **`failure()`** → dann faellt
   der Test. **Lehre: eine Mutation, die man nicht hat zuenden sehen, prueft
   nichts — sie prueft nur, dass man die falsche Zeile getroffen hat.**
4. `skipValue` rekursiv statt iterativ machen → Tiefenbombe stürzt ab.

- [ ] **Step 6: Committen**

```bash
git add -A
git commit -m "feat: enforce parser limits including a depth guard

A 100 KB file of 100,000 nested brackets crashes a recursive parser; the
depth guard turns it into a reported truncation. Skipping is iterative for
the same reason. Children beyond the limit are still read so the omitted
count is exact rather than guessed."
```

---

### Task 6: Fehlerdiagnostik mit Quelltext-Ausschnitt

**Files:**
- Create: `Sources/LoupeCore/JSON/SourceExcerpt.swift`
- Create: `Tests/LoupeTests/SourceExcerptTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: `Position` (Task 2)
- Produces: `SourceExcerpt.make(bytes:around:contextLines:) -> [ExcerptLine]`
  mit `ExcerptLine { number: Int, text: String, caretColumn: Int? }` — von
  Task 9 zum Rendern des Fehlerbanners gebraucht.

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/SourceExcerptTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum SourceExcerptTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("SourceExcerpt") {

            runner.runTest(name: "testExcerptShowsContextAndCaret") {
                let src = "{\n  \"version\": \"1.0.0\"\n  \"private\": true\n}"
                let lines = SourceExcerpt.make(bytes: Array(src.utf8),
                                               around: Position(line: 3, column: 3, offset: 0),
                                               contextLines: 1)
                try assertEqual(lines.map(\.number), [2, 3])
                try assertEqual(lines[1].caretColumn, 3)
                try assertEqual(lines[0].caretColumn, nil)
                try assertTrue(lines[1].text.contains("private"))
            }

            runner.runTest(name: "testExcerptAtFirstLineDoesNotUnderflow") {
                let lines = SourceExcerpt.make(bytes: Array("{}".utf8),
                                               around: Position(line: 1, column: 1, offset: 0),
                                               contextLines: 2)
                try assertEqual(lines.map(\.number), [1])
            }

            runner.runTest(name: "testVeryLongLineIsClipped") {
                // Eine minifizierte JSON-Datei ist EINE Zeile mit Millionen
                // Zeichen. Ungeklippt legt sie das Fehlerbanner lahm.
                let long = "{\"a\":" + String(repeating: "1", count: 5000) + "}"
                let lines = SourceExcerpt.make(bytes: Array(long.utf8),
                                               around: Position(line: 1, column: 4000, offset: 0),
                                               contextLines: 0)
                try assertLessThan(lines[0].text.count, 400)
                // Der Zeiger muss trotz Klippung auf die richtige Stelle zeigen.
                try assertTrue(lines[0].caretColumn != nil)
                try assertLessThan(lines[0].caretColumn!, lines[0].text.count + 1)
            }

            runner.runTest(name: "testTabsBecomeSpacesSoCaretAligns") {
                // Ein Tab ist EIN Zeichen, wird aber breit dargestellt --
                // der Zeiger stuende sonst falsch.
                let lines = SourceExcerpt.make(bytes: Array("\t\tx".utf8),
                                               around: Position(line: 1, column: 3, offset: 0),
                                               contextLines: 0)
                try assertFalse(lines[0].text.contains("\t"))
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `SourceExcerpt` unbekannt.

- [ ] **Step 3: Implementieren**

`Sources/LoupeCore/JSON/SourceExcerpt.swift`:

```swift
import Foundation

public struct ExcerptLine: Equatable, Sendable {
    public let number: Int
    public let text: String
    /// 1-basierte Spalte im BEREITS geklippten Text, oder nil.
    public let caretColumn: Int?
}

public enum SourceExcerpt {
    /// Maximale Breite einer Ausschnittszeile. Minifiziertes JSON ist eine
    /// einzige Zeile mit Millionen Zeichen -- ungeklippt unbrauchbar.
    public static let maxLineWidth = 200

    public static func make(bytes: [UInt8],
                            around position: Position,
                            contextLines: Int = 1) -> [ExcerptLine] {
        let all = String(decoding: bytes, as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false)
        guard !all.isEmpty else { return [] }

        let first = max(1, position.line - contextLines)
        let last  = min(all.count, position.line + contextLines)
        guard first <= last else { return [] }

        return (first ... last).map { number in
            // Tabs vor dem Klippen ersetzen, sonst verschiebt sich der Zeiger.
            let raw = String(all[number - 1]).replacingOccurrences(of: "\t", with: "    ")
            let isCaretLine = number == position.line
            guard raw.count > maxLineWidth else {
                return ExcerptLine(number: number, text: raw,
                                   caretColumn: isCaretLine ? min(position.column, raw.count + 1) : nil)
            }
            // Fenster um die Fehlerstelle legen, nicht stumpf vorne abschneiden.
            let centre = isCaretLine ? position.column : 1
            let start = max(0, min(centre - maxLineWidth / 2, raw.count - maxLineWidth))
            let clipped = String(raw.dropFirst(start).prefix(maxLineWidth))
            let prefix = start > 0 ? "…" : ""
            return ExcerptLine(number: number,
                               text: prefix + clipped,
                               caretColumn: isCaretLine
                                   ? max(1, centre - start + prefix.count)
                                   : nil)
        }
    }
}
```

- [ ] **Step 4: `main.swift` erweitern, Tests grün sehen**

`SourceExcerptTests.run()` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün.

- [ ] **Step 5: Mutationsprobe**

1. `max(1, position.line - contextLines)` → `position.line - contextLines` →
   `testExcerptAtFirstLineDoesNotUnderflow` muss fallen.
2. Die Tab-Ersetzung entfernen → `testTabsBecomeSpacesSoCaretAligns` muss fallen.
3. Die Klippung entfernen → `testVeryLongLineIsClipped` muss fallen.

- [ ] **Step 6: Committen**

```bash
git add -A
git commit -m "feat: source excerpts with a caret for parse errors

Long lines are windowed around the error instead of cut from the front,
because minified JSON is a single line of millions of characters. Tabs
are expanded first so the caret lands where the eye expects it."
```

---

### Task 7: `HTMLEscape` und `LoupeSettings`

**Files:**
- Modify: `Sources/LoupeCore/Configuration/LoupeSettings.swift` (ersetzt den Platzhalter aus Task 1)
- Create: `Tests/LoupeTests/HTMLEscapeTests.swift`
- Create: `Tests/LoupeTests/SettingsTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: nichts
- Produces: `HTMLEscape.escape(_ text: String) -> String`;
  `LoupeSettings` mit `appearance`, `textSize`, `expansionLineBudget`,
  `showTypeBadges`, plus `load()`/`save()` und
  `LoupeAppearance`, `LoupeTextSize`

- [ ] **Step 1: Die fehlschlagenden Tests schreiben**

`Tests/LoupeTests/HTMLEscapeTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum HTMLEscapeTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("HTMLEscape") {

            runner.runTest(name: "testEscapesAllFiveDangerousCharacters") {
                try assertEqual(HTMLEscape.escape("&"), "&amp;")
                try assertEqual(HTMLEscape.escape("<"), "&lt;")
                try assertEqual(HTMLEscape.escape(">"), "&gt;")
                try assertEqual(HTMLEscape.escape("\""), "&quot;")
                try assertEqual(HTMLEscape.escape("'"), "&#39;")
            }

            runner.runTest(name: "testAmpersandEscapedFirst") {
                // Wuerde & zuletzt ersetzt, entstuende aus < erst &lt; und
                // daraus &amp;lt; -- sichtbarer Muell.
                try assertEqual(HTMLEscape.escape("<a>"), "&lt;a&gt;")
            }

            runner.runTest(name: "testScriptInJSONStringIsNeutralised") {
                // Ein JSON-String DARF <script> enthalten. Escaped ist er Text.
                let out = HTMLEscape.escape("<script>alert(1)</script>")
                try assertFalse(out.contains("<script"))
                try assertTrue(out.contains("&lt;script&gt;"))
            }

            runner.runTest(name: "testUnicodeAndEmojiSurviveUnchanged") {
                try assertEqual(HTMLEscape.escape("äöü 😀 日本語"), "äöü 😀 日本語")
            }
        }
    }
}
```

`Tests/LoupeTests/SettingsTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum SettingsTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("LoupeSettings") {

            runner.runTest(name: "testDefaults") {
                let s = LoupeSettings()
                try assertEqual(s.appearance, .system)
                try assertEqual(s.textSize, .standard)
                // Vertragswert aus Spec §6.
                try assertEqual(s.expansionLineBudget, 300)
                try assertTrue(s.showTypeBadges)
            }

            runner.runTest(name: "testRoundTripThroughJSON") {
                var s = LoupeSettings()
                s.appearance = .dark
                s.expansionLineBudget = 42
                let data = try JSONEncoder().encode(s)
                let back = try JSONDecoder().decode(LoupeSettings.self, from: data)
                try assertEqual(back, s)
            }

            runner.runTest(name: "testAppGroupConstants") {
                try assertEqual(LoupeSettings.appGroupSuiteName, "group.io.celox.loupe")
                try assertEqual(LoupeSettings.settingsKey, "io.celox.loupe.settings")
            }

            runner.runTest(name: "testTextSizeFontSizes") {
                try assertEqual(LoupeTextSize.small.baseFontSizePx, 12)
                try assertEqual(LoupeTextSize.standard.baseFontSizePx, 13)
                try assertEqual(LoupeTextSize.large.baseFontSizePx, 15)
            }
        }
    }
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `HTMLEscape` unbekannt, `LoupeSettings` hat die Felder nicht.

- [ ] **Step 3: `HTMLEscape` gegenprüfen (die Datei existiert bereits)**

⚠ `Sources/LoupeCore/Render/HTMLEscape.swift` wurde in **Task 1 vorgezogen** — dort
schreibt die Erweiterung einen Dateinamen ins HTML, und ein Dateiname ist ein fremder
Eingabewert. Nicht neu anlegen. Prüfe, dass der Bestand exakt der folgenden Fassung
entspricht, und korrigiere Abweichungen:

```swift
import Foundation

/// Bewusste Kopie aus MarkLooks HTMLSanitizer.
///
/// ⚠ Diese 15 Zeilen liegen in zwei Repos. Eine Korrektur hier erreicht
/// MarkLook NICHT von selbst (siehe Spec §9).
public enum HTMLEscape {
    public static func escape(_ text: String) -> String {
        var result = String()
        result.reserveCapacity(text.count + 20)
        for char in text {
            switch char {
            case "&":  result.append("&amp;")
            case "<":  result.append("&lt;")
            case ">":  result.append("&gt;")
            case "\"": result.append("&quot;")
            case "'":  result.append("&#39;")
            default:   result.append(char)
            }
        }
        return result
    }
}
```

Zeichenweises Durchgehen umgeht die Reihenfolgefalle von `replacingOccurrences`
strukturell — es gibt keine zweite Ersetzungsrunde, die eine erste anfassen
könnte.

- [ ] **Step 4: `LoupeSettings` schreiben**

`Sources/LoupeCore/Configuration/LoupeSettings.swift` (ersetzt den Platzhalter):

```swift
import Foundation

public enum LoupeAppearance: String, CaseIterable, Codable, Equatable, Sendable {
    case system, light, dark

    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Hell"
        case .dark:   return "Dunkel"
        }
    }
}

public enum LoupeTextSize: String, CaseIterable, Codable, Equatable, Sendable {
    case small, standard, large

    public var displayName: String {
        switch self {
        case .small:    return "Klein"
        case .standard: return "Standard"
        case .large:    return "Groß"
        }
    }

    /// Kleiner als bei MarkLook: der Baum ist durchgehend Monospace,
    /// und Monospace traegt bei gleicher Punktgroesse breiter auf.
    public var baseFontSizePx: Int {
        switch self {
        case .small: return 12
        case .standard: return 13
        case .large: return 15
        }
    }
}

public struct LoupeSettings: Codable, Equatable, Sendable {
    public var appearance: LoupeAppearance
    public var textSize: LoupeTextSize
    /// Sichtbare Zeilen, die beim Oeffnen aufgeklappt sein duerfen (Spec §6).
    public var expansionLineBudget: Int
    public var showTypeBadges: Bool

    public static let appGroupSuiteName = "group.io.celox.loupe"
    public static let settingsKey = "io.celox.loupe.settings"

    public init(appearance: LoupeAppearance = .system,
                textSize: LoupeTextSize = .standard,
                expansionLineBudget: Int = 300,
                showTypeBadges: Bool = true) {
        self.appearance = appearance
        self.textSize = textSize
        self.expansionLineBudget = expansionLineBudget
        self.showTypeBadges = showTypeBadges
    }

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }

    public static func load() -> LoupeSettings {
        let defaults = sharedDefaults
        if let data = defaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(LoupeSettings.self, from: data) {
            return settings
        }
        return LoupeSettings()
    }

    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            Self.sharedDefaults.set(data, forKey: Self.settingsKey)
        }
    }
}
```

- [ ] **Step 5: `main.swift` erweitern, Tests grün sehen**

`HTMLEscapeTests.run()` und `SettingsTests.run()` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün.

- [ ] **Step 6: Mutationsprobe**

1. Den `case "&"`-Zweig in `escape` entfernen →
   `testEscapesAllFiveDangerousCharacters` muss fallen.
2. `expansionLineBudget: Int = 300` → `= 100` → `testDefaults` muss fallen.

- [ ] **Step 7: Committen**

```bash
git add -A
git commit -m "feat: HTML escaping and settings model

Escaping walks characters once instead of running replacement passes, so
the ordering trap where & re-escapes earlier output cannot occur."
```

---

### Task 8: `CSSGenerator` — Theme, Farbrollen, gemessener Kontrast

**Files:**
- Create: `Sources/LoupeCore/Theme/CSSGenerator.swift`
- Create: `Tests/LoupeTests/CSSGeneratorTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: `LoupeSettings`, `LoupeAppearance`, `LoupeTextSize` (Task 7)
- Produces: `CSSGenerator.generateCSS(settings:) -> String`. Die Klassennamen,
  die Task 9 erzeugt, sind hier definiert: `.lp-tree`, `.lp-node`, `.lp-key`,
  `.lp-str`, `.lp-num`, `.lp-bool`, `.lp-null`, `.lp-count`, `.lp-peek`,
  `.lp-omitted`, `.lp-banner`, `.lp-banner-error`, `.lp-banner-notice`,
  `.lp-excerpt`, `.lp-caret`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/CSSGeneratorTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum CSSGeneratorTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("CSSGenerator") {

            runner.runTest(name: "testSystemAppearanceEmitsBothThemes") {
                var s = LoupeSettings(); s.appearance = .system
                let css = CSSGenerator.generateCSS(settings: s)
                try assertTrue(css.contains("prefers-color-scheme: dark"),
                               "System-Modus braucht die Media-Query")
            }

            runner.runTest(name: "testFixedAppearanceOmitsMediaQuery") {
                // Bei fester Wahl darf die OS-Einstellung NICHT mitreden --
                // sonst kippt ein auf hell gestelltes Fenster nachts um.
                var s = LoupeSettings(); s.appearance = .light
                let css = CSSGenerator.generateCSS(settings: s)
                try assertFalse(css.contains("prefers-color-scheme"))
            }

            runner.runTest(name: "testAllRenderClassesArePresent") {
                let css = CSSGenerator.generateCSS(settings: LoupeSettings())
                for cls in [".lp-tree", ".lp-node", ".lp-key", ".lp-str", ".lp-num",
                            ".lp-bool", ".lp-null", ".lp-count", ".lp-peek",
                            ".lp-omitted", ".lp-banner", ".lp-excerpt", ".lp-caret"] {
                    try assertTrue(css.contains(cls), "fehlt: \(cls)")
                }
            }

            runner.runTest(name: "testTextSizeReachesTheCSS") {
                var s = LoupeSettings(); s.textSize = .large
                try assertTrue(CSSGenerator.generateCSS(settings: s).contains("15px"))
            }

            runner.runTest(name: "testNoJavaScriptAnywhere") {
                // Die Doktrin des Projekts, hier festgenagelt.
                let css = CSSGenerator.generateCSS(settings: LoupeSettings())
                try assertFalse(css.lowercased().contains("<script"))
                try assertFalse(css.lowercased().contains("javascript:"))
            }

            runner.runTest(name: "testTreeIsMonospace") {
                let css = CSSGenerator.generateCSS(settings: LoupeSettings())
                try assertTrue(css.contains("ui-monospace") || css.contains("SFMono"))
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `CSSGenerator` unbekannt.

- [ ] **Step 3: Implementieren**

`Sources/LoupeCore/Theme/CSSGenerator.swift`. Aufbau wie bei MarkLook: zwei
Variablenblöcke, danach die Regeln. Die Farbrollen sind neu (Spec §6):

```swift
import Foundation

public enum CSSGenerator {

    private static let lightVars = """
        --bg: #ffffff;
        --bg-alt: #f6f8fa;
        --text: #1d1d1f;
        --text-dim: #5b5e69;
        --border: #e5e5ea;
        --key:  #0b5fb0;
        --str:  #b3261e;
        --num:  #1c00cf;
        --bool: #7a3ea3;
        --null: #5b5e69;
        --count: #5b5e69;
        --err-bg: rgba(255, 59, 48, 0.06);
        --err-fg: #a5251c;
        --note-bg: rgba(0, 113, 227, 0.06);
        --note-fg: #0a5aa8;
    """

    private static let darkVars = """
        --bg: #1e1e1e;
        --bg-alt: #28282b;
        --text: #f5f5f7;
        --text-dim: #a1a1a6;
        --border: #38383a;
        --key:  #7ab8ff;
        --str:  #ff8170;
        --num:  #dabaff;
        --bool: #d8a0ff;
        --null: #a1a1a6;
        --count: #a1a1a6;
        --err-bg: rgba(255, 69, 58, 0.10);
        --err-fg: #ff8a80;
        --note-bg: rgba(10, 132, 255, 0.12);
        --note-fg: #7ab8ff;
    """

    public static func generateCSS(settings: LoupeSettings) -> String {
        let size = settings.textSize.baseFontSizePx
        let vars: String
        switch settings.appearance {
        case .light:
            vars = ":root {\n\(lightVars)\n}"
        case .dark:
            vars = ":root {\n\(darkVars)\n}"
        case .system:
            // Nur im System-Modus darf die OS-Einstellung mitreden.
            vars = """
            :root {
            \(lightVars)
            }
            @media (prefers-color-scheme: dark) {
                :root {
                \(darkVars)
                }
            }
            """
        }

        return """
        \(vars)

        * { box-sizing: border-box; }
        body {
            margin: 0;
            padding: 20px 24px;
            background: var(--bg);
            color: var(--text);
            font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
            font-size: \(size)px;
            line-height: 1.55;
            -webkit-font-smoothing: antialiased;
        }

        .lp-tree { white-space: nowrap; }
        .lp-node { padding-left: 1.35em; }
        .lp-tree > .lp-node { padding-left: 0; }

        details > summary {
            cursor: default;
            list-style: none;
            border-radius: 5px;
            padding: 1px 4px;
            margin-left: -4px;
        }
        details > summary::-webkit-details-marker { display: none; }
        details > summary::before {
            content: "\\25B8";
            display: inline-block;
            width: 1em;
            color: var(--text-dim);
            transition: transform 120ms ease;
        }
        details[open] > summary::before { transform: rotate(90deg); }
        details > summary:hover { background: var(--bg-alt); }
        details > summary:focus-visible {
            outline: 2px solid var(--key);
            outline-offset: 1px;
        }

        .lp-key  { color: var(--key); }
        .lp-str  { color: var(--str); }
        .lp-num  { color: var(--num); }
        .lp-bool { color: var(--bool); }
        .lp-null { color: var(--null); font-style: italic; }

        .lp-count, .lp-peek { color: var(--count); }
        .lp-peek::before { content: " · "; }

        .lp-omitted {
            color: var(--text-dim);
            font-style: italic;
            padding-left: 1.35em;
        }

        .lp-banner {
            border-radius: 8px;
            padding: 12px 14px;
            margin-bottom: 16px;
            border: 1px solid var(--border);
            white-space: normal;
        }
        .lp-banner-error  { background: var(--err-bg);  color: var(--err-fg); }
        .lp-banner-notice { background: var(--note-bg); color: var(--note-fg); }

        .lp-excerpt {
            margin: 10px 0 0;
            padding: 8px 10px;
            background: var(--bg-alt);
            border-radius: 6px;
            color: var(--text);
            overflow-x: auto;
            white-space: pre;
        }
        .lp-caret { color: var(--err-fg); font-weight: 700; }

        @media (prefers-reduced-motion: reduce) {
            details > summary::before { transition: none; }
        }
        """
    }
}
```

- [ ] **Step 4: `main.swift` erweitern, Tests grün sehen**

`CSSGeneratorTests.run()` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün.

- [ ] **Step 5: Kontraste MESSEN, nicht schätzen**

⚠ Hausregel: Farbwerte werden im laufenden Browser gemessen. Die obigen Werte
sind ein **Vorschlag**, kein Nachweis.

Vorgehen: Task 11 liefert die erste echte Vorschau. Sobald sie steht, eine
JSON-Datei mit allen fünf Werttypen öffnen und je Rolle den Kontrast gegen den
tatsächlichen Hintergrund messen — **Farbe auf ein Canvas rastern und das Pixel
lesen**, nicht per Regex aus `getComputedStyle` zerlegen (Chrome liefert real
`color(srgb 0.7 0.72 1)`, eine Ziffernsuche liest daraus Unsinn).

Grenzen: **4,5:1** für Text. Jede Rolle in **beiden** Themes prüfen. Unterschreitet
eine, die Variable anheben und den gemessenen Wert als Kommentar an die Zeile
schreiben.

⚠ **Gegenprobe:** Das Messwerkzeug einmal gegen eine absichtlich zu blasse Farbe
laufen lassen (z. B. `--null: #cccccc` im hellen Theme) und sehen, dass es
anschlägt. Ein Werkzeug, das null meldet, ist erst nach der Gegenprobe
glaubwürdig.

Diese Messung ist ein **Eintrag in Task 13**, nicht hier abschließbar — hier
wird nur festgehalten, dass sie aussteht.

- [ ] **Step 6: Mutationsprobe**

1. Im `.system`-Zweig die Media-Query entfernen →
   `testSystemAppearanceEmitsBothThemes` muss fallen.
2. Im `.light`-Zweig die Media-Query **hinzufügen** →
   `testFixedAppearanceOmitsMediaQuery` muss fallen.
3. `.lp-peek` aus dem CSS löschen → `testAllRenderClassesArePresent` muss fallen.

- [ ] **Step 7: Committen**

```bash
git add -A
git commit -m "feat: CSS generator with colour roles for JSON value types

A fixed light or dark choice deliberately omits the prefers-color-scheme
query: otherwise a window pinned to light flips at night. Contrast values
are proposals until measured in a browser (tracked in the final task)."
```

---

### Task 9: `JSONTreeRenderer` — Baum zu verschachtelten `<details>`

**Files:**
- Create: `Sources/LoupeCore/Render/JSONTreeRenderer.swift`
- Create: `Tests/LoupeTests/JSONTreeRendererTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: `JSONValue`, `Member`, `ParseResult`, `Diagnostic`, `ParseOutcome`
  (Task 2); `ExcerptLine`, `SourceExcerpt` (Task 6); `HTMLEscape` (Task 7);
  die CSS-Klassen aus Task 8
- Produces: `JSONTreeRenderer` mit
  `init(settings: LoupeSettings, openPaths: Set<[Int]>)` und
  `func renderBody(_ result: ParseResult, sourceBytes: [UInt8]) -> String`

> `openPaths` kommt aus Task 10. In dieser Aufgabe wird es durchgereicht und
> getestet, berechnet wird es noch nicht.

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/JSONTreeRendererTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum JSONTreeRendererTests {

    static func render(_ text: String, open: Set<[Int]> = []) -> String {
        var parser = JSONParser(bytes: Array(text.utf8))
        let result = parser.parse()
        let renderer = JSONTreeRenderer(settings: LoupeSettings(), openPaths: open)
        return renderer.renderBody(result, sourceBytes: Array(text.utf8))
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("JSONTreeRenderer") {

            runner.runTest(name: "testContainersBecomeDetailsElements") {
                let html = render(#"{"a":{"b":1}}"#)
                try assertTrue(html.contains("<details"))
                try assertTrue(html.contains("<summary"))
            }

            runner.runTest(name: "testScalarsAreNotCollapsible") {
                // Ein Skalar hat nichts zum Aufklappen -- ein <details> darum
                // waere ein Bedienelement, das nichts tut.
                let html = render(#"{"a":1}"#)
                try assertEqual(html.components(separatedBy: "<details").count - 1, 1)
            }

            runner.runTest(name: "testKeyOrderSurvivesIntoHTML") {
                let html = render(#"{"zebra":1,"alpha":2}"#)
                guard let z = html.range(of: "zebra"), let a = html.range(of: "alpha") else {
                    throw TestFailure(message: "Schluessel fehlen", file: #file, line: #line)
                }
                try assertTrue(z.lowerBound < a.lowerBound, "Reihenfolge verdreht")
            }

            runner.runTest(name: "testCollapsedSummaryCarriesCountAndPeek") {
                // Ein blosses "scripts" waere wertlos -- Typ, Anzahl und ein
                // Blick auf den Inhalt machen den Unterschied (Spec §6).
                let html = render(#"{"scripts":{"build":1,"test":2,"lint":3}}"#)
                try assertTrue(html.contains("3"), "Anzahl fehlt")
                try assertTrue(html.contains("lp-count"), "Zaehler-Klasse fehlt")
                try assertTrue(html.contains("lp-peek"), "Vorschau-Klasse fehlt")
                try assertTrue(html.contains("build"), "Vorschau nennt keinen Schluessel")
            }

            runner.runTest(name: "testOpenPathsControlTheOpenAttribute") {
                let closed = render(#"{"a":{"b":1}}"#, open: [])
                let opened = render(#"{"a":{"b":1}}"#, open: [[], [0]])
                try assertFalse(closed.contains("<details open"))
                try assertTrue(opened.contains("<details open"))
            }

            runner.runTest(name: "testValueTypesGetTheirClasses") {
                let html = render(#"{"s":"x","n":1,"b":true,"z":null}"#)
                for cls in ["lp-str", "lp-num", "lp-bool", "lp-null", "lp-key"] {
                    try assertTrue(html.contains(cls), "fehlt: \(cls)")
                }
            }

            runner.runTest(name: "testScriptTagInStringIsEscaped") {
                let html = render("{\"a\":\"<script>alert(1)</script>\"}")
                try assertFalse(html.contains("<script>"))
                try assertTrue(html.contains("&lt;script&gt;"))
            }

            runner.runTest(name: "testKeyWithAngleBracketsIsEscaped") {
                // Auch der SCHLUESSEL muss escaped werden, nicht nur der Wert.
                let html = render("{\"<img>\":1}")
                try assertFalse(html.contains("<img>"))
            }

            runner.runTest(name: "testOmittedChildrenAreDeclared") {
                let items = (0 ..< 1500).map(String.init).joined(separator: ",")
                let html = render("[\(items)]")
                try assertTrue(html.contains("lp-omitted"), "Marker fehlt")
                try assertTrue(html.contains("500"), "Anzahl der Ausgelassenen fehlt")
            }

            runner.runTest(name: "testParseErrorRendersBannerWithExcerpt") {
                let html = render("{\n  \"a\": 1\n  \"b\": 2\n}")
                try assertTrue(html.contains("lp-banner-error"))
                try assertTrue(html.contains("lp-excerpt"))
                try assertTrue(html.contains("lp-caret"))
                // Der Teilbaum muss trotz Fehler dastehen.
                try assertTrue(html.contains("\"a\"") || html.contains("&quot;a&quot;")
                               || html.contains("lp-key"))
            }

            runner.runTest(name: "testTruncationUsesNoticeNotError") {
                // Eine von UNS gekuerzte Datei ist nicht kaputt.
                var parser = JSONParser(bytes: Array(#"{"a":1,"b"#.utf8),
                                        wasTruncatedByReader: true)
                let result = parser.parse()
                let html = JSONTreeRenderer(settings: LoupeSettings(), openPaths: [])
                    .renderBody(result, sourceBytes: [])
                try assertTrue(html.contains("lp-banner-notice"))
                try assertFalse(html.contains("lp-banner-error"))
            }

            runner.runTest(name: "testNoJavaScriptInOutput") {
                let html = render(#"{"a":[1,2,3]}"#)
                try assertFalse(html.lowercased().contains("<script"))
                try assertFalse(html.lowercased().contains("onclick"))
                try assertFalse(html.lowercased().contains("javascript:"))
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `JSONTreeRenderer` unbekannt.

- [ ] **Step 3: Implementieren**

`Sources/LoupeCore/Render/JSONTreeRenderer.swift`:

```swift
import Foundation

public struct JSONTreeRenderer {
    private let settings: LoupeSettings
    private let openPaths: Set<[Int]>

    public init(settings: LoupeSettings, openPaths: Set<[Int]> = []) {
        self.settings = settings
        self.openPaths = openPaths
    }

    public func renderBody(_ result: ParseResult, sourceBytes: [UInt8]) -> String {
        var out = banner(for: result, sourceBytes: sourceBytes)
        if let root = result.root {
            out += "<div class=\"lp-tree\">\n"
            out += node(root, label: nil, path: [])
            out += "</div>\n"
        }
        return out
    }

    // MARK: - Banner

    private func banner(for result: ParseResult, sourceBytes: [UInt8]) -> String {
        switch result.outcome {
        case .complete:
            return ""
        case .truncatedByLimit(let kind):
            // KEIN Fehler -- wir haben gekuerzt, die Datei ist in Ordnung.
            return """
            <div class="lp-banner lp-banner-notice">\(HTMLEscape.escape(noticeText(kind)))</div>
            """
        case .failed(let position):
            let message = result.diagnostics.last(where: { $0.severity == .error })?.message
                ?? "Die Datei konnte nicht vollständig gelesen werden."
            var html = "<div class=\"lp-banner lp-banner-error\">"
            html += "Zeile \(position.line), Spalte \(position.column): "
            html += HTMLEscape.escape(message)
            let lines = SourceExcerpt.make(bytes: sourceBytes, around: position, contextLines: 1)
            if !lines.isEmpty {
                html += "<div class=\"lp-excerpt\">"
                for line in lines {
                    let number = String(format: "%4d", line.number)
                    html += "\(number) │ \(HTMLEscape.escape(line.text))\n"
                    if let caret = line.caretColumn {
                        html += "     │ \(String(repeating: " ", count: max(0, caret - 1)))"
                        html += "<span class=\"lp-caret\">^</span>\n"
                    }
                }
                html += "</div>"
            }
            html += "</div>"
            return html
        }
    }

    private func noticeText(_ kind: LimitKind) -> String {
        switch kind {
        case .bytes:  return "Datei abgeschnitten — nur der Anfang wurde gelesen. Die Datei selbst ist in Ordnung."
        case .nodes:  return "Sehr großes Dokument — nur ein Teil des Baums wird dargestellt."
        case .children: return "Sehr große Listen — je Container werden höchstens 1.000 Einträge dargestellt."
        case .depth:  return "Sehr tief verschachtelt — ab Ebene 64 wird nicht weiter dargestellt."
        case .stringLength: return "Sehr lange Textwerte wurden für die Anzeige gekürzt."
        }
    }

    // MARK: - Knoten

    /// `label` ist der Schluessel (Objekt), der Index (Array) oder nil (Wurzel).
    private func node(_ value: JSONValue, label: String?, path: [Int]) -> String {
        let prefix = label.map { "<span class=\"lp-key\">\(HTMLEscape.escape($0))</span> : " } ?? ""

        switch value {
        case .null:
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-null\">null</span></div>\n"
        case .bool(let b):
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-bool\">\(b)</span></div>\n"
        case .number(let n):
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-num\">\(HTMLEscape.escape(n))</span></div>\n"
        case .string(let s):
            let escaped = HTMLEscape.escape(s)
            return "<div class=\"lp-node\">\(prefix)<span class=\"lp-str\">\"\(escaped)\"</span></div>\n"

        case .array(let items, let omitted):
            let open = openPaths.contains(path) ? " open" : ""
            var html = "<details class=\"lp-node\"\(open)><summary>"
            html += prefix + "[ ] <span class=\"lp-count\">\(items.count + omitted) Einträge</span>"
            html += peek(arrayItems: items)
            html += "</summary>\n"
            for (index, item) in items.enumerated() {
                html += node(item, label: String(index), path: path + [index])
            }
            if omitted > 0 {
                html += "<div class=\"lp-omitted\">… \(omitted) weitere Einträge nicht dargestellt</div>\n"
            }
            html += "</details>\n"
            return html

        case .object(let members, let omitted):
            let open = openPaths.contains(path) ? " open" : ""
            var html = "<details class=\"lp-node\"\(open)><summary>"
            html += prefix + "{ } <span class=\"lp-count\">\(members.count + omitted) Schlüssel</span>"
            html += peek(objectMembers: members)
            html += "</summary>\n"
            for (index, member) in members.enumerated() {
                html += node(member.value, label: member.key, path: path + [index])
            }
            if omitted > 0 {
                html += "<div class=\"lp-omitted\">… \(omitted) weitere Schlüssel nicht dargestellt</div>\n"
            }
            html += "</details>\n"
            return html
        }
    }

    // MARK: - Vorschau in der zugeklappten Zeile

    /// Ohne diesen Blick muesste man jeden Knoten oeffnen, um zu wissen,
    /// ob er interessant ist (Spec §6).
    private func peek(objectMembers members: [Member]) -> String {
        guard settings.showTypeBadges, !members.isEmpty else { return "" }
        let names = members.prefix(3).map { HTMLEscape.escape($0.key) }
        let more = members.count > 3 ? ", …" : ""
        return "<span class=\"lp-peek\">\(names.joined(separator: ", "))\(more)</span>"
    }

    private func peek(arrayItems items: [JSONValue]) -> String {
        guard settings.showTypeBadges, !items.isEmpty else { return "" }
        let shown = items.prefix(3).map(shortDescription)
        let more = items.count > 3 ? ", …" : ""
        return "<span class=\"lp-peek\">\(shown.joined(separator: ", "))\(more)</span>"
    }

    private func shortDescription(_ value: JSONValue) -> String {
        switch value {
        case .null:            return "null"
        case .bool(let b):     return "\(b)"
        case .number(let n):   return HTMLEscape.escape(n)
        case .string(let s):   return "\"" + HTMLEscape.escape(String(s.prefix(18))) + (s.count > 18 ? "…\"" : "\"")
        case .array(let i, let o):   return "[\(i.count + o)]"
        case .object(let m, let o):  return "{\(m.count + o)}"
        }
    }
}
```

⚠ **Rekursion:** `node` ruft sich selbst auf. Die Tiefe ist durch die
Parser-Bremse aus Task 5 auf 64 begrenzt — der Renderer kann gar keinen
tieferen Baum bekommen. **Diese Abhängigkeit ist tragend:** wird die
Tiefengrenze je erhöht, muss der Renderer mitbedacht werden.

- [ ] **Step 4: `main.swift` erweitern, Tests grün sehen**

`JSONTreeRendererTests.run()` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün, darunter die 12 neuen.

- [ ] **Step 5: Mutationsprobe**

1. In `node` den `peek(...)`-Aufruf für Objekte entfernen →
   `testCollapsedSummaryCarriesCountAndPeek` muss fallen.
2. `HTMLEscape.escape($0)` im `prefix` durch `$0` ersetzen →
   `testKeyWithAngleBracketsIsEscaped` muss fallen.
3. Im `.truncatedByLimit`-Zweig `lp-banner-notice` durch `lp-banner-error`
   ersetzen → `testTruncationUsesNoticeNotError` muss fallen.
4. `openPaths.contains(path) ? " open" : ""` durch `" open"` ersetzen →
   `testOpenPathsControlTheOpenAttribute` muss fallen.

- [ ] **Step 6: Committen**

```bash
git add -A
git commit -m "feat: render JSON trees as nested details elements

Collapsed rows carry type, count and a peek at the contents, because a
bare key name forces you to open every node to find out whether it is
interesting. Truncation renders as a notice, never as an error."
```

---

### Task 10: Zeilenbudget — welche Knoten beim Öffnen aufgeklappt sind

> Spec §6: **nicht nach fester Tiefe**, sondern Breitensuche bis ~300 sichtbare
> Zeilen. Feste Tiefe versagt genau dort, wo es zählt — ein flaches Array mit
> 2.000 Einträgen ist „Ebene 1" und stünde komplett offen.

**Files:**
- Create: `Sources/LoupeCore/Render/ExpansionPolicy.swift`
- Create: `Tests/LoupeTests/ExpansionPolicyTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: `JSONValue` (Task 2)
- Produces: `ExpansionPolicy.plan(root:budget:) -> Set<[Int]>` — genau die
  Menge, die Task 9 als `openPaths` erwartet

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/ExpansionPolicyTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum ExpansionPolicyTests {

    static func parse(_ text: String) -> JSONValue {
        var p = JSONParser(bytes: Array(text.utf8))
        return p.parse().root ?? .null
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("ExpansionPolicy") {

            runner.runTest(name: "testSmallDocumentOpensCompletely") {
                // Eine package.json soll offen dastehen, nicht zugeklappt.
                let root = parse(#"{"a":{"b":{"c":1}},"d":[1,2]}"#)
                let open = ExpansionPolicy.plan(root: root, budget: 300)
                try assertTrue(open.contains([]),    "Wurzel zu")
                try assertTrue(open.contains([0]),   "a zu")
                try assertTrue(open.contains([0,0]), "b zu")
                try assertTrue(open.contains([1]),   "d zu")
            }

            runner.runTest(name: "testFlatArrayBeyondBudgetStaysClosed") {
                // Genau der Fall, an dem feste Tiefe scheitert: Ebene 1,
                // aber 2.000 Zeilen.
                let items = (0 ..< 2000).map(String.init).joined(separator: ",")
                let root = parse("[\(items)]")
                let open = ExpansionPolicy.plan(root: root, budget: 300)
                try assertFalse(open.contains([]), "Riesenarray haette zu bleiben muessen")
            }

            runner.runTest(name: "testBreadthFirstPrefersUpperLevels") {
                // Bei knappem Budget sind die oberen Ebenen wertvoller --
                // sie geben den Ueberblick.
                var deep = "1"
                for _ in 0 ..< 20 { deep = "{\"x\":\(deep)}" }
                let root = parse(deep)
                let open = ExpansionPolicy.plan(root: root, budget: 5)
                try assertTrue(open.contains([]), "Wurzel muss offen sein")
                try assertFalse(open.contains(Array(repeating: 0, count: 19)),
                                "tiefste Ebene darf nicht offen sein")
            }

            runner.runTest(name: "testBudgetIsRespected") {
                // Summe der Kinder aller geoeffneten Container = sichtbare Zeilen.
                let items = (0 ..< 40).map { "{\"k\($0)\":[1,2,3,4,5]}" }.joined(separator: ",")
                let root = parse("[\(items)]")
                let open = ExpansionPolicy.plan(root: root, budget: 60)
                var visible = 0
                func count(_ v: JSONValue, _ path: [Int]) {
                    guard open.contains(path) else { return }
                    switch v {
                    case .array(let xs, _):
                        visible += xs.count
                        for (i, x) in xs.enumerated() { count(x, path + [i]) }
                    case .object(let ms, _):
                        visible += ms.count
                        for (i, m) in ms.enumerated() { count(m.value, path + [i]) }
                    default: break
                    }
                }
                count(root, [])
                try assertTrue(visible <= 60, "Budget ueberschritten: \(visible)")
            }

            runner.runTest(name: "testScalarRootYieldsEmptyPlan") {
                try assertEqual(ExpansionPolicy.plan(root: parse("42"), budget: 300).count, 0)
            }

            runner.runTest(name: "testZeroBudgetOpensNothing") {
                let root = parse(#"{"a":1}"#)
                try assertEqual(ExpansionPolicy.plan(root: root, budget: 0).count, 0)
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `ExpansionPolicy` unbekannt.

- [ ] **Step 3: Implementieren**

`Sources/LoupeCore/Render/ExpansionPolicy.swift`:

```swift
import Foundation

public enum ExpansionPolicy {

    /// Liefert die Pfade der Container, die beim Oeffnen aufgeklappt sein
    /// sollen. Ein Pfad ist die Folge der Kindindizes ab der Wurzel;
    /// die Wurzel selbst ist der leere Pfad.
    ///
    /// Breitensuche statt fester Tiefe: bei knappem Budget sind die oberen
    /// Ebenen wertvoller, und ein flaches Riesenarray bleibt zu, obwohl es
    /// auf Ebene 1 liegt.
    public static func plan(root: JSONValue, budget: Int) -> Set<[Int]> {
        var open: Set<[Int]> = []
        var spent = 0
        var queue: [(path: [Int], value: JSONValue)] = [([], root)]
        var head = 0

        while head < queue.count {
            let (path, value) = queue[head]
            head += 1

            let children: [(Int, JSONValue)]
            switch value {
            case .array(let items, _):
                children = Array(items.enumerated())
            case .object(let members, _):
                children = members.enumerated().map { ($0.offset, $0.element.value) }
            default:
                continue                     // Skalare kosten nichts und sind nie "offen"
            }

            // Ein geoeffneter Container zeigt eine Zeile je Kind.
            let cost = children.count
            guard spent + cost <= budget else { continue }

            open.insert(path)
            spent += cost
            for (index, child) in children {
                queue.append((path + [index], child))
            }
        }
        return open
    }
}
```

⚠ **`continue`, nicht `break`:** Passt ein großer Container nicht mehr ins
Budget, bleibt er zu — aber ein *kleinerer* Geschwisterknoten dahinter darf
durchaus noch aufgehen. Ein `break` würde die Suche beenden und die restliche
Ebene grundlos zuklappen.

⚠ Die Warteschlange wächst nur um Kinder **geöffneter** Container. Ein
zugeklappter Knoten reiht seine Kinder nicht ein — sonst liefe der Planer über
den gesamten Baum, obwohl sein Ergebnis längst feststeht.

- [ ] **Step 4: `main.swift` erweitern, Tests grün sehen**

`ExpansionPolicyTests.run()` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün.

- [ ] **Step 5: Mutationsprobe**

1. `guard spent + cost <= budget else { continue }` → `else { break }` →
   `testBudgetIsRespected` oder `testSmallDocumentOpensCompletely` muss fallen.
2. Die Prüfung ganz entfernen → `testFlatArrayBeyondBudgetStaysClosed` muss fallen.
3. Die Warteschlange in eine Tiefensuche umbauen (`queue.insert(..., at: head)`) →
   `testBreadthFirstPrefersUpperLevels` muss fallen.

- [ ] **Step 6: Committen**

```bash
git add -A
git commit -m "feat: breadth-first expansion planning within a line budget

Fixed depth fails exactly where it matters: a flat array of 2000 entries
is level one and would open in full. The budget counts visible rows, so a
package.json opens completely and a large export shows its upper levels."
```

---

### Task 11: Registry, `.appex`-Verdrahtung und der erste echte Durchlauf

**Files:**
- Create: `Sources/LoupeCore/Preview/JSONPreviewRenderer.swift`
- Create: `Sources/LoupeCore/Preview/RendererRegistry.swift`
- Create: `Sources/LoupeCore/Preview/HTMLDocument.swift`
- Modify: `Sources/LoupePreview/PreviewProvider.swift` (ersetzt die Hallo-Ausgabe aus Task 1)
- Create: `Tests/LoupeTests/RegistryTests.swift`
- Create: `Tests/Fixtures/package.json`, `Tests/Fixtures/broken.json`, `Tests/Fixtures/unicode.json`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: alles aus den Tasks 2–10
- Produces: `JSONPreviewRenderer` (erfüllt `PreviewRenderer`),
  `RendererRegistry.renderer(for: UTType) -> (any PreviewRenderer)?`,
  `HTMLDocument.wrap(body:title:css:) -> String`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/RegistryTests.swift`:

```swift
import Foundation
import UniformTypeIdentifiers
import LoupeCore

@MainActor
public enum RegistryTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("Registry & Document") {

            runner.runTest(name: "testJSONTypeResolvesToJSONRenderer") {
                try assertTrue(RendererRegistry.renderer(for: .json) != nil)
            }

            runner.runTest(name: "testUnknownTypeResolvesToNil") {
                try assertTrue(RendererRegistry.renderer(for: .mp3) == nil)
            }

            runner.runTest(name: "testDocumentCarriesTheExactCSP") {
                let html = HTMLDocument.wrap(body: "<p>x</p>", title: "t", css: "")
                // Mit schliessendem Anfuehrungszeichen geprueft: ein blosses
                // contains() wuerde ein angehaengtes ";" durchwinken, und genau
                // dieser Fehler ist in Task 1 real aufgetreten.
                try assertTrue(html.contains(
                    "content=\"default-src 'none'; style-src 'unsafe-inline'; img-src 'none'\""))
            }

            runner.runTest(name: "testDocumentEscapesTheTitle") {
                let html = HTMLDocument.wrap(body: "", title: "<script>x</script>", css: "")
                try assertFalse(html.contains("<script>x"))
            }

            runner.runTest(name: "testEndToEndRenderOfRealFile") {
                let json = #"{"name":"loupe","keywords":["json","macos"],"private":true}"#
                let input = PreviewInput(data: Data(json.utf8),
                                         url: URL(fileURLWithPath: "/tmp/package.json"),
                                         wasTruncatedByReader: false)
                let html = JSONPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.hasPrefix("<!DOCTYPE html>"))
                try assertTrue(html.contains("<details"))
                try assertTrue(html.contains("loupe"))
                try assertFalse(html.lowercased().contains("<script"))
            }

            runner.runTest(name: "testInvalidUTF8DoesNotCrash") {
                // Rohbytes, die kein gueltiges UTF-8 sind. Erwartung:
                // eine Antwort, kein Absturz.
                let input = PreviewInput(data: Data([0xFF, 0xFE, 0x00, 0x7B]),
                                         url: URL(fileURLWithPath: "/tmp/x.json"),
                                         wasTruncatedByReader: false)
                let html = JSONPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.contains("<!DOCTYPE html>"))
            }

            runner.runTest(name: "testEmptyFileRendersBannerNotBlankPage") {
                let input = PreviewInput(data: Data(),
                                         url: URL(fileURLWithPath: "/tmp/e.json"),
                                         wasTruncatedByReader: false)
                let html = JSONPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.contains("lp-banner"))
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `RendererRegistry`, `HTMLDocument`, `JSONPreviewRenderer` unbekannt.

- [ ] **Step 3: `HTMLDocument` schreiben**

`Sources/LoupeCore/Preview/HTMLDocument.swift`:

```swift
import Foundation

public enum HTMLDocument {
    /// Die CSP steht an genau EINER Stelle. Jede Kopie waere eine Stelle,
    /// an der sie versehentlich abweichen kann.
    public static let contentSecurityPolicy =
        "default-src 'none'; style-src 'unsafe-inline'; img-src 'none'"

    public static func wrap(body: String, title: String, css: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="Content-Security-Policy" content="\(contentSecurityPolicy)">
            <title>\(HTMLEscape.escape(title))</title>
            <style>
        \(css)
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
```

- [ ] **Step 4: `JSONPreviewRenderer` und die Registry schreiben**

`Sources/LoupeCore/Preview/JSONPreviewRenderer.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

public struct JSONPreviewRenderer: PreviewRenderer {
    public static var supportedTypes: [UTType] { [.json] }

    public init() {}

    public func renderHTML(input: PreviewInput, settings: LoupeSettings) -> String {
        let bytes = [UInt8](input.data)
        var parser = JSONParser(bytes: bytes,
                                limits: ParseLimits(),
                                wasTruncatedByReader: input.wasTruncatedByReader)
        let result = parser.parse()

        let openPaths = result.root.map {
            ExpansionPolicy.plan(root: $0, budget: settings.expansionLineBudget)
        } ?? []

        let body = JSONTreeRenderer(settings: settings, openPaths: openPaths)
            .renderBody(result, sourceBytes: bytes)

        return HTMLDocument.wrap(body: body,
                                 title: input.url.lastPathComponent,
                                 css: CSSGenerator.generateCSS(settings: settings))
    }
}
```

`Sources/LoupeCore/Preview/RendererRegistry.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

/// Die Naht fuer weitere Formate. Markdown wird spaeter EIN Eintrag mehr.
public enum RendererRegistry {
    private static let all: [any PreviewRenderer] = [
        JSONPreviewRenderer()
    ]

    public static func renderer(for type: UTType) -> (any PreviewRenderer)? {
        all.first { candidate in
            Swift.type(of: candidate).supportedTypes.contains {
                // Gleichheit ZUERST: ob conforms(to:) einen Typ als zu sich
                // selbst konform meldet, ist eine Annahme ueber Apples
                // Implementierung -- die Gleichheit ist es nicht.
                type == $0 || type.conforms(to: $0)
            }
        }
    }
}
```

⚠ `conforms(to:)` zusätzlich zur Gleichheit: ein abgeleiteter Typ (etwa ein
eigener UTType, der auf `public.json` aufsetzt) wird so mit abgedeckt, ohne
ihn einzeln zu listen. Die Gleichheitsprüfung davor ist bewusst kein
Doppelmoppel — sie macht den häufigsten Fall unabhängig davon, wie Apple
Selbstkonformität behandelt.

- [ ] **Step 5: Die `.appex` verdrahten**

`Sources/LoupePreview/PreviewProvider.swift` — ersetzt Task 1 vollständig:

```swift
import Foundation
import QuickLookUI
import UniformTypeIdentifiers
import LoupeCore

@objc(PreviewProvider)
public final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    private static let maxBytes = ParseLimits().maxBytes

    public override init() { super.init() }

    public func providePreview(
        for request: QLFilePreviewRequest,
        completionHandler: @escaping (QLPreviewReply?, (any Error)?) -> Void
    ) {
        let url = request.fileURL
        let settings = LoupeSettings.load()

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attributes[.size] as? Int) ?? 0

            let data: Data
            let truncated: Bool
            if size > Self.maxBytes {
                // Nur den Anfang lesen -- und dem Parser SAGEN, dass wir
                // gekuerzt haben, sonst meldet er die Datei als kaputt.
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }
                data = handle.readData(ofLength: Self.maxBytes)
                truncated = true
            } else {
                data = try Data(contentsOf: url)
                truncated = false
            }

            let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? .json
            guard let renderer = RendererRegistry.renderer(for: type) else {
                completionHandler(nil, CocoaError(.fileReadUnsupportedScheme))
                return
            }

            let input = PreviewInput(data: data, url: url, wasTruncatedByReader: truncated)
            let html = renderer.renderHTML(input: input, settings: settings)

            let reply = QLPreviewReply(dataOfContentType: .html,
                                       contentSize: CGSize(width: 840, height: 640)) { _ in
                html.data(using: .utf8) ?? Data()
            }
            reply.title = url.lastPathComponent
            completionHandler(reply, nil)
        } catch {
            let body = """
            <div class="lp-banner lp-banner-error">Die Datei konnte nicht gelesen werden: \
            \(HTMLEscape.escape(error.localizedDescription))</div>
            """
            let html = HTMLDocument.wrap(body: body,
                                         title: url.lastPathComponent,
                                         css: CSSGenerator.generateCSS(settings: settings))
            let reply = QLPreviewReply(dataOfContentType: .html,
                                       contentSize: CGSize(width: 520, height: 300)) { _ in
                html.data(using: .utf8) ?? Data()
            }
            completionHandler(reply, nil)
        }
    }
}
```

- [ ] **Step 6: Fixtures anlegen**

```bash
mkdir -p Tests/Fixtures
cat > Tests/Fixtures/package.json <<'EOF'
{
  "name": "loupe",
  "version": "0.1.0",
  "private": true,
  "scripts": { "build": "swift build", "test": "swift run LoupeTests" },
  "keywords": ["quicklook", "json", "macos"],
  "nested": { "a": { "b": { "c": [1, 2, 3] } } }
}
EOF
printf '{\n  "a": 1\n  "b": 2\n}\n' > Tests/Fixtures/broken.json
printf '{"grüße":"äöü 😀 日本語","pfad":"C:\\\\tmp"}\n' > Tests/Fixtures/unicode.json
```

- [ ] **Step 7: `main.swift` erweitern, Tests grün sehen**

`RegistryTests.run()` ergänzen.

Run: `swift run LoupeTests`
Expected: alle grün.

- [ ] **Step 8: Der erste echte Durchlauf im Finder**

```bash
./Scripts/install_app.sh
cp Tests/Fixtures/package.json Tests/Fixtures/broken.json Tests/Fixtures/unicode.json ~/Desktop/
```

Im Finder jede der drei Dateien auswählen, **Leertaste**, und prüfen:

| Datei | Erwartung |
|---|---|
| `package.json` | Baum offen, `scripts` und `nested` aufklappbar, Klicken funktioniert |
| `broken.json` | Rotes Banner „Zeile 3, Spalte 3", Ausschnitt mit Zeiger, **`"a": 1` trotzdem sichtbar** |
| `unicode.json` | Umlaute, Emoji und CJK korrekt; der Backslash-Pfad als `C:\tmp` |

- [ ] **Step 9: Kontraste messen (der offene Punkt aus Task 8)**

Jetzt existiert eine echte Vorschau. Kontraste beider Themes messen wie in
Task 8 Step 5 beschrieben — **Farbe auf Canvas rastern**, Hintergrund über die
Vorfahren komponieren, Grenze 4,5:1. Gegenprobe mit einer absichtlich zu
blassen Farbe nicht vergessen. Unterschreitungen in `CSSGenerator.swift`
korrigieren und den gemessenen Wert als Kommentar an die Zeile schreiben.

- [ ] **Step 10: Mutationsprobe**

Die Global Constraint gilt auch hier — sieben neue Pins, drei Proben:

1. In `HTMLDocument.wrap` `HTMLEscape.escape(title)` durch `title` ersetzen →
   `testDocumentEscapesTheTitle` muss fallen.
2. In `RendererRegistry.renderer(for:)` `all.first { … }` durch `all.first`
   ersetzen (liefert immer den JSON-Renderer) → `testUnknownTypeResolvesToNil`
   muss fallen.
3. In `JSONPreviewRenderer.renderHTML` `wasTruncatedByReader: input.wasTruncatedByReader`
   durch `wasTruncatedByReader: false` ersetzen → ein Test in der Parser-Suite
   oder `testEmptyFileRendersBannerNotBlankPage` muss reagieren; **tut das
   keiner, ist das ein blinder Fleck** — dann einen Pin ergänzen, der genau
   diese Weitergabe prüft (sonst könnte die Kürzungs-Erkennung Ende-zu-Ende
   tot sein, während die Suite grün bleibt).

Jede Mutation einzeln, `md5 -q` vorher/nachher, danach `git checkout --`.

- [ ] **Step 11: Committen**

```bash
rm -f ~/Desktop/package.json ~/Desktop/broken.json ~/Desktop/unicode.json
git add -A
git commit -m "feat: wire the JSON renderer into the Quick Look extension

The reader tells the parser when it truncated, so a valid 50 MB file is
reported as truncated rather than broken. The CSP lives in exactly one
place."
```

---

### Task 12: Begleit-App

**Files:**
- Create: `Sources/LoupeCore/Utilities/ExtensionStatusChecker.swift`
- Create: `Sources/Loupe/App/AppDelegate.swift`
- Create: `Sources/Loupe/UI/MainViewController.swift`
- Modify: `Sources/Loupe/main.swift` (ersetzt das Gerüst aus Task 1)
- Create: `Tests/LoupeTests/ExtensionStatusTests.swift`
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: `LoupeSettings` (Task 7)
- Produces: `ExtensionStatus`, `ExtensionStatusChecker.checkStatus()`

> **YAGNI (Spec §12):** kein Live-Editor. Die App trägt die Erweiterung, zeigt
> deren Status und die Einstellungen. Mehr braucht sie nicht.

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/LoupeTests/ExtensionStatusTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum ExtensionStatusTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("ExtensionStatus") {

            runner.runTest(name: "testTitles") {
                try assertEqual(ExtensionStatus.active.title, "Installiert und aktiv")
                try assertEqual(ExtensionStatus.installed.title, "Installiert, aber deaktiviert")
                try assertEqual(ExtensionStatus.notInstalled.title, "Nicht registriert")
            }

            runner.runTest(name: "testIsOperational") {
                try assertTrue(ExtensionStatus.active.isOperational)
                try assertTrue(ExtensionStatus.installed.isOperational)
                try assertFalse(ExtensionStatus.notInstalled.isOperational)
            }

            runner.runTest(name: "testBundleIdConstant") {
                try assertEqual(ExtensionStatusChecker.extensionBundleId, "io.celox.loupe.preview")
            }

            runner.runTest(name: "testParsesPluginkitOutput") {
                // Reine Auswertung, ohne Prozessaufruf -- damit der Test
                // auf jeder Maschine dasselbe tut.
                try assertEqual(
                    ExtensionStatusChecker.interpret("+    io.celox.loupe.preview(0.1.0)\t…"),
                    .active)
                try assertEqual(
                    ExtensionStatusChecker.interpret("!    io.celox.loupe.preview(0.1.0)\t…"),
                    .installed)
                try assertEqual(ExtensionStatusChecker.interpret(""), .notInstalled)
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `swift run LoupeTests`
Expected: `ExtensionStatusChecker` unbekannt.

- [ ] **Step 3: Implementieren**

`Sources/LoupeCore/Utilities/ExtensionStatusChecker.swift`:

```swift
import Foundation

public enum ExtensionStatus: Equatable, Sendable {
    case active, installed, notInstalled

    public var title: String {
        switch self {
        case .active:       return "Installiert und aktiv"
        case .installed:    return "Installiert, aber deaktiviert"
        case .notInstalled: return "Nicht registriert"
        }
    }

    public var isOperational: Bool { self != .notInstalled }
}

public enum ExtensionStatusChecker {
    public static let extensionBundleId = "io.celox.loupe.preview"

    /// Die Auswertung ist von der Prozessausfuehrung getrennt, damit sie
    /// ohne installierte Erweiterung pruefbar ist.
    public static func interpret(_ output: String) -> ExtensionStatus {
        guard output.contains(extensionBundleId) else { return .notInstalled }
        return output.contains("!") ? .installed : .active
    }

    public static func checkStatus() -> ExtensionStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-v", "-i", extensionBundleId]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return interpret(String(data: data, encoding: .utf8) ?? "")
        } catch {
            return .notInstalled
        }
    }
}
```

- [ ] **Step 4: Die Oberfläche schreiben**

`Sources/Loupe/UI/MainViewController.swift` — ein Fenster mit drei Teilen:

```swift
import AppKit
import LoupeCore

public final class MainViewController: NSViewController {
    private let statusLabel = NSTextField(labelWithString: "")
    private let appearancePopup = NSPopUpButton()
    private let textSizePopup = NSPopUpButton()

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 420))
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)
        ])

        let title = NSTextField(labelWithString: "Loupe")
        title.font = .systemFont(ofSize: 24, weight: .bold)
        stack.addArrangedSubview(title)

        let subtitle = NSTextField(labelWithString:
            "Zeigt .json-Dateien im Finder als aufklappbaren Baum. Leertaste drücken.")
        subtitle.textColor = .secondaryLabelColor
        stack.addArrangedSubview(subtitle)

        stack.addArrangedSubview(NSBox())
        stack.addArrangedSubview(statusLabel)

        for size in LoupeTextSize.allCases { textSizePopup.addItem(withTitle: size.displayName) }
        for look in LoupeAppearance.allCases { appearancePopup.addItem(withTitle: look.displayName) }
        appearancePopup.target = self
        appearancePopup.action = #selector(settingsChanged)
        textSizePopup.target = self
        textSizePopup.action = #selector(settingsChanged)

        stack.addArrangedSubview(labelled("Erscheinungsbild", appearancePopup))
        stack.addArrangedSubview(labelled("Textgröße", textSizePopup))

        stack.addArrangedSubview(NSBox())
        let guide = NSTextField(wrappingLabelWithString: """
        Erscheint stattdessen roher Text?
        1. Systemeinstellungen → Datenschutz & Sicherheit → Erweiterungen → Quick Look
        2. „Loupe QuickLook Preview“ einschalten
        3. Im Terminal: qlmanage -r && qlmanage -r cache && killall Finder
        """)
        guide.textColor = .secondaryLabelColor
        stack.addArrangedSubview(guide)

        loadSettings()
        refreshStatus()
    }

    private func labelled(_ text: String, _ control: NSView) -> NSStackView {
        let row = NSStackView(views: [NSTextField(labelWithString: text), control])
        row.orientation = .horizontal
        row.spacing = 12
        return row
    }

    private func loadSettings() {
        let s = LoupeSettings.load()
        appearancePopup.selectItem(at: LoupeAppearance.allCases.firstIndex(of: s.appearance) ?? 0)
        textSizePopup.selectItem(at: LoupeTextSize.allCases.firstIndex(of: s.textSize) ?? 1)
    }

    @objc private func settingsChanged() {
        var s = LoupeSettings.load()
        s.appearance = LoupeAppearance.allCases[appearancePopup.indexOfSelectedItem]
        s.textSize = LoupeTextSize.allCases[textSizePopup.indexOfSelectedItem]
        s.save()
    }

    private func refreshStatus() {
        let status = ExtensionStatusChecker.checkStatus()
        statusLabel.stringValue = "Erweiterung: \(status.title)"
        statusLabel.textColor = status.isOperational ? .systemGreen : .systemRed
    }
}
```

`Sources/Loupe/App/AppDelegate.swift` und `Sources/Loupe/main.swift` nach dem
Muster von MarkLook (`Sources/MarkLook/App/AppDelegate.swift`): ein
`NSWindowController` mit `MainViewController` als `contentViewController`,
`applicationShouldTerminateAfterLastWindowClosed` → `true`.

- [ ] **Step 5: `main.swift` erweitern, bauen, Tests grün sehen**

`ExtensionStatusTests.run()` ergänzen.

Run: `swift run LoupeTests && swift build`
Expected: Tests grün, Build ohne Warnungen.

Danach `./Scripts/install_app.sh && open /Applications/Loupe.app` — das Fenster
muss „Installiert und aktiv" in Grün zeigen. Erscheinungsbild auf „Dunkel"
stellen, eine `.json` im Finder mit Leertaste öffnen: die Vorschau muss dunkel
sein, **auch wenn das System hell steht**.

- [ ] **Step 6: Mutationsprobe**

1. In `interpret` die `!`-Prüfung entfernen → `testParsesPluginkitOutput` muss fallen.
2. `isOperational` auf `self == .active` ändern → `testIsOperational` muss fallen.

- [ ] **Step 7: Committen**

```bash
git add -A
git commit -m "feat: companion app with extension status and settings

pluginkit output parsing is separated from running the process so it is
testable without an installed extension. No live editor: JSON is read,
not written."
```

---

### Task 13: Leistung messen, CI, Release, README

**Files:**
- Create: `Tests/LoupeTests/PerformanceTests.swift`
- Create: `Tests/Fixtures/large.json` (erzeugt, nicht eingecheckt)
- Create: `.github/workflows/ci.yml`, `.github/workflows/release.yml`
- Create: `Scripts/package_release.sh`
- Create: `README.md`, `CHANGELOG.md`, `.gitignore`
- Modify: `docs/superpowers/specs/2026-09-22-loupe-json-preview-design.md` (R1-Ergebnis, Kontrastwerte)
- Modify: `Tests/LoupeTests/main.swift`

**Interfaces:**
- Consumes: alles
- Produces: ein veröffentlichungsfähiges Repo

- [ ] **Step 1: Leistungstest schreiben**

`Tests/LoupeTests/PerformanceTests.swift`:

```swift
import Foundation
import LoupeCore

@MainActor
public enum PerformanceTests {

    /// Baut ein JSON von ungefaehr `targetBytes` Groesse.
    static func syntheticJSON(targetBytes: Int) -> String {
        var parts: [String] = []
        var size = 0
        var index = 0
        while size < targetBytes {
            let chunk = """
            {"id":\(index),"name":"eintrag-\(index)","aktiv":\(index % 2 == 0),\
            "werte":[1,2,3,4,5],"text":"Lorem ipsum dolor sit amet \(index)"}
            """
            parts.append(chunk)
            size += chunk.utf8.count + 1
            index += 1
        }
        return "[" + parts.joined(separator: ",") + "]"
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("Performance") {

            runner.runTest(name: "testSmallDocumentUnder50ms") {
                let json = syntheticJSON(targetBytes: 50 * 1024)
                let input = PreviewInput(data: Data(json.utf8),
                                         url: URL(fileURLWithPath: "/tmp/s.json"),
                                         wasTruncatedByReader: false)
                let start = CFAbsoluteTimeGetCurrent()
                _ = JSONPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
                try assertLessThan(ms, 50.0)
            }

            runner.runTest(name: "testFiveMegabytesUnderOneSecond") {
                // Quick Look bricht eine zu langsame Vorschau ab (Spec §11/R2).
                let json = syntheticJSON(targetBytes: 5 * 1024 * 1024)
                let input = PreviewInput(data: Data(json.utf8),
                                         url: URL(fileURLWithPath: "/tmp/l.json"),
                                         wasTruncatedByReader: false)
                let start = CFAbsoluteTimeGetCurrent()
                let html = JSONPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
                try assertLessThan(ms, 1000.0)
                // Die Knotengrenze muss greifen, sonst waere das HTML riesig.
                try assertLessThan(html.utf8.count, 12 * 1024 * 1024)
            }
        }
    }
}
```

- [ ] **Step 2: Messen und entscheiden**

Run: `swift run LoupeTests` (im **Release**-Modus messen:
`swift run -c release LoupeTests`)

- Bleiben beide unter der Grenze → **nichts optimieren.** Die Spec-Notiz zu
  `UnsafeBufferPointer` (§5) ist damit erledigt; das vermerken.
- Reißt der 5-MB-Fall die Sekunde → **erst profilieren, dann ändern.** Die
  naheliegende Stelle ist `String(decoding:)` je Rohtext-Abschnitt im Lexer
  und das Zusammenbauen des HTML per `+=`. Ein `withUnsafeBufferPointer` um
  die Lexer-Schleife ist der nächste Schritt, aber nur mit Messung davor und
  danach.

⚠ **Die Messung ist erst nach der Gegenprobe glaubwürdig:** Setze
`maxNodes` testweise auf 100 und prüfe, dass die 5-MB-Messung dadurch
*deutlich schneller* wird. Tut sie das nicht, misst der Test nicht, was er
zu messen vorgibt.

- [ ] **Step 3: `.gitignore` und `CHANGELOG.md`**

`.gitignore` ist eine Kopie von MarkLooks Datei
(`/Users/martin/claude/marklook/.gitignore`). Zusätzlich ergänzen:

```
Tests/Fixtures/large.json
```

`CHANGELOG.md` nach Keep a Changelog:

```markdown
# Changelog

Alle nennenswerten Änderungen an **Loupe** stehen in dieser Datei.

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [0.1.0] - JJJJ-MM-TT

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
```

Das Datum beim Taggen eintragen — ein geratenes Datum im Changelog ist eine
Falschaussage.

- [ ] **Step 4: CI-Workflow**

`.github/workflows/ci.yml` — Kopie von MarkLooks Datei mit `MarkLookTests` →
`LoupeTests`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-and-build:
    name: Test and Build
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode 16 (Swift 6)
        run: |
          XCODE_APP=$(ls -d /Applications/Xcode_16*.app 2>/dev/null | sort -V | tail -n 1)
          if [ -n "$XCODE_APP" ]; then
            sudo xcode-select -s "$XCODE_APP/Contents/Developer"
          fi
          swift --version

      - name: Run Test Suite
        run: swift run LoupeTests

      - name: Build Application Bundle
        run: ./Scripts/build_app.sh release
```

`.github/workflows/release.yml` und `Scripts/package_release.sh` analog von
MarkLook übernehmen (`MarkLook` → `Loupe`, `MarkLookTests` → `LoupeTests`).

- [ ] **Step 5: README schreiben**

`README.md` mit: Titel, einem Satz zum Zweck, Screenshot-Platz, den
unterstützten Formaten (JSON — und der ausdrücklichen Notiz, dass weitere
folgen), Installation (Release-ZIP **und** `./Scripts/install_app.sh`), der
**Aktivierung in den Systemeinstellungen** (ohne sie sieht niemand etwas),
`swift run LoupeTests`, Sicherheitsabschnitt (Sandbox, CSP, kein JavaScript,
kein Netzzugriff, keine Telemetrie), Lizenz, PayPal-Link auf
`martin.pfeffer@celox.io`.

⚠ **Keine Badge-Zahl behaupten, die nicht gemessen ist.** Testanzahl und
Codezeilen aus dem laufenden Stand entnehmen:

```bash
swift run LoupeTests | tail -3
find Sources Tests -name '*.swift' | xargs wc -l | tail -1
```

Der Verweis auf MarkLook gehört in den Text: Loupe ist dessen Nachfolger,
Markdown zieht später ein.

- [ ] **Step 6: Spec nachführen**

In `docs/superpowers/specs/2026-09-22-loupe-json-preview-design.md`:

- §11/R1: Ergebnis mit Datum eintragen (falls in Task 1 versäumt)
- §11/R2: die gemessene Zeit für 5 MB eintragen
- §5: vermerken, ob `UnsafeBufferPointer` nötig war oder `[UInt8]` reicht
- §6: die **gemessenen** Kontrastwerte je Farbrolle und Theme eintragen

Eine Spec, deren Risiken keinen Ausgang haben, wird beim nächsten Lesen
erneut untersucht.

- [ ] **Step 7: Vollständiger Durchlauf**

```bash
swift run LoupeTests                 # alle grün
swift build -c release               # ohne Warnungen
./Scripts/build_app.sh release       # Bundle baut und signiert
./Scripts/install_app.sh             # installiert
```

Danach im Finder mit den drei Fixtures aus Task 11 gegenprüfen — und
zusätzlich mit einer **echten großen Datei** aus dem Alltag, etwa
`~/claude/marklook/Package.resolved` oder einer `package-lock.json`.

- [ ] **Step 8: Repo auf GitHub anlegen und pushen**

```bash
gh repo create pepperonas/loupe --public --source=. --remote=origin --push
```

Danach prüfen, dass die CI grün durchläuft:

```bash
gh run list --limit 3
```

- [ ] **Step 9: Committen und taggen**

```bash
git add -A
git commit -m "chore: CI, release packaging, README and performance tests

Performance is measured rather than assumed: the spec's note about using
an unsafe buffer pointer is settled by the 5 MB benchmark, not by guessing."
git tag v0.1.0
git push origin main --tags
```

---

## Selbstprüfung des Plans

**1. Spec-Abdeckung** — jede Spec-Sektion gegen eine Aufgabe:

| Spec | Aufgabe |
|---|---|
| §2 Kernannahme (Klicks) | Task 1 (R1), Task 11 (echter Durchlauf) |
| §4 Architektur, Renderer-Naht | Task 1 (Protokoll), Task 11 (Registry) |
| §5 Modell, kein `JSONSerialization` | Task 2 (Modell), Task 3 (Lexer), Task 4 (Parser) |
| §6 Darstellung, Zeilenbudget | Task 9 (Baum), Task 10 (Budget) |
| §7 Grenzen inkl. Tiefenbremse | Task 5 |
| §8 Fehlerbehandlung, gekürzt ≠ kaputt | Task 4 (Unterscheidung), Task 6 (Ausschnitt), Task 9 (Banner) |
| §9 Sicherheit, CSP, Escaping | Task 7 (Escaping), Task 11 (CSP an einer Stelle) |
| §10 Tests, Mutationsproben | jede Aufgabe |
| §11/R1 Vorrang | Task 1 |
| §11/R2 Zeitbudget | Task 13 |
| §12 Nicht in v1 | Task 12 (kein Editor) |

Keine Lücke gefunden.

**2. Platzhalter-Prüfung** — kein „TBD", kein „implement later", kein
„ähnlich wie Task N" ohne wiederholten Code. Drei Stellen verweisen bewusst
auf MarkLook-Dateien zum **wörtlichen Kopieren** (TestFramework, `.gitignore`,
Release-Workflow); das ist eine exakte Anweisung, kein Platzhalter.

**3. Typ-Konsistenz** — durchgängig geprüft:
`Position`/`JSONValue`/`Member`/`LimitKind`/`Diagnostic`/`ParseOutcome`/`ParseResult`
(Task 2) · `Token`/`TokenKind`/`LexError`/`JSONLexer` (Task 3) ·
`ParseLimits`/`JSONParser`/`ParseError` (Task 4/5) ·
`ExcerptLine`/`SourceExcerpt` (Task 6) · `HTMLEscape`/`LoupeSettings`/
`LoupeAppearance`/`LoupeTextSize` (Task 7) · `CSSGenerator` + die `lp-*`-Klassen
(Task 8, von Task 9 erzeugt) · `JSONTreeRenderer(settings:openPaths:)` (Task 9)
passt zu `ExpansionPolicy.plan(root:budget:) -> Set<[Int]>` (Task 10) ·
`PreviewInput`/`PreviewRenderer` (Task 1) zu `JSONPreviewRenderer`/
`RendererRegistry`/`HTMLDocument` (Task 11) · `ExtensionStatus`/
`ExtensionStatusChecker` (Task 12).

**Drei Stellen, an denen eine spätere Aufgabe eine frühere ersetzt** — bewusst
so und jeweils vermerkt: der `LoupeSettings`-Platzhalter (Task 1 → Task 7), die
Hallo-Ausgabe der `.appex` (Task 1 → Task 11) und das App-Gerüst
(Task 1 → Task 12).
