import Foundation
import UniformTypeIdentifiers
import LoupeCore

/// `.chart` (Clone Hero / Moonscraper): Abschnitte `[Name] { schluessel = wert }`.
/// Vorgabe des Nutzers: jeder Abschnitt ist beim Oeffnen ZUGEKLAPPT.
@MainActor
public enum ChartTests {
    static let sample = """
    [Song]
    {
      Name = "Test Song"
      Artist = "Test Band"
      Resolution = 480
      Offset = 0
    }
    [SyncTrack]
    {
      0 = TS 4
      0 = B 120000
      1920 = B 240000
      3840 = TS 6 3
    }
    [Events]
    {
      0 = E "section Intro"
      1920 = E "section Verse 1"
    }
    [ExpertSingle]
    {
      0 = N 0 0
      480 = N 1 240
      960 = N 2 0
      960 = N 5 0
      1440 = N 3 0
      1440 = N 6 0
      1920 = N 4 0
      2400 = N 7 0
      2880 = S 2 960
      3360 = E solo
    }
    """

    static func render(_ text: String, name: String = "notes.chart",
                       truncated: Bool = false, settings: LoupeSettings = LoupeSettings()) -> String {
        let input = PreviewInput(data: Data(text.utf8), url: URL(fileURLWithPath: "/tmp/\(name)"),
                                 wasTruncatedByReader: truncated)
        return ChartPreviewRenderer().renderHTML(input: input, settings: settings)
    }

    static func count(_ needle: String, in hay: String) -> Int {
        hay.components(separatedBy: needle).count - 1
    }

