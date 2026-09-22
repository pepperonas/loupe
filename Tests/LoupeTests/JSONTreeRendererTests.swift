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
