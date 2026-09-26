import Foundation
import LoupeCore

/// Die Begleit-App spricht Englisch und Deutsch. Die Quick-Look-Vorschau wird
/// ausdruecklich NICHT uebersetzt (Nutzervorgabe) -- auch das ist hier gepinnt.
@MainActor
public enum LocalizationTests {
    static func settings(_ lang: LoupeLanguageSetting) -> LoupeSettings {
        var s = LoupeSettings(); s.language = lang; return s
    }

    static func url(_ name: String) -> URL { URL(fileURLWithPath: "/tmp/loupe-l10n/\(name)") }

    /// Jede Oberflaechen-Situation mit Text: Zaehler, Banner, Fehler, Grenzen.
    static func samples(_ s: LoupeSettings) -> [(String, String)] {
        let broken = Data("{\n  \"a\": 1,\n  \"b\": [1, 2,]\n}".utf8)
        let obj = Data(#"{"a":[1,2,3],"b":{"c":1}}"#.utf8)
        let tsv = Data("a\tb\n1\t2\n".utf8)
        let log = Data("2026-09-24 10:00:00 INFO start\n2026-09-24 10:00:01 ERROR boom\n".utf8)
        let code = Data("let a = 1\nlet b = 2\n".utf8)
        return [
            ("json-error", JSONPreviewRenderer().renderHTML(input: PreviewInput(data: broken, url: url("a.json"), wasTruncatedByReader: false), settings: s)),
            ("json-tree", JSONPreviewRenderer().renderHTML(input: PreviewInput(data: obj, url: url("a.json"), wasTruncatedByReader: false), settings: s)),
            ("json-cut", JSONPreviewRenderer().renderHTML(input: PreviewInput(data: Data(#"{"a":[1,2"#.utf8), url: url("a.json"), wasTruncatedByReader: true), settings: s)),
            ("json-empty", JSONPreviewRenderer().renderHTML(input: PreviewInput(data: Data(), url: url("a.json"), wasTruncatedByReader: false), settings: s)),
            ("tsv", CSVPreviewRenderer().renderHTML(input: PreviewInput(data: tsv, url: url("t.tsv"), wasTruncatedByReader: true), settings: s)),
            ("log", LogPreviewRenderer().renderHTML(input: PreviewInput(data: log, url: url("s.log"), wasTruncatedByReader: false, skippedBytesAtStart: 2048), settings: s)),
            ("log-empty", LogPreviewRenderer().renderHTML(input: PreviewInput(data: Data(), url: url("s.log"), wasTruncatedByReader: false), settings: s)),
            ("code", SourceCodePreviewRenderer().renderHTML(input: PreviewInput(data: code, url: url("a.swift"), wasTruncatedByReader: false), settings: s)),
        ]
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("Localization") {

            runner.runTest(name: "testSystemLanguageResolution") {
                try assertEqual(LoupeLanguage.resolve(preferred: ["de-DE", "en-US"]), .de)
                try assertEqual(LoupeLanguage.resolve(preferred: ["en-US", "de-DE"]), .en)
                try assertEqual(LoupeLanguage.resolve(preferred: ["fr-FR", "de-CH"]), .de, "erste BEKANNTE Sprache")
                try assertEqual(LoupeLanguage.resolve(preferred: ["de_AT"]), .de)
                try assertEqual(LoupeLanguage.resolve(preferred: ["fr-FR", "ja"]), .en, "Rueckfall Englisch")
                try assertEqual(LoupeLanguage.resolve(preferred: []), .en)
            }

            runner.runTest(name: "testFixedLanguageIgnoresTheSystem") {
                try assertEqual(LoupeLanguageSetting.de.resolved(preferred: ["en-US"]), .de)
                try assertEqual(LoupeLanguageSetting.en.resolved(preferred: ["de-DE"]), .en)
                try assertEqual(LoupeLanguageSetting.system.resolved(preferred: ["de-DE"]), .de)
            }

            runner.runTest(name: "testOldSettingsFollowTheSystemLanguage") {
                let old = #"{"appearance":"dark","previewsEnabled":true}"#
                let s = try JSONDecoder().decode(LoupeSettings.self, from: Data(old.utf8))
                try assertEqual(s.language, .system)
                let odd = #"{"language":"klingon"}"#
                try assertEqual(try JSONDecoder().decode(LoupeSettings.self, from: Data(odd.utf8)).language, .system)
            }

            runner.runTest(name: "testLanguageSurvivesRoundTrip") {
                let s = settings(.de)
                let back = try JSONDecoder().decode(LoupeSettings.self, from: JSONEncoder().encode(s))
                try assertEqual(back.language, .de)
            }

            runner.runTest(name: "testPreviewsAreNeverTranslated") {
                // Die Sprache gilt nur fuer die App: jede Vorschau ist mit Englisch
                // und Deutsch byte-gleich.
                let en = samples(settings(.en)), de = samples(settings(.de))
                for ((name, e), (_, d)) in zip(en, de) {
                    try assertTrue(e == d, "\(name): Vorschau haengt von der App-Sprache ab")
                }
            }

            runner.runTest(name: "testAppTextsExistInBothLanguagesAndDiffer") {
                let en = L10n(.en), de = L10n(.de)
                let pairs: [(String, String)] = [
                    (en.appSubtitle, de.appSubtitle), (en.previewsEnabled, de.previewsEnabled),
                    (en.previewsOffHint, de.previewsOffHint), (en.appearance, de.appearance),
                    (en.textSize, de.textSize), (en.markdownWidth, de.markdownWidth), (en.language, de.language),
                    (en.setupGuide, de.setupGuide), (en.donate, de.donate), (en.licensePrefix, de.licensePrefix),
                    (en.licenseName, de.licenseName), (en.menuHideOthers, de.menuHideOthers),
                    (en.menuShowAll, de.menuShowAll), (en.menuWindow, de.menuWindow), (en.menuMinimize, de.menuMinimize)]
                for (e, d) in pairs {
                    try assertFalse(e.isEmpty || d.isEmpty)
                    try assertFalse(e == d, "nicht uebersetzt: \(e)")
                    for w in ["ä", "ö", "ü", "ß"] where e.contains(w) {
                        throw TestFailure(message: "Umlaut im Englischen: \(e)", file: #file, line: #line)
                    }
                }
                for c in PreviewCategory.allCases where c == .table || c == .log || c == .code {
                    try assertFalse(c.displayName(.en) == c.displayName(.de), "\(c)")
                }
            }

            runner.runTest(name: "testLanguageNamesAreInTheirOwnLanguage") {
                // Wer die falsche Sprache eingestellt hat, findet seine trotzdem.
                for lang in LoupeLanguage.allCases {
                    try assertEqual(LoupeLanguageSetting.de.displayName(lang), "Deutsch")
                    try assertEqual(LoupeLanguageSetting.en.displayName(lang), "English")
                }
            }

            runner.runTest(name: "testTheAppDeclaresEnglishAndGerman") {
                let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                let p = "Sources/Loupe/Resources/Info.plist"
                let d = try PropertyListSerialization.propertyList(from: Data(contentsOf: root.appendingPathComponent(p)),
                                                                    format: nil) as? [String: Any] ?? [:]
                try assertEqual(Set(d["CFBundleLocalizations"] as? [String] ?? []), ["en", "de"], p)
            }
        }
    }
}