    public static func run() {
        let runner = TestRunner.shared

        runner.suite("Chart parser") {
            runner.runTest(name: "testSectionsInOrderWithTheirEntries") {
                let doc = ChartParser.parse(sample)
                try assertEqual(doc.sections.map(\.name), ["Song", "SyncTrack", "Events", "ExpertSingle"])
                try assertEqual(doc.sections.map { $0.entries.count }, [4, 4, 2, 10])
                try assertTrue(doc.isChart)
                try assertTrue(doc.problems.isEmpty, "\(doc.problems)")
            }

            runner.runTest(name: "testBOMAndCRLFAreHandled") {
                let crlf = "\u{FEFF}" + sample.replacingOccurrences(of: "\n", with: "\r\n")
                let doc = ChartParser.parse(crlf)
                try assertEqual(doc.sections.first?.name, "Song", "BOM darf nicht im Namen landen")
                try assertEqual(doc.sections.map { $0.entries.count }, [4, 4, 2, 10])
                try assertEqual(doc.songValue("Name"), "Test Song", "kein \\r am Wert")
            }

            runner.runTest(name: "testEntryIsSplitIntoTickKindAndArguments") {
                let track = ChartParser.parse(sample).sections[3]
                let e = track.entries[1]
                try assertEqual(e.tick, 480)
                try assertEqual(e.kind, "N")
                try assertEqual(e.args, ["1", "240"])
                let song = ChartParser.parse(sample).sections[0].entries[0]
                try assertEqual(song.key, "Name")
                try assertTrue(song.tick == nil, "Name ist kein Tick")
            }

            runner.runTest(name: "testSongValuesAreUnquoted") {
                let doc = ChartParser.parse(sample)
                try assertEqual(doc.songValue("Artist"), "Test Band")
                try assertEqual(doc.songValue("Resolution"), "480")
                try assertTrue(doc.songValue("Charter") == nil)
            }

            runner.runTest(name: "testEventTextKeepsSpacesAndQuotesAreRemoved") {
                let events = ChartParser.parse(sample).sections[2]
                try assertEqual(events.entries[1].kind, "E")
                try assertEqual(events.entries[1].text, "section Verse 1")
            }

            runner.runTest(name: "testUnclosedSectionIsKeptAndReported") {
                let doc = ChartParser.parse("[Song]\n{\n  Name = \"X\"\n")
                try assertEqual(doc.sections.count, 1)
                try assertEqual(doc.sections[0].entries.count, 1)
                try assertFalse(doc.problems.isEmpty, "fehlende } muss gemeldet werden")
            }

            runner.runTest(name: "testStrayLinesAreReportedWithTheirLineNumber") {
                let doc = ChartParser.parse("[Song]\n{\n  Name = \"X\"\n  kaputt\n}\nlose = 1\n")
                try assertEqual(doc.sections[0].entries.count, 1)
                try assertEqual(doc.problems.map(\.line), [4, 6])
            }

            runner.runTest(name: "testTextWithoutSectionsIsNoChart") {
                try assertFalse(ChartParser.parse("Hallo Welt\nnoch eine Zeile\n").isChart)
                try assertFalse(ChartParser.parse("").isChart)
            }
        }

        runner.suite("Chart timing") {
            runner.runTest(name: "testTicksBecomeSecondsAcrossTempoChanges") {
                let t = ChartTiming(document: ChartParser.parse(sample))
                try assertEqual(t.resolution, 480)
                // 120 BPM: ein Viertel (480 Ticks) = 0,5 s
                try assertTrue(abs(t.seconds(at: 480) - 0.5) < 1e-9, "\(t.seconds(at: 480))")
                try assertTrue(abs(t.seconds(at: 1920) - 2.0) < 1e-9)
                // ab 1920: 240 BPM, 480 Ticks = 0,25 s
                try assertTrue(abs(t.seconds(at: 2400) - 2.25) < 1e-9, "\(t.seconds(at: 2400))")
            }

            runner.runTest(name: "testEveryTempoSegmentUsesItsOwnTempo") {
                // Drei Tempi: erst ab dem DRITTEN Abschnitt zeigt sich, ob jeder Abschnitt
                // mit seinem eigenen Tempo zaehlt (mit nur zwei faellt ein Fehler nicht auf).
                let text = "[Song]\n{\n Resolution = 480\n}\n[SyncTrack]\n{\n 0 = B 120000\n 1920 = B 240000\n 3840 = B 60000\n}\n"
                let t = ChartTiming(document: ChartParser.parse(text))
                try assertTrue(abs(t.seconds(at: 3840) - 3.0) < 1e-9, "2 s + 1 s: \(t.seconds(at: 3840))")
                try assertTrue(abs(t.seconds(at: 4320) - 4.0) < 1e-9, "+ ein Viertel bei 60 BPM: \(t.seconds(at: 4320))")
            }

            runner.runTest(name: "testDefaultsWithoutResolutionOrTempo") {
                let t = ChartTiming(document: ChartParser.parse("[ExpertSingle]\n{\n  192 = N 0 0\n}\n"))
                try assertEqual(t.resolution, 192)
                try assertTrue(abs(t.seconds(at: 192) - 0.5) < 1e-9, "192 Ticks bei 120 BPM")
            }

            runner.runTest(name: "testTempoOrderInTheFileDoesNotMatter") {
                let text = "[Song]\n{\n Resolution = 480\n}\n[SyncTrack]\n{\n 1920 = B 240000\n 0 = B 120000\n}\n"
                let t = ChartTiming(document: ChartParser.parse(text))
                try assertTrue(abs(t.seconds(at: 2400) - 2.25) < 1e-9)
            }

            runner.runTest(name: "testTimeFormat") {
                try assertEqual(ChartTiming.format(0), "0:00.000")
                try assertEqual(ChartTiming.format(83.456), "1:23.456")
                try assertEqual(ChartTiming.format(601.5), "10:01.500")
            }
        }

        runner.suite("Chart renderer") {
            runner.runTest(name: "testEverySectionStartsCollapsed") {
                let html = render(sample)
                try assertEqual(count("<details class=\"ch-sec\"", in: html), 4)
                try assertFalse(html.contains("<details open"), "Vorgabe: alles zugeklappt")
                try assertFalse(html.range(of: #"<details[^>]*\bopen\b"#, options: .regularExpression) != nil)
            }

            runner.runTest(name: "testSummaryCountsNotesStarPowerAndEvents") {
                let html = render(sample)
                try assertTrue(html.contains("8 Noten"), "8 N-Zeilen in ExpertSingle")
                try assertTrue(html.contains("1 Star Power"))
                try assertTrue(html.contains("2 Ereignisse"))
                try assertTrue(html.contains("4 Tempo/Takt"))
                try assertTrue(html.contains("4 Werte"))
            }

            runner.runTest(name: "testFretsGetTheirColoursAndSpecialFlags") {
                let html = render(sample)
                for f in 0...4 { try assertTrue(html.contains("class=\"ch-fret ch-f\(f)\""), "Bund \(f)") }
                try assertTrue(html.contains(">Force<"))
                try assertTrue(html.contains(">Tap<"))
                try assertTrue(html.contains(">Open<"))
                try assertTrue(html.contains("↦ 240"), "Sustain wird gezeigt")
            }

            runner.runTest(name: "testTempoAndTimeSignatureAreReadable") {
                let html = render(sample)
                try assertTrue(html.contains("120 BPM"))
                try assertTrue(html.contains("240 BPM"))
                try assertTrue(html.contains("4/4"))
                try assertTrue(html.contains("6/8"), "TS 6 3 = 6/2^3")
                try assertTrue(render("[SyncTrack]\n{\n 0 = B 175336\n}\n").contains("175,336 BPM"))
            }

            runner.runTest(name: "testSongTimeColumn") {
                let html = render(sample)
                try assertTrue(html.contains(">0:02.250<"), "Tick 2400 bei 120/240 BPM")
                try assertTrue(html.contains(">0:00.500<"))
            }

            runner.runTest(name: "testToolbarShowsArtistAndTitle") {
                let html = render(sample)
                try assertTrue(html.contains("Test Band – Test Song"))
                try assertTrue(html.contains(">CHART<"))
            }

            runner.runTest(name: "testEverythingIsEscaped") {
                let html = render("[Song]\n{\n Name = \"<b>x</b>\"\n}\n[Events]\n{\n 0 = E \"<script>alert(1)</script>\"\n}\n[<i>]\n{\n}\n")
                try assertFalse(html.contains("<script>alert"))
                try assertFalse(html.contains("<b>x"))
                try assertFalse(html.contains("[<i>]"))
                try assertTrue(html.contains("&lt;script&gt;"))
            }

            runner.runTest(name: "testLongSectionsAreCappedWithANotice") {
                var lines = ["[ExpertSingle]", "{"]
                for i in 0..<(ChartPreviewRenderer.maxRowsPerSection + 7) { lines.append("  \(i * 10) = N 0 0") }
                lines.append("}")
                let html = render(lines.joined(separator: "\n"))
                try assertEqual(count("<tr", in: html), ChartPreviewRenderer.maxRowsPerSection)
                try assertTrue(html.contains("7 weitere Einträge nicht dargestellt"))
                try assertTrue(html.contains("\(ChartPreviewRenderer.maxRowsPerSection + 7) Noten"),
                               "Zusammenfassung zaehlt alle, nicht nur die gezeigten")
            }

            runner.runTest(name: "testTotalRowsAreCappedAcrossSections") {
                // Genug Abschnitte, dass die Gesamtgrenze VOR der Abschnittsgrenze greift.
                let per = ChartPreviewRenderer.maxRowsPerSection
                let sections = ChartPreviewRenderer.maxRowsTotal / per + 2
                var lines: [String] = []
                for s in 0..<sections {
                    lines += ["[Track\(s)]", "{"]
                    for i in 0..<per { lines.append("  \(i) = N 1 0") }
                    lines.append("}")
                }
                let html = render(lines.joined(separator: "\n"))
                try assertEqual(count("<tr", in: html), ChartPreviewRenderer.maxRowsTotal)
                try assertEqual(count("<details class=\"ch-sec\"", in: html), sections,
                                "jeder Abschnitt bleibt als Zeile sichtbar, auch ohne Tabelle")
                try assertTrue(html.contains("\(per) weitere Einträge nicht dargestellt"),
                               "Abschnitte hinter der Grenze sagen, was fehlt")
            }

            runner.runTest(name: "testChartsAreReadUpToEightMegabytes") {
                try assertEqual(ChartPreviewRenderer.readStrategy, .headAtMost(maxBytes: 8 * 1024 * 1024))
                let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("loupe-\(UUID()).chart")
                try Data(repeating: 65, count: 5000).write(to: file)
                defer { try? FileManager.default.removeItem(at: file) }
                let r = try PreviewFileReader.read(url: file, strategy: .headAtMost(maxBytes: 1000), headLimit: 1 << 20)
                try assertEqual(r.data.count, 1000, "die kleinere Grenze gilt")
                try assertTrue(r.truncatedAtEnd)
                let g = try PreviewFileReader.read(url: file, strategy: .headAtMost(maxBytes: 1 << 20), headLimit: 2000)
                try assertEqual(g.data.count, 2000, "die allgemeine Grenze gilt, wenn sie kleiner ist")
                let whole = try PreviewFileReader.read(url: file, strategy: .headAtMost(maxBytes: 9000), headLimit: 1 << 20)
                try assertEqual(whole.data.count, 5000)
                try assertFalse(whole.truncatedAtEnd)
            }

            runner.runTest(name: "testTextWithoutSectionsFallsBackToPlainText") {
                let html = render("Das hier ist\nkein <Chart>\n")
                try assertFalse(html.contains("<details"))
                try assertTrue(html.contains("kein &lt;Chart&gt;"))
                try assertTrue(html.contains("Keine Chart-Abschnitte erkannt"))
            }

            runner.runTest(name: "testParserProblemsAreShownAsANotice") {
                let html = render("[Song]\n{\n Name = \"X\"\n kaputt\n}\n")
                try assertTrue(html.contains("lp-banner"))
                try assertTrue(html.contains("Zeile 4"))
            }

            runner.runTest(name: "testTruncatedFileSaysSo") {
                try assertTrue(render(sample, truncated: true).contains("nur der Anfang wurde gelesen"))
            }

            runner.runTest(name: "testNoScriptsAndStrictCSP") {
                let html = render(sample)
                try assertFalse(html.lowercased().contains("<script"))
                try assertTrue(html.contains("default-src 'none'"))
            }

            runner.runTest(name: "testChartColorsMeetWCAGAAInBothThemes") {
                for appearance in [LoupeAppearance.light, .dark] {
                    var s = LoupeSettings()
                    s.appearance = appearance
                    let vars = cssVariables(CSSGenerator.generateChartCSS(settings: s))
                    let bg = try unwrap(vars["--bg-code"].flatMap(hexRGB))
                    for name in ["--ch-f0", "--ch-f1", "--ch-f2", "--ch-f3", "--ch-f4", "--ch-flag",
                                 "--ch-sp", "--ch-ev", "--ch-sync", "--ch-tick", "--ch-time", "--ch-dim"] {
                        let fg = try unwrap(vars[name].flatMap(hexRGB))
                        let ratio = contrast(fg, bg)
                        try assertTrue(ratio >= 4.5, "\(appearance) \(name): \(String(format: "%.2f", ratio)):1")
                    }
                }
            }
        }

        runner.suite("Chart integration") {
            runner.runTest(name: "testChartFilesGoToTheChartRenderer") {
                for name in ["notes.chart", "NOTES.CHART", "song.Chart"] {
                    try assertTrue(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/\(name)")) is ChartPreviewRenderer, name)
                }
                try assertFalse(RendererRegistry.renderer(for: URL(fileURLWithPath: "/tmp/a.json")) is ChartPreviewRenderer)
            }

            runner.runTest(name: "testChartHasItsOwnCategory") {
                try assertEqual(ChartPreviewRenderer.category, .chart)
                try assertEqual(PreviewCategory.chart.displayName(.de), "Charts (.chart)")
                try assertEqual(PreviewCategory.chart.displayName(.en), "Charts (.chart)")
            }

            runner.runTest(name: "testChartTypeIsDeclaredAndReachable") {
                let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                func plist(_ p: String) throws -> [String: Any] {
                    try PropertyListSerialization.propertyList(from: Data(contentsOf: root.appendingPathComponent(p)),
                                                               format: nil) as? [String: Any] ?? [:]
                }
                let app = try plist("Sources/Loupe/Resources/Info.plist")
                let exported = (app["UTExportedTypeDeclarations"] as? [[String: Any]]) ?? []
                let decl = exported.first { ($0["UTTypeIdentifier"] as? String) == ChartPreviewRenderer.typeIdentifier }
                let tags = (decl?["UTTypeTagSpecification"] as? [String: Any])?["public.filename-extension"] as? [String]
                try assertEqual(tags, ["chart"])
                try assertTrue(((decl?["UTTypeConformsTo"] as? [String]) ?? []).contains("public.plain-text"),
                               "als Text deklariert -- sonst faellt die Rohtext-Anzeige bei 'aus' weg")
                let ext = try plist("Sources/LoupePreview/Resources/Info.plist")
                let attrs = ((ext["NSExtension"] as? [String: Any])?["NSExtensionAttributes"] as? [String: Any]) ?? [:]
                try assertTrue(((attrs["QLSupportedContentTypes"] as? [String]) ?? []).contains(ChartPreviewRenderer.typeIdentifier))
            }
        }
    }

    // MARK: Kontrast-Helfer (wie bei den Logs)

    nonisolated static func cssVariables(_ css: String) -> [String: String] {
        var out: [String: String] = [:]
        for line in css.split(separator: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("--"), let colon = t.firstIndex(of: ":") else { continue }
            let key = String(t[..<colon])
            let value = t[t.index(after: colon)...].trimmingCharacters(in: CharacterSet(charactersIn: " ;"))
            if out[key] == nil { out[key] = value }
        }
        return out
    }

    nonisolated static func hexRGB(_ s: String) -> (Double, Double, Double)? {
        let v = s.split(separator: " ").first.map(String.init) ?? s
        guard v.hasPrefix("#"), v.count == 7, let n = Int(v.dropFirst(), radix: 16) else { return nil }
        return (Double((n >> 16) & 0xff) / 255, Double((n >> 8) & 0xff) / 255, Double(n & 0xff) / 255)
    }

    nonisolated static func contrast(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
        func lin(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        func lum(_ c: (Double, Double, Double)) -> Double { 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2) }
        let (l1, l2) = (lum(a), lum(b))
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
}
