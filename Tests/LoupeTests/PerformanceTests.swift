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
                #if DEBUG
                let threshold = 150.0 // Debug-Builds ohne Optimierungen auf Shared CI-Runnern
                #else
                let threshold = 50.0
                #endif
                try assertLessThan(ms, threshold)
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
                #if DEBUG
                let threshold = 2500.0 // Debug-Builds ohne Optimierungen auf Shared CI-Runnern
                #else
                let threshold = 1000.0
                #endif
                try assertLessThan(ms, threshold)
                // Die Knotengrenze muss greifen, sonst waere das HTML riesig.
                try assertLessThan(html.utf8.count, 12 * 1024 * 1024)
            }

            runner.runTest(name: "testFourMegabyteLogUnderOneSecond") {
                // Genau die Menge, die der Log-Renderer vom Dateiende liest.
                var lines: [String] = []
                var bytes = 0
                var i = 0
                let levels = ["INFO", "DEBUG", "WARN", "ERROR"]
                while bytes < LogPreviewRenderer.tailBytes {
                    let line = "2026-09-24 17:01:\(String(format: "%02d", i % 60)).\(i % 1000) \(levels[i % 4]) [worker-\(i % 8)] request id=\(i) took \(i % 500)ms from 10.0.\(i % 256).7 path=/api/v1/items/\(i)"
                    lines.append(line)
                    bytes += line.utf8.count + 1
                    i += 1
                }
                let input = PreviewInput(data: Data(lines.joined(separator: "\n").utf8),
                                         url: URL(fileURLWithPath: "/tmp/big.log"),
                                         wasTruncatedByReader: false,
                                         skippedBytesAtStart: 1)
                let start = CFAbsoluteTimeGetCurrent()
                let html = LogPreviewRenderer().renderHTML(input: input, settings: LoupeSettings())
                let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
                #if DEBUG
                // Debug ~1,2 s auf einem M1 Pro; geteilte CI-Runner sind deutlich langsamer.
                // Gleicher Puffer (~3,7x) wie beim 5-MB-JSON-Test. Release bleibt bei 1 s.
                let threshold = 4500.0
                #else
                let threshold = 1000.0
                #endif
                try assertLessThan(ms, threshold)
                // Die Zeilengrenze muss greifen: 5000 Zeilen, nicht ~40.000.
                try assertTrue(html.contains("5000 Zeilen"))
            }
        }
    }
}
