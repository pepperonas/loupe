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

            runner.runTest(name: "testMarkdownTypeResolvesToMarkdownRenderer") {
                if let mdType = UTType("net.daringfireball.markdown") {
                    try assertTrue(RendererRegistry.renderer(for: mdType) != nil)
                }
                try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/README.md")) != nil)
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

            runner.runTest(name: "testTruncatedInputRendersTruncationNotice") {
                let input = PreviewInput(data: Data(#"{"a": 1}"#.utf8),
                                         url: URL(fileURLWithPath: "/tmp/t.json"),
                                         wasTruncatedByReader: true)
                let html = JSONPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.contains("<div class=\"lp-banner lp-banner-notice\">"))
                try assertTrue(html.contains("Datei abgeschnitten"))
            }

            runner.runTest(name: "testCSVTypeResolvesToCSVRenderer") {
                try assertTrue(RendererRegistry.renderer(for: .commaSeparatedText) != nil)
                try assertTrue(RendererRegistry.renderer(for: .tabSeparatedText) != nil)
                try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/data.csv")) != nil)
                try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/data.tsv")) != nil)
            }

            runner.runTest(name: "testCSVEndToEndRenderOfRealFile") {
                let csv = "Name,Age,Role\nAlice,30,Engineer\nBob,25,Designer"
                let input = PreviewInput(data: Data(csv.utf8),
                                         url: URL(fileURLWithPath: "/tmp/team.csv"),
                                         wasTruncatedByReader: false)
                let renderer = RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/team.csv"))
                try assertTrue(renderer != nil)
                let html = renderer!.renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.hasPrefix("<!DOCTYPE html>"))
                try assertTrue(html.contains("<table class=\"lp-csv-table\">"))
                try assertTrue(html.contains("Alice"))
                try assertTrue(html.contains("Engineer"))
                try assertFalse(html.lowercased().contains("<script"))
            }

            runner.runTest(name: "testCSVEmptyFileRendersBanner") {
                let input = PreviewInput(data: Data(),
                                         url: URL(fileURLWithPath: "/tmp/empty.csv"),
                                         wasTruncatedByReader: false)
                let html = CSVPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.contains("lp-banner"))
            }

            runner.runTest(name: "testCSVTruncatedInputRendersTruncationNotice") {
                let input = PreviewInput(data: Data("a,b\n1,2".utf8),
                                         url: URL(fileURLWithPath: "/tmp/trunc.csv"),
                                         wasTruncatedByReader: true)
                let html = CSVPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                try assertTrue(html.contains("lp-banner lp-banner-notice"))
                try assertTrue(html.contains("Datei abgeschnitten"))
            }
        }
    }
}
