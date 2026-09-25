import Foundation
import UniformTypeIdentifiers
import LoupeCore

/// Globaler Schalter + Schalter je Rubrik (Markdown, JSON, Tabellen, Logs, Code).
@MainActor
public enum PreviewToggleTests {
    public static func run() {
        let runner = TestRunner.shared
        runner.suite("PreviewToggles") {

            runner.runTest(name: "testEverythingIsOnByDefault") {
                let s = LoupeSettings()
                try assertTrue(s.previewsEnabled)
                for c in PreviewCategory.allCases {
                    try assertTrue(s.isEnabled(c), "\(c) muss ab Werk an sein")
                }
            }

            runner.runTest(name: "testOldSettingsWithoutTogglesKeepEverythingOn") {
                // Einstellungen aus v0.4.0 kennen die Schalter nicht.
                let old = #"{"appearance":"dark","textSize":"small","contentWidth":"wide"}"#
                let s = try JSONDecoder().decode(LoupeSettings.self, from: Data(old.utf8))
                try assertTrue(s.previewsEnabled)
                for c in PreviewCategory.allCases { try assertTrue(s.isEnabled(c)) }
                try assertEqual(s.appearance, .dark)
            }

            runner.runTest(name: "testCategoryOffDisablesOnlyThatCategory") {
                var s = LoupeSettings()
                s.setEnabled(false, for: .log)
                try assertFalse(s.isEnabled(.log))
                for c in PreviewCategory.allCases where c != .log {
                    try assertTrue(s.isEnabled(c), "\(c) darf nicht mit ausgehen")
                }
                s.setEnabled(true, for: .log)
                try assertTrue(s.isEnabled(.log))
            }

            runner.runTest(name: "testGlobalSwitchWinsOverCategories") {
                var s = LoupeSettings()
                s.previewsEnabled = false
                for c in PreviewCategory.allCases { try assertFalse(s.isEnabled(c)) }
                // Die Wahl je Rubrik bleibt erhalten und gilt wieder, sobald global an ist.
                s.setEnabled(false, for: .json)
                s.previewsEnabled = true
                try assertFalse(s.isEnabled(.json))
                try assertTrue(s.isEnabled(.markdown))
            }

            runner.runTest(name: "testTogglesSurviveRoundTrip") {
                var s = LoupeSettings()
                s.previewsEnabled = false
                s.setEnabled(false, for: .code)
                s.setEnabled(false, for: .table)
                let back = try JSONDecoder().decode(LoupeSettings.self, from: JSONEncoder().encode(s))
                try assertEqual(back, s)
                try assertFalse(back.previewsEnabled)
                var on = back; on.previewsEnabled = true
                try assertFalse(on.isEnabled(.code))
                try assertFalse(on.isEnabled(.table))
                try assertTrue(on.isEnabled(.json))
            }

            runner.runTest(name: "testUnknownStoredCategoryIsIgnored") {
                // Eine spaetere Version koennte eine Rubrik kennen, die es hier nicht gibt:
                // die Einstellungen muessen trotzdem lesbar bleiben.
                let json = #"{"previewsEnabled":true,"disabledCategories":["log","hologram"]}"#
                let s = try JSONDecoder().decode(LoupeSettings.self, from: Data(json.utf8))
                try assertFalse(s.isEnabled(.log))
                try assertTrue(s.isEnabled(.json))
            }

            runner.runTest(name: "testEveryRendererHasTheRightCategory") {
                try assertEqual(JSONPreviewRenderer.category, .json)
                try assertEqual(MarkdownPreviewRenderer.category, .markdown)
                try assertEqual(CSVPreviewRenderer.category, .table)
                try assertEqual(LogPreviewRenderer.category, .log)
                try assertEqual(SourceCodePreviewRenderer.category, .code)
            }

            runner.runTest(name: "testCategoryFollowsTheRendererChosenForAFile") {
                let cases: [(String, PreviewCategory)] = [
                    ("a.json", .json), ("README.md", .markdown), ("t.tsv", .table),
                    ("server.log", .log), ("main.swift", .code), ("deploy.ps1", .code),
                    ("build.bat", .code), ("pom.xml", .code), ("Dockerfile", .code)
                ]
                for (name, expected) in cases {
                    let url = URL(fileURLWithPath: "/tmp/loupe-toggle-test/\(name)")
                    guard let r = RendererRegistry.renderer(for: url) else {
                        throw TestFailure(message: "kein Renderer fuer \(name)", file: #file, line: #line)
                    }
                    try assertEqual(type(of: r).category, expected, name)
                }
            }

            runner.runTest(name: "testEveryCategoryHasAGermanLabelAndIsDistinct") {
                let labels = PreviewCategory.allCases.map(\.displayName)
                try assertEqual(Set(labels).count, labels.count)
                for l in labels { try assertFalse(l.isEmpty) }
                try assertEqual(PreviewCategory.allCases.count, 5)
            }
        }
    }
}
