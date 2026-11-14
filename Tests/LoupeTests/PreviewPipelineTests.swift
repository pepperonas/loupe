import Foundation
import LoupeCore

/// Eine gemeinsame Vorschau-Pipeline fuer Quick Look und das Dokumentfenster der App:
/// Doppelklick auf eine Datei soll genau das zeigen, was die Leertaste zeigt.
@MainActor
public enum PreviewPipelineTests {
    static func file(_ name: String, _ content: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("loupe-pipeline", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try Data(content.utf8).write(to: url)
        return url
    }

    static func html(_ output: PreviewPipeline.Output) throws -> String {
        guard case .html(let s) = output else { throw TestFailure(message: "HTML erwartet, bekam \(output)", file: #file, line: #line) }
        return s
    }

    public static func run() {
        let runner = TestRunner.shared
        runner.suite("PreviewPipeline") {

            runner.runTest(name: "testMarkdownBecomesRenderedHTML") {
                let url = try file("liesmich.md", "# Überschrift\n\n| a | b |\n|---|---|\n| 1 | 2 |\n")
                let s = try html(try PreviewPipeline.render(url: url, settings: LoupeSettings()))
                try assertTrue(s.contains("<h1"), "Überschrift muss gerendert sein")
                try assertTrue(s.contains("<table"), "GFM-Tabelle muss gerendert sein")
                try assertTrue(s.contains("Content-Security-Policy"), "CSP gilt auch im Fenster")
            }

            runner.runTest(name: "testDisabledCategoryGivesPlainTextInQuickLook") {
                let url = try file("aus.md", "# Roh\n")
                var s = LoupeSettings()
                s.setEnabled(false, for: .markdown)
                guard case .plainText(let text) = try PreviewPipeline.render(url: url, settings: s) else {
                    throw TestFailure(message: "abgeschaltet muss Rohtext kommen", file: #file, line: #line)
                }
                try assertEqual(text, "# Roh\n")
            }

            runner.runTest(name: "testWindowIgnoresTogglesBecauseTheUserOpenedTheFileInLoupe") {
                let url = try file("fenster.md", "# Trotzdem\n")
                var s = LoupeSettings()
                s.previewsEnabled = false
                let out = try PreviewPipeline.render(url: url, settings: s, respectToggles: false)
                try assertTrue(try html(out).contains("<h1"))
            }

            runner.runTest(name: "testJSONAndSourceUseTheirRenderers") {
                let json = try html(try PreviewPipeline.render(url: try file("a.json", #"{"x": 1}"#), settings: LoupeSettings()))
                try assertTrue(json.contains("x"))
                let swift = try html(try PreviewPipeline.render(url: try file("a.swift", "let x = 1\n"), settings: LoupeSettings()))
                try assertTrue(swift.contains("let"))
            }

            runner.runTest(name: "testMissingFileThrows") {
                let url = URL(fileURLWithPath: "/tmp/loupe-pipeline/gibt-es-nicht.md")
                var warf = false
                do { _ = try PreviewPipeline.render(url: url, settings: LoupeSettings()) } catch { warf = true }
                try assertTrue(warf, "fehlende Datei muss werfen")
            }

            runner.runTest(name: "testErrorPageEscapesTheMessage") {
                let s = PreviewPipeline.errorHTML(message: "<b>kaputt</b>", title: "x.md", settings: LoupeSettings())
                try assertTrue(s.contains("&lt;b&gt;kaputt&lt;/b&gt;"))
                try assertFalse(s.contains("<b>kaputt</b>"))
            }
        }
    }
}
