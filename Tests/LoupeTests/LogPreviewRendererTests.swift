import Foundation
import UniformTypeIdentifiers
import LoupeCore

@MainActor
public enum LogPreviewRendererTests {
    private static func render(_ text: String,
                               name: String = "app.log",
                               skipped: Int = 0,
                               settings: LoupeSettings = LoupeSettings()) -> String {
        let input = PreviewInput(data: Data(text.utf8),
                                 url: URL(fileURLWithPath: "/tmp/\(name)"),
                                 wasTruncatedByReader: false,
                                 skippedBytesAtStart: skipped)
        return LogPreviewRenderer().renderHTML(input: input, settings: settings)
    }

    public static func run() {
        let runner = TestRunner.shared

        runner.suite("LogHighlighter") {
            runner.runTest(name: "testHighlightsTokensInMessages") {
                let html = LogHighlighter.highlight(
                    #"GET https://x.io/a from 10.0.0.12:443 took 35ms id=7f3c2a10-1b2c-4d5e-8f90-a1b2c3d4e5f6 file /var/log/app.log said "hi""#)
                try assertTrue(html.contains(#"<span class="lg-url">https://x.io/a</span>"#))
                try assertTrue(html.contains(#"<span class="lg-ip">10.0.0.12:443</span>"#))
                try assertTrue(html.contains(#"<span class="lg-num">35ms</span>"#))
                try assertTrue(html.contains(#"<span class="lg-key">id</span>="#))
                try assertTrue(html.contains(#"<span class="lg-uuid">7f3c2a10-1b2c-4d5e-8f90-a1b2c3d4e5f6</span>"#))
                try assertTrue(html.contains(#"<span class="lg-path">/var/log/app.log</span>"#))
                try assertTrue(html.contains(#"<span class="lg-str">&quot;hi&quot;</span>"#))
            }

            runner.runTest(name: "testAnySchemeURLIsOneToken") {
                let html = LogHighlighter.highlight("pool postgres://db.internal:5432/app and redis://cache:6379")
                try assertTrue(html.contains(#"<span class="lg-url">postgres://db.internal:5432/app</span>"#), html)
                try assertTrue(html.contains(#"<span class="lg-url">redis://cache:6379</span>"#), html)
            }

            runner.runTest(name: "testDigitsInsideWordsAreNotNumbers") {
                let html = LogHighlighter.highlight("user abc123 v2 x86_64")
                try assertFalse(html.contains("lg-num"), html)
            }

            runner.runTest(name: "testHighlighterEscapesEverything") {
                let html = LogHighlighter.highlight(#"<script>alert(1)</script> "<b>" & more"#)
                try assertFalse(html.contains("<script>"))
                try assertFalse(html.contains("<b>"))
                try assertTrue(html.contains("&lt;script&gt;"))
                try assertTrue(html.contains("&amp; more"))
            }
        }

        runner.suite("PreviewFileReader") {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("loupe-reader-\(UUID().uuidString)")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let file = dir.appendingPathComponent("big.log")
            let content = (1...1000).map { "line \($0)" }.joined(separator: "\n")
            try? Data(content.utf8).write(to: file)
            let size = content.utf8.count

            runner.runTest(name: "testHeadReadsWholeSmallFile") {
                let r = try PreviewFileReader.read(url: file, strategy: .head, headLimit: 1 << 20)
                try assertEqual(r.data.count, size)
                try assertFalse(r.truncatedAtEnd)
                try assertEqual(r.skippedBytesAtStart, 0)
            }

            runner.runTest(name: "testHeadTruncatesAtLimit") {
                let r = try PreviewFileReader.read(url: file, strategy: .head, headLimit: 100)
                try assertEqual(r.data.count, 100)
                try assertTrue(r.truncatedAtEnd)
            }

            runner.runTest(name: "testTailReadsOnlyTheEnd") {
                let r = try PreviewFileReader.read(url: file, strategy: .tail(maxBytes: 100), headLimit: 1 << 20)
                try assertEqual(r.data.count, 100)
                try assertEqual(r.skippedBytesAtStart, size - 100)
                try assertFalse(r.truncatedAtEnd)
                try assertTrue(String(decoding: r.data, as: UTF8.self).hasSuffix("line 1000"))
            }

            runner.runTest(name: "testTailCountsSkippedLines") {
                let r = try PreviewFileReader.read(url: file, strategy: .tail(maxBytes: 100), headLimit: 1 << 20)
                let skippedText = content.utf8.prefix(size - 100)
                try assertEqual(r.skippedLineBreaks, skippedText.filter { $0 == 0x0A }.count)
            }

            runner.runTest(name: "testTailedRenderShowsAbsoluteLineNumbers") {
                let r = try PreviewFileReader.read(url: file, strategy: .tail(maxBytes: 100), headLimit: 1 << 20)
                let html = LogPreviewRenderer().renderHTML(
                    input: PreviewInput(data: r.data, url: file, wasTruncatedByReader: false,
                                        skippedBytesAtStart: r.skippedBytesAtStart,
                                        skippedLineBreaks: r.skippedLineBreaks),
                    settings: LoupeSettings())
                try assertTrue(html.contains(#"<td class="lp-line-no">1000</td>"#), "letzte Zeile der Datei ist 1000")
                try assertFalse(html.contains("relativ"))
            }

            runner.runTest(name: "testUnknownOffsetSaysNumbersAreRelative") {
                let html = render("tial\nINFO a\nINFO b", skipped: 900 * 1024 * 1024)
                try assertTrue(html.contains(#"<td class="lp-line-no">1</td>"#))
                try assertTrue(html.contains("relativ"))
            }

            runner.runTest(name: "testTailOfSmallFileReadsEverything") {
                let r = try PreviewFileReader.read(url: file, strategy: .tail(maxBytes: 1 << 20), headLimit: 10)
                try assertEqual(r.data.count, size)
                try assertEqual(r.skippedBytesAtStart, 0)
            }

            runner.runTest(name: "testTailCutInsideMultibyteCharacterStaysDecodable") {
                // "ä" ist zwei Bytes; der Schnitt landet mitten im Zeichen.
                let f = dir.appendingPathComponent("umlaut.log")
                try Data("ää\nINFO fertig\n".utf8).write(to: f)
                let r = try PreviewFileReader.read(url: f, strategy: .tail(maxBytes: 15), headLimit: 1 << 20)
                let doc = LogParser.parse(text: String(decoding: r.data, as: UTF8.self),
                                          startsMidLine: r.skippedBytesAtStart > 0)
                try assertEqual(doc.entries.count, 1)
                try assertEqual(doc.entries[0].message, "fertig")
            }
        }

        runner.suite("LogPreviewRenderer") {
            runner.runTest(name: "testRendersStructuredRows") {
                let html = render("""
                2026-09-24 17:01:02.123 INFO  [main] Server started on :8080
                2026-09-24 17:01:03.456 ERROR [db] Connection refused
                """)
                try assertTrue(html.contains(#"<table class="lg-table">"#))
                try assertTrue(html.contains(#"<tr class="lg-row lg-lvl-error">"#))
                try assertTrue(html.contains(#"<td class="lg-ts">2026-09-24 17:01:03.456</td>"#))
                try assertTrue(html.contains(#"<span class="lg-badge">ERROR</span>"#))
                try assertTrue(html.contains(#"<td class="lg-src">db</td>"#))
                try assertTrue(html.contains("app.log"))
                try assertTrue(html.contains("2 Zeilen"))
            }

            runner.runTest(name: "testToolbarCountsLevels") {
                let html = render("ERROR a\nERROR b\nWARN c\nINFO d")
                try assertTrue(html.contains(#"<span class="lg-count lg-lvl-error">2 ERROR</span>"#))
                try assertTrue(html.contains(#"<span class="lg-count lg-lvl-warning">1 WARN</span>"#))
                try assertFalse(html.contains("lg-count lg-lvl-info"), "INFO wird nicht gezaehlt -- nur Auffaelliges")
            }

            runner.runTest(name: "testEmptyColumnsAreOmitted") {
                let html = render("just some text\nanother line")
                try assertFalse(html.contains(#"class="lg-ts""#))
                try assertFalse(html.contains(#"class="lg-lvl""#))
                try assertFalse(html.contains(#"class="lg-src""#))
                try assertTrue(html.contains(#"class="lg-msg""#))
            }

            runner.runTest(name: "testContinuationRowsSpanAndInheritLevel") {
                let html = render("""
                2026-09-24 17:01:02 ERROR [main] failed
                \tat com.x.Foo(Foo.java:1)
                """)
                try assertTrue(html.contains(#"<tr class="lg-cont lg-lvl-error"><td class="lp-line-no">2</td><td class="lg-msg" colspan="4">"#), html)
            }

            runner.runTest(name: "testAccessLogRow") {
                let html = render(#"203.0.113.7 - - [24/Sep/2026:17:01:02 +0200] "GET /api HTTP/1.1" 503 1024 "-" "curl/8.4.0""#,
                                  name: "access.log")
                try assertTrue(html.contains(#"<span class="lg-badge lg-status lg-st-5xx">503</span>"#))
                try assertTrue(html.contains(#"<span class="lg-method">GET</span>"#))
                try assertTrue(html.contains(#"<span class="lg-ua">curl/8.4.0</span>"#))
                try assertTrue(html.contains("nginx/Apache"))
            }

            runner.runTest(name: "testJSONFieldsRendered") {
                let html = render(#"{"level":"info","msg":"<hi>","user":"anna"}"#)
                try assertTrue(html.contains("&lt;hi&gt;"))
                try assertFalse(html.contains("<hi>"))
                try assertTrue(html.contains(#"<span class="lg-field"><span class="lg-key">user</span>=<span class="lg-str">anna</span></span>"#), html)
            }

            runner.runTest(name: "testNoScriptAndStrictCSP") {
                let html = render(#"ERROR <script>alert(1)</script> <img src=x onerror=y>"#)
                try assertFalse(html.contains("<script>alert"))
                try assertFalse(html.contains("<img"))
                try assertTrue(html.contains("default-src 'none'"))
            }

            runner.runTest(name: "testHeaderCellsAreEscaped") {
                // Zeit und Quelle stammen aus der Datei -- auch sie muessen escaped werden.
                let html = render("[2026-09-24 <i>x</i>] INFO [<b>src</b>] msg")
                try assertTrue(html.contains(#"<td class="lg-ts">2026-09-24 &lt;i&gt;x&lt;/i&gt;</td>"#), html)
                try assertTrue(html.contains(#"<td class="lg-src">&lt;b&gt;src&lt;/b&gt;</td>"#))
                try assertFalse(html.contains("<i>x"))
                try assertFalse(html.contains("<b>src"))
            }

            runner.runTest(name: "testTailBannerMentionsSkippedPart") {
                let html = render("tial\nINFO newest", skipped: 3 * 1024 * 1024)
                try assertTrue(html.contains(#"class="lp-banner"#))
                try assertTrue(html.contains("3.0 MB"), html)
                try assertTrue(html.contains("Ende der Datei"))
            }

            runner.runTest(name: "testNoBannerForCompleteSmallFile") {
                try assertFalse(render("INFO ok").contains(#"class="lp-banner"#))
            }

            runner.runTest(name: "testHighlightingCanBeDisabled") {
                var s = LoupeSettings()
                s.enableSyntaxHighlighting = false
                let html = render("INFO took 35ms", settings: s)
                try assertFalse(html.contains(#"class="lg-num""#))
                try assertTrue(html.contains(#"class="lg-badge""#), "Struktur bleibt auch ohne Hervorhebung")
            }

            runner.runTest(name: "testLineNumbersAlwaysShownLikeSourceCode") {
                // Wie beim Quellcode: die (ungenutzte, standardmaessig false)
                // showLineNumbers-Einstellung darf die Nummern nicht verstecken.
                try assertTrue(render("INFO a").contains(#"<td class="lp-line-no">1</td>"#))
            }

            runner.runTest(name: "testRendererAsksForTail") {
                try assertEqual(LogPreviewRenderer.readStrategy, .tail(maxBytes: 4 * 1024 * 1024))
                try assertEqual(JSONPreviewRenderer.readStrategy, .head)
                try assertEqual(SourceCodePreviewRenderer.readStrategy, .head)
            }
        }

        runner.suite("Log registry & theme") {
            runner.runTest(name: "testLogFilesResolveToLogRenderer") {
                for name in ["app.log", "SYSTEM.LOG", "install.log"] {
                    let r = RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/\(name)"))
                    try assertTrue(r is LogPreviewRenderer, name)
                }
                if let t = UTType("com.apple.log") {
                    try assertTrue(RendererRegistry.renderer(for: t) is LogPreviewRenderer)
                }
                if let t = UTType("public.log") {
                    try assertTrue(RendererRegistry.renderer(for: t) is LogPreviewRenderer)
                }
            }

            runner.runTest(name: "testOtherFormatsUnaffected") {
                try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/a.json")) is JSONPreviewRenderer)
                try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/a.swift")) is SourceCodePreviewRenderer)
                try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/a.tsv")) is CSVPreviewRenderer)
                try assertFalse(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/a.out")) is LogPreviewRenderer,
                                "a.out ist klassisch ein Binary -- kein Log")
            }

            runner.runTest(name: "testLevelColorsMeetWCAGAAInBothThemes") {
                for appearance in [LoupeAppearance.light, .dark] {
                    var s = LoupeSettings()
                    s.appearance = appearance
                    let vars = cssVariables(CSSGenerator.generateLogCSS(settings: s))
                    let bg = try unwrap(vars["--bg-code"].flatMap(hexRGB), file: #file, line: #line)
                    for name in ["--lg-trace", "--lg-debug", "--lg-info", "--lg-notice", "--lg-warning",
                                 "--lg-error", "--lg-fatal", "--lg-ts", "--lg-src", "--lg-dim",
                                 "--lg-st-2xx", "--lg-st-3xx", "--lg-st-4xx", "--lg-st-5xx"] {
                        let fg = try unwrap(vars[name].flatMap(hexRGB))
                        let ratio = contrast(fg, bg)
                        try assertTrue(ratio >= 4.5, "\(appearance) \(name): \(String(format: "%.2f", ratio)):1")
                    }
                    // Fehlerzeilen tragen eine Toenung -- der Text muss auch darauf lesbar bleiben.
                    let tint = try unwrap(vars["--lg-error-row"].flatMap(rgba))
                    let tinted = blend(tint, over: bg)
                    for name in ["--text-primary", "--lg-dim", "--lg-error", "--lg-ts"] {
                        let fg = try unwrap(vars[name].flatMap(hexRGB))
                        try assertTrue(contrast(fg, tinted) >= 4.5, "\(appearance) \(name) auf Fehlerzeile")
                    }
                }
            }
        }
    }

    // MARK: Kontrast-Helfer

    nonisolated private static func cssVariables(_ css: String) -> [String: String] {
        var out: [String: String] = [:]
        // Nur der erste :root-Block zaehlt (bei fester Erscheinung gibt es genau einen).
        for line in css.split(separator: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("--"), let colon = t.firstIndex(of: ":") else { continue }
            let key = String(t[..<colon])
            let value = t[t.index(after: colon)...].trimmingCharacters(in: CharacterSet(charactersIn: " ;"))
            if out[key] == nil { out[key] = value }
        }
        return out
    }

    nonisolated private static func hexRGB(_ s: String) -> (Double, Double, Double)? {
        guard s.hasPrefix("#"), s.count == 7, let v = Int(s.dropFirst(), radix: 16) else { return nil }
        return (Double((v >> 16) & 0xff) / 255, Double((v >> 8) & 0xff) / 255, Double(v & 0xff) / 255)
    }

    nonisolated private static func rgba(_ s: String) -> (Double, Double, Double, Double)? {
        guard s.hasPrefix("rgba("), s.hasSuffix(")") else { return nil }
        let parts = s.dropFirst(5).dropLast().split(separator: ",").compactMap {
            Double($0.trimmingCharacters(in: .whitespaces))
        }
        guard parts.count == 4 else { return nil }
        return (parts[0] / 255, parts[1] / 255, parts[2] / 255, parts[3])
    }

    nonisolated private static func blend(_ top: (Double, Double, Double, Double),
                              over bottom: (Double, Double, Double)) -> (Double, Double, Double) {
        let a = top.3
        return (top.0 * a + bottom.0 * (1 - a), top.1 * a + bottom.1 * (1 - a), top.2 * a + bottom.2 * (1 - a))
    }

    nonisolated private static func contrast(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
        func lin(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        func lum(_ c: (Double, Double, Double)) -> Double { 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2) }
        let (l1, l2) = (lum(a), lum(b))
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
}
