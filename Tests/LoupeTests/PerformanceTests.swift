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
